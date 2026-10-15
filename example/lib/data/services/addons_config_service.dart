import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../../domain/models/addon_models.dart';

/// Exception thrown when addon configuration cannot be loaded, parsed, or validated.
class AddonConfigException implements Exception {
  final String message;
  final dynamic cause;

  const AddonConfigException(this.message, [this.cause]);

  @override
  String toString() => 'AddonConfigException: $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Service responsible for loading, parsing, and validating addon configurations.
///
/// Decoupled from BuildContext and UI navigation hierarchies.
class AddonsConfigService {
  final String assetPath;
  final AssetBundle _assetBundle;

  AddonsConfigService({
    this.assetPath = 'assets/config/addons.yaml',
    AssetBundle? assetBundle,
  }) : _assetBundle = assetBundle ?? rootBundle;

  /// Loads and parses the raw YAML configuration asset into domain [AddonItem] instances.
  Future<List<AddonItem>> loadAddonItems() async {
    try {
      final rawYaml = await _assetBundle.loadString(assetPath);
      return parseAddonItemsFromYaml(rawYaml);
    } catch (e) {
      if (e is AddonConfigException) rethrow;
      throw AddonConfigException(
        'Failed to load addon configuration from "$assetPath"',
        e,
      );
    }
  }

  /// Convenience method that wraps the parsed addon items into a single root [AddonSection].
  Future<AddonSection> loadAddonsSection({String sectionTitle = 'Addons'}) async {
    final items = await loadAddonItems();
    return AddonSection(
      title: sectionTitle,
      items: items,
    );
  }

  /// Parses raw YAML string directly into domain [AddonItem] list.
  ///
  /// Useful for testing without requiring Flutter asset bundles.
  static List<AddonItem> parseAddonItemsFromYaml(String rawYaml) {
    if (rawYaml.trim().isEmpty) {
      throw const AddonConfigException('YAML configuration content is empty.');
    }

    final dynamic yamlData;
    try {
      yamlData = loadYaml(rawYaml);
    } catch (e) {
      throw AddonConfigException('Malformed YAML syntax: $e', e);
    }

    if (yamlData is! YamlMap && yamlData is! Map) {
      throw const AddonConfigException('YAML root must be a mapping/object.');
    }

    final dynamic addonsList = yamlData['addons'];
    if (addonsList == null) {
      throw const AddonConfigException('YAML root is missing required "addons" list.');
    }

    if (addonsList is! YamlList && addonsList is! List) {
      throw const AddonConfigException('"addons" key must contain a list of addon definitions.');
    }

    final items = <AddonItem>[];
    for (int i = 0; i < addonsList.length; i++) {
      final dynamic rawItem = addonsList[i];
      if (rawItem is! YamlMap && rawItem is! Map) {
        throw AddonConfigException('Addon definition at index $i must be a map.');
      }
      items.add(_parseAddonItem(rawItem, 'addons[$i]'));
    }

    return List.unmodifiable(items);
  }

  static AddonItem _parseAddonItem(dynamic map, String contextPath) {
    final id = map['id']?.toString() ?? '';
    final label = map['label']?.toString() ?? '';
    final shortcut = map['shortcut']?.toString() ?? '';
    final rawUrl = map['url']?.toString();
    final dynamic rawSubMenu = map['subMenu'];

    Uri? uri;
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      try {
        uri = Uri.parse(rawUrl.trim());
      } catch (e) {
        throw AddonConfigException('Invalid URL format at $contextPath.url ("$rawUrl"): $e');
      }
    }

    List<AddonSection>? subMenu;
    if (rawSubMenu != null) {
      if (rawSubMenu is! YamlList && rawSubMenu is! List) {
        throw AddonConfigException('subMenu at $contextPath must be a list of sections.');
      }

      subMenu = [];
      for (int s = 0; s < rawSubMenu.length; s++) {
        final dynamic rawSection = rawSubMenu[s];
        if (rawSection is! YamlMap && rawSection is! Map) {
          throw AddonConfigException('Section at $contextPath.subMenu[$s] must be a map.');
        }

        final sectionTitle = rawSection['title']?.toString() ?? '';
        final dynamic rawSectionItems = rawSection['items'];

        if (rawSectionItems is! YamlList && rawSectionItems is! List) {
          throw AddonConfigException(
            'Section "$sectionTitle" at $contextPath.subMenu[$s] must contain an "items" list.',
          );
        }

        final sectionItems = <AddonItem>[];
        for (int k = 0; k < rawSectionItems.length; k++) {
          final dynamic subItem = rawSectionItems[k];
          if (subItem is! YamlMap && subItem is! Map) {
            throw AddonConfigException(
              'Item at $contextPath.subMenu[$s].items[$k] must be a map.',
            );
          }
          sectionItems.add(_parseAddonItem(subItem, '$contextPath.subMenu[$s].items[$k]'));
        }

        try {
          subMenu.add(AddonSection(
            title: sectionTitle,
            items: List.unmodifiable(sectionItems),
          ));
        } catch (e) {
          throw AddonConfigException('Invalid section at $contextPath.subMenu[$s]: $e');
        }
      }
    }

    try {
      return AddonItem(
        id: id,
        label: label,
        shortcut: shortcut,
        url: uri,
        subMenu: subMenu != null ? List.unmodifiable(subMenu) : null,
      );
    } catch (e) {
      throw AddonConfigException('Validation error at $contextPath: $e');
    }
  }
}
