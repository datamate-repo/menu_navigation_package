import 'package:flutter_test/flutter_test.dart';
import 'package:example/domain/models/addon_models.dart';

void main() {
  group('AddonItem Invariant Tests', () {
    test('instantiates valid leaf item with https url', () {
      final item = AddonItem(
        id: 'leaf-1',
        label: 'Analytics',
        shortcut: 'A',
        url: Uri.parse('https://example.com/analytics'),
      );

      expect(item.id, equals('leaf-1'));
      expect(item.label, equals('Analytics'));
      expect(item.shortcut, equals('A'));
      expect(item.isLeaf, isTrue);
      expect(item.isBranch, isFalse);
    });

    test('instantiates valid branch item with subMenu', () {
      final item = AddonItem(
        id: 'branch-1',
        label: 'Operations',
        shortcut: 'O',
        subMenu: [
          AddonSection(
            title: 'Sub Section',
            items: [
              AddonItem(
                id: 'sub-leaf',
                label: 'Sub Leaf',
                shortcut: 'S',
                url: Uri.parse('http://localhost:8080'),
              ),
            ],
          ),
        ],
      );

      expect(item.isBranch, isTrue);
      expect(item.isLeaf, isFalse);
      expect(item.subMenu?.length, equals(1));
    });

    test('throws ArgumentError if id, label, or shortcut is empty or whitespace', () {
      expect(
        () => AddonItem(
          id: '   ',
          label: 'Test',
          shortcut: 'T',
          url: Uri.parse('https://example.com'),
        ),
        throwsArgumentError,
      );

      expect(
        () => AddonItem(
          id: '1',
          label: '   ',
          shortcut: 'T',
          url: Uri.parse('https://example.com'),
        ),
        throwsArgumentError,
      );

      expect(
        () => AddonItem(
          id: '1',
          label: 'Test',
          shortcut: '',
          url: Uri.parse('https://example.com'),
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if both url and subMenu are provided', () {
      expect(
        () => AddonItem(
          id: 'invalid-both',
          label: 'Invalid',
          shortcut: 'I',
          url: Uri.parse('https://example.com'),
          subMenu: [
            AddonSection(
              title: 'Sub',
              items: [
                AddonItem(
                  id: 'leaf',
                  label: 'L',
                  shortcut: 'L',
                  url: Uri.parse('https://example.com/sub'),
                ),
              ],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if neither url nor subMenu are provided', () {
      expect(
        () => AddonItem(
          id: 'invalid-none',
          label: 'Invalid',
          shortcut: 'I',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError if url scheme is not http or https', () {
      expect(
        () => AddonItem(
          id: 'xss-attempt',
          label: 'Script',
          shortcut: 'S',
          url: Uri.parse('javascript:alert(1)'),
        ),
        throwsArgumentError,
      );

      expect(
        () => AddonItem(
          id: 'ftp-scheme',
          label: 'FTP',
          shortcut: 'F',
          url: Uri.parse('ftp://files.example.com'),
        ),
        throwsArgumentError,
      );
    });
  });

  group('AddonSection Invariant Tests', () {
    test('throws ArgumentError if title is empty or items is empty', () {
      final validLeaf = AddonItem(
        id: 'leaf',
        label: 'Leaf',
        shortcut: 'L',
        url: Uri.parse('https://example.com'),
      );

      expect(
        () => AddonSection(title: '', items: [validLeaf]),
        throwsArgumentError,
      );

      expect(
        () => AddonSection(title: 'Valid Title', items: const []),
        throwsArgumentError,
      );
    });
  });
}
