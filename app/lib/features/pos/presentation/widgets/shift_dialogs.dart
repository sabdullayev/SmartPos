import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/shift.dart';

class OpenShiftDialog extends StatefulWidget {
  final String defaultCashier;

  const OpenShiftDialog({super.key, this.defaultCashier = AppConstants.defaultCashierName});

  static Future<Map<String, dynamic>?> show(BuildContext context, {String defaultCashier = AppConstants.defaultCashierName}) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OpenShiftDialog(defaultCashier: defaultCashier),
    );
  }

  @override
  State<OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<OpenShiftDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cashierController = TextEditingController();
  final _startCashController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _cashierController.text = widget.defaultCashier;
  }

  @override
  void dispose() {
    _cashierController.dispose();
    _startCashController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final startCash = double.tryParse(_startCashController.text.trim()) ?? 0.0;
    Navigator.of(context).pop({
      'cashierName': _cashierController.text.trim(),
      'startCash': startCash,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.storefront_outlined, color: Color(0xFF0F766E)),
          SizedBox(width: 8),
          Text('Открытие кассовой смены'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Перед началом работы укажите имя кассира и сумму разменных денег в кассе (стартовая касса).',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cashierController,
                decoration: const InputDecoration(
                  labelText: 'Имя кассира *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Укажите имя';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Разменная касса (наличные на старте)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  suffixText: AppConstants.currency,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Введите сумму';
                  if (double.tryParse(val.trim()) == null) return 'Неверное число';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Открыть смену'),
        ),
      ],
    );
  }
}

class CloseShiftDialog extends StatefulWidget {
  final Shift shift;

  const CloseShiftDialog({super.key, required this.shift});

  static Future<double?> show(BuildContext context, {required Shift shift}) {
    return showDialog<double>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CloseShiftDialog(shift: shift),
    );
  }

  @override
  State<CloseShiftDialog> createState() => _CloseShiftDialogState();
}

class _CloseShiftDialogState extends State<CloseShiftDialog> {
  final _actualCashController = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,##0', 'ru_RU');

  @override
  void initState() {
    super.initState();
    _actualCashController.text = widget.shift.expectedCash.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('Закрытие смены (Z-отчет)'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Кассир: ${shift.cashierName}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Открыта: ${DateFormat('dd.MM.yyyy HH:mm').format(shift.openedAt)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const Divider(height: 24),
              _buildRow('Начальный остаток:', '${_fmt.format(shift.startCash)} ${AppConstants.currency}'),
              _buildRow('Чеков пробито:', '${shift.salesCount} шт'),
              _buildRow('Выручка наличными:', '${_fmt.format(shift.totalSalesCash)} ${AppConstants.currency}'),
              _buildRow('Выручка картой:', '${_fmt.format(shift.totalSalesCard)} ${AppConstants.currency}'),
              if (shift.totalSalesOther > 0)
                _buildRow('Переводы / QR:', '${_fmt.format(shift.totalSalesOther)} ${AppConstants.currency}'),
              const Divider(height: 20),
              _buildRow(
                'Ожидаемая сумма в кассе:',
                '${_fmt.format(shift.expectedCash)} ${AppConstants.currency}',
                isBold: true,
                color: const Color(0xFF0F766E),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _actualCashController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Фактическая сумма наличных в кассе *',
                  hintText: 'Посчитайте купюры',
                  prefixIcon: Icon(Icons.point_of_sale),
                  suffixText: AppConstants.currency,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () {
            final actual = double.tryParse(_actualCashController.text.trim()) ?? shift.expectedCash;
            Navigator.of(context).pop(actual);
          },
          child: const Text('Закрыть смену'),
        ),
      ],
    );
  }

  Widget _buildRow(String title, String val, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
