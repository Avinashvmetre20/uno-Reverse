import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/api/auth_api.dart';
import 'package:uno_reverse/core/authentication/auth_controller.dart';
import 'package:uno_reverse/features/shell/app_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _profileFuture = AuthApi.profile();
  bool _copied = false;

  Future<void> _copyToken(String token) async {
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Access token copied'),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final token = AuthScope.of(context).tokens.accessToken ?? '';

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error is AuthException
                  ? (snapshot.error! as AuthException).message
                  : 'Unable to load profile',
            ),
          );
        }

        final profile = snapshot.data ?? {};
        final name =
            '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Name'),
              subtitle: Text(name.isEmpty ? '—' : name),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Email'),
              subtitle: Text('${profile['email'] ?? ''}'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Role'),
              subtitle: Text('${profile['role'] ?? ''}'),
            ),
            const SizedBox(height: 8),
            Text(
              'Access token',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        token.isEmpty ? '—' : token,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy access token',
                      onPressed: token.isEmpty ? null : () => _copyToken(token),
                      icon: Icon(
                        _copied ? Icons.check_rounded : Icons.copy_rounded,
                        color: _copied ? shellAccent : const Color(0xFF1C1C1E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
