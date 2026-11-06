import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';

class CheckoutModal extends StatefulWidget {
  final double totalAmount;

  const CheckoutModal({super.key, required this.totalAmount});

  static Future<String?> show(BuildContext context, {required double totalAmount}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CheckoutModal(totalAmount: totalAmount),
    );
  }

  @override
  State<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  String _selectedPaymentType = 'cash'; // 'cash', 'card', 'transfer'
  final TextEditingController _receivedCashController = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,##0', 'ru_RU');

  @override
  void initState() {
    super.initState();
    _receivedCashController.text = widget.totalAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _receivedCashController.dispose();
    super.dispose();
  }

  double get _receivedCash => double.tryParse(_receivedCashController.text.replaceAll(' ', '')) ?? 0.0;
  double get _change => _receivedCash >= widget.totalAmount ? _receivedCash - widget.totalAmount : 0.0;

  List<double> _getQuickSuggestions() {
    final t = widget.totalAmount;
    final suggestions = <double>{t};

    // Common rounded bill suggestions
    final roundingSteps = [10000, 20000, 50000, 100000, 200000, 500000];
    for (final step in roundingSteps) {
      if (t < step) {
        suggestions.add(step.toDouble());
      } else {
        final ceil = ((t / step).ceil()) * step;
        if (ceil > t) suggestions.add(ceil.toDouble());
      }
    }

    final list = suggestions.toList()..sort();
    return list.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Оплата заказа',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'К оплате:',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${_fmt.format(widget.totalAmount)} ${AppConstants.currency}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Payment method selector
            Text(
              'Выберите способ оплаты:',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildMethodCard(
                  id: 'cash',
                  label: 'Наличные',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(width: 8),
                _buildMethodCard(
                  id: 'card',
                  label: 'Карта',
                  icon: Icons.credit_card,
                ),
                const SizedBox(width: 8),
                _buildMethodCard(
                  id: 'transfer',
                  label: 'Payme / Click',
                  icon: Icons.qr_code_2,
                ),
              ],
            ),

            // Cash calculator section
            if (_selectedPaymentType == 'cash') ...[
              const SizedBox(height: 18),
              TextField(
                controller: _receivedCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Получено от клиента',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: AppConstants.currency,
                ),
              ),
              const SizedBox(height: 10),

              // Quick bill suggestions
              Wrap(
                spacing: 8,
                children: _getQuickSuggestions().map((amt) {
                  return ActionChip(
                    label: Text('${_fmt.format(amt)} ${AppConstants.currency}'),
                    onPressed: () {
                      setState(() {
                        _receivedCashController.text = amt.toStringAsFixed(0);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Change output (Сдача)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _receivedCash >= widget.totalAmount
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _receivedCash >= widget.totalAmount
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFECACA),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Сдача клиенту:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _receivedCash >= widget.totalAmount
                            ? const Color(0xFF166534)
                            : Colors.red.shade900,
                      ),
                    ),
                    Text(
                      '${_fmt.format(_change)} ${AppConstants.currency}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: _receivedCash >= widget.totalAmount
                            ? const Color(0xFF166534)
                            : Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_selectedPaymentType == 'cash' && _receivedCash < widget.totalAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Внесенной суммы недостаточно для оплаты')),
                  );
                  return;
                }
                Navigator.of(context).pop(_selectedPaymentType);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Подтвердить и пробить чек', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String id,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentType == id;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedPaymentType = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F766E).withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFCBD5E1),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade700,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0F766E) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
