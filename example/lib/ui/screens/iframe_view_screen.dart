import 'package:flutter/material.dart';
import '../../domain/models/plugin_session_context.dart';
import '../widgets/iframe/iframe_view.dart';

/// Screen hosting an embedded IFrame with session context and adaptive controls.
class IFrameViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final PluginSessionContext sessionContext;

  const IFrameViewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.sessionContext,
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
    final ctx = widget.sessionContext.context;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${ctx.companyId} • ${ctx.finYear}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
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
            tooltip: 'Reload IFrame & Re-send Token',
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
        sessionContext: widget.sessionContext,
      ),
    );
  }
}
