import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uno_reverse/core/api/finance_api.dart';

class MoneyController extends ChangeNotifier {
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> banks = [];
  List<Map<String, dynamic>> cards = [];
  List<Map<String, dynamic>> creditCards = [];
  List<Map<String, dynamic>> transactions = [];
  double totalBalance = 0;

  Future<void> load({bool showFullPageLoader = true}) async {
    if (showFullPageLoader) {
      loading = true;
      error = null;
      notifyListeners();
    }

    try {
      final results = await Future.wait([
        FinanceApi.listBankBalances(),
        FinanceApi.listCreditCardBalances(),
        FinanceApi.listCards(),
        FinanceApi.listTransactions(),
      ]);

      final nextBanks = results[0];
      var total = 0.0;
      for (final bank in nextBanks) {
        total += asMoneyDouble(bank['balance']) ?? 0;
      }

      totalBalance = total;
      banks = nextBanks;
      creditCards = results[1];
      cards = results[2];
      transactions = results[3];
      loading = false;
      error = null;
      notifyListeners();
    } on FinanceException catch (e) {
      loading = false;
      if (showFullPageLoader) {
        error = e.message;
      }
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> debitCardsForBank(int? bankId) {
    if (bankId == null) {
      return [];
    }
    for (final bank in banks) {
      if (bank['bankId'] == bankId) {
        final raw = bank['debitCards'];
        if (raw is! List) {
          return [];
        }
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    return [];
  }

  String bankLabel(int? bankId) {
    if (bankId == null) {
      return 'Unknown bank';
    }
    for (final bank in banks) {
      if (bank['bankId'] == bankId) {
        final name = '${bank['bankName'] ?? 'Bank'}';
        final last4 = bank['accountLast4'];
        if (last4 != null && '$last4'.isNotEmpty) {
          return '$name · ****$last4';
        }
        return name;
      }
    }
    return 'Bank #$bankId';
  }

  String cardLabel(int? cardId) {
    if (cardId == null) {
      return '';
    }

    for (final card in creditCards) {
      if (card['cardId'] == cardId) {
        return _formatCardName(card);
      }
    }

    for (final bank in banks) {
      final debitCards = bank['debitCards'];
      if (debitCards is! List) {
        continue;
      }
      for (final item in debitCards.whereType<Map>()) {
        if (item['cardId'] == cardId) {
          return _formatCardName(Map<String, dynamic>.from(item));
        }
      }
    }

    for (final card in cards) {
      if (card['cardId'] == cardId) {
        return _formatCardName(card);
      }
    }
    return 'Card #$cardId';
  }

  String _formatCardName(Map<String, dynamic> card) {
    final name = '${card['cardName'] ?? 'Card'}';
    final last4 = card['cardLast4'];
    if (last4 != null && '$last4'.isNotEmpty) {
      return '$name · ****$last4';
    }
    return name;
  }

  void applyTransactionLocally(Map<String, dynamic> result) {
    final bankId = result['bankId'];
    final balanceAfter = asMoneyDouble(result['balanceAfter']);
    final transaction = result['transaction'];
    if (bankId is! int) {
      return;
    }

    if (balanceAfter != null) {
      banks = banks.map((bank) {
        if (bank['bankId'] == bankId) {
          return {
            ...bank,
            'balance': balanceAfter.toStringAsFixed(2),
          };
        }
        return Map<String, dynamic>.from(bank);
      }).toList();

      var total = 0.0;
      for (final bank in banks) {
        total += asMoneyDouble(bank['balance']) ?? 0;
      }
      totalBalance = total;
    }

    if (transaction is Map) {
      transactions = [
        Map<String, dynamic>.from(transaction),
        ...transactions,
      ];
    }

    notifyListeners();
  }

  Future<void> softRefreshBalancesAndActivity() async {
    try {
      final results = await Future.wait([
        FinanceApi.listBankBalances(),
        FinanceApi.listCreditCardBalances(),
        FinanceApi.listTransactions(),
      ]);

      final nextBanks = results[0];
      var total = 0.0;
      for (final bank in nextBanks) {
        total += asMoneyDouble(bank['balance']) ?? 0;
      }

      banks = nextBanks;
      creditCards = results[1];
      totalBalance = total;
      transactions = results[2];
      notifyListeners();
    } on FinanceException {
      // Keep current UI if quiet sync fails.
    }
  }

  Future<Map<String, dynamic>> submitSpendOrGain({
    required int bankId,
    int? cardId,
    required bool isSpend,
    required double amount,
    String? purpose,
    String? notes,
  }) async {
    final transaction = await FinanceApi.insertTransaction({
      'bankId': bankId,
      if (cardId != null) 'cardId': cardId,
      'transactionType': isSpend ? 'spend' : 'gain',
      'amount': amount,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    final balanceAfter = asMoneyDouble(transaction['balanceAmount']);

    applyTransactionLocally({
      'transaction': transaction,
      'bankId': bankId,
      'balanceAfter': balanceAfter,
    });

    unawaited(softRefreshBalancesAndActivity());

    return {
      'transaction': transaction,
      'bankId': bankId,
      'balanceAfter': balanceAfter,
    };
  }
}

double? asMoneyDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value'.trim());
}

String formatMoney(double value) {
  final fixed = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  return '₹$fixed';
}

String formatMoneyDate(dynamic value) {
  if (value == null) {
    return '';
  }
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) {
    return '';
  }
  final local = parsed.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
