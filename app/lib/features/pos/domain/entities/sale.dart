import 'package:equatable/equatable.dart';
import 'sale_item.dart';

class Sale extends Equatable {
  final String id;
  final String shopId;
  final String? shiftId;
  final String? cashierId;
  final double totalAmount;
  final double totalProfit;
  final String paymentType; // 'cash', 'card', 'transfer'
  final DateTime createdAt;
  final List<SaleItem> items;

  const Sale({
    required this.id,
    required this.shopId,
    this.shiftId,
    this.cashierId,
    required this.totalAmount,
    required this.totalProfit,
    required this.paymentType,
    required this.createdAt,
    this.items = const [],
  });

  String get paymentTypeName {
    switch (paymentType) {
      case 'card':
        return 'Карта';
      case 'transfer':
        return 'Перевод / QR';
      case 'cash':
      default:
        return 'Наличные';
    }
  }

  Sale copyWith({
    String? id,
    String? shopId,
    String? shiftId,
    String? cashierId,
    double? totalAmount,
    double? totalProfit,
    String? paymentType,
    DateTime? createdAt,
    List<SaleItem>? items,
  }) {
    return Sale(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shiftId: shiftId ?? this.shiftId,
      cashierId: cashierId ?? this.cashierId,
      totalAmount: totalAmount ?? this.totalAmount,
      totalProfit: totalProfit ?? this.totalProfit,
      paymentType: paymentType ?? this.paymentType,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shopId,
        shiftId,
        cashierId,
        totalAmount,
        totalProfit,
        paymentType,
        createdAt,
        items,
      ];
}
