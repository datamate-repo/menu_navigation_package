import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('MyApp boots and renders initial UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initially, during future loading, CircularProgressIndicator is rendered
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the asset future to complete
    await tester.pumpAndSettle();

    // Verify MaterialApp and Scaffold exist
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
  });
}
