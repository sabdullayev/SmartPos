import 'package:hive_ce/hive.dart';
import '../../domain/entities/sale_item.dart';

class SaleItemModel extends SaleItem {
  const SaleItemModel({
    required super.id,
    required super.saleId,
    super.productId,
    required super.productName,
    required super.qty,
    required super.costPrice,
    required super.sellPrice,
  });

  factory SaleItemModel.fromEntity(SaleItem item) {
    return SaleItemModel(
      id: item.id,
      saleId: item.saleId,
      productId: item.productId,
      productName: item.productName,
      qty: item.qty,
      costPrice: item.costPrice,
      sellPrice: item.sellPrice,
    );
  }

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      saleId: json['sale_id'] as String,
      productId: json['product_id'] as String?,
      productName: json['product_name'] as String,
      qty: (json['qty'] as num).toDouble(),
      costPrice: (json['cost_price'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'cost_price': costPrice,
      'sell_price': sellPrice,
    };
  }
}

class SaleItemModelAdapter extends TypeAdapter<SaleItemModel> {
  @override
  final int typeId = 2;

  @override
  SaleItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SaleItemModel(
      id: fields[0] as String,
      saleId: fields[1] as String,
      productId: fields[2] as String?,
      productName: fields[3] as String,
      qty: (fields[4] as num).toDouble(),
      costPrice: (fields[5] as num).toDouble(),
      sellPrice: (fields[6] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SaleItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.saleId)
      ..writeByte(2)
      ..write(obj.productId)
      ..writeByte(3)
      ..write(obj.productName)
      ..writeByte(4)
      ..write(obj.qty)
      ..writeByte(5)
      ..write(obj.costPrice)
      ..writeByte(6)
      ..write(obj.sellPrice);
  }
}
