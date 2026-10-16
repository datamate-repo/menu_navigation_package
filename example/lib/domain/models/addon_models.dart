import 'package:flutter/foundation.dart';

/// Domain model representing a single addon navigation item.
///
/// Follows strict domain invariants:
/// - Must have a valid non-empty [id], [label], and [shortcut].
/// - Must either be a leaf action with a valid HTTP/HTTPS [url], OR a branch node
///   with a non-empty [subMenu] of [AddonSection]s.
@immutable
class AddonItem {
  final String id;
  final String label;
  final String shortcut;
  final Uri? url;
  final List<AddonSection>? subMenu;

  AddonItem({
    required this.id,
    required this.label,
    required this.shortcut,
    this.url,
    this.subMenu,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'AddonItem id cannot be empty');
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(label, 'label', 'AddonItem label cannot be empty');
    }
    if (shortcut.trim().isEmpty) {
      throw ArgumentError.value(shortcut, 'shortcut', 'AddonItem shortcut cannot be empty');
    }

    final hasUrl = url != null;
    final hasSubMenu = subMenu != null && subMenu!.isNotEmpty;

    if (hasUrl == hasSubMenu) {
      throw ArgumentError(
        'AddonItem ($id) must have either a valid url or a non-empty subMenu, but not both.',
      );
    }

    if (hasUrl) {
      if (!url!.hasScheme || (url!.scheme != 'http' && url!.scheme != 'https')) {
        throw ArgumentError.value(
          url,
          'url',
          'AddonItem ($id) url must be an absolute URI with an http or https scheme.',
        );
      }
      if (url!.host.isEmpty) {
        throw ArgumentError.value(
          url,
          'url',
          'AddonItem ($id) url must have a non-empty host.',
        );
      }
    }
  }

  /// Whether this item is a leaf node that opens an IFrame.
  bool get isLeaf => url != null;

  /// Whether this item is a branch node containing sub-menus.
  bool get isBranch => subMenu != null && subMenu!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddonItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          shortcut == other.shortcut &&
          url == other.url &&
          listEquals(subMenu, other.subMenu);

  @override
  int get hashCode => Object.hash(id, label, shortcut, url, subMenu);

  @override
  String toString() =>
      'AddonItem(id: $id, label: $label, shortcut: $shortcut, url: $url, subMenu: $subMenu)';
}

/// Domain model representing a section/grouping of addon items.
@immutable
class AddonSection {
  final String title;
  final List<AddonItem> items;

  AddonSection({
    required this.title,
    required this.items,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'AddonSection title cannot be empty');
    }
    if (items.isEmpty) {
      throw ArgumentError.value(items, 'items', 'AddonSection items cannot be empty');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddonSection &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(title, items);

  @override
  String toString() => 'AddonSection(title: $title, items: $items)';
}
