import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/auth/user_session.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/storage/hive_boxes.dart';
import 'core/theme/app_theme.dart';
import 'features/pos/presentation/bloc/pos_bloc.dart';
import 'features/products/domain/repositories/product_repository.dart';
import 'features/products/presentation/bloc/products_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline Hive database
  await HiveBoxes.init();

  // Initialize RBAC session
  UserSession.init();

  // Initialize DI
  await initDependencies();

  // If local catalog is completely empty, populate with initial demo products
  if (HiveBoxes.productsBox.isEmpty) {
    await sl<ProductRepository>().seedDemoProducts();
  }

  runApp(const SmartPosApp());
}

class SmartPosApp extends StatelessWidget {
  const SmartPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductsBloc>(
          create: (_) => sl<ProductsBloc>()..add(const LoadProducts()),
        ),
        BlocProvider<PosBloc>(
          create: (_) => sl<PosBloc>()..add(InitPosEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
