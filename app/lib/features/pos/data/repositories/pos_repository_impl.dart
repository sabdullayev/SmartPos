import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../models/shift_model.dart';
import '../models/sale_model.dart';
import '../models/sale_item_model.dart';
import '../../domain/entities/shift.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/repositories/pos_repository.dart';

class PosRepositoryImpl implements PosRepository {
  final _uuid = const Uuid();

  @override
  Future<Shift?> getCurrentShift() async {
    try {
      return HiveBoxes.shiftsBox.values.firstWhere((s) => s.closedAt == null);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Shift> openShift({
    required double startCash,
    required String cashierName,
  }) async {
    final existingOpen = await getCurrentShift();
    if (existingOpen != null) {
      return existingOpen;
    }

    final newShift = ShiftModel(
      id: _uuid.v4(),
      shopId: AppConstants.defaultShopId,
      cashierId: AppConstants.defaultCashierId,
      cashierName: cashierName,
      openedAt: DateTime.now(),
      startCash: startCash,
      expectedCash: startCash,
    );

    await HiveBoxes.shiftsBox.put(newShift.id, newShift);
    return newShift;
  }

  @override
  Future<Shift> closeShift({
    required String shiftId,
    required double actualCash,
  }) async {
    final shift = HiveBoxes.shiftsBox.get(shiftId);
    if (shift == null) {
      throw Exception('Смена не найдена');
    }

    final closedShift = shift.copyWith(
      closedAt: DateTime.now(),
      actualCash: actualCash,
    );

    await HiveBoxes.shiftsBox.put(shiftId, closedShift);
    return closedShift;
  }

  @override
  Future<List<Shift>> getAllShifts() async {
    final list = HiveBoxes.shiftsBox.values.toList();
    list.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return list;
  }

  @override
  Future<Sale> createSale({
    required List<SaleItem> items,
    required String paymentType,
    String? shiftId,
    String? cashierId,
  }) async {
    final saleId = _uuid.v4();
    final now = DateTime.now();

    double totalAmount = 0.0;
    double totalProfit = 0.0;

    final saleItemModels = <SaleItemModel>[];

    for (final item in items) {
      final itemAmount = item.qty * item.sellPrice;
      final itemProfit = (item.sellPrice - item.costPrice) * item.qty;
      totalAmount += itemAmount;
      totalProfit += itemProfit;

      saleItemModels.add(SaleItemModel(
        id: item.id.isNotEmpty ? item.id : _uuid.v4(),
        saleId: saleId,
        productId: item.productId,
        productName: item.productName,
        qty: item.qty,
        costPrice: item.costPrice,
        sellPrice: item.sellPrice,
      ));

      // Deduct stock if linked to a registered product
      if (item.productId != null) {
        final product = HiveBoxes.productsBox.get(item.productId!);
        if (product != null) {
          final updatedProduct = product.copyWith(
            stockQty: product.stockQty - item.qty,
            updatedAt: now,
          );
          await HiveBoxes.productsBox.put(product.id, updatedProduct);
        }
      }
    }

    // Check & update active shift
    final currentShift = await getCurrentShift();
    final activeShiftId = shiftId ?? currentShift?.id;

    if (activeShiftId != null) {
      final shift = HiveBoxes.shiftsBox.get(activeShiftId);
      if (shift != null) {
        final double addCash = paymentType == 'cash' ? totalAmount : 0.0;
        final double addCard = paymentType == 'card' ? totalAmount : 0.0;
        final double addOther = paymentType == 'transfer' ? totalAmount : 0.0;

        final updatedShift = shift.copyWith(
          salesCount: shift.salesCount + 1,
          expectedCash: shift.expectedCash + addCash,
          totalSalesCash: shift.totalSalesCash + addCash,
          totalSalesCard: shift.totalSalesCard + addCard,
          totalSalesOther: shift.totalSalesOther + addOther,
        );
        await HiveBoxes.shiftsBox.put(shift.id, updatedShift);
      }
    }

    final sale = SaleModel(
      id: saleId,
      shopId: AppConstants.defaultShopId,
      shiftId: activeShiftId,
      cashierId: cashierId ?? AppConstants.defaultCashierId,
      totalAmount: totalAmount,
      totalProfit: totalProfit,
      paymentType: paymentType,
      createdAt: now,
      items: saleItemModels,
    );

    await HiveBoxes.salesBox.put(sale.id, sale);
    return sale;
  }

  @override
  Future<List<Sale>> getSales({
    String? shiftId,
    DateTime? from,
    DateTime? to,
  }) async {
    var list = HiveBoxes.salesBox.values.toList();

    if (shiftId != null) {
      list = list.where((s) => s.shiftId == shiftId).toList();
    }
    if (from != null) {
      list = list.where((s) => s.createdAt.isAfter(from) || s.createdAt.isAtSameMomentAs(from)).toList();
    }
    if (to != null) {
      list = list.where((s) => s.createdAt.isBefore(to) || s.createdAt.isAtSameMomentAs(to)).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Sale?> getSaleById(String id) async {
    return HiveBoxes.salesBox.get(id);
  }
}
