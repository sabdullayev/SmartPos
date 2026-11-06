import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/sale.dart';

class ReceiptDialog extends StatelessWidget {
  final Sale sale;
  final String shopName;
  final String cashierName;

  const ReceiptDialog({
    super.key,
    required this.sale,
    this.shopName = AppConstants.defaultShopName,
    this.cashierName = AppConstants.defaultCashierName,
  });

  static Future<void> show(
    BuildContext context, {
    required Sale sale,
    String shopName = AppConstants.defaultShopName,
    String cashierName = AppConstants.defaultCashierName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ReceiptDialog(
        sale: sale,
        shopName: shopName,
        cashierName: cashierName,
      ),
    );
  }

  String _generateTextReceipt() {
    final fmt = NumberFormat('#,##0', 'ru_RU');
    final dateStr = DateFormat('dd.MM.yyyy HH:mm:ss').format(sale.createdAt);

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('        $shopName');
    buffer.writeln('================================');
    buffer.writeln('Чек №: ${sale.id.substring(0, 8).toUpperCase()}');
    buffer.writeln('Дата: $dateStr');
    buffer.writeln('Кассир: $cashierName');
    buffer.writeln('--------------------------------');

    for (final item in sale.items) {
      final total = item.qty * item.sellPrice;
      buffer.writeln(item.productName);
      buffer.writeln('  ${item.qty} x ${fmt.format(item.sellPrice)} = ${fmt.format(total)} ${AppConstants.currency}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('ИТОГО К ОПЛАТЕ: ${fmt.format(sale.totalAmount)} ${AppConstants.currency}');
    buffer.writeln('Оплата: ${sale.paymentTypeName}');
    buffer.writeln('================================');
    buffer.writeln('Спасибо за покупку!');
    buffer.writeln('🚀 Чек сформирован в SmartPOS');
    buffer.writeln('Касса для вашего бизнеса: @SmartPosBot');
    buffer.writeln('================================');

    return buffer.toString();
  }

  void _shareReceipt() {
    final text = _generateTextReceipt();
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Электронный чек $shopName',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'ru_RU');
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success badge
              Center(
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 30),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Оплата принята!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Paper Receipt Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      shopName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Чек № ${sale.id.substring(0, 8).toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    Text(
                      dateStr,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 20),

                    // Items list
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: sale.items.length,
                        itemBuilder: (ctx, idx) {
                          final item = sale.items[idx];
                          final total = item.qty * item.sellPrice;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${item.qty.toStringAsFixed(0)} x ${fmt.format(item.sellPrice)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${fmt.format(total)} ${AppConstants.currency}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ИТОГО:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${fmt.format(sale.totalAmount)} ${AppConstants.currency}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Способ оплаты:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Text(sale.paymentTypeName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),

                    const SizedBox(height: 14),
                    // Viral Marketing Footer
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, size: 14, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text(
                                'Работает на SmartPOS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Создай свою кассу за 1 мин: @SmartPosBot',
                            style: TextStyle(fontSize: 10, color: Colors.green.shade800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareReceipt,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Чек (Share)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Готово'),
                    ),
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
