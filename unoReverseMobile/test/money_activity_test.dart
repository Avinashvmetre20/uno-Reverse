import 'package:flutter_test/flutter_test.dart';
import 'package:uno_reverse/features/money/money_controller.dart';

void main() {
  test('formats transaction amounts from decimal strings', () {
    expect(formatMoneyExact('50.00'), '₹50.00');
    expect(formatMoneyExact('1000.00'), '₹1,000.00');
    expect(formatMoneyExact('10000'), '₹10,000.00');
    expect(moneySignedAmount(MoneyTransactionKind.spend, '100.00'), '-₹100.00');
    expect(moneySignedAmount(MoneyTransactionKind.gain, '100.00'), '+₹100.00');
  });

  test('uses purpose or a type fallback and skips null card names', () {
    expect(moneyTransactionTitle(MoneyTransactionKind.spend, 'rent'), 'Rent');
    expect(
      moneyTransactionTitle(MoneyTransactionKind.spend, null),
      'Card payment',
    );
    expect(
      moneyTransactionTitle(MoneyTransactionKind.gain, null),
      'Money received',
    );
    expect(
      moneyActivityMeta(bankName: 'SBI', cardName: null, time: '10:40 PM'),
      'SBI · 10:40 PM',
    );
    expect(
      moneyActivityMeta(bankName: 'SBI', cardName: 'Freedom', time: '10:35 PM'),
      'SBI · Freedom · 10:35 PM',
    );
  });

  test('groups activity by local day and converts UTC timestamps', () {
    const iso = '2026-09-24T17:10:57.228Z';
    final local = DateTime.parse(iso).toLocal();
    expect(moneyActivityClock(iso), _clock(local));
    expect(
      moneyDetailsStamp(iso),
      '${local.day} ${_month(local.month)} ${local.year} · ${_clock(local)}',
    );

    final rows = groupMoneyActivity([
      {'transactionDate': iso, 'purpose': 'rent'},
      {'transactionDate': iso, 'purpose': 'food'},
    ], now: local);

    expect(rows.first.isHeader, isTrue);
    expect(
      rows.first.label,
      'TODAY · ${local.day} ${_month(local.month).toUpperCase()}',
    );
    expect(rows.where((row) => !row.isHeader), hasLength(2));
  });
}

String _clock(DateTime local) {
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour12:$minute $suffix';
}

String _month(int month) {
  const names = [
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
  return names[month - 1];
}
