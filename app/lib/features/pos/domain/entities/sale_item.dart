import 'package:equatable/equatable.dart';

class SaleItem extends Equatable {
  final String id;
  final String saleId;
  final String? productId;
  final String productName;
  final double qty;
  final double costPrice;
  final double sellPrice;

  const SaleItem({
    required this.id,
    required this.saleId,
    this.productId,
    required this.productName,
    required this.qty,
    required this.costPrice,
    required this.sellPrice,
  });

  double get totalAmount => qty * sellPrice;
  double get totalProfit => (sellPrice - costPrice) * qty;

  SaleItem copyWith({
    String? id,
    String? saleId,
    String? productId,
    String? productName,
    double? qty,
    double? costPrice,
    double? sellPrice,
  }) {
    return SaleItem(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      qty: qty ?? this.qty,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
    );
  }

  @override
  List<Object?> get props => [
        id,
        saleId,
        productId,
        productName,
        qty,
        costPrice,
        sellPrice,
      ];
}
