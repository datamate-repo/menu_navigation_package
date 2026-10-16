import 'package:flutter_test/flutter_test.dart';
import 'package:example/domain/models/addon_models.dart';
import 'package:example/domain/models/plugin_session_context.dart';
import 'package:example/ui/mappers/addon_menu_mapper.dart';
import 'package:example/ui/screens/iframe_view_screen.dart';

void main() {
  const mapper = AddonMenuMapper();

  group('AddonMenuMapper Tests', () {
    test('correctly maps leaf AddonItem to MenuItem with navigateTo returning IFrameViewScreen and default sessionContext', () {
      final item = AddonItem(
        id: 'leaf-test',
        label: 'My Addon',
        shortcut: 'M',
        url: Uri.parse('https://example.com/app'),
      );

      final menuItem = mapper.mapItem(item);

      expect(menuItem.label, equals('My Addon'));
      expect(menuItem.shortcut, equals('M'));
      expect(menuItem.subMenu, isNull);
      expect(menuItem.navigateTo, isNotNull);

      // Verify the widget returned by navigateTo
      final screen = menuItem.navigateTo!.call();
      expect(screen, isA<IFrameViewScreen>());
      final iframeScreen = screen as IFrameViewScreen;
      expect(iframeScreen.url, equals('https://example.com/app'));
      expect(iframeScreen.title, equals('My Addon'));
      expect(iframeScreen.sessionContext.context.companyId, equals('COMP-001'));
      expect(iframeScreen.sessionContext.auth.token.isNotEmpty, isTrue);
    });

    test('injects custom sessionContext from sessionContextProvider', () {
      final customMapper = AddonMenuMapper(
        sessionContextProvider: () => const PluginSessionContext(
          auth: AuthContext(token: 'custom.jwt.token'),
          context: FiscalContext(
            companyId: 'CUSTOM-CORP',
            companyName: 'Custom Corp',
            finYear: '2030-2031',
            branchId: 'BR-WEST',
            currency: 'EUR',
          ),
          user: UserContext(id: 'U99', name: 'Bob', role: 'MANAGER'),
        ),
      );

      final item = AddonItem(
        id: 'leaf-2',
        label: 'Addon 2',
        shortcut: '2',
        url: Uri.parse('https://example.com/two'),
      );

      final menuItem = customMapper.mapItem(item);
      final screen = menuItem.navigateTo!.call() as IFrameViewScreen;
      expect(screen.sessionContext.context.companyId, equals('CUSTOM-CORP'));
      expect(screen.sessionContext.auth.token, equals('custom.jwt.token'));
      expect(screen.sessionContext.context.currency, equals('EUR'));
    });

    test('correctly maps branch AddonItem to MenuItem with nested subMenu', () {
      final item = AddonItem(
        id: 'branch-test',
        label: 'Finance',
        shortcut: 'F',
        subMenu: [
          AddonSection(
            title: 'Cash Ops',
            items: [
              AddonItem(
                id: 'imprest',
                label: 'Imprest',
                shortcut: 'I',
                url: Uri.parse('http://localhost:55874/cash'),
              ),
            ],
          ),
        ],
      );

      final menuItem = mapper.mapItem(item);

      expect(menuItem.label, equals('Finance'));
      expect(menuItem.shortcut, equals('F'));
      expect(menuItem.navigateTo, isNull);
      expect(menuItem.subMenu, isNotNull);
      expect(menuItem.subMenu?.length, equals(1));
      expect(menuItem.subMenu?.first.title, equals('Cash Ops'));
      expect(menuItem.subMenu?.first.items.length, equals(1));
      expect(menuItem.subMenu?.first.items.first.label, equals('Imprest'));
      expect(menuItem.subMenu?.first.items.first.navigateTo, isNotNull);
    });

    test('correctly maps AddonSection to MenuSection', () {
      final section = AddonSection(
        title: 'Addons Root',
        items: [
          AddonItem(
            id: 'addon-1',
            label: 'Addon 1',
            shortcut: '1',
            url: Uri.parse('http://localhost:3000'),
          ),
        ],
      );

      final menuSection = mapper.mapSection(section);

      expect(menuSection.title, equals('Addons Root'));
      expect(menuSection.items.length, equals(1));
      expect(menuSection.items.first.label, equals('Addon 1'));
    });
  });
}
