import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morgant_thierry/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('loads the operations dashboard and navigates sections', (
    tester,
  ) async {
    await tester.pumpWidget(const MorgantThierryApp());
    await tester.pumpAndSettle();

    expect(find.text('MORGANT THIERRY'), findsOneWidget);
    expect(find.text('Daily operations board'), findsOneWidget);

    await tester.tap(navLabel('Stock'));
    await tester.pumpAndSettle();

    expect(find.text('Inventory tracking'), findsOneWidget);
    expect(find.text('Tamper seal packaging'), findsOneWidget);

    await tester.tap(navLabel('Orders'));
    await tester.pumpAndSettle();

    expect(find.text('Supply ordering'), findsOneWidget);
    expect(find.text('Northline Supplies'), findsOneWidget);
  });

  testWidgets('creates and saves a local inventory item', (tester) async {
    await tester.pumpWidget(const MorgantThierryApp());
    await tester.pumpAndSettle();

    await tester.tap(navLabel('Stock'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Safety gloves');
    await tester.enterText(find.byType(TextField).at(2), '30');
    await tester.enterText(find.byType(TextField).at(3), '12');
    await tester.enterText(find.byType(TextField).at(4), '60');

    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Safety gloves'), findsOneWidget);
    expect(find.textContaining('30 in stock'), findsOneWidget);
  });

  testWidgets('settings screen describes local privacy behavior', (
    tester,
  ) async {
    await tester.pumpWidget(const MorgantThierryApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Settings and privacy'), findsOneWidget);
    expect(find.textContaining('No cloud upload'), findsOneWidget);
    expect(find.textContaining('contact@morgantthierry.app'), findsOneWidget);
  });
}

Finder navLabel(String label) {
  return find
      .descendant(of: find.byType(NavigationBar), matching: find.text(label))
      .first;
}
