import 'package:uno_reverse/core/api/api_client.dart';

typedef AuthException = ApiException;

class AuthApi {
  static Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post('/auth/register', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    });

    if (data.statusCode != 201) {
      throw AuthException(ApiClient.message(data.body, 'Unable to register'));
    }
  }

  static Future<Map<String, dynamic>> profile() async {
    final data = await ApiClient.get('/auth/profile');

    if (data.statusCode != 200) {
      throw AuthException(ApiClient.message(data.body, 'Unable to load profile'));
    }

    return ApiClient.asMap(data.body);
  }
}
