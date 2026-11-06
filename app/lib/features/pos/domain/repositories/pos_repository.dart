import '../entities/sale.dart';
import '../entities/sale_item.dart';
import '../entities/shift.dart';

abstract class PosRepository {
  Future<Shift?> getCurrentShift();
  Future<Shift> openShift({
    required double startCash,
    required String cashierName,
  });
  Future<Shift> closeShift({
    required String shiftId,
    required double actualCash,
  });
  Future<List<Shift>> getAllShifts();
  
  Future<Sale> createSale({
    required List<SaleItem> items,
    required String paymentType,
    String? shiftId,
    String? cashierId,
  });
  Future<List<Sale>> getSales({String? shiftId, DateTime? from, DateTime? to});
  Future<Sale?> getSaleById(String id);
}
