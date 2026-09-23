import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';
import 'package:uno_reverse/features/auth/login_page.dart';
import 'package:uno_reverse/features/profile/profile_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  void _open(BuildContext context, int index) {
    Navigator.of(context).pop();
    onSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Uno Reverse',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Home'),
              selected: selectedIndex == 0,
              onTap: () => _open(context, 0),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Vault'),
              selected: selectedIndex == 1,
              onTap: () => _open(context, 1),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Money'),
              selected: selectedIndex == 2,
              onTap: () => _open(context, 2),
            ),
            ListTile(
              leading: const Icon(Icons.more_horiz),
              title: const Text('More'),
              selected: selectedIndex == 3,
              onTap: () => _open(context, 3),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                AuthApi.logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
