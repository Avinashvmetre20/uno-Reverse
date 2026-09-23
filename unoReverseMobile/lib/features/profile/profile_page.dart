import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/auth_api.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthApi.profile();
  }

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
          final firstName = '${profile['firstName'] ?? ''}';
          final lastName = '${profile['lastName'] ?? ''}';
          final email = '${profile['email'] ?? ''}';
          final role = '${profile['role'] ?? ''}';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ListTile(
                title: const Text('Name'),
                subtitle: Text('$firstName $lastName'.trim()),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(email),
              ),
              ListTile(
                title: const Text('Role'),
                subtitle: Text(role),
              ),
            ],
          );
        },
      ),
    );
  }
}
