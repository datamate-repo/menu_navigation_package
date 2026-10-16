import 'package:menu_navigation/menu_navigation.dart';

import '../../data/services/mock_auth_service.dart';
import '../../domain/models/addon_models.dart';
import '../../domain/models/plugin_session_context.dart';
import '../screens/iframe_view_screen.dart';

/// Pure mapping logic decoupling domain addon models from UI menu components.
class AddonMenuMapper {
  final PluginSessionContext Function()? _sessionContextProvider;

  const AddonMenuMapper({
    PluginSessionContext Function()? sessionContextProvider,
  }) : _sessionContextProvider = sessionContextProvider;

  PluginSessionContext _resolveSessionContext() {
    if (_sessionContextProvider != null) {
      return _sessionContextProvider();
    }
    return const MockAuthService().getMockSessionContext();
  }

  /// Transforms a domain [AddonSection] into a package [MenuSection].
  MenuSection mapSection(AddonSection section) {
    return MenuSection(
      title: section.title,
      items: section.items.map(mapItem).toList(),
    );
  }

  /// Recursively transforms a domain [AddonItem] into a package [MenuItem].
  MenuItem mapItem(AddonItem item) {
    if (item.isLeaf) {
      return MenuItem(
        shortcut: item.shortcut,
        label: item.label,
        navigateTo: () => IFrameViewScreen(
          url: item.url.toString(),
          title: item.label,
          sessionContext: _resolveSessionContext(),
        ),
      );
    }

    return MenuItem(
      shortcut: item.shortcut,
      label: item.label,
      subMenu: item.subMenu?.map(mapSection).toList(),
    );
  }
}
