import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _profileFuture = AuthApi.profile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
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
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(title: const Text('Name'), subtitle: Text(name)),
              ListTile(
                title: const Text('Email'),
                subtitle: Text('${profile['email'] ?? ''}'),
              ),
              ListTile(
                title: const Text('Role'),
                subtitle: Text('${profile['role'] ?? ''}'),
              ),
            ],
          );
        },
      ),
    );
  }
}
