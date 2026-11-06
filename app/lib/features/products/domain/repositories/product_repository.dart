import '../entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({String? searchQuery, bool includeDeleted = false});
  Future<Product?> getProductById(String id);
  Future<Product?> getProductByBarcode(String barcode);
  Future<void> saveProduct(Product product);
  Future<void> deleteProduct(String id); // soft delete
  Future<void> restoreProduct(String id);
  Future<void> updateStock(String id, double deltaQty);
  Future<void> seedDemoProducts();
  Future<int> getProductsCount();
}
