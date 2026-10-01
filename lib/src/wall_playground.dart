import 'dart:js' as js;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class Stroke {
  final List<Offset> points;
  Color color; // mutable so theme-toggle can flip it
  final double strokeWidth;
  final bool isThemeColor; // true = drawn with auto theme color (black/white)
  final bool isEraser;

  Stroke(this.points, this.color, this.strokeWidth,
      {this.isThemeColor = false, this.isEraser = false});
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isThemeColor': isThemeColor,
      'isEraser': isEraser,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      (json['points'] as List)
          .map((p) =>
              Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
      Color((json['color'] as num).toInt()),
      (json['strokeWidth'] as num).toDouble(),
      isThemeColor: json['isThemeColor'] ?? false,
      isEraser: json['isEraser'] ?? false,
    );
  }
}

enum CanvasItemType { note, sticker, gif }

class CanvasItem {
  final String id;
  CanvasItemType type;
  Offset position;
  double scale;
  double rotation;
  Color color;
  String content;
  int zIndex;
  double width;
  double height;

  CanvasItem({
    required this.id,
    required this.type,
    this.position = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.color = Colors.white,
    this.content = '',
    this.zIndex = 0,
    this.width = 240,
    this.height = 240,
  });
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'position': {'dx': position.dx, 'dy': position.dy},
      'scale': scale,
      'rotation': rotation,
      'color': color.value,
      'content': content,
      'zIndex': zIndex,
      'width': width,
      'height': height,
    };
  }

  factory CanvasItem.fromJson(Map<String, dynamic> json) {
    return CanvasItem(
      id: json['id'],
      type: CanvasItemType.values[json['type'] ?? 0],
      position: Offset((json['position']['dx'] as num).toDouble(),
          (json['position']['dy'] as num).toDouble()),
      scale: (json['scale'] as num).toDouble(),
      rotation: (json['rotation'] as num).toDouble(),
      color: Color((json['color'] as num).toInt()),
      content: json['content'],
      zIndex: (json['zIndex'] as num).toInt(),
      width: (json['width'] as num?)?.toDouble() ?? 240.0,
      height: (json['height'] as num?)?.toDouble() ?? 240.0,
    );
  }
}

// ─── Undo/Redo removed ───────────────────────────────────────────────────────

// ─── Widget ──────────────────────────────────────────────────────────────────

class WallPlayground extends StatefulWidget {
  /// Called whenever the list of canvas items (notes) changes.
  final void Function(List<CanvasItem> items)? onItemsChanged;

  /// Called whenever the list of strokes changes.
  final void Function(List<Stroke> strokes)? onStrokesChanged;

  /// Called when drawing mode is toggled.
  final void Function(bool isDrawing)? onDrawingModeChanged;

  /// Pre-load items saved by the parent (e.g. from local storage).
  final List<CanvasItem>? initialItems;

  /// Pre-load strokes saved by the parent.
  final List<Stroke>? initialStrokes;

  const WallPlayground({
    super.key,
    this.onItemsChanged,
    this.onStrokesChanged,
    this.onDrawingModeChanged,
    this.initialItems,
    this.initialStrokes,
  });

  @override
  State<WallPlayground> createState() => _WallPlaygroundState();
}

class _WallPlaygroundState extends State<WallPlayground> {
  late List<CanvasItem> _items;
  late List<Stroke> _strokes;
  List<Offset> _currentStroke = [];

  bool _isDarkMesh = false;
  bool _isDrawingMode = false;
  bool _isEraserMode = false;
  double _eraserSize = 20.0;
  int _maxZIndex = 0;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.initialItems ?? []);
    _strokes = List.of(widget.initialStrokes ?? []);
    if (_items.isNotEmpty) {
      _maxZIndex = _items.map((i) => i.zIndex).reduce((a, b) => a > b ? a : b);
    }
  }

  // Notify parent of items change
  void _notifyItems() {
    widget.onItemsChanged?.call(List.unmodifiable(_items));
  }

  // Notify parent of strokes change
  void _notifyStrokes() {
    widget.onStrokesChanged?.call(List.unmodifiable(_strokes));
  }

  // ── Draw color ──
  Color _drawColor = Colors.black;
  bool _customColorSelected = false;
  bool _showColorPicker = false;

  static const List<Color> _drawPalette = [
    Colors.black,
    Colors.white,
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFFFF6F00),
    Color(0xFF8E24AA),
    Color(0xFF00ACC1),
    Color(0xFFFF4081),
  ];

  // Undo/Redo removed

  // ── Note colors ──
  final List<Color> _noteColors = [
    // Yellows & Oranges
    const Color(0xFFFFF7D1), // classic sticky yellow
    const Color(0xFFFFE0A3), // warm peach
    const Color(0xFFFFCB77), // golden amber
    const Color(0xFFFFD4A8), // soft apricot
    // Pinks & Reds
    const Color(0xFFFFE4E1), // blush rose
    const Color(0xFFFFB3C1), // bubblegum pink
    const Color(0xFFFFCDD2), // soft red
    const Color(0xFFF8BBD0), // dusty pink
    // Greens
    const Color(0xFFDDF5DF), // mint green
    const Color(0xFFB7E4C7), // sage
    const Color(0xFFCCF2D4), // fresh lime
    const Color(0xFFD4EDDA), // seafoam
    // Blues & Purples
    const Color(0xFFD4F0F0), // sky blue
    const Color(0xFFBBDEFB), // powder blue
    const Color(0xFFF3E8FF), // lavender
    const Color(0xFFE1BEE7), // soft violet
  ];

  int _colorIndex = 0;

  // Always black draw color unless user picked a custom one
  Color get _activeDrawColor =>
      _customColorSelected ? _drawColor : Colors.black;

  // Undo logic removed

  // ── Actions ───────────────────────────────────────────────────────────────

  // ── iOS-style pop sound via Web Audio API ──────────────────────────────
  void _playPopSound() {
    try {
      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            var ctx = new (window.AudioContext || window.webkitAudioContext)();
            // First tone: high
            var o1 = ctx.createOscillator();
            var g1 = ctx.createGain();
            o1.connect(g1); g1.connect(ctx.destination);
            o1.type = 'sine';
            o1.frequency.setValueAtTime(1200, ctx.currentTime);
            o1.frequency.exponentialRampToValueAtTime(900, ctx.currentTime + 0.06);
            g1.gain.setValueAtTime(0.18, ctx.currentTime);
            g1.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.12);
            o1.start(ctx.currentTime);
            o1.stop(ctx.currentTime + 0.12);
            // Second tone: low
            var o2 = ctx.createOscillator();
            var g2 = ctx.createGain();
            o2.connect(g2); g2.connect(ctx.destination);
            o2.type = 'sine';
            o2.frequency.setValueAtTime(700, ctx.currentTime + 0.05);
            o2.frequency.exponentialRampToValueAtTime(500, ctx.currentTime + 0.14);
            g2.gain.setValueAtTime(0.12, ctx.currentTime + 0.05);
            g2.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.18);
            o2.start(ctx.currentTime + 0.05);
            o2.stop(ctx.currentTime + 0.18);
          } catch(e) {}
        })();
        '''
      ]);
    } catch (_) {}
  }

  void _addNote() {
    final item = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: CanvasItemType.note,
      position: Offset(
        MediaQuery.of(context).size.width / 2 - 120,
        MediaQuery.of(context).size.height / 2 - 120,
      ),
      color: _noteColors[_colorIndex % _noteColors.length],
      zIndex: ++_maxZIndex,
    );
    setState(() {
      _items.add(item);
      _colorIndex++;
    });
    // Undo pushed here previously
    _notifyItems();
    _playPopSound();
    HapticFeedback.mediumImpact();
  }

  void _clearCanvas() {
    if (_items.isEmpty && _strokes.isEmpty) return;
    _showClearConfirmation();
  }

  Future<void> _showClearConfirmation() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: Center(
              child: _IosAlertDialog(
                title: 'Clear Wall',
                message: 'All notes and drawings will be permanently removed.',
                onCancel: () => Navigator.of(ctx).pop(false),
                onConfirm: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed == true) {
      setState(() {
        _items.clear();
        _strokes.clear();
        _isDrawingMode = false;
        _isEraserMode = false;
        _showColorPicker = false;
      });
      _notifyItems();
      _notifyStrokes();
      widget.onDrawingModeChanged?.call(false);
      HapticFeedback.heavyImpact();
    }
  }

  void _toggleDrawMode() {
    setState(() {
      if (_isDrawingMode && !_isEraserMode) {
        _isDrawingMode = false;
      } else {
        _isDrawingMode = true;
        _isEraserMode = false;
      }
      _showColorPicker = false;
    });
    widget.onDrawingModeChanged?.call(_isDrawingMode);
    HapticFeedback.selectionClick();
  }

  void _toggleEraserMode() {
    setState(() {
      if (_isDrawingMode && _isEraserMode) {
        _isDrawingMode = false;
      } else {
        _isDrawingMode = true;
        _isEraserMode = true;
      }
      _showColorPicker = false;
    });
    widget.onDrawingModeChanged?.call(_isDrawingMode);
    HapticFeedback.selectionClick();
  }

  void _toggleBg() {}

  // kept for stroke color compat — always light, no-op

  void _bringToFront(CanvasItem item) {
    if (item.zIndex != _maxZIndex) {
      setState(() {
        _maxZIndex++;
        item.zIndex = _maxZIndex;
        _items.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      });
      _notifyItems();
    }
  }

  void _removeItem(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    setState(() {
      _items.removeWhere((i) => i.id == id);
    });
    // Undo pushed here previously
    _notifyItems();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background — always light
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
                ),
              ),
            ),
          ),

          // Empty State
          if (_items.isEmpty && _strokes.isEmpty)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 64,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notes or Drawings',
                      style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.3),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap + Note or start drawing to add to your wall',
                      style: TextStyle(
                        fontFamily: GoogleFonts.poppins().fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Drawing Render Layer (moved below items)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: DrawingPainter(_strokes),
              ),
            ),
          ),

          // Current Drawing Overlay
          if (_isDrawingMode)
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _currentStroke = [details.localPosition];
                    _strokes.add(Stroke(
                      _currentStroke,
                      _isEraserMode ? Colors.transparent : _activeDrawColor,
                      _isEraserMode ? _eraserSize : 4.0,
                      isThemeColor: !_isEraserMode && !_customColorSelected,
                      isEraser: _isEraserMode,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  if (_strokes.isNotEmpty && _currentStroke.isNotEmpty) {
                    _notifyStrokes();
                  }
                  setState(() => _currentStroke = []);
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // Canvas Items
          ..._items.map((item) => _buildCanvasItem(item)),

          // Color picker panel (only in draw mode)
          if (_isDrawingMode && !_isEraserMode && _showColorPicker)
            _buildColorPickerPanel(),

          if (_isDrawingMode && _isEraserMode) _buildEraserSizePanel(),

          // Toolbar — bottom center
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(child: _buildGlassDock()),
          ),
        ],
      ),
    );
  }

  // ── Color picker panel ────────────────────────────────────────────────────

  Widget _buildColorPickerPanel() {
    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _drawPalette.map((color) {
                final isSelected = _activeDrawColor == color;
                return GestureDetector(
                  onTap: () => setState(() {
                    _drawColor = color;
                    _customColorSelected = true;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 24 : 18,
                    height: isSelected ? 24 : 18,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black45 : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1)
                            ]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEraserSizePanel() {
    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.blur_circular,
                    size: 16, color: Colors.black54),
                Expanded(
                  child: SliderTheme(
                    data: const SliderThemeData(
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.blueAccent,
                      inactiveTrackColor: Colors.black12,
                      thumbColor: Colors.blueAccent,
                    ),
                    child: Slider(
                      value: _eraserSize,
                      min: 10.0,
                      max: 80.0,
                      onChanged: (val) {
                        setState(() {
                          _eraserSize = val;
                        });
                      },
                    ),
                  ),
                ),
                const Icon(Icons.circle, size: 24, color: Colors.black54),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDockButton(Icons.note_add_rounded, '+ Note', _addNote),
            _buildDockDivider(),
            _buildDrawButton(),
            _buildDockDivider(),
            _buildEraserButton(),
            _buildDockDivider(),
            _buildDockButton(Icons.delete_sweep_rounded, 'Clear', _clearCanvas,
                isDestructive: true),
          ],
        ),
      ),
    );
  }

  /// Draw button — tap toggles draw mode; long-press opens color picker
  Widget _buildDrawButton() {
    final isActive = _isDrawingMode && !_isEraserMode;
    const color = Colors.black87;
    const activeColor = Colors.blueAccent;
    final btnColor = isActive ? activeColor : color;

    return GestureDetector(
      onTap: _toggleDrawMode,
      onLongPress: () {
        setState(() {
          if (!_isDrawingMode) _isDrawingMode = true;
          _showColorPicker = !_showColorPicker;
        });
        HapticFeedback.mediumImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.brush_rounded, color: btnColor, size: 18),
                if (_isDrawingMode)
                  Positioned(
                    bottom: -1,
                    right: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _activeDrawColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 4),
            Text(
              'Draw',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.inter().fontFamily,
                color: btnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEraserButton() {
    final isActive = _isDrawingMode && _isEraserMode;
    const color = Colors.black87;
    const activeColor = Colors.blueAccent;
    final btnColor = isActive ? activeColor : color;

    return GestureDetector(
      onTap: _toggleEraserMode,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_fix_high_rounded, color: btnColor, size: 18),
            const SizedBox(width: 4),
            Text(
              'Eraser',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.inter().fontFamily,
                color: btnColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockDivider() {
    return Container(
      height: 20,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.black.withOpacity(0.1),
    );
  }

  Widget _buildDockButton(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isDestructive = false,
    bool isActive = false,
  }) {
    final disabled = onTap == null;
    final color = disabled
        ? Colors.black26
        : isDestructive
            ? Colors.redAccent
            : isActive
                ? Colors.blueAccent
                : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.inter().fontFamily,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasItem(CanvasItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: IgnorePointer(
        ignoring: _isDrawingMode,
        child: DraggableStickyNote(
          item: item,
          onDragUpdate: (delta) {
            setState(() {
              item.position += delta;
            });
            _notifyItems();
          },
          onResize: (delta) {
            setState(() {
              item.width = (item.width + delta.dx).clamp(160.0, 600.0);
              item.height = (item.height + delta.dy).clamp(160.0, 600.0);
            });
            _notifyItems();
          },
          onChanged: (val) {
            _notifyItems();
          },
          onTapDown: () => _bringToFront(item),
          onRemove: () => _removeItem(item.id),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        final paint = Paint()
          ..color = stroke.isEraser ? Colors.transparent : stroke.color
          ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver
          ..style = PaintingStyle.fill;
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
        continue;
      }
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      final paint = Paint()
        ..color = stroke.isEraser ? Colors.transparent : stroke.color
        ..blendMode = stroke.isEraser ? BlendMode.clear : BlendMode.srcOver
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) => true;
}

class DraggableStickyNote extends StatefulWidget {
  final CanvasItem item;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onResize;
  final VoidCallback onTapDown;
  final VoidCallback onRemove;
  final ValueChanged<String>? onChanged;

  const DraggableStickyNote({
    super.key,
    required this.item,
    required this.onDragUpdate,
    required this.onResize,
    required this.onTapDown,
    required this.onRemove,
    this.onChanged,
  });

  @override
  State<DraggableStickyNote> createState() => _DraggableStickyNoteState();
}

class _DraggableStickyNoteState extends State<DraggableStickyNote> {
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isHoveringDelete = false;
  bool _isHoveringResize = false;
  bool _isHoveringNote = false;

  Future<void> _showDeleteConfirmation() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: Center(
              child: _IosAlertDialog(
                title: 'Delete Note',
                message: 'This note will be permanently removed from your wall.',
                onCancel: () => Navigator.of(ctx).pop(false),
                onConfirm: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ),
        );
      },
    );
    if (confirmed == true) widget.onRemove();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: (_) => setState(() => _isHoveringNote = true),
        onExit: (_) => setState(() => _isHoveringNote = false),
        child: GestureDetector(
          onPanStart: (details) {
            widget.onTapDown();
            setState(() => _isDragging = true);
            HapticFeedback.selectionClick();
          },
          onPanUpdate: (details) {
            widget.onDragUpdate(details.delta);
          },
          onPanEnd: (details) {
            setState(() => _isDragging = false);
            HapticFeedback.lightImpact();
          },
          child: Transform.rotate(
            angle: widget.item.rotation,
            child: AnimatedScale(
              scale: _isDragging ? 1.04 : widget.item.scale,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                width: widget.item.width,
                height: widget.item.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    // Soft deep shadow
                    BoxShadow(
                      color: Colors.black.withOpacity(
                          _isDragging || _isResizing ? 0.20 : 0.12),
                      blurRadius: _isDragging || _isResizing ? 25 : 12,
                      spreadRadius: 0,
                      offset: Offset(0, _isDragging || _isResizing ? 12 : 6),
                    ),
                    // Sharp close shadow for crispness
                    BoxShadow(
                      color: Colors.black.withOpacity(
                          _isDragging || _isResizing ? 0.10 : 0.05),
                      blurRadius: _isDragging || _isResizing ? 10 : 4,
                      spreadRadius: 0,
                      offset: Offset(0, _isDragging || _isResizing ? 4 : 2),
                    ),
                  ],
                  // No colored border — clean look
                  color: widget.item.color,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Top adhesive fold shadow
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 35,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.04),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Note Content
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
                        child: TextField(
                          controller:
                              TextEditingController(text: widget.item.content)
                                ..selection = TextSelection.collapsed(
                                    offset: widget.item.content.length),
                          onChanged: (val) {
                            widget.item.content = val;
                            widget.onChanged?.call(val);
                          },
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            filled: false,
                            hoverColor: Colors.transparent,
                            hintText: 'Write a note...',
                            hintStyle: TextStyle(color: Colors.black38),
                          ),
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            fontFamily: GoogleFonts.kalam().fontFamily ??
                                GoogleFonts.inter().fontFamily,
                          ),
                        ),
                      ),
                    ),
                    // Delete Button
                    Positioned(
                      top: -8,
                      right: -8,
                      child: IgnorePointer(
                        ignoring: !_isHoveringNote,
                        child: AnimatedOpacity(
                          opacity: _isHoveringNote ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isHoveringDelete = true),
                            onExit: (_) =>
                                setState(() => _isHoveringDelete = false),
                            child: GestureDetector(
                              onTap: _showDeleteConfirmation,
                              child: AnimatedScale(
                                scale: _isHoveringDelete ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── Resize handle (bottom-right corner) ──
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeDownRight,
                        onEnter: (_) =>
                            setState(() => _isHoveringResize = true),
                        onExit: (_) =>
                            setState(() => _isHoveringResize = false),
                        child: GestureDetector(
                          onPanStart: (_) {
                            setState(() => _isResizing = true);
                            HapticFeedback.selectionClick();
                          },
                          onPanUpdate: (details) {
                            widget.onResize(details.delta);
                          },
                          onPanEnd: (_) {
                            setState(() => _isResizing = false);
                            HapticFeedback.lightImpact();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _isHoveringResize || _isResizing
                                  ? Colors.black.withOpacity(0.12)
                                  : Colors.transparent,
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.open_in_full_rounded,
                                size: 13,
                                color: Colors.black.withOpacity(
                                    _isHoveringResize || _isResizing
                                        ? 0.5
                                        : 0.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

// ─── iOS 18-style Alert Dialog ───────────────────────────────────────────────

class _IosAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _IosAlertDialog({
    required this.title,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
          width: 270,
          decoration: BoxDecoration(
            // iOS frosted glass — slightly warm white with high opacity
            color: const Color(0xF5FFFFFF),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + Message
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF000000),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF3C3C43).withOpacity(0.6),
                        letterSpacing: -0.1,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              // Top horizontal divider
              Container(height: 0.5, color: const Color(0xFF3C3C43).withOpacity(0.22)),
              // Buttons
              IntrinsicHeight(
                child: Row(
                  children: [
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: onCancel,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: Colors.transparent,
                          child: Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF007AFF), // iOS blue
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Vertical divider
                    Container(
                      width: 0.5,
                      color: const Color(0xFF3C3C43).withOpacity(0.22),
                    ),
                    // Delete
                    Expanded(
                      child: GestureDetector(
                        onTap: onConfirm,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: Colors.transparent,
                          child: Text(
                            'Delete',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF3B30), // iOS destructive red
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
