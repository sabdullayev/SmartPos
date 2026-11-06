import 'package:hive_ce/hive.dart';
import '../../domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.shopId,
    required super.name,
    super.barcode,
    required super.costPrice,
    required super.sellPrice,
    required super.stockQty,
    super.minQty = 5.0,
    super.isDeleted = false,
    required super.updatedAt,
    super.imagePath,
  });

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      id: product.id,
      shopId: product.shopId,
      name: product.name,
      barcode: product.barcode,
      costPrice: product.costPrice,
      sellPrice: product.sellPrice,
      stockQty: product.stockQty,
      minQty: product.minQty,
      isDeleted: product.isDeleted,
      updatedAt: product.updatedAt,
      imagePath: product.imagePath,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String?,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (json['sell_price'] as num?)?.toDouble() ?? 0.0,
      stockQty: (json['stock_qty'] as num?)?.toDouble() ?? 0.0,
      minQty: (json['min_qty'] as num?)?.toDouble() ?? 5.0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      imagePath: json['image_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'barcode': barcode,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'stock_qty': stockQty,
      'min_qty': minQty,
      'is_deleted': isDeleted,
      'updated_at': updatedAt.toIso8601String(),
      'image_path': imagePath,
    };
  }

  @override
  ProductModel copyWith({
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
    return ProductModel(
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
}

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      shopId: fields[1] as String,
      name: fields[2] as String,
      barcode: fields[3] as String?,
      costPrice: (fields[4] as num).toDouble(),
      sellPrice: (fields[5] as num).toDouble(),
      stockQty: (fields[6] as num).toDouble(),
      minQty: (fields[7] as num).toDouble(),
      isDeleted: fields[8] as bool,
      updatedAt: DateTime.parse(fields[9] as String),
      imagePath: fields.containsKey(10) ? fields[10] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shopId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.barcode)
      ..writeByte(4)
      ..write(obj.costPrice)
      ..writeByte(5)
      ..write(obj.sellPrice)
      ..writeByte(6)
      ..write(obj.stockQty)
      ..writeByte(7)
      ..write(obj.minQty)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(10)
      ..write(obj.imagePath);
  }
}
