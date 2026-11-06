import 'package:get_it/get_it.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';
import '../../features/pos/domain/repositories/pos_repository.dart';
import '../../features/pos/data/repositories/pos_repository_impl.dart';
import '../../features/pos/presentation/bloc/pos_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Repositories
  sl.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl());
  sl.registerLazySingleton<PosRepository>(() => PosRepositoryImpl());

  // Blocs
  sl.registerFactory<ProductsBloc>(
    () => ProductsBloc(repository: sl<ProductRepository>()),
  );
  sl.registerFactory<PosBloc>(
    () => PosBloc(
      posRepository: sl<PosRepository>(),
      productRepository: sl<ProductRepository>(),
    ),
  );
}
