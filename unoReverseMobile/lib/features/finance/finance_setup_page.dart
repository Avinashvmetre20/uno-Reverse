import 'package:flutter/material.dart';
import 'package:uno_reverse/core/api/finance_api.dart';

const _accountTypes = ['Savings', 'Current', 'Salary', 'NRI', 'Other'];
const _cardTypes = ['Credit Card', 'Debit Card', 'Prepaid Card', 'Other'];

String? _matchOption(String? value, List<String> options) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final trimmed = value.trim();
  for (final option in options) {
    if (option.toLowerCase() == trimmed.toLowerCase()) {
      return option;
    }
  }
  return 'Other';
}

class FinanceSetupPage extends StatefulWidget {
  const FinanceSetupPage({super.key});

  @override
  State<FinanceSetupPage> createState() => _FinanceSetupPageState();
}

class _FinanceSetupPageState extends State<FinanceSetupPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _cards = [];

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
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _banks = results[0];
        _cards = results[1];
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

  String _bankName(int? bankId) {
    if (bankId == null) {
      return 'Not linked';
    }
    for (final bank in _banks) {
      if (bank['bankId'] == bankId) {
        return '${bank['bankName'] ?? 'Bank'}';
      }
    }
    return 'Bank #$bankId';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openBankForm({Map<String, dynamic>? bank}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BankFormSheet(bank: bank),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _openCardForm({Map<String, dynamic>? card}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CardFormSheet(card: card, banks: _banks),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _deleteBank(Map<String, dynamic> bank) async {
    final bankId = bank['bankId'];
    if (bankId is! int) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete bank'),
        content: Text('Delete ${bank['bankName'] ?? 'this bank'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FinanceApi.deleteBank(bankId);
      await _load();
    } on FinanceException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _deleteCard(Map<String, dynamic> card) async {
    final cardId = card['cardId'];
    if (cardId is! int) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete card'),
        content: Text('Delete ${card['cardName'] ?? 'this card'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FinanceApi.deleteCard(cardId);
      await _load();
    } on FinanceException catch (error) {
      _showMessage(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance Setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _SectionHeader(
                        title: 'Banks',
                        onAdd: () => _openBankForm(),
                      ),
                      if (_banks.isEmpty)
                        const _EmptyBox(text: 'No bank accounts yet')
                      else
                        ..._banks.map(
                          (bank) => _FinanceTile(
                            title: '${bank['bankName'] ?? ''}',
                            subtitle: [
                              if (bank['accountType'] != null)
                                '${bank['accountType']}',
                              if (bank['accountLast4'] != null)
                                '****${bank['accountLast4']}',
                              if (bank['balance'] != null)
                                'Bal: ${bank['balance']}',
                            ].where((part) => part.isNotEmpty).join('  ·  '),
                            onEdit: () => _openBankForm(bank: bank),
                            onDelete: () => _deleteBank(bank),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        title: 'Cards',
                        onAdd: () => _openCardForm(),
                      ),
                      if (_cards.isEmpty)
                        const _EmptyBox(text: 'No cards yet')
                      else
                        ..._cards.map(
                          (card) => _FinanceTile(
                            title: '${card['cardName'] ?? ''}',
                            subtitle: [
                              if (card['cardType'] != null) '${card['cardType']}',
                              if (card['cardLast4'] != null)
                                '****${card['cardLast4']}',
                              _bankName(
                                card['bankId'] is int ? card['bankId'] as int : null,
                              ),
                            ].where((part) => part.isNotEmpty).join('  ·  '),
                            onEdit: () => _openCardForm(card: card),
                            onDelete: () => _deleteCard(card),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _BankFormSheet extends StatefulWidget {
  const _BankFormSheet({this.bank});

  final Map<String, dynamic>? bank;

  @override
  State<_BankFormSheet> createState() => _BankFormSheetState();
}

class _BankFormSheetState extends State<_BankFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _otherType;
  late final TextEditingController _last4;
  late final TextEditingController _balance;
  String? _accountType;
  bool _saving = false;

  bool get _isEdit => widget.bank != null;

  @override
  void initState() {
    super.initState();
    final bank = widget.bank;
    final existingType = '${bank?['accountType'] ?? ''}';
    _accountType = _matchOption(existingType, _accountTypes);
    _name = TextEditingController(text: '${bank?['bankName'] ?? ''}');
    _otherType = TextEditingController(
      text: _accountType == 'Other' ? existingType : '',
    );
    _last4 = TextEditingController(text: '${bank?['accountLast4'] ?? ''}');
    _balance = TextEditingController(
      text: bank?['balance'] == null ? '' : '${bank?['balance']}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _otherType.dispose();
    _last4.dispose();
    _balance.dispose();
    super.dispose();
  }

  String? _resolvedAccountType() {
    if (_accountType == null) {
      return null;
    }
    if (_accountType == 'Other') {
      final other = _otherType.text.trim();
      return other.isEmpty ? 'Other' : other;
    }
    return _accountType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'bankName': _name.text.trim(),
      'accountType': _resolvedAccountType(),
      'accountLast4': _last4.text.trim().isEmpty ? null : _last4.text.trim(),
      'balance':
          _balance.text.trim().isEmpty ? null : num.tryParse(_balance.text.trim()),
    };

    try {
      if (_isEdit) {
        await FinanceApi.updateBank(widget.bank!['bankId'] as int, payload);
      } else {
        await FinanceApi.createBank(payload);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on FinanceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? 'Edit bank' : 'Add bank',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Bank name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Bank name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account type',
                  border: OutlineInputBorder(),
                ),
                items: _accountTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _accountType = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select account type';
                  }
                  return null;
                },
              ),
              if (_accountType == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherType,
                  decoration: const InputDecoration(
                    labelText: 'Other account type',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_accountType == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Enter account type';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _last4,
                decoration: const InputDecoration(
                  labelText: 'Account last 4',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _balance,
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFormSheet extends StatefulWidget {
  const _CardFormSheet({this.card, required this.banks});

  final Map<String, dynamic>? card;
  final List<Map<String, dynamic>> banks;

  @override
  State<_CardFormSheet> createState() => _CardFormSheetState();
}

class _CardFormSheetState extends State<_CardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _otherType;
  late final TextEditingController _last4;
  String? _cardType;
  int? _bankId;
  bool _saving = false;

  bool get _isEdit => widget.card != null;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    final existingType = '${card?['cardType'] ?? ''}';
    _cardType = _matchOption(existingType, _cardTypes);
    _name = TextEditingController(text: '${card?['cardName'] ?? ''}');
    _otherType = TextEditingController(
      text: _cardType == 'Other' ? existingType : '',
    );
    _last4 = TextEditingController(text: '${card?['cardLast4'] ?? ''}');
    _bankId = card?['bankId'] is int ? card!['bankId'] as int : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _otherType.dispose();
    _last4.dispose();
    super.dispose();
  }

  String? _resolvedCardType() {
    if (_cardType == null) {
      return null;
    }
    if (_cardType == 'Other') {
      final other = _otherType.text.trim();
      return other.isEmpty ? 'Other' : other;
    }
    return _cardType;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'cardName': _name.text.trim(),
      'cardType': _resolvedCardType(),
      'cardLast4': _last4.text.trim().isEmpty ? null : _last4.text.trim(),
      'bankId': _bankId,
    };

    try {
      if (_isEdit) {
        await FinanceApi.updateCard(widget.card!['cardId'] as int, payload);
      } else {
        await FinanceApi.createCard(payload);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } on FinanceException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEdit ? 'Edit card' : 'Add card',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Card name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Card name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _cardType,
                decoration: const InputDecoration(
                  labelText: 'Card type',
                  border: OutlineInputBorder(),
                ),
                items: _cardTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _cardType = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Select card type';
                  }
                  return null;
                },
              ),
              if (_cardType == 'Other') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherType,
                  decoration: const InputDecoration(
                    labelText: 'Other card type',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_cardType == 'Other' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Enter card type';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _last4,
                decoration: const InputDecoration(
                  labelText: 'Card last 4',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _bankId,
                decoration: const InputDecoration(
                  labelText: 'Linked bank',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Not linked'),
                  ),
                  ...widget.banks.map(
                    (bank) => DropdownMenuItem<int?>(
                      value: bank['bankId'] as int?,
                      child: Text('${bank['bankName']}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _bankId = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

