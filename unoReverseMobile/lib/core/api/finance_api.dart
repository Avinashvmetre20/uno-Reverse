import 'package:uno_reverse/core/api/api_client.dart';

typedef FinanceException = ApiException;

class FinanceApi {
  static Future<List<Map<String, dynamic>>> listBanks() async {
    final data = await ApiClient.get('/banks');
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to load banks'));
    }
    return ApiClient.asList(data.body);
  }

  static Future<List<Map<String, dynamic>>> listBankBalances() async {
    final data = await ApiClient.get('/bank-balance');
    if (data.statusCode != 200) {
      throw FinanceException(
        ApiClient.message(data.body, 'Unable to load bank balances'),
      );
    }

    final body = data.body;
    if (body is Map && body['data'] is List) {
      return ApiClient.asList(body['data']);
    }
    return ApiClient.asList(body);
  }

  static Future<List<Map<String, dynamic>>> listCreditCardBalances() async {
    final data = await ApiClient.get('/credit-card-balance');
    if (data.statusCode != 200) {
      throw FinanceException(
        ApiClient.message(data.body, 'Unable to load credit card balances'),
      );
    }

    final body = data.body;
    if (body is Map && body['data'] is List) {
      return ApiClient.asList(body['data']);
    }
    return ApiClient.asList(body);
  }

  static Future<Map<String, dynamic>> createBank(Map<String, dynamic> payload) async {
    final data = await ApiClient.post('/banks', payload);
    if (data.statusCode != 201) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to create bank'));
    }
    return ApiClient.asMap(data.body);
  }

  static Future<Map<String, dynamic>> updateBank(
    int bankId,
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.put('/banks/$bankId', payload);
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to update bank'));
    }
    return ApiClient.asMap(data.body);
  }

  static Future<void> deleteBank(int bankId) async {
    final data = await ApiClient.delete('/banks/$bankId');
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to delete bank'));
    }
  }

  static Future<List<Map<String, dynamic>>> listCards() async {
    final data = await ApiClient.get('/cards');
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to load cards'));
    }
    return ApiClient.asList(data.body);
  }

  static Future<Map<String, dynamic>> createCard(Map<String, dynamic> payload) async {
    final data = await ApiClient.post('/cards', payload);
    if (data.statusCode != 201) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to create card'));
    }
    return ApiClient.asMap(data.body);
  }

  static Future<Map<String, dynamic>> updateCard(
    int cardId,
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.put('/cards/$cardId', payload);
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to update card'));
    }
    return ApiClient.asMap(data.body);
  }

  static Future<void> deleteCard(int cardId) async {
    final data = await ApiClient.delete('/cards/$cardId');
    if (data.statusCode != 200) {
      throw FinanceException(ApiClient.message(data.body, 'Unable to delete card'));
    }
  }

  static Future<List<Map<String, dynamic>>> listTransactions() async {
    final data = await ApiClient.get('/transactions/list');
    if (data.statusCode != 200) {
      throw FinanceException(
        ApiClient.message(data.body, 'Unable to load transactions'),
      );
    }

    final body = data.body;
    if (body is Map && body['data'] is List) {
      return ApiClient.asList(body['data']);
    }
    return ApiClient.asList(body);
  }

  static Future<Map<String, dynamic>> insertTransaction(
    Map<String, dynamic> payload,
  ) async {
    final data = await ApiClient.post('/insert-transactions', payload);
    if (data.statusCode != 201) {
      throw FinanceException(
        ApiClient.message(data.body, 'Unable to insert transaction'),
      );
    }

    final body = data.body;
    if (body is Map && body['data'] is Map) {
      return ApiClient.asMap(body['data']);
    }
    return ApiClient.asMap(body);
  }
}
