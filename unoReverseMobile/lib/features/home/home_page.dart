import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';
import 'package:uno_reverse/features/auth/login_page.dart';
import 'package:uno_reverse/features/finance/finance_setup_page.dart';
import 'package:uno_reverse/features/home/profile_page.dart';
import 'package:uno_reverse/features/money/money_page.dart';

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

  void _openFinanceSetup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FinanceSetupPage()),
    );
  }

  void _logout() {
    AuthApi.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const DrawerHeader(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Uno Reverse',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < _titles.length; i++)
                      ListTile(
                        leading: Icon(_tabIcon(i, selected: false)),
                        title: Text(_titles[i]),
                        selected: _index == i,
                        onTap: () {
                          Navigator.of(context).pop();
                          setState(() => _index = i);
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: const Text('Finance Setup'),
                      onTap: () {
                        Navigator.of(context).pop();
                        _openFinanceSetup();
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: _logout,
              ),
            ],
          ),
        ),
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
        children: [
          const Center(child: Text('Home')),
          const Center(child: Text('Vault')),
          MoneyPage(isActive: _index == 2),
          Center(
            child: TextButton(
              onPressed: _logout,
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          for (var i = 0; i < _titles.length; i++)
            NavigationDestination(
              icon: Icon(_tabIcon(i, selected: false)),
              selectedIcon: Icon(_tabIcon(i, selected: true)),
              label: _titles[i],
            ),
        ],
      ),
    );
  }

  IconData _tabIcon(int index, {required bool selected}) {
    switch (index) {
      case 1:
        return selected ? Icons.lock : Icons.lock_outline;
      case 2:
        return selected
            ? Icons.account_balance_wallet
            : Icons.account_balance_wallet_outlined;
      case 3:
        return Icons.more_horiz;
      default:
        return selected ? Icons.home : Icons.home_outlined;
    }
  }
}
