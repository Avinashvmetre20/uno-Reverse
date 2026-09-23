import 'package:flutter/material.dart';
import 'package:uno_reverse/features/money/money_page.dart';
import 'package:uno_reverse/features/more/more_page.dart';
import 'package:uno_reverse/features/profile/profile_page.dart';
import 'package:uno_reverse/features/vault/vault_page.dart';
import 'package:uno_reverse/shared/widgets/app_drawer.dart';
import 'package:uno_reverse/shared/widgets/placeholder_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = ['Home', 'Vault', 'Money', 'More'];

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedIndex: _index,
        onSelect: (value) => setState(() => _index = value),
      ),
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.apps),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 18),
            ),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          PlaceholderView('Home'),
          VaultPage(),
          MoneyPage(),
          MorePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline),
            selectedIcon: Icon(Icons.lock),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Money',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
