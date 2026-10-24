import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'screens/command_generator_screen.dart';
import 'screens/search_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/settings_screen.dart';
import 'services/content_service.dart';
import 'services/command_service.dart';
import 'services/app_state.dart';
import 'services/tts_service.dart';
import 'services/ai_service.dart';
import 'services/scratchpad_service.dart';
import 'theme/app_theme.dart';
import 'widgets/tts_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgCard,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const HackTricksVaultApp());
}

class HackTricksVaultApp extends StatelessWidget {
  const HackTricksVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HackTricks Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  final ContentService _contentService = ContentService();
  final AppState _appState = AppState();
  final TtsService _ttsService = TtsService();
  final AiService _aiService = AiService();
  final ScratchpadService _scratchpadService = ScratchpadService();

  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      _contentService.init(),
      _appState.init(),
      _ttsService.init(),
      _aiService.init(),
      _scratchpadService.init(),
      CommandService().init(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.redTeam.withAlpha(150), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.redTeam.withAlpha(50),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'HackTricks Vault',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '100% Çevrimdışı Pentesting Bilgi Tabanı',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.redTeam),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screens = [
      HomeScreen(),
      const CommandGeneratorScreen(),
      const SearchScreen(),
      const BookmarksScreen(),
      const SettingsScreen(),
    ];

    final isTr = _contentService.currentLanguage == 'tr';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // Her zaman ekranın altından erişilebilir Floating TTS Player Bar
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: TtsPlayerBar(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.bgCard,
          indicatorColor: AppTheme.redTeam.withAlpha(40),
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppTheme.redTeam),
              label: isTr ? 'Ana Sayfa' : 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.terminal_outlined),
              selectedIcon: const Icon(Icons.terminal, color: AppTheme.redTeam),
              label: isTr ? 'Arsenal' : 'Arsenal',
            ),
            NavigationDestination(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search, color: AppTheme.redTeam),
              label: isTr ? 'Arama' : 'Search',
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_outline),
              selectedIcon: const Icon(Icons.bookmark, color: AppTheme.redTeam),
              label: isTr ? 'Yer İmleri' : 'Bookmarks',
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: AppTheme.redTeam),
              label: isTr ? 'Ayarlar' : 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
