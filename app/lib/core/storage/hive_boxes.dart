import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/pos/data/models/shift_model.dart';
import '../../features/pos/data/models/sale_item_model.dart';
import '../../features/pos/data/models/sale_model.dart';

class HiveBoxes {
  static late Box<ProductModel> productsBox;
  static late Box<ShiftModel> shiftsBox;
  static late Box<SaleModel> salesBox;
  static late Box settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ProductModelAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ShiftModelAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(SaleItemModelAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SaleModelAdapter());

    // Open boxes
    productsBox = await Hive.openBox<ProductModel>(AppConstants.boxProducts);
    shiftsBox = await Hive.openBox<ShiftModel>(AppConstants.boxShifts);
    salesBox = await Hive.openBox<SaleModel>(AppConstants.boxSales);
    settingsBox = await Hive.openBox(AppConstants.boxSettings);

    debugPrint('Hive initialized successfully. Total products in storage: ${productsBox.length}');
  }
}
