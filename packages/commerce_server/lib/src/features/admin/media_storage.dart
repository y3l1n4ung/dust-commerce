import 'dart:io';

import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_server/server.dart';

/// Minimal storage-owned identity used while product attachment is in flight.
typedef AdminMediaClaim = ({String id, String url});

/// Maximum number of bytes accepted for one product image.
const int adminMediaFileLimit = 5 * 1024 * 1024;

/// Maximum number of images accepted in one upload request or product.
const int adminMediaFileCountLimit = 10;

/// Why a merchant upload cannot be stored.
enum AdminMediaFailure {
  /// The configured storage adapter is unavailable.
  unavailable,

  /// The part is empty or its signature is not a supported image.
  invalidImage,

  /// The request contains no files or too many files.
  invalidCount,
}

/// Typed media failure kept out of public response details.
final class AdminMediaException implements Exception {
  /// Creates a media failure.
  const AdminMediaException(this.failure);

  /// Classified failure mapped by the HTTP boundary.
  final AdminMediaFailure failure;
}

/// One immutable file ready to stream to a public product surface.
final class AdminStoredMediaAsset {
  /// Creates a stored media read result.
  const AdminStoredMediaAsset({
    required this.file,
    required this.mimeType,
    required this.size,
  });

  /// File opened only after the opaque key has passed validation.
  final File file;

  /// Content type inferred from the key written after signature validation.
  final String mimeType;

  /// Exact content length used by the public response.
  final int size;
}

/// Storage boundary used by upload, product creation, deletion, and reads.
abstract interface class AdminMediaStorage {
  /// Persists one streamed multipart file under a server-generated key.
  Future<AdminUploadedFile> store(MultipartPart part);

  /// Opens one public immutable file by opaque key.
  Future<Option<AdminStoredMediaAsset>> find(String key);

  /// Deletes one unreferenced staged file.
  Future<bool> delete(String key);

  /// Whether [key] and [url] are a pair issued by this storage adapter.
  bool accepts(String key, String url);

  /// Reserves existing staged files while a product transaction attaches them.
  bool claim(List<AdminMediaClaim> media);

  /// Releases reservations after the product transaction finishes.
  void release(List<AdminMediaClaim> media);

  /// Public URL corresponding to [key].
  String urlFor(String key);
}

/// Safe default for tests and embeddings that do not configure file storage.
final class UnavailableAdminMediaStorage implements AdminMediaStorage {
  /// Creates an unavailable storage adapter.
  const UnavailableAdminMediaStorage();

  @override
  bool accepts(String key, String url) => false;

  @override
  bool claim(List<AdminMediaClaim> media) => media.isEmpty;

  @override
  Future<bool> delete(String key) async => false;

  @override
  Future<Option<AdminStoredMediaAsset>> find(String key) async => const None();

  @override
  Future<AdminUploadedFile> store(MultipartPart part) async =>
      throw const AdminMediaException(AdminMediaFailure.unavailable);

  @override
  void release(List<AdminMediaClaim> media) {}

  @override
  String urlFor(String key) => '';
}

/// Durable single-node media storage with streamed, signature-checked writes.
final class LocalAdminMediaStorage implements AdminMediaStorage {
  /// Creates a local storage adapter.
  LocalAdminMediaStorage({
    required Directory root,
    required Uri publicBaseUrl,
    required String Function() nextKey,
  })  : _root = root,
        _baseUrl = publicBaseUrl.toString().replaceFirst(RegExp(r'/$'), ''),
        _nextKey = nextKey;

  final Directory _root;
  final String _baseUrl;
  final String Function() _nextKey;
  final Set<String> _claimed = {};
  final Set<String> _deleting = {};

  /// Creates the storage directory before the server accepts traffic.
  Future<void> prepare() => _root.create(recursive: true);

  @override
  bool accepts(String key, String url) =>
      _validKey.hasMatch(key) && url == urlFor(key);

  @override
  bool claim(List<AdminMediaClaim> media) {
    final keys = media.map((item) => item.id).toList();
    if (keys.toSet().length != keys.length ||
        media.any((item) =>
            !accepts(item.id, item.url) ||
            _claimed.contains(item.id) ||
            _deleting.contains(item.id) ||
            !File('${_root.path}/${item.id}').existsSync())) {
      return false;
    }
    _claimed.addAll(keys);
    return true;
  }

  @override
  Future<bool> delete(String key) async {
    if (!_validKey.hasMatch(key) ||
        _claimed.contains(key) ||
        !_deleting.add(key)) {
      return false;
    }
    final file = File('${_root.path}/$key');
    try {
      if (!file.existsSync()) return false;
      await file.delete();
      return true;
    } finally {
      _deleting.remove(key);
    }
  }

  @override
  Future<Option<AdminStoredMediaAsset>> find(String key) async {
    if (!_validKey.hasMatch(key)) return const None();
    final format = _formatForKey(key);
    if (format == null) return const None();
    final file = File('${_root.path}/$key');
    if (!file.existsSync()) return const None();
    return Some(AdminStoredMediaAsset(
      file: file,
      mimeType: format.mimeType,
      size: await file.length(),
    ));
  }

  @override
  Future<AdminUploadedFile> store(MultipartPart part) async {
    if (!part.isFile) {
      throw const AdminMediaException(AdminMediaFailure.invalidImage);
    }
    await prepare();
    final opaque = _nextKey();
    if (!_opaqueKey.hasMatch(opaque)) {
      throw StateError('Media storage generated an unsafe key');
    }
    final pending = File('${_root.path}/.$opaque.pending');
    final sink = pending.openWrite(mode: FileMode.writeOnly);
    int size;
    try {
      size = await part.writeTo(sink, limit: adminMediaFileLimit);
    } on Object {
      await sink.close();
      if (pending.existsSync()) await pending.delete();
      rethrow;
    }
    await sink.close();

    try {
      if (size == 0) {
        throw const AdminMediaException(AdminMediaFailure.invalidImage);
      }
      final opened = await pending.open();
      final header = await opened.read(12);
      await opened.close();
      final format = _MediaFormat.fromHeader(header);
      if (format == null) {
        throw const AdminMediaException(AdminMediaFailure.invalidImage);
      }
      final key = '$opaque.${format.extension}';
      final stored = await pending.rename('${_root.path}/$key');
      return AdminUploadedFile(
        id: key,
        url: urlFor(key),
        filename: _safeFilename(part.filename!, format.extension),
        mimeType: format.mimeType,
        size: await stored.length(),
      );
    } on Object {
      if (pending.existsSync()) await pending.delete();
      rethrow;
    }
  }

  @override
  String urlFor(String key) => '$_baseUrl/uploads/$key';

  @override
  void release(List<AdminMediaClaim> media) {
    _claimed.removeAll(media.map((item) => item.id));
  }

  static final RegExp _opaqueKey = RegExp(r'^[A-Za-z0-9_-]{8,128}$');
  static final RegExp _validKey =
      RegExp(r'^[A-Za-z0-9_-]{8,128}\.(?:jpg|png|gif|webp)$');

  static _MediaFormat? _formatForKey(String key) =>
      switch (key.split('.').last) {
        'jpg' => _MediaFormat.jpeg,
        'png' => _MediaFormat.png,
        'gif' => _MediaFormat.gif,
        'webp' => _MediaFormat.webp,
        _ => null,
      };

  static String _safeFilename(String source, String extension) {
    final leaf = source.split(RegExp(r'[/\\]')).last;
    final printable = leaf.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (printable.isEmpty) return 'image.$extension';
    return printable.length <= 255 ? printable : printable.substring(0, 255);
  }
}

enum _MediaFormat {
  jpeg('jpg', 'image/jpeg'),
  png('png', 'image/png'),
  gif('gif', 'image/gif'),
  webp('webp', 'image/webp');

  const _MediaFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;

  static _MediaFormat? fromHeader(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return jpeg;
    }
    if (bytes.length >= 8 &&
        _matches(
            bytes, const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) {
      return png;
    }
    if (bytes.length >= 6 &&
        (_matches(bytes, 'GIF87a'.codeUnits) ||
            _matches(bytes, 'GIF89a'.codeUnits))) {
      return gif;
    }
    if (bytes.length >= 12 &&
        _matches(bytes, 'RIFF'.codeUnits) &&
        _matches(bytes, 'WEBP'.codeUnits, offset: 8)) {
      return webp;
    }
    return null;
  }

  static bool _matches(List<int> bytes, List<int> signature, {int offset = 0}) {
    if (bytes.length < offset + signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[offset + index] != signature[index]) return false;
    }
    return true;
  }
}
