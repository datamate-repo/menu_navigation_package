import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data models ─────────────────────────────────────────────────────────────

class Stroke {
  final List<Offset> points;
  Color color; // mutable so theme-toggle can flip it
  final double strokeWidth;
  final bool isThemeColor; // true = drawn with auto theme color (black/white)

  Stroke(this.points, this.color, this.strokeWidth,
      {this.isThemeColor = false});
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isThemeColor': isThemeColor,
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

// ─── Undo/Redo action types ──────────────────────────────────────────────────

abstract class CanvasAction {}

class AddNoteAction extends CanvasAction {
  final CanvasItem item;
  AddNoteAction(this.item);
}

class RemoveNoteAction extends CanvasAction {
  final CanvasItem item;
  RemoveNoteAction(this.item);
}

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction(this.stroke);
}

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

  // ── Undo / Redo ──
  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];

  // ── Note colors ──
  final List<Color> _noteColors = [
    const Color(0xFFFFF7D1),
    const Color(0xFFD4F0F0),
    const Color(0xFFF3E8FF),
    const Color(0xFFFFE4E1),
    const Color(0xFFDDF5DF),
  ];
  int _colorIndex = 0;

  // Always black draw color unless user picked a custom one
  Color get _activeDrawColor =>
      _customColorSelected ? _drawColor : Colors.black;

  // ── Undo/Redo helpers ─────────────────────────────────────────────────────

  void _pushUndo(CanvasAction action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    setState(() {
      if (action is AddNoteAction) {
        _items.removeWhere((i) => i.id == action.item.id);
        _redoStack.add(action);
      } else if (action is RemoveNoteAction) {
        _items.add(action.item);
        _items.sort((a, b) => a.zIndex.compareTo(b.zIndex));
        _redoStack.add(action);
      } else if (action is AddStrokeAction) {
        _strokes.remove(action.stroke);
        _redoStack.add(action);
      }
    });
    _notifyItems();
    _notifyStrokes();
    HapticFeedback.lightImpact();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    setState(() {
      if (action is AddNoteAction) {
        _items.add(action.item);
        _items.sort((a, b) => a.zIndex.compareTo(b.zIndex));
        _undoStack.add(action);
      } else if (action is RemoveNoteAction) {
        _items.removeWhere((i) => i.id == action.item.id);
        _undoStack.add(action);
      } else if (action is AddStrokeAction) {
        _strokes.add(action.stroke);
        _undoStack.add(action);
      }
    });
    _notifyItems();
    _notifyStrokes();
    HapticFeedback.lightImpact();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

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
    _pushUndo(AddNoteAction(item));
    _notifyItems();
    HapticFeedback.mediumImpact();
  }

  void _clearCanvas() {
    if (_items.isEmpty && _strokes.isEmpty) return;
    setState(() {
      _items.clear();
      _strokes.clear();
      _undoStack.clear();
      _redoStack.clear();
      _isDrawingMode = false;
      _showColorPicker = false;
    });
    _notifyItems();
    _notifyStrokes();
    widget.onDrawingModeChanged?.call(false);
    HapticFeedback.heavyImpact();
  }

  void _toggleDrawMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (!_isDrawingMode) _showColorPicker = false;
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
    _pushUndo(RemoveNoteAction(item));
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

          // Canvas Items
          ..._items.map((item) => _buildCanvasItem(item)),

          // Drawing Render Layer
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
                      _activeDrawColor,
                      4.0,
                      isThemeColor: !_customColorSelected,
                    ));
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _currentStroke.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  // Record completed stroke for undo
                  if (_strokes.isNotEmpty && _currentStroke.isNotEmpty) {
                    _pushUndo(AddStrokeAction(_strokes.last));
                    _notifyStrokes();
                  }
                  setState(() => _currentStroke = []);
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // Color picker panel (only in draw mode)
          if (_isDrawingMode && _showColorPicker) _buildColorPickerPanel(),

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
        ));
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
            // Undo/Redo only visible in draw modeif wall is empty
            if (_isDrawingMode) ...[
              _buildDockDivider(),
              _buildDockButton(
                Icons.undo_rounded,
                'Undo',
                _undoStack.isEmpty ? null : _undo,
              ),
              _buildDockButton(
                Icons.redo_rounded,
                'Redo',
                _redoStack.isEmpty ? null : _redo,
              ),
            ],
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
    final isActive = _isDrawingMode;
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
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        final paint = Paint()
          ..color = stroke.color
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
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                BoxShadow(
                  color: Colors.black
                      .withOpacity(_isDragging || _isResizing ? 0.18 : 0.10),
                  blurRadius: _isDragging || _isResizing ? 18 : 8,
                  spreadRadius: 0,
                  offset: Offset(0, _isDragging || _isResizing ? 8 : 3),
                ),
              ],
              border: Border.all(
                color: widget.item.color.withOpacity(0.5),
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.item.color,
                  Color.lerp(widget.item.color, Colors.black, 0.05)!,
                ],
              ),
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
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringDelete = true),
                    onExit: (_) => setState(() => _isHoveringDelete = false),
                    child: GestureDetector(
                      onTap: widget.onRemove,
                      child: AnimatedScale(
                        scale: _isHoveringDelete ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
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
                // ── Resize handle (bottom-right corner) ──
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    onEnter: (_) => setState(() => _isHoveringResize = true),
                    onExit: (_) => setState(() => _isHoveringResize = false),
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
                                _isHoveringResize || _isResizing ? 0.5 : 0.2),
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
    );
  }
}
