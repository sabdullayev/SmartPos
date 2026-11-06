import 'package:hive_ce/hive.dart';
import '../../domain/entities/shift.dart';

class ShiftModel extends Shift {
  const ShiftModel({
    required super.id,
    required super.shopId,
    super.cashierId,
    required super.cashierName,
    required super.openedAt,
    super.closedAt,
    required super.startCash,
    required super.expectedCash,
    super.actualCash,
    super.totalSalesCash = 0.0,
    super.totalSalesCard = 0.0,
    super.totalSalesOther = 0.0,
    super.salesCount = 0,
  });

  factory ShiftModel.fromEntity(Shift shift) {
    return ShiftModel(
      id: shift.id,
      shopId: shift.shopId,
      cashierId: shift.cashierId,
      cashierName: shift.cashierName,
      openedAt: shift.openedAt,
      closedAt: shift.closedAt,
      startCash: shift.startCash,
      expectedCash: shift.expectedCash,
      actualCash: shift.actualCash,
      totalSalesCash: shift.totalSalesCash,
      totalSalesCard: shift.totalSalesCard,
      totalSalesOther: shift.totalSalesOther,
      salesCount: shift.salesCount,
    );
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      cashierId: json['cashier_id'] as String?,
      cashierName: json['cashier_name'] as String? ?? 'Кассир',
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
      startCash: (json['start_cash'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (json['actual_cash'] as num?)?.toDouble(),
      totalSalesCash: (json['total_sales_cash'] as num?)?.toDouble() ?? 0.0,
      totalSalesCard: (json['total_sales_card'] as num?)?.toDouble() ?? 0.0,
      totalSalesOther: (json['total_sales_other'] as num?)?.toDouble() ?? 0.0,
      salesCount: (json['sales_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'start_cash': startCash,
      'expected_cash': expectedCash,
      'actual_cash': actualCash,
      'total_sales_cash': totalSalesCash,
      'total_sales_card': totalSalesCard,
      'total_sales_other': totalSalesOther,
      'sales_count': salesCount,
    };
  }

  @override
  ShiftModel copyWith({
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
    return ShiftModel(
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
}

class ShiftModelAdapter extends TypeAdapter<ShiftModel> {
  @override
  final int typeId = 1;

  @override
  ShiftModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftModel(
      id: fields[0] as String,
      shopId: fields[1] as String,
      cashierId: fields[2] as String?,
      cashierName: fields[3] as String? ?? 'Кассир',
      openedAt: DateTime.parse(fields[4] as String),
      closedAt: fields[5] != null ? DateTime.parse(fields[5] as String) : null,
      startCash: (fields[6] as num).toDouble(),
      expectedCash: (fields[7] as num).toDouble(),
      actualCash: (fields[8] as num?)?.toDouble(),
      totalSalesCash: (fields[9] as num?)?.toDouble() ?? 0.0,
      totalSalesCard: (fields[10] as num?)?.toDouble() ?? 0.0,
      totalSalesOther: (fields[11] as num?)?.toDouble() ?? 0.0,
      salesCount: (fields[12] as num?)?.toInt() ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ShiftModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.cashierId)
      ..writeByte(3)
      ..write(obj.cashierName)
      ..writeByte(4)
      ..write(obj.openedAt.toIso8601String())
      ..writeByte(5)
      ..write(obj.closedAt?.toIso8601String())
      ..writeByte(6)
      ..write(obj.startCash)
      ..writeByte(7)
      ..write(obj.expectedCash)
      ..writeByte(8)
      ..write(obj.actualCash)
      ..writeByte(9)
      ..write(obj.totalSalesCash)
      ..writeByte(10)
      ..write(obj.totalSalesCard)
      ..writeByte(11)
      ..write(obj.totalSalesOther)
      ..writeByte(12)
      ..write(obj.salesCount);
  }
}
