import 'package:flutter/material.dart';
import 'package:uno_reverse/features/finance/finance_setup_page.dart';
import 'package:uno_reverse/features/money/money_controller.dart';
import 'package:uno_reverse/features/money/money_widgets.dart';

class MoneyPage extends StatefulWidget {
  const MoneyPage({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<MoneyPage> createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  late final MoneyController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MoneyController()..addListener(_onControllerChanged);
    if (widget.isActive) {
      _controller.load();
    }
  }

  @override
  void didUpdateWidget(MoneyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openTransactionForm({required bool isSpend}) async {
    if (isSpend) {
      if (_controller.banks.isEmpty && _controller.creditCards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a bank or credit card first in Finance Setup'),
          ),
        );
        return;
      }
    } else if (_controller.banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a bank account first in Finance Setup'),
        ),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionFormSheet(
        isSpend: isSpend,
        banks: _controller.banks,
        cards: _controller.cards,
        controller: _controller,
      ),
    );

    if (saved != true || !mounted) {
      return;
    }
  }

  void _openFinanceSetup() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FinanceSetupPage()))
        .then((_) => _controller.load(showFullPageLoader: false));
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_controller.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _controller.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.load(showFullPageLoader: false),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          BalanceHero(
            total: _controller.totalBalance,
            bankCount: _controller.banks.length,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: MoneyActionButton(
                  label: 'Spend',
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFC62828),
                  onTap: () => _openTransactionForm(isSpend: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MoneyActionButton(
                  label: 'Gain',
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF2E7D32),
                  onTap: () => _openTransactionForm(isSpend: false),
                ),
              ),
            ],
          ),
          if (_controller.banks.isEmpty) ...[
            const SizedBox(height: 16),
            EmptySetupCard(onSetup: _openFinanceSetup),
          ],
          const SizedBox(height: 28),
          Text(
            'Recent activity',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          if (_controller.transactions.isEmpty)
            const EmptyActivity()
          else
            ..._controller.transactions.map((tx) {
              final type = '${tx['transactionType'] ?? ''}'.toLowerCase();
              final isSpend = type == 'spend';
              final amount = asMoneyDouble(tx['amount']) ?? 0;
              final purpose = '${tx['purpose'] ?? ''}'.trim();
              final bankId = tx['bankId'] is int ? tx['bankId'] as int : null;
              final cardId = tx['cardId'] is int ? tx['cardId'] as int : null;
              final cardText = _controller.cardLabel(cardId);

              return TransactionTile(
                isSpend: isSpend,
                amount: amount,
                title: purpose.isEmpty
                    ? (isSpend ? 'Spent' : 'Received')
                    : purpose,
                subtitle: [
                  _controller.bankLabel(bankId),
                  if (cardText.isNotEmpty) cardText,
                ].join('  ·  '),
                balanceAfter: asMoneyDouble(tx['balanceAmount']),
                date: formatMoneyDate(tx['transactionDate'] ?? tx['createdAt']),
              );
            }),
        ],
      ),
    );
  }
}
