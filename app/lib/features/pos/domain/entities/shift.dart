import 'package:equatable/equatable.dart';

class Shift extends Equatable {
  final String id;
  final String shopId;
  final String? cashierId;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double startCash;
  final double expectedCash;
  final double? actualCash;
  final double totalSalesCash;
  final double totalSalesCard;
  final double totalSalesOther;
  final int salesCount;

  const Shift({
    required this.id,
    required this.shopId,
    this.cashierId,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.startCash,
    required this.expectedCash,
    this.actualCash,
    this.totalSalesCash = 0.0,
    this.totalSalesCard = 0.0,
    this.totalSalesOther = 0.0,
    this.salesCount = 0,
  });

  bool get isOpen => closedAt == null;
  double get totalRevenue => totalSalesCash + totalSalesCard + totalSalesOther;
  double? get cashDifference => actualCash != null ? actualCash! - expectedCash : null;

  Shift copyWith({
    String? id,
    String? shopId,
    String? cashierId,
    String? cashierName,
    DateTime? openedAt,
    DateTime? closedAt,
    double? startCash,
    double? expectedCash,
    double? actualCash,
    double? totalSalesCash,
    double? totalSalesCard,
    double? totalSalesOther,
    int? salesCount,
  }) {
    return Shift(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      startCash: startCash ?? this.startCash,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      totalSalesCash: totalSalesCash ?? this.totalSalesCash,
      totalSalesCard: totalSalesCard ?? this.totalSalesCard,
      totalSalesOther: totalSalesOther ?? this.totalSalesOther,
      salesCount: salesCount ?? this.salesCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        shopId,
        cashierId,
        cashierName,
        openedAt,
        closedAt,
        startCash,
        expectedCash,
        actualCash,
        totalSalesCash,
        totalSalesCard,
        totalSalesOther,
        salesCount,
      ];
}
