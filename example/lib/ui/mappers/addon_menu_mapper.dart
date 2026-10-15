import 'package:menu_navigation/menu_navigation.dart';

import '../../domain/models/addon_models.dart';
import '../screens/iframe_view_screen.dart';

/// Pure mapping logic decoupling domain addon models from UI menu components.
class AddonMenuMapper {
  const AddonMenuMapper();

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
