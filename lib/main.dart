import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/settings_controller.dart';
import 'features/home/home_page.dart';
import 'features/settings/settings_page.dart';
import 'features/chat/chat_page.dart';
import 'features/tools/tools_page.dart';
import 'features/tools/browser/browser_page.dart';
import 'features/webview_library/webview_library_page.dart';
import 'core/update/update_dialog.dart';
import 'core/theme/kyowi_grid_background.dart';

void main() {
  runApp(const KyowiApp());
}

class KyowiApp extends StatelessWidget {
  const KyowiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kyowi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      builder: (context, child) => KyowiGridBackground(child: child ?? const SizedBox()),
      home: const RootShell(),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _ready = false;
  late final AnimationController _fadeController;

  // Semua page dibuat sekali di sini dan dijaga tetap hidup lewat
  // IndexedStack (bukan diganti-ganti widget) - jadi state kayak history
  // chat AI gak ilang pas pindah tab, cuma reset kalau app di-close total.
  final _pages = const [
    HomePage(),
    ChatPage(),
    ToolsPage(),
    BrowserPage(),
    WebviewLibraryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _init();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _selectTab(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _fadeController.forward(from: 0);
  }

  Future<void> _init() async {
    await SettingsController.instance.load();
    if (mounted) setState(() => _ready = true);
    // Cek update diam-diam - dialog cuma nongol kalau memang ada versi baru.
    if (mounted) checkAndShowUpdateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
      );
    }

    return ListenableBuilder(
      listenable: SettingsController.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kyowi Sys.',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.gray)),
            centerTitle: false,
            actions: const [
              Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.circle, size: 8, color: AppColors.cyan),
              ),
            ],
          ),
          body: SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
              child: IndexedStack(
                index: _index,
                children: _pages,
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _selectTab,
            backgroundColor: AppColors.bg,
            indicatorColor: AppColors.panel2,
            elevation: 0,
            height: 62,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.cyan), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.chat_outlined), selectedIcon: Icon(Icons.chat, color: AppColors.cyan), label: 'Chat'),
              NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build, color: AppColors.cyan), label: 'Tools'),
              NavigationDestination(icon: Icon(Icons.public_outlined), selectedIcon: Icon(Icons.public, color: AppColors.cyan), label: 'Web'),
              NavigationDestination(icon: Icon(Icons.code), selectedIcon: Icon(Icons.code, color: AppColors.cyan), label: 'WB'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: AppColors.cyan), label: 'Setting'),
            ],
          ),
        );
      },
    );
  }
}
