import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/products/domain/entities/product.dart';
import 'package:app/features/pos/presentation/bloc/pos_bloc.dart';

void main() {
  test('Product calculation logic test', () {
    final product = Product(
      id: 'test-1',
      shopId: 'shop-1',
      name: 'Кофе Капучино',
      costPrice: 8000,
      sellPrice: 18000,
      stockQty: 5,
      minQty: 10,
      updatedAt: DateTime.now(),
    );

    expect(product.profitMargin, equals(10000));
    expect(product.isLowStock, isTrue);
  });

  test('CartItem total and profit calculation test', () {
    final product = Product(
      id: 'test-2',
      shopId: 'shop-1',
      name: 'Круассан',
      costPrice: 5000,
      sellPrice: 12000,
      stockQty: 20,
      updatedAt: DateTime.now(),
    );

    final item = CartItem(product: product, qty: 3);
    expect(item.total, equals(36000));
    expect(item.profit, equals(21000));
  });
}
