import 'package:hive_ce/hive.dart';
import '../../domain/entities/sale.dart';
import 'sale_item_model.dart';

class SaleModel extends Sale {
  const SaleModel({
    required super.id,
    required super.shopId,
    super.shiftId,
    super.cashierId,
    required super.totalAmount,
    required super.totalProfit,
    required super.paymentType,
    required super.createdAt,
    required List<SaleItemModel> super.items,
  });

  factory SaleModel.fromEntity(Sale sale) {
    return SaleModel(
      id: sale.id,
      shopId: sale.shopId,
      shiftId: sale.shiftId,
      cashierId: sale.cashierId,
      totalAmount: sale.totalAmount,
      totalProfit: sale.totalProfit,
      paymentType: sale.paymentType,
      createdAt: sale.createdAt,
      items: sale.items.map((i) => SaleItemModel.fromEntity(i)).toList(),
    );
  }

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      shiftId: json['shift_id'] as String?,
      cashierId: json['cashier_id'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      totalProfit: (json['total_profit'] as num).toDouble(),
      paymentType: json['payment_type'] as String? ?? 'cash',
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => SaleItemModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'shift_id': shiftId,
      'cashier_id': cashierId,
      'total_amount': totalAmount,
      'total_profit': totalProfit,
      'payment_type': paymentType,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((i) => (i as SaleItemModel).toJson()).toList(),
    };
  }
}

class SaleModelAdapter extends TypeAdapter<SaleModel> {
  @override
  final int typeId = 3;

  @override
  SaleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleModel(
      id: fields[0] as String,
      shopId: fields[1] as String,
      shiftId: fields[2] as String?,
      cashierId: fields[3] as String?,
      totalAmount: (fields[4] as num).toDouble(),
      totalProfit: (fields[5] as num).toDouble(),
      paymentType: fields[6] as String,
      createdAt: DateTime.parse(fields[7] as String),
      items: (fields[8] as List).cast<SaleItemModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, SaleModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.shiftId)
      ..writeByte(3)
      ..write(obj.cashierId)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.totalProfit)
      ..writeByte(6)
      ..write(obj.paymentType)
      ..writeByte(7)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(8)
      ..write(obj.items);
  }
}
