import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/api/finance_api.dart';
import 'package:uno_reverse/features/money/money_controller.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({
    super.key,
    required this.banks,
    required this.creditCards,
  });

  final List<Map<String, dynamic>> banks;
  final List<Map<String, dynamic>> creditCards;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final bankTotal = banks.fold<double>(
      0,
      (sum, bank) => sum + (asMoneyDouble(bank['balance']) ?? 0),
    );
    final spendTotal = creditCards.fold<double>(
      0,
      (sum, card) => sum + (asMoneyDouble(card['spentAmount']) ?? 0),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.28)!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _BalanceColumn(
                title: 'Bank accounts',
                color: onPrimary,
                lines: [
                  for (final bank in banks)
                    _BalanceLine(
                      label: '${bank['bankName'] ?? 'Bank'}',
                      amount: formatMoney(asMoneyDouble(bank['balance']) ?? 0),
                    ),
                ],
                total: formatMoney(bankTotal),
                emptyText: 'No banks',
              ),
            ),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: onPrimary.withValues(alpha: 0.28),
            ),
            Expanded(
              child: _BalanceColumn(
                title: 'Credit cards',
                color: onPrimary,
                lines: [
                  for (final card in creditCards)
                    _BalanceLine(
                      label: '${card['cardName'] ?? 'Card'}',
                      amount: formatMoney(
                        asMoneyDouble(card['spentAmount']) ?? 0,
                      ),
                    ),
                ],
                total: '-${formatMoney(spendTotal)}',
                emptyText: 'No cards',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceLine {
  const _BalanceLine({required this.label, required this.amount});

  final String label;
  final String amount;
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.title,
    required this.color,
    required this.lines,
    required this.total,
    required this.emptyText,
  });

  final String title;
  final Color color;
  final List<_BalanceLine> lines;
  final String total;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color.withValues(alpha: 0.75),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (lines.isEmpty)
          Text(
            emptyText,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
          )
        else
          for (final line in lines) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  line.amount,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        const SizedBox(height: 2),
        Divider(height: 1, thickness: 1, color: color.withValues(alpha: 0.35)),
        const SizedBox(height: 8),
        Text(
          total,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class MoneyActionButton extends StatelessWidget {
  const MoneyActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptySetupCard extends StatelessWidget {
  const EmptySetupCard({super.key, required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            'Add a bank account to start tracking spend and gain.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onSetup,
            child: const Text('Open Finance Setup'),
          ),
        ],
      ),
    );
  }
}

class EmptyActivity extends StatelessWidget {
  const EmptyActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        'No transactions yet\n\nYour spending and income activity\nwill appear here.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final Map<String, dynamic> transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = moneyTransactionKind(transaction['transactionType']);
    final color = _transactionColor(kind);
    final title = moneyTransactionTitle(kind, transaction['purpose']);
    final meta = moneyActivityMeta(
      bankName: transaction['bankName'],
      cardName: transaction['cardName'],
      time: moneyActivityClock(
        transaction['transactionDate'] ?? transaction['createdAt'],
      ),
    );
    final amount = moneySignedAmount(kind, transaction['amount']);
    final balance = formatMoneyExact(transaction['balanceAmount']);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(_transactionIcon(kind), size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                  if (balance.isNotEmpty)
                    Text(
                      balance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: muted),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionDateHeader extends StatelessWidget {
  const TransactionDateHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

void showTransactionDetails(
  BuildContext context,
  Map<String, dynamic> transaction,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TransactionDetailsSheet(transaction: transaction),
  );
}

class TransactionDetailsSheet extends StatelessWidget {
  const TransactionDetailsSheet({super.key, required this.transaction});

  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final kind = moneyTransactionKind(transaction['transactionType']);
    final color = _transactionColor(kind);
    final title = moneyTransactionTitle(kind, transaction['purpose']);
    final signed = moneySignedAmount(kind, transaction['amount']);
    final amount = formatMoneyExact(transaction['amount']);
    final balance = formatMoneyExact(transaction['balanceAmount']);
    final bank = _detailText(transaction['bankName'], 'Not linked');
    final card = _detailText(transaction['cardName'], 'Not linked');
    final notes = _detailText(transaction['notes'], 'No notes');
    final when = moneyDetailsStamp(transaction['transactionDate']);
    final created = moneyDetailsStamp(transaction['createdAt']);
    final updated = moneyDetailsStamp(transaction['updatedAt']);
    final id = transaction['userTransactionId'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Transaction Details',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Icon(_transactionIcon(kind), color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              signed,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              moneyTransactionTypeLabel(kind).toUpperCase(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 20),
            const _DetailHeading('Account'),
            _DetailRow(label: 'Bank', value: bank),
            _DetailRow(label: 'Card', value: card),
            const _DetailHeading('Transaction'),
            _DetailRow(label: 'Amount', value: amount.isEmpty ? '—' : amount),
            _DetailRow(
              label: 'Transaction Type',
              value: moneyTransactionTypeLabel(kind),
            ),
            _DetailRow(
              label: 'Balance After Transaction',
              value: balance.isEmpty ? '—' : balance,
            ),
            _DetailRow(label: 'Purpose', value: title),
            _DetailRow(label: 'Date & Time', value: when.isEmpty ? '—' : when),
            const _DetailHeading('Additional Information'),
            _DetailRow(label: 'Notes', value: notes),
            if (id != null) _DetailRow(label: 'Transaction ID', value: '#$id'),
            if (created.isNotEmpty)
              _DetailRow(label: 'Created', value: created),
            if (updated.isNotEmpty)
              _DetailRow(label: 'Updated', value: updated),
          ],
        ),
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

Color _transactionColor(MoneyTransactionKind kind) {
  switch (kind) {
    case MoneyTransactionKind.spend:
    case MoneyTransactionKind.transfer:
      return const Color(0xFFC62828);
    case MoneyTransactionKind.gain:
    case MoneyTransactionKind.refund:
      return const Color(0xFF2E7D32);
    case MoneyTransactionKind.other:
      return const Color(0xFF546E7A);
  }
}

IconData _transactionIcon(MoneyTransactionKind kind) {
  switch (kind) {
    case MoneyTransactionKind.spend:
      return Icons.arrow_upward_rounded;
    case MoneyTransactionKind.gain:
      return Icons.arrow_downward_rounded;
    case MoneyTransactionKind.transfer:
      return Icons.swap_horiz_rounded;
    case MoneyTransactionKind.refund:
      return Icons.undo_rounded;
    case MoneyTransactionKind.other:
      return Icons.receipt_long_outlined;
  }
}

String _detailText(dynamic value, String fallback) {
  if (value == null) {
    return fallback;
  }
  final text = '$value'.trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return fallback;
  }
  return text;
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.isSpend,
    required this.banks,
    required this.controller,
  });

  final bool isSpend;
  final List<Map<String, dynamic>> banks;
  final MoneyController controller;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  /// true = Bank, false = Credit Card (spend form only)
  bool _useBank = true;
  late bool _isSpend;
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  int? _bankId;
  int? _cardId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isSpend = widget.isSpend;
    if (widget.banks.length == 1) {
      _bankId = widget.banks.first['bankId'] as int?;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selectedBank {
    for (final bank in widget.controller.banks) {
      if (bank['bankId'] == _bankId) {
        return bank;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _debitCards =>
      widget.controller.debitCardsForBank(_bankId);

  Map<String, dynamic>? get _selectedCreditCard {
    for (final card in widget.controller.creditCards) {
      if (card['cardId'] == _cardId) {
        return card;
      }
    }
    return null;
  }

  double get _previousBalance {
    if (widget.isSpend && !_useBank) {
      final card = _selectedCreditCard;
      final limit = asMoneyDouble(card?['creditLimit']) ?? 0;
      final spent = asMoneyDouble(card?['spentAmount']) ?? 0;
      return limit - spent;
    }
    return asMoneyDouble(_selectedBank?['balance']) ?? 0;
  }

  double? get _amount => asMoneyDouble(_amountController.text);

  double? get _balanceAfter {
    final amount = _amount;
    if (amount == null) {
      return null;
    }
    if (widget.isSpend && !_useBank) {
      return _previousBalance - amount;
    }
    return _isSpend ? _previousBalance - amount : _previousBalance + amount;
  }

  void _onSourceChanged(bool useBank) {
    setState(() {
      _useBank = useBank;
      _bankId = null;
      _cardId = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final amount = _amount;
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }

    int? bankId;
    int? cardId;

    if (widget.isSpend) {
      if (_useBank) {
        if (_bankId == null) {
          setState(() => _error = 'Select a bank account');
          return;
        }
        bankId = _bankId;
        cardId = _cardId;
        if (amount > _previousBalance) {
          setState(() => _error = 'Amount is more than available bank balance');
          return;
        }
      } else {
        if (_cardId == null) {
          setState(() => _error = 'Select a credit card');
          return;
        }
        final linkedBankId = _selectedCreditCard?['bankId'];
        bankId = linkedBankId is int ? linkedBankId : null;
        cardId = _cardId;
        if (amount > _previousBalance) {
          setState(() => _error = 'Amount is more than available credit');
          return;
        }
      }
    } else {
      if (_bankId == null) {
        setState(() => _error = 'Select a bank account');
        return;
      }
      bankId = _bankId;
      cardId = _cardId;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.controller.submitSpendOrGain(
        bankId: bankId,
        cardId: cardId,
        isSpend: widget.isSpend ? true : _isSpend,
        amount: amount,
        purpose: _purposeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context, true);
    } on FinanceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final activeColor = widget.isSpend
        ? const Color(0xFFC62828)
        : const Color(0xFF2E7D32);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isSpend ? 'Record spend' : 'Record gain',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (widget.isSpend)
                ..._buildSpendFields(activeColor)
              else
                ..._buildGainFields(activeColor),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isSpend ? 'Save spend' : 'Save gain'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSpendFields(Color activeColor) {
    return [
      SegmentedButton<bool>(
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13)),
        ),
        segments: const [
          ButtonSegment(
            value: true,
            label: Text('Bank'),
            icon: Icon(Icons.account_balance_outlined, size: 16),
          ),
          ButtonSegment(
            value: false,
            label: Text('Credit card'),
            icon: Icon(Icons.credit_card, size: 16),
          ),
        ],
        selected: {_useBank},
        onSelectionChanged: (value) => _onSourceChanged(value.first),
      ),
      const SizedBox(height: 10),
      if (_useBank) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _bankId,
                isExpanded: true,
                decoration: _fieldDecoration('Bank account'),
                style: _fieldTextStyle,
                items: [
                  for (final bank in widget.controller.banks)
                    DropdownMenuItem(
                      value: bank['bankId'] as int?,
                      child: Text(
                        _bankOptionLabel(bank),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _bankId = value;
                    _cardId = null;
                    _error = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: _cardId,
                isExpanded: true,
                decoration: _fieldDecoration('Spend via'),
                style: _fieldTextStyle,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('UPI')),
                  for (final card in _debitCards)
                    DropdownMenuItem(
                      value: card['cardId'] as int?,
                      child: Text(
                        _cardOptionLabel(card),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _cardId = value),
              ),
            ),
          ],
        ),
      ] else ...[
        DropdownButtonFormField<int>(
          value: _cardId,
          decoration: _fieldDecoration('Credit card'),
          style: _fieldTextStyle,
          items: [
            for (final card in widget.controller.creditCards)
              DropdownMenuItem(
                value: card['cardId'] as int?,
                child: Text(
                  _creditCardOptionLabel(card),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _cardId = value;
              _error = null;
            });
          },
        ),
      ],
      const SizedBox(height: 10),
      ..._amountPurposeNotes(activeColor),
    ];
  }

  List<Widget> _buildGainFields(Color activeColor) {
    return [
      DropdownButtonFormField<int>(
        value: _bankId,
        isExpanded: true,
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Bank account'),
        items: [
          for (final bank in widget.banks)
            DropdownMenuItem(
              value: bank['bankId'] as int?,
              child: Text(
                _bankOptionLabel(bank),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          setState(() {
            _bankId = value;
            if (_cardId != null &&
                !_debitCards.any((card) => card['cardId'] == _cardId)) {
              _cardId = null;
            }
          });
        },
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Amount', hint: '0.00', prefix: '₹ '),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<int?>(
        value: _cardId,
        isExpanded: true,
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Card (optional)'),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('No card / Cash'),
          ),
          for (final card in _debitCards)
            DropdownMenuItem(
              value: card['cardId'] as int?,
              child: Text(
                _cardOptionLabel(card),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: _bankId == null
            ? null
            : (value) => setState(() => _cardId = value),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _purposeController,
        textCapitalization: TextCapitalization.sentences,
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Purpose', hint: 'Food, salary, rent...'),
      ),
      const SizedBox(height: 10),
      BalancePreview(
        previous: _bankId == null ? null : _previousBalance,
        next: _bankId == null ? null : _balanceAfter,
        color: activeColor,
      ),
    ];
  }

  List<Widget> _amountPurposeNotes(Color activeColor) {
    final hasSource = _useBank ? _bankId != null : _cardId != null;

    return [
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Amount', hint: '0.00', prefix: '₹ '),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _purposeController,
        textCapitalization: TextCapitalization.sentences,
        style: _fieldTextStyle,
        decoration: _fieldDecoration('Purpose', hint: 'Food, salary, rent...'),
      ),
      const SizedBox(height: 10),
      BalancePreview(
        previous: hasSource ? _previousBalance : null,
        next: hasSource ? _balanceAfter : null,
        color: activeColor,
      ),
    ];
  }

  TextStyle get _fieldTextStyle => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );

  InputDecoration _fieldDecoration(
    String label, {
    String? hint,
    String? prefix,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(10);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(fontSize: 13, color: scheme.primary),
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    );
  }

  String _bankOptionLabel(Map<String, dynamic> bank) {
    final name = '${bank['bankName'] ?? 'Bank'}';
    final last4 = bank['accountLast4'];
    final balance = asMoneyDouble(bank['balance']);
    final parts = <String>[name];
    if (last4 != null && '$last4'.isNotEmpty) {
      parts.add('****$last4');
    }
    if (balance != null) {
      parts.add(formatMoney(balance));
    }
    return parts.join(' · ');
  }

  String _cardOptionLabel(Map<String, dynamic> card) {
    final name = '${card['cardName'] ?? 'Card'}';
    final last4 = card['cardLast4'];
    if (last4 != null && '$last4'.isNotEmpty) {
      return '$name · ****$last4';
    }
    return name;
  }

  String _creditCardOptionLabel(Map<String, dynamic> card) {
    final name = _cardOptionLabel(card);
    final limit = asMoneyDouble(card['creditLimit']);
    final spent = asMoneyDouble(card['spentAmount']) ?? 0;
    if (limit == null) {
      return name;
    }
    final available = limit - spent;
    return '$name · ${formatMoney(available)} avail';
  }
}

class BalancePreview extends StatelessWidget {
  const BalancePreview({
    super.key,
    required this.previous,
    required this.next,
    required this.color,
  });

  final double? previous;
  final double? next;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previous == null ? '--' : formatMoney(previous!),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, size: 16, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'After',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  next == null ? '--' : formatMoney(next!),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
