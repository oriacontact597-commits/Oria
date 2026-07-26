import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav.dart';
import 'chat/oria_screen.dart';
import 'explorer/explorer_screen.dart';
import 'home/home_oria.dart';
import 'profile/profile_screen.dart';

/// Bottom nav 3 onglets : Accueil / Explorer / Profil.
/// ORIA devient la Home (HomeOriaScreen), plus un FAB séparé.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _loadingRole = true;

  static const _tabs = [
    NavTab(
      icon: Icons.auto_awesome,
      iconOutlined: Icons.auto_awesome_outlined,
      label: 'ORIA',
    ),
    NavTab(
      icon: Icons.menu_book_rounded,
      iconOutlined: Icons.menu_book_outlined,
      label: 'Explorer',
    ),
    NavTab(
      icon: Icons.person_rounded,
      iconOutlined: Icons.person_outline_rounded,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final api = ApiService();
      await api.getUserRole();
      if (mounted) {
        setState(() {
          _loadingRole = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRole = false);
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 1:
        return const ExplorerScreen();
      case 2:
        return const ProfileScreen();
      default:
        return _loadingRole ? const SizedBox() : const HomeOriaScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        tabs: _tabs,
      ),
      floatingActionButton: _currentIndex == 0
          ? null
          : FloatingActionButton.small(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OriaScreen()),
              ),
              backgroundColor: const Color(0xFF3133DD),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
    );
  }
}
