part of 'admin_product_media_editor.dart';

extension on _AdminProductMediaEditorState {
  Widget _mediaTile(int index, bool busy) {
    final item = _media[index];
    return Padding(
      key: ValueKey(item.id),
      padding: const EdgeInsets.only(right: 18),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.url,
                        fit: BoxFit.cover,
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Icon(Icons.image_outlined),
                        ),
                      ),
                    ),
                  ),
                  if (item.isThumbnail)
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: _ThumbnailBadge(),
                    ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: PopupMenuButton<_MediaEditorAction>(
                      enabled: !busy,
                      tooltip: 'Image actions',
                      onSelected: (action) => switch (action) {
                        _MediaEditorAction.thumbnail => _makeThumbnail(index),
                        _MediaEditorAction.delete => _remove(index),
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _MediaEditorAction.thumbnail,
                          child: Text('Make thumbnail'),
                        ),
                        PopupMenuItem(
                          value: _MediaEditorAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  enabled: !busy,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.drag_indicator_rounded, size: 18),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _failureBanner(String message) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      );
}

final class _ThumbnailBadge extends StatelessWidget {
  const _ThumbnailBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(5),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 4)],
        ),
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(Icons.photo_size_select_actual_outlined, size: 14),
        ),
      );
}

enum _MediaEditorAction { thumbnail, delete }
