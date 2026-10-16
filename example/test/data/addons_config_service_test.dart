import 'package:flutter_test/flutter_test.dart';
import 'package:example/data/services/addons_config_service.dart';

void main() {
  group('AddonsConfigService YAML Parser Tests', () {
    test('parses valid YAML containing both branch and leaf addons', () {
      const validYaml = '''
version: "1.0"
addons:
  - id: "cash-addons"
    label: "Cash Addons"
    shortcut: "C"
    subMenu:
      - title: "Cash Operations"
        items:
          - id: "imprest-cash"
            label: "Imprest Cash"
            shortcut: "I"
            url: "http://localhost:55874/hello-world"
  - id: "addon-b"
    label: "Addon B"
    shortcut: "B"
    url: "https://example.com/addon-b"
''';

      final items = AddonsConfigService.parseAddonItemsFromYaml(validYaml);

      expect(items.length, equals(2));

      // Item 0: Branch
      final branchItem = items[0];
      expect(branchItem.id, equals('cash-addons'));
      expect(branchItem.label, equals('Cash Addons'));
      expect(branchItem.shortcut, equals('C'));
      expect(branchItem.isBranch, isTrue);
      expect(branchItem.subMenu?.length, equals(1));
      expect(branchItem.subMenu?.first.title, equals('Cash Operations'));
      expect(branchItem.subMenu?.first.items.first.id, equals('imprest-cash'));

      // Item 1: Leaf
      final leafItem = items[1];
      expect(leafItem.id, equals('addon-b'));
      expect(leafItem.isLeaf, isTrue);
      expect(leafItem.url.toString(), equals('https://example.com/addon-b'));
    });

    test('throws AddonConfigException on empty YAML string', () {
      expect(
        () => AddonsConfigService.parseAddonItemsFromYaml('   '),
        throwsA(isA<AddonConfigException>()),
      );
    });

    test('throws AddonConfigException when YAML syntax is malformed', () {
      const brokenYaml = '''
addons:
  - id: "broken"
     shortcut: "B
''';
      expect(
        () => AddonsConfigService.parseAddonItemsFromYaml(brokenYaml),
        throwsA(isA<AddonConfigException>()),
      );
    });

    test('throws AddonConfigException when root addons key is missing', () {
      const missingAddonsKeyYaml = '''
version: "1.0"
other:
  - foo: "bar"
''';
      expect(
        () => AddonsConfigService.parseAddonItemsFromYaml(missingAddonsKeyYaml),
        throwsA(isA<AddonConfigException>()),
      );
    });

    test('throws AddonConfigException when item fails domain invariant validation', () {
      const invalidItemYaml = '''
addons:
  - id: "bad"
    label: "Bad Item"
    shortcut: "X"
    url: "javascript:void(0)"
''';
      expect(
        () => AddonsConfigService.parseAddonItemsFromYaml(invalidItemYaml),
        throwsA(isA<AddonConfigException>()),
      );
    });
  });
}
