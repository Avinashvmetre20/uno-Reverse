import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/features/shell/app_bottom_nav.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    required this.onFinanceSetup,
    required this.onSettings,
    required this.onLogout,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onFinanceSetup;
  final VoidCallback onSettings;
  final VoidCallback onLogout;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late final Future<Map<String, dynamic>> _profile = AuthApi.profile();

  @override
  Widget build(BuildContext context) {
    final email = AuthScope.of(context).tokens.email ?? '';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.84,
      backgroundColor: const Color(0xFFFCFAFB),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                children: [
                  _DrawerProfile(profile: _profile, fallbackEmail: email),
                  const SizedBox(height: 12),
                  for (var i = 0; i < appTabs.length && i < 3; i++)
                    _DrawerRow(
                      icon: widget.selectedIndex == i
                          ? appTabs[i].selectedIcon
                          : appTabs[i].icon,
                      label: appTabs[i].label,
                      selected: widget.selectedIndex == i,
                      onTap: () => widget.onSelectTab(i),
                    ),
                  _DrawerRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Finance Setup',
                    onTap: widget.onFinanceSetup,
                  ),
                  _DrawerRow(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: widget.onSettings,
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerRow(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    plainIcon: true,
                    onTap: () => _showHelp(context),
                  ),
                ],
              ),
            ),
            _DrawerRow(
              icon: Icons.logout_rounded,
              label: 'Logout',
              danger: true,
              plainIcon: true,
              onTap: widget.onLogout,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    showDialog<void>(
      context: navigator.context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'M-PIN, biometric unlock, and logout are in Settings. Banks and cards are in Finance Setup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _DrawerProfile extends StatelessWidget {
  const _DrawerProfile({
    required this.profile,
    required this.fallbackEmail,
  });

  final Future<Map<String, dynamic>> profile;
  final String fallbackEmail;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: profile,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        final name =
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        final email = '${data['email'] ?? fallbackEmail}'.trim();
        final title = name.isEmpty ? _labelFromEmail(email) : name;

        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              const _Avatar(radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: shellMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) {
      return 'Account';
    }
    return local;
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
    this.plainIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;
  final bool plainIcon;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? shellAccent
        : selected
        ? shellAccent
        : const Color(0xFF2C2C2E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: selected ? shellAccentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected || plainIcon
                        ? Colors.transparent
                        : const Color(0xFFF2F1F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: selected || danger
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.radius});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: shellAccentSoft,
      child: Icon(Icons.person, size: radius, color: shellAccent),
    );
  }
}
