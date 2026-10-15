import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../../domain/models/plugin_session_context.dart';

/// Web implementation of the embedded IFrame widget supporting PostMessage session dispatch.
class IFramePlatformWidget extends StatefulWidget {
  final String url;
  final String title;
  final PluginSessionContext sessionContext;

  const IFramePlatformWidget({
    super.key,
    required this.url,
    required this.title,
    required this.sessionContext,
  });

  @override
  State<IFramePlatformWidget> createState() => _IFramePlatformWidgetState();
}

class _IFramePlatformWidgetState extends State<IFramePlatformWidget> {
  late final String _viewType;
  late final Uri _targetUri;
  web.HTMLIFrameElement? _iframeElement;
  web.EventListener? _messageListener;
  bool _isLoading = true;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _targetUri = Uri.parse(widget.url);
    final sanitizedKey = widget.url.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    _viewType = 'addon_iframe_${sanitizedKey}_${widget.url.hashCode.abs()}';

    // 1. Setup bidirectional message listener using type-safe JS interop
    _messageListener = (web.Event event) {
      if (!event.isA<web.MessageEvent>()) return;
      final messageEvent = event as web.MessageEvent;

      // Origin guardrail: only accept messages from the target iframe origin
      if (messageEvent.origin != _targetUri.origin) return;

      final data = messageEvent.data;
      if (data == null || !data.isA<JSObject>()) return;

      try {
        final dartData = data.dartify();
        if (dartData is Map) {
          final type = dartData['type']?.toString();
          if (type == 'PLUGIN_READY') {
            debugPrint('[Host Bridge] Received PLUGIN_READY handshake. Dispatching INIT_SESSION.');
            _dispatchSessionEnvelope();
          }
        }
      } catch (e) {
        // Ignore parsing errors from untracked frames
      }
    }.toJS;

    web.window.addEventListener('message', _messageListener!);

    // 2. Register Platform View
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = widget.url;
      iframe.title = widget.title;
      iframe.setAttribute('style', 'border: none; width: 100%; height: 100%;');
      iframe.setAttribute(
        'sandbox',
        'allow-scripts allow-same-origin allow-forms allow-popups allow-modals',
      );

      iframe.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        // Fallback: Dispatch session context after iframe finishes initial DOM load
        _fallbackTimer?.cancel();
        _fallbackTimer = Timer(const Duration(milliseconds: 300), () {
          _dispatchSessionEnvelope();
        });
      });

      _iframeElement = iframe;
      return iframe;
    });
  }

  /// Dispatches the bootstrap session envelope containing JWT and fiscal context.
  void _dispatchSessionEnvelope() {
    if (_iframeElement?.contentWindow == null) return;

    final envelope = {
      'type': 'INIT_SESSION',
      'payload': widget.sessionContext.toJson(),
    };

    try {
      final jsPayload = envelope.jsify();
      _iframeElement!.contentWindow!.postMessage(
        jsPayload,
        _targetUri.origin.toJS,
      );
      debugPrint('[Host Bridge] Successfully posted INIT_SESSION to ${_targetUri.origin}');
    } catch (e) {
      debugPrint('[Host Bridge] Error posting message to iframe: $e');
    }
  }

  @override
  void didUpdateWidget(covariant IFramePlatformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionContext != widget.sessionContext) {
      _dispatchSessionEnvelope();
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    if (_messageListener != null) {
      web.window.removeEventListener('message', _messageListener!);
    }
    super.dispose();
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
