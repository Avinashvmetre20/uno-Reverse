import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/api/finance_api.dart';
import 'package:uno_reverse/features/money/money_controller.dart';

class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.total, required this.bankCount});

  final double total;
  final int bankCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatMoney(total),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bankCount == 0
                ? 'No banks linked yet'
                : '$bankCount bank account${bankCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(
        'No transactions yet.\nTap Spend or Gain to add one.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.isSpend,
    required this.amount,
    required this.title,
    required this.subtitle,
    required this.balanceAfter,
    required this.date,
  });

  final bool isSpend;
  final double amount;
  final String title;
  final String subtitle;
  final double? balanceAfter;
  final String date;

  @override
  Widget build(BuildContext context) {
    final color = isSpend ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isSpend ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: color,
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            subtitle,
            if (balanceAfter != null) 'Bal ${formatMoney(balanceAfter!)}',
            if (date.isNotEmpty) date,
          ].where((part) => part.isNotEmpty).join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${isSpend ? '-' : '+'}${formatMoney(amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.isSpend,
    required this.banks,
    required this.cards,
    required this.controller,
  });

  final bool isSpend;
  final List<Map<String, dynamic>> banks;
  final List<Map<String, dynamic>> cards;
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
  final _notesController = TextEditingController();
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
    _notesController.dispose();
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

  List<Map<String, dynamic>> get _availableCards {
    return widget.cards.where((card) {
      final linkedBankId = card['bankId'];
      if (linkedBankId == null) {
        return true;
      }
      return linkedBankId == _bankId;
    }).toList();
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
        final creditCard = _selectedCreditCard;
        final linkedBankId = creditCard?['bankId'];
        if (linkedBankId is! int) {
          setState(() => _error = 'Selected credit card is not linked to a bank');
          return;
        }
        bankId = linkedBankId;
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
        bankId: bankId!,
        cardId: cardId,
        isSpend: widget.isSpend ? true : _isSpend,
        amount: amount,
        purpose: _purposeController.text.trim(),
        notes: _notesController.text.trim(),
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
    final activeColor =
        widget.isSpend ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.isSpend ? 'Record spend' : 'Record gain',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              if (widget.isSpend) ..._buildSpendFields(activeColor)
              else ..._buildGainFields(activeColor),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: activeColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
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
        segments: const [
          ButtonSegment(
            value: true,
            label: Text('Bank'),
            icon: Icon(Icons.account_balance_outlined),
          ),
          ButtonSegment(
            value: false,
            label: Text('Credit card'),
            icon: Icon(Icons.credit_card),
          ),
        ],
        selected: {_useBank},
        onSelectionChanged: (value) => _onSourceChanged(value.first),
      ),
      const SizedBox(height: 16),
      if (_useBank) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _bankId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bank account',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Spend via',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Cash'),
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
                onChanged: (value) => setState(() => _cardId = value),
              ),
            ),
          ],
        ),
      ] else ...[
        DropdownButtonFormField<int>(
          value: _cardId,
          decoration: const InputDecoration(
            labelText: 'Credit card',
            border: OutlineInputBorder(),
          ),
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
      const SizedBox(height: 16),
      ..._amountPurposeNotes(activeColor),
    ];
  }

  List<Widget> _buildGainFields(Color activeColor) {
    return [
      Text(
        'Amount',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixText: '₹ ',
          hintText: '0.00',
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int>(
        value: _bankId,
        decoration: const InputDecoration(
          labelText: 'Bank account',
          border: OutlineInputBorder(),
        ),
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
                !_availableCards.any((card) => card['cardId'] == _cardId)) {
              _cardId = null;
            }
          });
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        value: _cardId,
        decoration: const InputDecoration(
          labelText: 'Card (optional)',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<int?>(
            value: null,
            child: Text('No card / Cash'),
          ),
          for (final card in _availableCards)
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
      const SizedBox(height: 12),
      TextField(
        controller: _purposeController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Purpose',
          hintText: 'Food, salary, rent...',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _notesController,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      if (_bankId != null) ...[
        const SizedBox(height: 16),
        BalancePreview(
          previous: _previousBalance,
          next: _balanceAfter,
          color: activeColor,
        ),
      ],
    ];
  }

  List<Widget> _amountPurposeNotes(Color activeColor) {
    final showPreview = _useBank ? _bankId != null : _cardId != null;

    return [
      Text(
        'Amount',
        style: Theme.of(context).textTheme.labelLarge,
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _amountController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixText: '₹ ',
          hintText: '0.00',
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _purposeController,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Purpose',
          hintText: 'Food, salary, rent...',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _notesController,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Notes (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      if (showPreview) ...[
        const SizedBox(height: 16),
        BalancePreview(
          previous: _previousBalance,
          next: _balanceAfter,
          color: activeColor,
        ),
      ],
    ];
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

  final double previous;
  final double? next;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Before', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  formatMoney(previous),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('After', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  next == null ? '--' : formatMoney(next!),
                  style: TextStyle(
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
