import 'package:flutter/material.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/features/finance/finance_setup_page.dart';
import 'package:uno_reverse/features/home/home_page.dart';
import 'package:uno_reverse/features/home/profile_page.dart';
import 'package:uno_reverse/features/money/money_page.dart';
import 'package:uno_reverse/features/settings/settings_page.dart';
import 'package:uno_reverse/features/shell/app_bottom_nav.dart';
import 'package:uno_reverse/features/shell/app_drawer.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  bool _drawerOpen = false;

  void _openFinanceSetup() {
    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FinanceSetupPage()));
  }

  void _openSettings() {
    Navigator.of(context).pop();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  Future<void> _logout() async {
    await AuthScope.of(context).logout();
  }

  void _selectTab(int index) {
    Navigator.of(context).pop();
    setState(() => _index = index);
  }

  void _onSystemBack(bool didPop) {
    if (didPop) {
      return;
    }
    if (_drawerOpen) {
      _scaffoldKey.currentState?.closeDrawer();
      return;
    }
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0 && !_drawerOpen,
      onPopInvokedWithResult: (didPop, _) => _onSystemBack(didPop),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: shellCanvas,
        onDrawerChanged: (open) {
          if (_drawerOpen == open) {
            return;
          }
          setState(() => _drawerOpen = open);
        },
        drawer: AppDrawer(
          selectedIndex: _index,
          onSelectTab: _selectTab,
          onFinanceSetup: _openFinanceSetup,
          onSettings: _openSettings,
          onLogout: _logout,
        ),
        appBar: AppBar(
          backgroundColor: shellCanvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 64,
          leading: Builder(
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _RoundIconButton(
                  icon: Icons.apps_rounded,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              );
            },
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: Text(
              appTabs[_index].label,
              key: ValueKey(appTabs[_index].label),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1E),
              ),
            ),
          ),
        ),
        body: _AnimatedTabs(
          index: _index,
          children: [
            const HomePage(),
            const Center(child: Text('Vault')),
            MoneyPage(isActive: _index == 2),
            const ProfilePage(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppBottomNav(
              selectedIndex: _index,
              onSelected: (value) => setState(() => _index = value),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedTabs extends StatelessWidget {
  const _AnimatedTabs({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          IgnorePointer(
            ignoring: i != index,
            child: AnimatedOpacity(
              opacity: i == index ? 1 : 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: i == index
                    ? Offset.zero
                    : Offset(i < index ? -0.05 : 0.05, 0),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: TickerMode(enabled: i == index, child: children[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: shellAccentSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: const Color(0xFF1C1C1E)),
          ),
        ),
      ),
    );
  }
}
