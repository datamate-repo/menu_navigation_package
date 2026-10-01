import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import 'overflow_aware_text.dart';
import 'snackbar_manager.dart';
import 'wall_playground.dart';

class MenuSection {
  final String title;
  final List<MenuItem> items;

  MenuSection({required this.title, required this.items});
}

class MenuItem {
  final String shortcut;
  final String label;
  final List<MenuSection>? subMenu;
  final VoidCallback? onTap;
  final Widget Function()? navigateTo;

  MenuItem({
    required this.shortcut,
    required this.label,
    this.subMenu,
    this.onTap,
    this.navigateTo,
  });
}

class CustomChip extends StatefulWidget {
  final String shortcut;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final Color? shortcutBackgroundColor;
  final Color? selectedShortcutBackgroundColor;
  final Color? shortcutTextColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final double elevation;
  final bool forceHoverShadow;

  const CustomChip({
    super.key,
    required this.shortcut,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.borderColor,
    this.selectedBorderColor,
    this.shortcutBackgroundColor,
    this.selectedShortcutBackgroundColor,
    this.shortcutTextColor,
    this.textColor,
    this.selectedTextColor,
    this.elevation = 4.0,
    this.forceHoverShadow = false,
  });

  @override
  State<CustomChip> createState() => _CustomChipState();
}

class _CustomChipState extends State<CustomChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final chipTheme = ChipTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final defaultLabelColor =
        chipTheme.labelStyle?.color ?? colorScheme.onSurface;
    final defaultSelectedLabelColor = colorScheme.primary;

    final lblColor = widget.isSelected
        ? (widget.selectedTextColor ?? defaultSelectedLabelColor)
        : (widget.textColor ?? defaultLabelColor);

    final baseBackgroundColor = widget.isSelected
        ? (widget.selectedBackgroundColor ?? Colors.blue.shade100)
        : (widget.backgroundColor ?? Colors.white);

    final hoverBackgroundColor = Theme.of(context).primaryColor;
    final currentBackgroundColor =
        _isHovering ? hoverBackgroundColor : baseBackgroundColor;

    final baseShadowColor = Colors.grey.shade400;
    final hoverShadowColor = Colors.black.withOpacity(0.5);

    final baseBoxShadow = [
      BoxShadow(
        color: baseShadowColor,
        offset: const Offset(6.0, 6.0),
        blurRadius: 15.0,
        spreadRadius: 1.0,
      ),
      BoxShadow(
        color: widget.forceHoverShadow
            ? Colors.grey.withOpacity(.1)
            : Colors.white.withOpacity(0.9),
        offset: const Offset(-6.0, -6.0),
        blurRadius: 15.0,
        spreadRadius: 1.0,
      ),
    ];

    final hoverBoxShadow = [
      BoxShadow(
        color: hoverShadowColor,
        offset: const Offset(6.0, 6.0),
        blurRadius: 15.0,
        spreadRadius: 1.0,
      ),
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        offset: const Offset(-6.0, -6.0),
        blurRadius: 15.0,
        spreadRadius: 1.0,
      ),
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        curve: Curves.fastLinearToSlowEaseIn,
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: currentBackgroundColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: _isHovering ? hoverBoxShadow : baseBoxShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
                  .copyWith(right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    width: 46.0,
                    height: 46.0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.fastEaseInToSlowEaseOut,
                    decoration: BoxDecoration(
                      color: _isHovering
                          ? Colors.white
                          : (widget.shortcutBackgroundColor ??
                              const Color(0xFF4A6CEE)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isHovering
                              ? hoverShadowColor
                              : Colors.grey.shade100,
                          offset: const Offset(-4, -4),
                          blurRadius: 8,
                        ),
                        BoxShadow(
                          color: _isHovering
                              ? hoverShadowColor
                              : Colors.black.withOpacity(.3),
                          offset: const Offset(4, 4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.shortcut,
                        style: TextStyle(
                            fontSize: 14,
                            color: _isHovering
                                ? Theme.of(context).primaryColor
                                : (widget.shortcutTextColor ?? Colors.white),
                            fontWeight: FontWeight.w600,
                            fontFamily: GoogleFonts.poppins().fontFamily),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _isHovering ? Colors.white : lblColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: GoogleFonts.poppins().fontFamily),
                    ).withOverflowTooltip(
                      waitDuration: const Duration(milliseconds: 500),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tooltipTextStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DynamicMenu extends StatefulWidget {
  final List<MenuSection> menuData;
  final Function(MenuItem) onMenuItemSelected;
  final String title;
  final Map<LogicalKeyboardKey, VoidCallback> shortcuts;
  final bool showAppBar;
  final FocusNode? focusNode;

  /// Optional widget shown on the left side of the split layout.
  /// When provided, the menu sections are shown in a right-side panel
  /// and this widget fills the remaining space on the left.
  final Widget? dashboardWidget;

  /// Width of the right-side menu panel when [dashboardWidget] is provided.
  /// Defaults to 340.
  final double menuPanelWidth;

  /// Whether the menu panel starts on the left side.
  final bool isMenuOnLeft;

  /// Callback when the layout is swapped via drag and drop.
  final Function(bool isMenuOnLeft)? onLayoutSwapped;

  /// Which tab is shown initially: 0 = Dashboard, 1 = Wall.
  /// Defaults to 0 (Dashboard).
  final int initialTab;

  /// Called when the user switches between Dashboard (0) and Wall (1).
  final void Function(int tabIndex)? onTabChanged;

  final List<CanvasItem>? initialItems;
  final List<Stroke>? initialStrokes;
  final void Function(List<CanvasItem> items)? onItemsChanged;
  final void Function(List<Stroke> strokes)? onStrokesChanged;
  final void Function(bool isDrawing)? onDrawingModeChanged;

  /// Called when the user clicks a top-level menu section.
  final void Function(int sectionIndex)? onMenuSectionSelected;

  final Color? backgroundColor;
  final Color? appBarColor;
  final Color? appBarTextColor;
  final Color? sectionTitleColor;
  final Color? backButtonColor;
  final Color? backButtonTextColor;
  final Color? buttonBackgroundColor;
  final Color? buttonSelectedBackgroundColor;
  final Color? buttonBorderColor;
  final Color? buttonSelectedBorderColor;
  final Color? shortcutBackgroundColor;
  final Color? shortcutSelectedBackgroundColor;
  final Color? shortcutTextColor;
  final Color? buttonTextColor;
  final Color? buttonSelectedTextColor;

  const DynamicMenu({
    super.key,
    required this.menuData,
    required this.onMenuItemSelected,
    required this.title,
    this.shortcuts = const {},
    this.showAppBar = true,
    this.dashboardWidget,
    this.menuPanelWidth = 340,
    this.isMenuOnLeft = false,
    this.onLayoutSwapped,
    this.initialTab = 0,
    this.onTabChanged,
    this.backgroundColor,
    this.appBarColor,
    this.appBarTextColor,
    this.sectionTitleColor,
    this.backButtonColor,
    this.backButtonTextColor,
    this.buttonBackgroundColor,
    this.buttonSelectedBackgroundColor,
    this.buttonBorderColor,
    this.buttonSelectedBorderColor,
    this.shortcutBackgroundColor,
    this.shortcutSelectedBackgroundColor,
    this.shortcutTextColor,
    this.buttonTextColor,
    this.buttonSelectedTextColor,
    this.focusNode,
    this.initialItems,
    this.initialStrokes,
    this.onItemsChanged,
    this.onStrokesChanged,
    this.onDrawingModeChanged,
    this.onMenuSectionSelected,
  });

  @override
  State<DynamicMenu> createState() => _DynamicMenuState();
}

class _DynamicMenuState extends State<DynamicMenu> {
  late final FocusNode _focusNode;
  final List<List<MenuSection>> _menuStack = [];
  late List<MenuSection> _currentMenu;
  int _selectedSectionIndex = 0;
  int _selectedItemIndex = -1;
  int _selectedTab = 0;

  bool _isMenuOnLeft = false;
  bool _isDragging = false;
  bool _isFirstSectionPressed = false;
  bool _isDrawingMode = false;

  List<CanvasItem>? _cachedItems;
  List<Stroke>? _cachedStrokes;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _currentMenu = widget.menuData;
    _isMenuOnLeft = widget.isMenuOnLeft;
    _selectedTab = widget.initialTab.clamp(0, 1);
    _cachedItems = widget.initialItems;
    _cachedStrokes = widget.initialStrokes;
  }

  @override
  void didUpdateWidget(DynamicMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMenuOnLeft != widget.isMenuOnLeft) {
      _isMenuOnLeft = widget.isMenuOnLeft;
    }
  }

  void _navigateToSubMenu(MenuItem item) {
    if (item.navigateTo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EscListenerPage(
                allowRootNavigation: true, child: item.navigateTo!())),
      );
    } else if (item.subMenu != null && item.subMenu!.isNotEmpty) {
      setState(() {
        _menuStack.add(_currentMenu);
        _currentMenu = item.subMenu!;
        _selectedSectionIndex = 0;
        _selectedItemIndex = -1;
      });
    } else if (item.onTap != null) {
      widget.onMenuItemSelected(item);
      widget.onMenuSectionSelected?.call(_selectedSectionIndex);
      item.onTap?.call();
    } else if (item.subMenu != null && item.subMenu!.isEmpty) {
      showCustomSnackBar(
          context: context,
          message: "Not authorized to access this menu",
          type: SnackBarType.alert);
    } else {
      widget.onMenuItemSelected(item);
      widget.onMenuSectionSelected?.call(_selectedSectionIndex);
    }
  }

  void _navigateBack() {
    if (_menuStack.isNotEmpty) {
      setState(() {
        _currentMenu = _menuStack.removeLast();
        _selectedSectionIndex = 0;
        _selectedItemIndex = -1;
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      String key = event.logicalKey.keyLabel.toUpperCase();

      if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
          event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
        key = String.fromCharCode(
          '0'.codeUnitAt(0) +
              (event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId),
        );
      }

      final bool isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter;

      if (key == 'ARROW_UP') {
        setState(() {
          _selectedItemIndex = (_selectedItemIndex - 1)
              .clamp(-1, _currentMenu[_selectedSectionIndex].items.length - 1);
        });
      } else if (key == 'ARROW_DOWN') {
        setState(() {
          _selectedItemIndex = (_selectedItemIndex + 1) %
              _currentMenu[_selectedSectionIndex].items.length;
        });
      } else if (isEnter && _selectedItemIndex != -1) {
        _navigateToSubMenu(
            _currentMenu[_selectedSectionIndex].items[_selectedItemIndex]);
      } else if (key == 'ESCAPE') {
        if (_menuStack.isNotEmpty) {
          _navigateBack();
        }
      } else if (key == 'BACKSPACE') {
        if (_menuStack.isNotEmpty) {
          _navigateBack();
        }
      } else {
        for (var section in _currentMenu) {
          for (var item in section.items) {
            if (item.shortcut.toUpperCase() == key) {
              _navigateToSubMenu(item);
              return;
            }
          }
        }
      }
      for (final entry in widget.shortcuts.entries) {
        final skey = entry.key;
        final callback = entry.value;

        if (event.logicalKey == skey) {
          callback();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTh = theme.textTheme;
    final chipTh = ChipTheme.of(context);

    Color resolve(Color? override, Color def) => override ?? def;

    final bgColor = resolve(widget.backgroundColor, cs.surface);
    final sectionColor = resolve(
        widget.sectionTitleColor, textTh.titleMedium?.color ?? Colors.black);
    final backIcon = resolve(widget.backButtonColor, cs.onSurface);
    final backTxt = resolve(widget.backButtonTextColor, cs.onSurface);
    final btnBg = resolve(
        widget.buttonBackgroundColor, chipTh.backgroundColor ?? Colors.white);
    final btnSelBg = resolve(
        widget.buttonSelectedBackgroundColor, cs.primary.withOpacity(0.1));
    final btnBorder = widget.buttonBorderColor ?? const Color(0xffE1E1E1);
    final btnSelBorder = resolve(widget.buttonSelectedBorderColor, cs.primary);
    final scBg =
        resolve(widget.shortcutBackgroundColor, const Color(0xFF4A6CEE));
    final scSelBg =
        resolve(widget.shortcutSelectedBackgroundColor, cs.secondaryContainer);
    final scTxt = resolve(widget.shortcutTextColor, cs.onSecondary);
    final btnTxt = resolve(
        widget.buttonTextColor, textTh.bodyMedium?.color ?? Colors.black);
    final btnSelTxt = resolve(widget.buttonSelectedTextColor, cs.primary);

    // Build the scrollable menu panel (sections list)
    final menuPanel = Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(-2, 0),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_menuStack.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _navigateBack,
                  style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: backIcon.withOpacity(0.06),
                  ),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: backIcon,
                    size: 16,
                  ),
                  label: Text(
                    'Back',
                    style: TextStyle(
                      color: backTxt,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          for (int i = 0; i < _currentMenu.length; i++) ...[
            Builder(builder: (context) {
              final section = _currentMenu[i];
              final sectionWidget = MenuSectionWidget(
                section: section,
                onPressed: _navigateToSubMenu,
                selectedSectionIndex: _selectedSectionIndex,
                selectedItemIndex: _selectedItemIndex,
                currentMenu: _currentMenu,
                sectionColor: sectionColor,
                btnBg: btnBg,
                btnSelBg: btnSelBg,
                btnBorder: btnBorder,
                btnSelBorder: btnSelBorder,
                scBg: scBg,
                scSelBg: scSelBg,
                scTxt: scTxt,
                btnTxt: btnTxt,
                btnSelTxt: btnSelTxt,
              );

              if (i == 0) {
                return _SectionDraggableWrapper(
                  panelWidth: widget.menuPanelWidth,
                  onDragStarted: () => setState(() => _isDragging = true),
                  onDragEnd: () => setState(() => _isDragging = false),
                  onPressedStateChanged: (pressed) =>
                      setState(() => _isFirstSectionPressed = pressed),
                  feedbackWidget: Container(
                    width: widget.menuPanelWidth,
                    height: MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    decoration: BoxDecoration(color: bgColor),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        if (_menuStack.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: null,
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: backIcon,
                                  size: 20,
                                ),
                                label: Text('Back', style: TextStyle(color: backTxt)),
                              ),
                            ),
                          ),
                        for (int j = 0; j < _currentMenu.length; j++) ...[
                          if (j == 0)
                            Transform.scale(
                              scale: 0.96,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                      offset: Offset.zero,
                                    )
                                  ],
                                ),
                                child: MenuSectionWidget(
                                  section: _currentMenu[j],
                                  onPressed: (_) {},
                                  selectedSectionIndex: _selectedSectionIndex,
                                  selectedItemIndex: _selectedItemIndex,
                                  currentMenu: _currentMenu,
                                  sectionColor: sectionColor,
                                  btnBg: btnBg,
                                  btnSelBg: btnSelBg,
                                  btnBorder: btnBorder,
                                  btnSelBorder: btnSelBorder,
                                  scBg: scBg,
                                  scSelBg: scSelBg,
                                  scTxt: scTxt,
                                  btnTxt: btnTxt,
                                  btnSelTxt: btnSelTxt,
                                ),
                              ),
                            )
                          else
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Opacity(
                                opacity: 0.4,
                                child: MenuSectionWidget(
                                  section: _currentMenu[j],
                                  onPressed: (_) {},
                                  selectedSectionIndex: _selectedSectionIndex,
                                  selectedItemIndex: _selectedItemIndex,
                                  currentMenu: _currentMenu,
                                  sectionColor: sectionColor,
                                  btnBg: btnBg,
                                  btnSelBg: btnSelBg,
                                  btnBorder: btnBorder,
                                  btnSelBorder: btnSelBorder,
                                  scBg: scBg,
                                  scSelBg: scSelBg,
                                  scTxt: scTxt,
                                  btnTxt: btnTxt,
                                  btnSelTxt: btnSelTxt,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  child: sectionWidget,
                  forceHighlight: _isFirstSectionPressed || _isDragging,
                );
              }

              // Blur and fade other items when the first section is pressed or dragging
              final isDimmed = _isFirstSectionPressed || _isDragging;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                      begin: 0.0, end: isDimmed ? 4.0 : 0.0),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, blurValue, child) {
                    if (blurValue == 0.0) return child!;
                    return ImageFiltered(
                      imageFilter: ImageFilter.blur(
                          sigmaX: blurValue, sigmaY: blurValue),
                      child: child,
                    );
                  },
                  child: AnimatedOpacity(
                    opacity: isDimmed ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: sectionWidget,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );

    final dashboardContent = widget.dashboardWidget ??
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                size: 56,
                color: cs.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Dashboard',
                style: textTh.titleLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                ),
              ),
            ],
          ),
        );

    final leftPanel = Stack(
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _selectedTab == 0
                ? WallPlayground(
                    initialItems: _cachedItems,
                    initialStrokes: _cachedStrokes,
                    onItemsChanged: (items) {
                      _cachedItems = items;
                      widget.onItemsChanged?.call(items);
                    },
                    onStrokesChanged: (strokes) {
                      _cachedStrokes = strokes;
                      widget.onStrokesChanged?.call(strokes);
                    },
                    onDrawingModeChanged: (isDrawing) {
                      widget.onDrawingModeChanged?.call(isDrawing);
                    },
                  )
                : dashboardContent,
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: _buildTabSwitcher(cs),
        ),
      ],
    );

    final dropZone = DragTarget<String>(
      onWillAccept: (data) => data == 'menuPanel',
      onAccept: (data) {
        setState(() {
          _isMenuOnLeft = !_isMenuOnLeft;
        });
        if (widget.onLayoutSwapped != null) {
          widget.onLayoutSwapped!(_isMenuOnLeft);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Stack(
          children: [
            // Render the dashboard widget normally without distorting it
            Positioned.fill(child: leftPanel),

            // Overlay glow + Drop Here label
            if (_isDragging)
              Positioned(
                left: _isMenuOnLeft ? null : 0,
                right: _isMenuOnLeft ? 0 : null,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: widget.menuPanelWidth,
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(isHovered ? 0.08 : 0.02),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(isHovered ? 0.3 : 0.1),
                          blurRadius: 40,
                          spreadRadius: isHovered ? 15 : 5,
                        ),
                      ],
                    ),
                    child: AnimatedOpacity(
                      opacity: isHovered ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: AnimatedScale(
                          scale: isHovered ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isHovered
                                    ? Icons.south_rounded
                                    : Icons.swap_horiz_rounded,
                                size: 36,
                                color: cs.primary
                                    .withOpacity(isHovered ? 0.9 : 0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isHovered ? 'Release to drop' : 'Drop here',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  color: cs.primary
                                      .withOpacity(isHovered ? 0.9 : 0.5),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final panelWidth = widget.menuPanelWidth;
          final dropZoneWidth = totalWidth - panelWidth;

          return Stack(
            children: [
              // Dashboard Panel
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                left: _isMenuOnLeft ? panelWidth : 0,
                width: dropZoneWidth,
                child: dropZone,
              ),
              // Menu Panel
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                left: _isMenuOnLeft ? 0 : dropZoneWidth,
                width: panelWidth,
                child: menuPanel,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // ── iOS 18-style segmented control ───────────────────────────────────────
  Widget _buildTabSwitcher(ColorScheme cs) {
    const tabs = ['Wall', 'Dashboard'];
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA), // iOS system grey 5
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() => _selectedTab = i);
              widget.onTabChanged?.call(i);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isSelected
                    ? const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 2,
                          offset: Offset(0, 0),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF000000)
                      : const Color(0xFF8E8E93), // iOS label / tertiary
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabButton(String title, int index, ColorScheme cs) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        widget.onTabChanged?.call(index);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? cs.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  )
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6),
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
      ),
    );
  }
}

class MenuSectionWidget extends StatefulWidget {
  final MenuSection section;
  final int selectedSectionIndex;
  final int selectedItemIndex;
  final List<MenuSection> currentMenu;
  final Color sectionColor;
  final Color btnBg;
  final Color btnSelBg;
  final Color btnBorder;
  final Color btnSelBorder;
  final Color scBg;
  final Color scSelBg;
  final Color scTxt;
  final Color btnTxt;
  final Color btnSelTxt;
  final void Function(MenuItem item) onPressed;

  const MenuSectionWidget({
    super.key,
    required this.section,
    required this.selectedSectionIndex,
    required this.selectedItemIndex,
    required this.currentMenu,
    required this.sectionColor,
    required this.btnBg,
    required this.btnSelBg,
    required this.btnBorder,
    required this.btnSelBorder,
    required this.scBg,
    required this.scSelBg,
    required this.scTxt,
    required this.btnTxt,
    required this.btnSelTxt,
    required this.onPressed,
  });

  @override
  State<MenuSectionWidget> createState() => _MenuSectionWidgetState();
}

class _MenuSectionWidgetState extends State<MenuSectionWidget> {
  int _hoveredItemIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isCurrentSection = widget.currentMenu.indexOf(widget.section) ==
        widget.selectedSectionIndex;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.section.title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: widget.sectionColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 16,
              mainAxisExtent: 50,
            ),
            itemCount: widget.section.items.length,
            itemBuilder: (context, idx) {
              final item = widget.section.items[idx];
              final isSelected =
                  isCurrentSection && idx == widget.selectedItemIndex;

              final shouldShowHoverShadow =
                  _hoveredItemIndex != -1 && idx == _hoveredItemIndex + 2;

              return MouseRegion(
                onEnter: (_) {
                  if (_hoveredItemIndex != idx) {
                    setState(() => _hoveredItemIndex = idx);
                  }
                },
                onExit: (_) {
                  if (_hoveredItemIndex != -1) {
                    setState(() => _hoveredItemIndex = -1);
                  }
                },
                child: CustomChip(
                  shortcut: item.shortcut,
                  label: item.label,
                  isSelected: isSelected,
                  onPressed: () => widget.onPressed(item),
                  backgroundColor: widget.btnBg,
                  selectedBackgroundColor: widget.btnSelBg,
                  borderColor: widget.btnBorder,
                  selectedBorderColor: widget.btnSelBorder,
                  shortcutBackgroundColor: widget.scBg,
                  selectedShortcutBackgroundColor: widget.scSelBg,
                  shortcutTextColor: widget.scTxt,
                  textColor: widget.btnTxt,
                  selectedTextColor: widget.btnSelTxt,
                  forceHoverShadow: shouldShowHoverShadow,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class EscListenerPage extends StatefulWidget {
  final Widget child;
  final bool allowRootNavigation;
  final VoidCallback? onEscapeRoot;

  const EscListenerPage({
    super.key,
    required this.child,
    this.allowRootNavigation = false,
    this.onEscapeRoot,
  });

  @override
  State<EscListenerPage> createState() => _EscListenerPageState();
}

class _EscListenerPageState extends State<EscListenerPage> {
  Timer? _escKeyTimer;
  bool _isFirstEscPress = false;

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey.keyLabel.toUpperCase();

      if (key == 'ESCAPE') {
        if (_isFirstEscPress) {
          if (Navigator.of(context).canPop()) {
            Navigator.pop(context);
          } else if (widget.allowRootNavigation) {
            if (widget.onEscapeRoot != null) {
              widget.onEscapeRoot!();
            } else {
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
          _isFirstEscPress = false;
          _escKeyTimer?.cancel();
        } else {
          _isFirstEscPress = true;
          _escKeyTimer = Timer(const Duration(milliseconds: 300), () {
            _isFirstEscPress = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _escKeyTimer?.cancel();
    super.dispose();
  }
}

class _SectionDraggableWrapper extends StatefulWidget {
  final Widget child;
  final Widget feedbackWidget;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final ValueChanged<bool> onPressedStateChanged;
  final double panelWidth;
  final bool forceHighlight;

  const _SectionDraggableWrapper({
    required this.child,
    required this.feedbackWidget,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onPressedStateChanged,
    required this.panelWidth,
    this.forceHighlight = false,
  });

  @override
  State<_SectionDraggableWrapper> createState() =>
      _SectionDraggableWrapperState();
}

class _SectionDraggableWrapperState extends State<_SectionDraggableWrapper> {
  bool _isPressed = false;

  void _setPressed(bool pressed) {
    if (_isPressed != pressed) {
      setState(() => _isPressed = pressed);
      widget.onPressedStateChanged(pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: LongPressDraggable<String>(
        data: 'menuPanel',
        delay: const Duration(milliseconds: 250),
        onDragStarted: () {
          widget.onDragStarted();
          HapticFeedback.heavyImpact();
        },
        onDragEnd: (_) {
          _setPressed(false);
          widget.onDragEnd();
        },
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: widget.panelWidth, 
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.95, end: 1.05),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Opacity(
                      opacity: 0.95,
                      child: widget.feedbackWidget,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.2, // Leave a ghost of the section behind
          child: widget.child,
        ),
        child: AnimatedScale(
          scale: _isPressed || widget.forceHighlight ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: _isPressed || widget.forceHighlight
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 8,
                        offset: Offset.zero,
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
