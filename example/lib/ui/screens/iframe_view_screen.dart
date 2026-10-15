import 'package:flutter/material.dart';

import '../widgets/iframe/iframe_view.dart';

/// Screen hosting an embedded IFrame with Material 3 navigation and controls.
class IFrameViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const IFrameViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<IFrameViewScreen> createState() => _IFrameViewScreenState();
}

class _IFrameViewScreenState extends State<IFrameViewScreen> {
  int _reloadCounter = 0;

  void _reload() {
    setState(() {
      _reloadCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Main Menu',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload IFrame',
            onPressed: _reload,
          ),
          const SizedBox(width: 8),
        ],
        elevation: 1,
      ),
      body: IFramePlatformWidget(
        key: ValueKey('${widget.url}_$_reloadCounter'),
        url: widget.url,
        title: widget.title,
      ),
    );
  }
}
