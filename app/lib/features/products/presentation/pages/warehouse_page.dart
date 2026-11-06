import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/auth/pin_dialog.dart';
import '../../../../core/auth/user_session.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/entities/product.dart';
import '../bloc/products_bloc.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/barcode_scanner_modal.dart';

class WarehousePage extends StatefulWidget {
  const WarehousePage({super.key});

  @override
  State<WarehousePage> createState() => _WarehousePageState();
}

class _WarehousePageState extends State<WarehousePage> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'ru_RU');

  @override
  void initState() {
    super.initState();
    context.read<ProductsBloc>().add(const LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<ProductsBloc>().add(LoadProducts(searchQuery: query));
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerModal.show(context);
    if (barcode != null && barcode.isNotEmpty) {
      _searchController.text = barcode;
      _onSearch(barcode);
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    if (!UserSession.isBoss) {
      final ok = await PinDialog.requestPin(context, title: 'Управление номенклатурой');
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    final result = await ProductFormDialog.show(context, product: product);
    if (result != null && mounted) {
      context.read<ProductsBloc>().add(SaveProductEvent(result));
    }
  }

  Future<void> _confirmDelete(Product product) async {
    if (!UserSession.isBoss) {
      final ok = await PinDialog.requestPin(context, title: 'Удаление товара');
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удаление товара'),
        content: Text('Удалить "${product.name}" из номенклатуры?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductsBloc>().add(DeleteProductEvent(product.id));
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Склад и Номенклатура'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Загрузить демо-товары',
            onPressed: () {
              context.read<ProductsBloc>().add(const SeedDemoProductsEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Сканировать штрихкод',
            onPressed: _scanBarcode,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        icon: const Icon(Icons.add),
        label: const Text('Новый товар'),
      ),
      body: BlocConsumer<ProductsBloc, ProductsState>(
        listener: (context, state) {
          if (state is ProductsLoaded && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          } else if (state is ProductsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или штрихкоду...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _scanBarcode,
                          ),
                  ),
                ),
              ),

              if (state is ProductsLoaded) ...[
                // Horizontal scrolling metric chips (Never overflow, fully readable!)
                SizedBox(
                  height: 84,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    children: [
                      _buildMetricChip(
                        context,
                        title: 'Всего товаров',
                        value: '${state.products.length} поз.',
                        icon: Icons.inventory_2_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricChip(
                        context,
                        title: 'Заканчиваются',
                        value: '${state.lowStockCount} поз.',
                        icon: Icons.warning_amber_rounded,
                        color: state.lowStockCount > 0 ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricChip(
                        context,
                        title: 'Оценка склада',
                        value: '${_numberFormat.format(state.totalStockValue)} ${AppConstants.currency}',
                        icon: Icons.monetization_on_outlined,
                        color: const Color(0xFF0F766E),
                      ),
                    ],
                  ),
                ),

                // Products list
                Expanded(
                  child: state.products.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                          itemCount: state.products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return _buildProductCard(context, product);
                          },
                        ),
                ),
              ] else if (state is ProductsLoading) ...[
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ] else ...[
                const Expanded(
                  child: Center(child: Text('Нет данных')),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final isLow = product.isLowStock;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLow ? Colors.orange.shade200 : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openProductForm(product: product),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image with fallback
              ProductImage(
                imagePath: product.imagePath,
                productName: product.name,
                width: 56,
                height: 56,
                borderRadius: 12,
              ),
              const SizedBox(width: 12),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Stock chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLow ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isLow ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                            ),
                          ),
                          child: Text(
                            '${product.stockQty.toStringAsFixed(0)} шт в наличии',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isLow ? Colors.red.shade800 : const Color(0xFF166534),
                            ),
                          ),
                        ),
                        if (product.barcode != null && product.barcode!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.barcode_reader, size: 12, color: Colors.grey),
                              const SizedBox(width: 2),
                              Text(
                                product.barcode!,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Prices & actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_numberFormat.format(product.sellPrice)} ${AppConstants.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  if (UserSession.isBoss && product.costPrice > 0)
                    Text(
                      'Закуп: ${_numberFormat.format(product.costPrice)} ${AppConstants.currency}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openProductForm(product: product);
                  } else if (val == 'delete') {
                    _confirmDelete(product);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Товары не найдены',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Склад пуст или поиск не дал результатов.\nВы можете добавить первый товар или загрузить демо-каталог.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openProductForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить товар'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<ProductsBloc>().add(const SeedDemoProductsEvent());
                  },
                  icon: const Icon(Icons.bolt),
                  label: const Text('Загрузить демо'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
