import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final _uuid = const Uuid();

  @override
  Future<List<Product>> getProducts({
    String? searchQuery,
    bool includeDeleted = false,
  }) async {
    var items = HiveBoxes.productsBox.values.toList();

    if (!includeDeleted) {
      items = items.where((p) => !p.isDeleted).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      items = items.where((p) {
        final matchesName = p.name.toLowerCase().contains(query);
        final matchesBarcode = p.barcode?.toLowerCase().contains(query) ?? false;
        return matchesName || matchesBarcode;
      }).toList();
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return items;
  }

  @override
  Future<Product?> getProductById(String id) async {
    return HiveBoxes.productsBox.get(id);
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    try {
      return HiveBoxes.productsBox.values.firstWhere(
        (p) => !p.isDeleted && p.barcode != null && p.barcode!.trim() == cleanBarcode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProduct(Product product) async {
    final model = ProductModel.fromEntity(product);
    await HiveBoxes.productsBox.put(model.id, model);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final existing = HiveBoxes.productsBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      await HiveBoxes.productsBox.put(id, updated);
    }
  }

  @override
  Future<void> restoreProduct(String id) async {
    final existing = HiveBoxes.productsBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isDeleted: false,
        updatedAt: DateTime.now(),
      );
      await HiveBoxes.productsBox.put(id, updated);
    }
  }

  @override
  Future<void> updateStock(String id, double deltaQty) async {
    final existing = HiveBoxes.productsBox.get(id);
    if (existing != null) {
      final updated = existing.copyWith(
        stockQty: existing.stockQty + deltaQty,
        updatedAt: DateTime.now(),
      );
      await HiveBoxes.productsBox.put(id, updated);
    }
  }

  @override
  Future<int> getProductsCount() async {
    return HiveBoxes.productsBox.values.where((p) => !p.isDeleted).length;
  }

  @override
  Future<void> seedDemoProducts() async {
    final now = DateTime.now();
    final demoItems = [
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Кофе Капучино 300мл',
        barcode: '478001001001',
        costPrice: 8000,
        sellPrice: 18000,
        stockQty: 50,
        minQty: 10,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Кофе Американо 250мл',
        barcode: '478001001002',
        costPrice: 6000,
        sellPrice: 15000,
        stockQty: 45,
        minQty: 10,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Круассан классический',
        barcode: '478001002001',
        costPrice: 7000,
        sellPrice: 14000,
        stockQty: 12,
        minQty: 5,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Сэндвич с индейкой',
        barcode: '478001002002',
        costPrice: 12000,
        sellPrice: 24000,
        stockQty: 4,
        minQty: 6,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Вода без газа 0.5л',
        barcode: '478001003001',
        costPrice: 2000,
        sellPrice: 4000,
        stockQty: 100,
        minQty: 20,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Кабель Type-C 1м FastCharge',
        barcode: '478001004001',
        costPrice: 25000,
        sellPrice: 55000,
        stockQty: 15,
        minQty: 3,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1588515724527-074a7a56616c?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Чехол силиконовый прозрачный',
        barcode: '478001004002',
        costPrice: 15000,
        sellPrice: 40000,
        stockQty: 22,
        minQty: 5,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1601784551446-20c9e07cdbdb?w=500&q=80',
      ),
      ProductModel(
        id: _uuid.v4(),
        shopId: AppConstants.defaultShopId,
        name: 'Шоколадный батончик 50г',
        barcode: '478001005001',
        costPrice: 4000,
        sellPrice: 8000,
        stockQty: 3,
        minQty: 10,
        updatedAt: now,
        imagePath: 'https://images.unsplash.com/photo-1582293041079-7814c2f12063?w=500&q=80',
      ),
    ];

    await HiveBoxes.productsBox.clear();
    for (final p in demoItems) {
      await HiveBoxes.productsBox.put(p.id, p);
    }
  }
}
