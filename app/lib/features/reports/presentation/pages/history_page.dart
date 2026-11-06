import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/user_session.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../pos/domain/entities/sale.dart';
import '../../../pos/domain/entities/shift.dart';
import '../../../pos/domain/repositories/pos_repository.dart';
import '../../../pos/presentation/widgets/receipt_dialog.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _fmt = NumberFormat('#,##0', 'ru_RU');

  List<Sale> _sales = [];
  List<Shift> _shifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final repo = sl<PosRepository>();
    final sales = await repo.getSales();
    final shifts = await repo.getAllShifts();
    setState(() {
      _sales = sales;
      _shifts = shifts;
      _isLoading = false;
    });
  }

  double get _totalRevenue => _sales.fold(0.0, (sum, s) => sum + s.totalAmount);
  double get _totalProfit => _sales.fold(0.0, (sum, s) => sum + s.totalProfit);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чеки и Отчеты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Чеки (Продажи)'),
            Tab(text: 'Смены (Z-отчеты)'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary metric cards (Never overflow!)
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      _buildMetric(
                        title: 'Выручка всего',
                        val: '${_fmt.format(_totalRevenue)} ${AppConstants.currency}',
                        color: const Color(0xFF0F766E),
                      ),
                      if (UserSession.isBoss) ...[
                        const SizedBox(width: 8),
                        _buildMetric(
                          title: 'Чистая прибыль',
                          val: '${_fmt.format(_totalProfit)} ${AppConstants.currency}',
                          color: Colors.blue.shade700,
                        ),
                      ],
                      const SizedBox(width: 8),
                      _buildMetric(
                        title: 'Чеков пробито',
                        val: '${_sales.length} шт',
                        color: Colors.orange.shade800,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSalesList(),
                      _buildShiftsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMetric({required String title, required String val, required Color color}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(
              val,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    if (_sales.isEmpty) {
      return const Center(child: Text('Пока нет пробитых чеков'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _sales.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sale = _sales[index];
        final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(sale.createdAt);

        return Card(
          child: ListTile(
            onTap: () {
              ReceiptDialog.show(context, sale: sale);
            },
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.1),
              child: const Icon(Icons.receipt_outlined, color: Color(0xFF0F766E)),
            ),
            title: Text(
              '${_fmt.format(sale.totalAmount)} ${AppConstants.currency}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${sale.paymentTypeName} • $dateStr • ${sale.items.length} поз.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }

  Widget _buildShiftsList() {
    if (_shifts.isEmpty) {
      return const Center(child: Text('Пока нет кассовых смен'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _shifts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final shift = _shifts[index];
        final openStr = DateFormat('dd.MM.yyyy HH:mm').format(shift.openedAt);
        final closeStr = shift.closedAt != null
            ? DateFormat('HH:mm').format(shift.closedAt!)
            : 'Открыта';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Кассир: ${shift.cashierName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: shift.isOpen ? const Color(0xFFDCFCE7) : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        shift.isOpen ? 'ОТКРЫТА' : 'ЗАКРЫТА',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: shift.isOpen ? const Color(0xFF166534) : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Период: $openStr — $closeStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Выручка: ${_fmt.format(shift.totalRevenue)} ${AppConstants.currency}'),
                    Text('Чеков: ${shift.salesCount}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ожидалось в кассе: ${_fmt.format(shift.expectedCash)} ${AppConstants.currency}'),
                    if (shift.actualCash != null)
                      Text(
                        'Факт: ${_fmt.format(shift.actualCash!)} ${AppConstants.currency}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: shift.cashDifference != null && shift.cashDifference! < 0
                              ? Colors.red
                              : Colors.green.shade800,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
