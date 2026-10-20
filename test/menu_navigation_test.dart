import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menu_navigation/menu_navigation.dart';

void main() {
  testWidgets('Typing key-by-key in sticky note with shortcuts enabled', (tester) async {
    bool shortcutTriggered = false;

    final menuData = [
      MenuSection(
        title: 'Section 1',
        items: [
          MenuItem(
            shortcut: 'O',
            label: 'Orders',
            onTap: () {
              shortcutTriggered = true;
            },
          ),
          MenuItem(
            shortcut: 'C',
            label: 'Customer',
            onTap: () {
              shortcutTriggered = true;
            },
          ),
        ],
      ),
    ];

    List<CanvasItem> currentItems = [];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            height: 800,
            child: DynamicMenu(
              title: 'Test Menu',
              menuData: menuData,
              initialItems: currentItems,
              onItemsChanged: (items) {
                currentItems = items;
              },
              onMenuItemSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Click "+ Note"
    await tester.tap(find.text('+ Note'));
    await tester.pumpAndSettle();

    // Focus the TextField
    final textFieldFinder = find.byType(TextField);
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();

    // Send Key events for 'O'
    await tester.sendKeyEvent(LogicalKeyboardKey.keyO);
    await tester.pump();

    // Check if shortcut was triggered
    print('Shortcut triggered for O: $shortcutTriggered');
    expect(shortcutTriggered, false, reason: 'Shortcut O must not be triggered while typing in sticky note');

    // Send Key events for 'C'
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(shortcutTriggered, false, reason: 'Shortcut C must not be triggered while typing in sticky note');
  });
}
