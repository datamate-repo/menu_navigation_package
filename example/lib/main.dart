import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:menu_navigation/menu_navigation.dart';

import 'data/services/addons_config_service.dart';
import 'data/services/mock_auth_service.dart';
import 'ui/mappers/addon_menu_mapper.dart';

void main() {
  runApp(const MyApp());
}

class AppColors {
  static const Color appThemeColorLight = Color.fromARGB(255, 22, 54, 123);
  static const Color surface = Color(0xFFF5F7FA);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Navigation Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.appThemeColorLight,
          primary: AppColors.appThemeColorLight,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final AddonsConfigService _configService = AddonsConfigService();
  final MockAuthService _authService = const MockAuthService();
  late final AddonMenuMapper _mapper;
  late final Future<MenuSection?> _addonsSectionFuture;

  @override
  void initState() {
    super.initState();
    _mapper = AddonMenuMapper(
      sessionContextProvider: () => _authService.getMockSessionContext(),
    );
    _addonsSectionFuture = _loadAddons();
  }

  Future<MenuSection?> _loadAddons() async {
    try {
      final domainSection = await _configService.loadAddonsSection();
      return _mapper.mapSection(domainSection);
    } catch (e) {
      debugPrint('Failed to load addons configuration: $e');
      return null;
    }
  }

  List<MenuSection> _getStaticSections(BuildContext context) {
    return [
      MenuSection(
        title: 'Actions',
        items: [
          MenuItem(
            shortcut: 'S',
            label: 'Save',
            onTap: () {
              showCustomSnackBar(
                context: context,
                message: 'Save action triggered',
                type: SnackBarType.success,
              );
            },
          ),
          MenuItem(
            shortcut: 'P',
            label: 'Print',
            onTap: () {
              showCustomSnackBar(
                context: context,
                message: 'Print action triggered',
                type: SnackBarType.normal,
              );
            },
          ),
        ],
      ),
      MenuSection(
        title: 'Navigation',
        items: [
          MenuItem(
            shortcut: 'G',
            label: 'Settings',
            subMenu: [
              MenuSection(
                title: 'General Settings',
                items: [
                  MenuItem(shortcut: 'T', label: 'Theme', onTap: () {}),
                  MenuItem(shortcut: 'L', label: 'Language', onTap: () {}),
                ],
              ),
            ],
          ),
          MenuItem(
            shortcut: 'A',
            label: 'About',
            navigateTo: () => const AboutScreen(),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final staticSections = _getStaticSections(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<MenuSection?>(
        future: _addonsSectionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final addonsSection = snapshot.data;
          final menuData = [
            ...staticSections,
            ?addonsSection,
          ];

          return DynamicMenu(
            title: 'Main Menu',
            menuData: menuData,
            onMenuItemSelected: (item) {},
          );
        },
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(
        child: Text('This is the About Screen. Double-tap Escape to go back.'),
      ),
    );
  }
}
