part of 'commerce_app.dart';

extension on _CommerceAppState {
  Future<void> _prepareStorefront() async {
    await _shell.load();
    if (!mounted) return;
    _showStorefront();
  }
}
