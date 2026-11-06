import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/presentation/bloc/products_bloc.dart';
import '../../../products/presentation/widgets/barcode_scanner_modal.dart';
import '../../domain/entities/shift.dart';
import '../bloc/pos_bloc.dart';
import '../widgets/checkout_modal.dart';
import '../widgets/receipt_dialog.dart';
import '../widgets/shift_dialogs.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _fmt = NumberFormat('#,##0', 'ru_RU');

  @override
  void initState() {
    super.initState();
    context.read<PosBloc>().add(InitPosEvent());
    context.read<ProductsBloc>().add(const LoadProducts());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    final isBarcode = RegExp(r'^[0-9]{4,20}$').hasMatch(query.trim());
    if (isBarcode) {
      context.read<PosBloc>().add(AddByBarcodePosEvent(query.trim()));
      _searchController.clear();
      context.read<ProductsBloc>().add(const LoadProducts());
    } else {
      context.read<ProductsBloc>().add(LoadProducts(searchQuery: query.trim()));
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await BarcodeScannerModal.show(context);
    if (barcode != null && barcode.isNotEmpty && mounted) {
      context.read<PosBloc>().add(AddByBarcodePosEvent(barcode.trim()));
    }
  }

  Future<void> _openShift() async {
    final result = await OpenShiftDialog.show(context);
    if (result != null && mounted) {
      context.read<PosBloc>().add(OpenShiftPosEvent(
            startCash: result['startCash'] as double,
            cashierName: result['cashierName'] as String,
          ));
    }
  }

  Future<void> _closeShift(Shift shift) async {
    final actual = await CloseShiftDialog.show(context, shift: shift);
    if (actual != null && mounted) {
      context.read<PosBloc>().add(CloseShiftPosEvent(
            shiftId: shift.id,
            actualCash: actual,
          ));
    }
  }

  Future<void> _startCheckout(PosState posState) async {
    if (!posState.isShiftOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала откройте кассовую смену!')),
      );
      return;
    }
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Корзина пуста')),
      );
      return;
    }

    final paymentType = await CheckoutModal.show(
      context,
      totalAmount: posState.cartTotal,
    );

    if (paymentType != null && mounted) {
      context.read<PosBloc>().add(CheckoutPosEvent(paymentType: paymentType));
    }
  }

  void _openCartSheet(PosState posState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocBuilder<PosBloc, PosState>(
        builder: (context, state) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F766E), size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Товары в чеке (${state.cartCount} шт)',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ],
                      ),
                      if (state.cart.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            context.read<PosBloc>().add(ClearCartEvent());
                            Navigator.of(ctx).pop();
                          },
                          icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                          label: const Text('Очистить всё', style: TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: state.cart.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart_outlined, size: 54, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('В чеке пока нет товаров', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: state.cart.length,
                          separatorBuilder: (_, _) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = state.cart[index];
                            return Row(
                              children: [
                                ProductImage(
                                  imagePath: item.product.imagePath,
                                  width: 46,
                                  height: 46,
                                  borderRadius: 10,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_fmt.format(item.price)} ${AppConstants.currency}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                // Minus / Count / Plus
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 18),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          context.read<PosBloc>().add(
                                                UpdateCartQtyEvent(productId: item.product.id, delta: -1),
                                              );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Text(
                                          item.qty.toStringAsFixed(0),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 18),
                                        padding: const EdgeInsets.all(6),
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          context.read<PosBloc>().add(
                                                UpdateCartQtyEvent(productId: item.product.id, delta: 1),
                                              );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    _fmt.format(item.total),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Удалить из чека',
                                  onPressed: () {
                                    context.read<PosBloc>().add(RemoveFromCartEvent(item.product.id));
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Итого к оплате:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '${_fmt.format(state.cartTotal)} ${AppConstants.currency}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: state.cart.isEmpty
                            ? null
                            : () {
                                Navigator.of(ctx).pop();
                                _startCheckout(state);
                              },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Перейти к оплате', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PosBloc, PosState>(
      listener: (context, posState) {
        if (posState.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(posState.errorMessage!),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }

        if (posState.lastCompletedSale != null) {
          ReceiptDialog.show(
            context,
            sale: posState.lastCompletedSale!,
            cashierName: posState.currentShift?.cashierName ?? AppConstants.defaultCashierName,
          );
          context.read<ProductsBloc>().add(const LoadProducts());
          context.read<PosBloc>().add(ClearLastSaleEvent());
        }
      },
      builder: (context, posState) {
        final isWideScreen = MediaQuery.of(context).size.width >= 850;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Кассовый Терминал'),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Сканировать штрихкод',
                onPressed: _scanBarcode,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              _buildShiftBanner(posState),
              Expanded(
                child: isWideScreen
                    ? Row(
                        children: [
                          Expanded(flex: 3, child: _buildCatalogSection(posState)),
                          const VerticalDivider(width: 1),
                          Expanded(flex: 2, child: _buildCartSection(posState)),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildCatalogSection(posState)),
                          _buildMobileCartBar(posState),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShiftBanner(PosState posState) {
    final shift = posState.currentShift;
    final isOpen = posState.isShiftOpen;

    if (!isOpen) {
      return Container(
        color: Colors.amber.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.lock_clock_outlined, color: Colors.brown, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Смена закрыта. Откройте смену для продаж.',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.brown, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _openShift,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Открыть', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFECFDF5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${shift!.cashierName} • В кассе: ${_fmt.format(shift.expectedCash)} ${AppConstants.currency}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton(
            onPressed: () => _closeShift(shift),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text('Z-отчет', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogSection(PosState posState) {
    return BlocBuilder<ProductsBloc, ProductsState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: _onSearchSubmitted,
                onChanged: (val) {
                  context.read<ProductsBloc>().add(LoadProducts(searchQuery: val));
                },
                decoration: InputDecoration(
                  hintText: 'Поиск товара или штрихкод...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ProductsBloc>().add(const LoadProducts());
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF0F766E)),
                        tooltip: 'Сканировать',
                        onPressed: _scanBarcode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Expanded(
              child: state is ProductsLoaded
                  ? (state.products.isEmpty
                      ? const Center(child: Text('Нет доступных товаров'))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 6, 14, 88),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.58,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: state.products.length,
                          itemBuilder: (context, index) {
                            final product = state.products[index];
                            return _buildProductCard(product, posState);
                          },
                        ))
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product, PosState posState) {
    final cartIndex = posState.cart.indexWhere((c) => c.product.id == product.id);
    final inCart = cartIndex >= 0;
    final inCartQty = inCart ? posState.cart[cartIndex].qty : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: inCart ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
          width: inCart ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: inCart
                ? const Color(0xFF0F766E).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          // Clicking anywhere on the card adds it to the cart!
          onTap: () {
            context.read<PosBloc>().add(AddToCartEvent(product));
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image container with rounded corners
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      ProductImage(
                        imagePath: product.imagePath,
                        productName: product.name,
                        width: double.infinity,
                        height: 115,
                        borderRadius: 16,
                      ),
                      // Stock pill badge
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 11, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                '${product.stockQty.toStringAsFixed(0)} шт',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (product.isLowStock)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Мало',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Product Title
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),

                // Subtitle / Specs
                Text(
                  product.barcode != null && product.barcode!.isNotEmpty
                      ? 'Код: ${product.barcode}'
                      : 'В наличии на складе',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Price
                Text(
                  '${_fmt.format(product.sellPrice)} ${AppConstants.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF0F2B48),
                  ),
                ),
                const Spacer(),

                // Bottom Pill Action Button (Guaranteed ZERO OVERFLOW with Expanded)
                if (inCart)
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                            onTap: () {
                              context.read<PosBloc>().add(
                                    UpdateCartQtyEvent(productId: product.id, delta: -1),
                                  );
                            },
                            child: const Center(
                              child: Icon(Icons.remove, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '${inCartQty.toStringAsFixed(0)} шт',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                            onTap: () {
                              context.read<PosBloc>().add(
                                    UpdateCartQtyEvent(productId: product.id, delta: 1),
                                  );
                            },
                            child: const Center(
                              child: Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2B48), // Deep navy
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'В чек',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSection(PosState posState) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: Color(0xFF0F766E)),
                    const SizedBox(width: 8),
                    Text(
                      'Текущий чек (${posState.cartCount} шт)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                if (posState.cart.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => context.read<PosBloc>().add(ClearCartEvent()),
                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    label: const Text('Очистить', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: posState.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Чек пуст\nНажмите на товар или отсканируйте штрихкод',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: posState.cart.length,
                    separatorBuilder: (_, _) => const Divider(height: 8),
                    itemBuilder: (context, index) {
                      final item = posState.cart[index];
                      return Row(
                        children: [
                          ProductImage(
                            imagePath: item.product.imagePath,
                            width: 38,
                            height: 38,
                            borderRadius: 8,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${_fmt.format(item.price)} ${AppConstants.currency}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () {
                                  context.read<PosBloc>().add(
                                        UpdateCartQtyEvent(productId: item.product.id, delta: -1),
                                      );
                                },
                              ),
                              Text(
                                item.qty.toStringAsFixed(0),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () {
                                  context.read<PosBloc>().add(
                                        UpdateCartQtyEvent(productId: item.product.id, delta: 1),
                                      );
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 65,
                            child: Text(
                              _fmt.format(item.total),
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: () {
                              context.read<PosBloc>().add(RemoveFromCartEvent(item.product.id));
                            },
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Итого к оплате:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${_fmt.format(posState.cartTotal)} ${AppConstants.currency}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: posState.cart.isEmpty ? null : () => _startCheckout(posState),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Оформить чек / Оплата', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartBar(PosState posState) {
    if (posState.cart.isEmpty) return const SizedBox.shrink();

    return Material(
      color: Colors.white,
      elevation: 16,
      child: InkWell(
        onTap: () => _openCartSheet(posState),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Badge(
                  label: Text('${posState.cartCount}'),
                  backgroundColor: const Color(0xFF0F766E),
                  child: const Icon(Icons.shopping_cart, color: Color(0xFF0F766E), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('Чек корзины', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_up, size: 14, color: Colors.grey),
                        ],
                      ),
                      Text(
                        '${_fmt.format(posState.cartTotal)} ${AppConstants.currency}',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F766E)),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _startCheckout(posState),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('Оплатить', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
