import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Web implementation of the embedded IFrame widget using HtmlElementView.
class IFramePlatformWidget extends StatefulWidget {
  final String url;
  final String title;

  const IFramePlatformWidget({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<IFramePlatformWidget> createState() => _IFramePlatformWidgetState();
}

class _IFramePlatformWidgetState extends State<IFramePlatformWidget> {
  late final String _viewType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Unique deterministic viewType per URL
    final sanitizedKey = widget.url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    _viewType = 'addon_iframe_${sanitizedKey}_${widget.url.hashCode.abs()}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = widget.url;
      iframe.title = widget.title;
      iframe.setAttribute('style', 'border: none; width: 100%; height: 100%;');
      iframe.setAttribute('sandbox', 'allow-scripts allow-same-origin allow-forms allow-popups allow-modals');

      iframe.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        HtmlElementView(viewType: _viewType),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
