import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uno_reverse/core/api/finance_api.dart';
import 'package:uno_reverse/features/finance/finance_setup_page.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key});

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        FinanceApi.listBanks(),
        FinanceApi.listCards(),
        FinanceApi.listTransactions(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _banks = results[0];
        _cards = results[1];
        _transactions = results[2];
        _loading = false;
      });
    } on FinanceException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  double get _totalBalance {
    var total = 0.0;
    for (final bank in _banks) {
      total += _asDouble(bank['balance']) ?? 0;
    }
    return total;
  }

  String _bankLabel(int? bankId) {
    if (bankId == null) {
      return 'Unknown bank';
    }
    for (final bank in _banks) {
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

  String _cardLabel(int? cardId) {
    if (cardId == null) {
      return '';
    }
    for (final card in _cards) {
      if (card['cardId'] == cardId) {
        final name = '${card['cardName'] ?? 'Card'}';
        final last4 = card['cardLast4'];
        if (last4 != null && '$last4'.isNotEmpty) {
          return '$name · ****$last4';
        }
        return name;
      }
    }
    return 'Card #$cardId';
  }

  Future<void> _openTransactionForm({required bool isSpend}) async {
    if (_banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a bank account first in Finance Setup')),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TransactionFormSheet(
        isSpend: isSpend,
        banks: _banks,
        cards: _cards,
      ),
    );

    if (saved == true) {
      await _load();
    }
  }

  void _openFinanceSetup() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FinanceSetupPage()))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _BalanceHero(total: _totalBalance, bankCount: _banks.length),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Spend',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFC62828),
                  onTap: () => _openTransactionForm(isSpend: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Gain',
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF2E7D32),
                  onTap: () => _openTransactionForm(isSpend: false),
                ),
              ),
            ],
          ),
          if (_banks.isEmpty) ...[
            const SizedBox(height: 16),
            _EmptySetupCard(onSetup: _openFinanceSetup),
          ],
          const SizedBox(height: 28),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          if (_transactions.isEmpty)
            const _EmptyActivity()
          else
            ..._transactions.map((tx) {
              final type = '${tx['transactionType'] ?? ''}'.toLowerCase();
              final isSpend = type == 'spend';
              final amount = _asDouble(tx['amount']) ?? 0;
              final purpose = '${tx['purpose'] ?? ''}'.trim();
              final bankId = tx['bankId'] is int ? tx['bankId'] as int : null;
              final cardId = tx['cardId'] is int ? tx['cardId'] as int : null;
              final cardText = _cardLabel(cardId);

              return _TransactionTile(
                isSpend: isSpend,
                amount: amount,
                title: purpose.isEmpty
                    ? (isSpend ? 'Spent' : 'Received')
                    : purpose,
                subtitle: [
                  _bankLabel(bankId),
                  if (cardText.isNotEmpty) cardText,
                ].join('  ·  '),
                balanceAfter: _asDouble(tx['balanceAmount']),
                date: _formatDate(tx['transactionDate'] ?? tx['createdAt']),
              );
            }),
        ],
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.total, required this.bankCount});

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
            _money(total),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

class _EmptySetupCard extends StatelessWidget {
  const _EmptySetupCard({required this.onSetup});

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

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

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

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
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
            if (balanceAfter != null) 'Bal ${_money(balanceAfter!)}',
            if (date.isNotEmpty) date,
          ].where((part) => part.isNotEmpty).join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${isSpend ? '-' : '+'}${_money(amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TransactionFormSheet extends StatefulWidget {
  const _TransactionFormSheet({
    required this.isSpend,
    required this.banks,
    required this.cards,
  });

  final bool isSpend;
  final List<Map<String, dynamic>> banks;
  final List<Map<String, dynamic>> cards;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
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
    for (final bank in widget.banks) {
      if (bank['bankId'] == _bankId) {
        return bank;
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

  double get _previousBalance =>
      _asDouble(_selectedBank?['balance']) ?? 0;

  double? get _amount => _asDouble(_amountController.text);

  double? get _balanceAfter {
    final amount = _amount;
    if (amount == null) {
      return null;
    }
    return _isSpend ? _previousBalance - amount : _previousBalance + amount;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final amount = _amount;
    if (_bankId == null) {
      setState(() => _error = 'Select a bank account');
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    if (_isSpend && amount > _previousBalance) {
      setState(() => _error = 'Amount is more than available bank balance');
      return;
    }

    final balanceAfter = _balanceAfter!;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await FinanceApi.createTransaction({
        'bankId': _bankId,
        if (_cardId != null) 'cardId': _cardId,
        'transactionType': _isSpend ? 'spend' : 'gain',
        'amount': amount,
        'previousBalance': _previousBalance,
        'balanceAmount': balanceAfter,
        if (_purposeController.text.trim().isNotEmpty)
          'purpose': _purposeController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });

      await FinanceApi.updateBank(_bankId!, {
        'balance': balanceAfter,
      });

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
    final spendColor = const Color(0xFFC62828);
    final gainColor = const Color(0xFF2E7D32);
    final activeColor = _isSpend ? spendColor : gainColor;

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
                _isSpend ? 'Record spend' : 'Record gain',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Spend'),
                    icon: Icon(Icons.arrow_upward_rounded),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Gain'),
                    icon: Icon(Icons.arrow_downward_rounded),
                  ),
                ],
                selected: {_isSpend},
                onSelectionChanged: (value) {
                  setState(() => _isSpend = value.first);
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Amount',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  hintText: '0.00',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                _BalancePreview(
                  previous: _previousBalance,
                  next: _balanceAfter,
                  color: activeColor,
                ),
              ],
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
                    : Text(_isSpend ? 'Save spend' : 'Save gain'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bankOptionLabel(Map<String, dynamic> bank) {
    final name = '${bank['bankName'] ?? 'Bank'}';
    final last4 = bank['accountLast4'];
    final balance = _asDouble(bank['balance']);
    final parts = <String>[name];
    if (last4 != null && '$last4'.isNotEmpty) {
      parts.add('****$last4');
    }
    if (balance != null) {
      parts.add(_money(balance));
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
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({
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
                  _money(previous),
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
                  next == null ? '--' : _money(next!),
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

double? _asDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value'.trim());
}

String _money(double value) {
  final fixed = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  return '₹$fixed';
}

String _formatDate(dynamic value) {
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
