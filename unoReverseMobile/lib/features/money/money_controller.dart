import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uno_reverse/core/api/finance_api.dart';

class MoneyController extends ChangeNotifier {
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> banks = [];
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
      transactions = results[2];
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
    final cardId = result['cardId'];
    final balanceAfter = asMoneyDouble(result['balanceAfter']);
    final transaction = result['transaction'];
    var changed = false;

    if (bankId is int) {
      if (balanceAfter != null) {
        banks = banks.map((bank) {
          if (bank['bankId'] == bankId) {
            return {...bank, 'balance': balanceAfter.toStringAsFixed(2)};
          }
          return Map<String, dynamic>.from(bank);
        }).toList();

        var total = 0.0;
        for (final bank in banks) {
          total += asMoneyDouble(bank['balance']) ?? 0;
        }
        totalBalance = total;
        changed = true;
      }
    } else if (cardId is int && balanceAfter != null) {
      creditCards = creditCards.map((card) {
        if (card['cardId'] == cardId) {
          changed = true;
          return {...card, 'spentAmount': balanceAfter.toStringAsFixed(2)};
        }
        return Map<String, dynamic>.from(card);
      }).toList();
    }

    if (transaction is Map) {
      transactions = [Map<String, dynamic>.from(transaction), ...transactions];
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
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
    int? bankId,
    int? cardId,
    required bool isSpend,
    required double amount,
    String? purpose,
    String? notes,
  }) async {
    final transaction = await FinanceApi.insertTransaction({
      if (bankId != null) 'bankId': bankId,
      if (cardId != null) 'cardId': cardId,
      'transactionType': isSpend ? 'spend' : 'gain',
      'amount': amount,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });

    final balanceAfter = asMoneyDouble(transaction['balanceAmount']);

    applyTransactionLocally({
      'transaction': transaction,
      'bankId': transaction['bankId'] ?? bankId,
      'cardId': transaction['cardId'] ?? cardId,
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

enum MoneyTransactionKind { spend, gain, transfer, refund, other }

MoneyTransactionKind moneyTransactionKind(dynamic raw) {
  switch ('${raw ?? ''}'.trim().toLowerCase()) {
    case 'spend':
      return MoneyTransactionKind.spend;
    case 'gain':
      return MoneyTransactionKind.gain;
    case 'transfer':
      return MoneyTransactionKind.transfer;
    case 'refund':
      return MoneyTransactionKind.refund;
    default:
      return MoneyTransactionKind.other;
  }
}

String moneyTransactionTypeLabel(MoneyTransactionKind kind) {
  switch (kind) {
    case MoneyTransactionKind.spend:
      return 'Spend';
    case MoneyTransactionKind.gain:
      return 'Gain';
    case MoneyTransactionKind.transfer:
      return 'Transfer';
    case MoneyTransactionKind.refund:
      return 'Refund';
    case MoneyTransactionKind.other:
      return 'Transaction';
  }
}

String moneyTransactionTitle(MoneyTransactionKind kind, dynamic purpose) {
  final text = _cleanText(purpose);
  if (text.isNotEmpty) {
    return _titleCase(text);
  }
  switch (kind) {
    case MoneyTransactionKind.spend:
      return 'Card payment';
    case MoneyTransactionKind.gain:
      return 'Money received';
    case MoneyTransactionKind.transfer:
      return 'Transfer';
    case MoneyTransactionKind.refund:
      return 'Refund';
    case MoneyTransactionKind.other:
      return 'Transaction';
  }
}

String formatMoneyExact(dynamic value) {
  final raw = _cleanText(value);
  if (raw.isEmpty) {
    return '';
  }
  final unsigned = raw.startsWith('-') ? raw.substring(1) : raw;
  final pieces = unsigned.split('.');
  final digits = pieces.first.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) {
    return '';
  }
  final whole = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final grouped = _groupThousands(whole.isEmpty ? '0' : whole);
  var fraction = pieces.length > 1
      ? pieces[1].replaceAll(RegExp(r'[^0-9]'), '')
      : '';
  if (fraction.length > 2) {
    fraction = fraction.substring(0, 2);
  }
  fraction = fraction.padRight(2, '0');
  return '₹$grouped.$fraction';
}

String moneySignedAmount(MoneyTransactionKind kind, dynamic amount) {
  final formatted = formatMoneyExact(amount);
  if (formatted.isEmpty) {
    return '';
  }
  switch (kind) {
    case MoneyTransactionKind.spend:
    case MoneyTransactionKind.transfer:
      return '-$formatted';
    case MoneyTransactionKind.gain:
    case MoneyTransactionKind.refund:
      return '+$formatted';
    case MoneyTransactionKind.other:
      return formatted;
  }
}

String moneyActivityMeta({
  required dynamic bankName,
  required dynamic cardName,
  required String time,
}) {
  final parts = <String>[
    if (_cleanText(bankName).isNotEmpty) _cleanText(bankName),
    if (_cleanText(cardName).isNotEmpty) _cleanText(cardName),
    if (time.isNotEmpty) time,
  ];
  return parts.join(' · ');
}

DateTime? moneyLocalTime(dynamic value) {
  final raw = _cleanText(value);
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw)?.toLocal();
}

String moneyActivityClock(dynamic value) {
  final local = moneyLocalTime(value);
  if (local == null) {
    return '';
  }
  return _clock(local);
}

String moneyActivityGroupLabel(dynamic value, [DateTime? now]) {
  final local = value is DateTime ? value : moneyLocalTime(value);
  if (local == null) {
    return 'UNDATED';
  }
  final clock = now ?? DateTime.now();
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(clock.year, clock.month, clock.day);
  final stamp = '${local.day} ${_monthUpper(local.month)}';
  if (day == today) {
    return 'TODAY · $stamp';
  }
  if (day == today.subtract(const Duration(days: 1))) {
    return 'YESTERDAY · $stamp';
  }
  if (local.year == clock.year) {
    return stamp;
  }
  return '$stamp ${local.year}';
}

String moneyDetailsStamp(dynamic value) {
  final local = moneyLocalTime(value);
  if (local == null) {
    return '';
  }
  return '${local.day} ${_month(local.month)} ${local.year} · ${_clock(local)}';
}

class MoneyActivityEntry {
  const MoneyActivityEntry.header(this.label) : transaction = null;

  const MoneyActivityEntry.item(this.transaction) : label = null;

  final String? label;
  final Map<String, dynamic>? transaction;

  bool get isHeader => label != null;
}

List<MoneyActivityEntry> groupMoneyActivity(
  List<Map<String, dynamic>> transactions, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final rows = <MoneyActivityEntry>[];
  DateTime? currentDay;
  var sawUndated = false;

  for (final transaction in transactions) {
    final local = moneyLocalTime(
      transaction['transactionDate'] ?? transaction['createdAt'],
    );
    if (local == null) {
      if (!sawUndated) {
        sawUndated = true;
        currentDay = null;
        rows.add(const MoneyActivityEntry.header('UNDATED'));
      }
      rows.add(MoneyActivityEntry.item(transaction));
      continue;
    }

    final day = DateTime(local.year, local.month, local.day);
    if (currentDay != day) {
      currentDay = day;
      sawUndated = false;
      rows.add(
        MoneyActivityEntry.header(moneyActivityGroupLabel(local, clock)),
      );
    }
    rows.add(MoneyActivityEntry.item(transaction));
  }

  return rows;
}

String _cleanText(dynamic value) {
  if (value == null) {
    return '';
  }
  final text = '$value'.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }
  return text;
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) {
          return word;
        }
        return '${word[0].toUpperCase()}${word.substring(1)}';
      })
      .join(' ');
}

String _groupThousands(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String _clock(DateTime local) {
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $suffix';
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _month(int month) => _monthNames[month - 1];

String _monthUpper(int month) => _month(month).toUpperCase();
