import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String shopId;
  final String name;
  final String? barcode;
  final double costPrice;
  final double sellPrice;
  final double stockQty;
  final double minQty;
  final bool isDeleted;
  final DateTime updatedAt;
  final String? imagePath; // Local path or network URL

  const Product({
    required this.id,
    required this.shopId,
    required this.name,
    this.barcode,
    required this.costPrice,
    required this.sellPrice,
    required this.stockQty,
    this.minQty = 5.0,
    this.isDeleted = false,
    required this.updatedAt,
    this.imagePath,
  });

  bool get isLowStock => stockQty <= minQty;
  double get profitMargin => sellPrice - costPrice;
  double get profitPercentage => costPrice > 0 ? ((sellPrice - costPrice) / costPrice) * 100 : 0.0;

  Product copyWith({
    String? id,
    String? shopId,
    String? name,
    String? barcode,
    double? costPrice,
    double? sellPrice,
    double? stockQty,
    double? minQty,
    bool? isDeleted,
    DateTime? updatedAt,
    String? Function()? imagePath,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stockQty: stockQty ?? this.stockQty,
      minQty: minQty ?? this.minQty,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      imagePath: imagePath != null ? imagePath() : this.imagePath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shopId,
        name,
        barcode,
        costPrice,
        sellPrice,
        stockQty,
        minQty,
        isDeleted,
        updatedAt,
        imagePath,
      ];
}
