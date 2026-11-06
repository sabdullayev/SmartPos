import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

// EVENTS
abstract class ProductsEvent extends Equatable {
  const ProductsEvent();
  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductsEvent {
  final String? searchQuery;
  const LoadProducts({this.searchQuery});
  @override
  List<Object?> get props => [searchQuery];
}

class SaveProductEvent extends ProductsEvent {
  final Product product;
  const SaveProductEvent(this.product);
  @override
  List<Object?> get props => [product];
}

class DeleteProductEvent extends ProductsEvent {
  final String productId;
  const DeleteProductEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class SeedDemoProductsEvent extends ProductsEvent {
  const SeedDemoProductsEvent();
}

// STATES
abstract class ProductsState extends Equatable {
  const ProductsState();
  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {}

class ProductsLoading extends ProductsState {}

class ProductsLoaded extends ProductsState {
  final List<Product> products;
  final String? searchQuery;
  final String? message;

  const ProductsLoaded({
    required this.products,
    this.searchQuery,
    this.message,
  });

  int get lowStockCount => products.where((p) => p.isLowStock).length;
  double get totalStockValue =>
      products.fold(0.0, (sum, p) => sum + (p.stockQty * p.sellPrice));
  double get totalCostValue =>
      products.fold(0.0, (sum, p) => sum + (p.stockQty * p.costPrice));

  @override
  List<Object?> get props => [products, searchQuery, message];
}

class ProductsError extends ProductsState {
  final String message;
  const ProductsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLOC
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository repository;

  ProductsBloc({required this.repository}) : super(ProductsInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SaveProductEvent>(_onSaveProduct);
    on<DeleteProductEvent>(_onDeleteProduct);
    on<SeedDemoProductsEvent>(_onSeedDemoProducts);
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      final products = await repository.getProducts(searchQuery: event.searchQuery);
      emit(ProductsLoaded(
        products: products,
        searchQuery: event.searchQuery,
      ));
    } catch (e) {
      emit(ProductsError('Ошибка загрузки товаров: $e'));
    }
  }

  Future<void> _onSaveProduct(
    SaveProductEvent event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await repository.saveProduct(event.product);
      final products = await repository.getProducts();
      emit(ProductsLoaded(
        products: products,
        message: 'Товар сохранен',
      ));
    } catch (e) {
      emit(ProductsError('Ошибка сохранения товара: $e'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductEvent event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await repository.deleteProduct(event.productId);
      final products = await repository.getProducts();
      emit(ProductsLoaded(
        products: products,
        message: 'Товар удален',
      ));
    } catch (e) {
      emit(ProductsError('Ошибка удаления товара: $e'));
    }
  }

  Future<void> _onSeedDemoProducts(
    SeedDemoProductsEvent event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      emit(ProductsLoading());
      await repository.seedDemoProducts();
      final products = await repository.getProducts();
      emit(ProductsLoaded(
        products: products,
        message: 'Демо-товары успешно загружены',
      ));
    } catch (e) {
      emit(ProductsError('Ошибка создания демо-товаров: $e'));
    }
  }
}
