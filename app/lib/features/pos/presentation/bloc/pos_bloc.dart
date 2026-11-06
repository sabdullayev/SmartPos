import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/sale.dart';
import '../../domain/entities/sale_item.dart';
import '../../domain/entities/shift.dart';
import '../../domain/repositories/pos_repository.dart';

// CART ITEM
class CartItem extends Equatable {
  final Product product;
  final double qty;
  final double? customPrice;

  const CartItem({
    required this.product,
    this.qty = 1.0,
    this.customPrice,
  });

  double get price => customPrice ?? product.sellPrice;
  double get total => price * qty;
  double get profit => (price - product.costPrice) * qty;

  CartItem copyWith({
    Product? product,
    double? qty,
    double? customPrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      qty: qty ?? this.qty,
      customPrice: customPrice ?? this.customPrice,
    );
  }

  @override
  List<Object?> get props => [product, qty, customPrice];
}

// EVENTS
abstract class PosEvent extends Equatable {
  const PosEvent();
  @override
  List<Object?> get props => [];
}

class InitPosEvent extends PosEvent {}

class OpenShiftPosEvent extends PosEvent {
  final double startCash;
  final String cashierName;
  const OpenShiftPosEvent({required this.startCash, required this.cashierName});
  @override
  List<Object?> get props => [startCash, cashierName];
}

class CloseShiftPosEvent extends PosEvent {
  final String shiftId;
  final double actualCash;
  const CloseShiftPosEvent({required this.shiftId, required this.actualCash});
  @override
  List<Object?> get props => [shiftId, actualCash];
}

class AddToCartEvent extends PosEvent {
  final Product product;
  final double qty;
  const AddToCartEvent(this.product, {this.qty = 1.0});
  @override
  List<Object?> get props => [product, qty];
}

class AddByBarcodePosEvent extends PosEvent {
  final String barcode;
  const AddByBarcodePosEvent(this.barcode);
  @override
  List<Object?> get props => [barcode];
}

class UpdateCartQtyEvent extends PosEvent {
  final String productId;
  final double delta;
  const UpdateCartQtyEvent({required this.productId, required this.delta});
  @override
  List<Object?> get props => [productId, delta];
}

class SetCartItemQtyEvent extends PosEvent {
  final String productId;
  final double qty;
  const SetCartItemQtyEvent({required this.productId, required this.qty});
  @override
  List<Object?> get props => [productId, qty];
}

class RemoveFromCartEvent extends PosEvent {
  final String productId;
  const RemoveFromCartEvent(this.productId);
  @override
  List<Object?> get props => [productId];
}

class ClearCartEvent extends PosEvent {}

class CheckoutPosEvent extends PosEvent {
  final String paymentType; // 'cash', 'card', 'transfer'
  const CheckoutPosEvent({required this.paymentType});
  @override
  List<Object?> get props => [paymentType];
}

class ClearLastSaleEvent extends PosEvent {}

// STATE
class PosState extends Equatable {
  final Shift? currentShift;
  final List<CartItem> cart;
  final bool isLoading;
  final Sale? lastCompletedSale;
  final String? errorMessage;
  final String? infoMessage;

  const PosState({
    this.currentShift,
    this.cart = const [],
    this.isLoading = false,
    this.lastCompletedSale,
    this.errorMessage,
    this.infoMessage,
  });

  bool get isShiftOpen => currentShift != null && currentShift!.isOpen;
  double get cartTotal => cart.fold(0.0, (sum, item) => sum + item.total);
  int get cartCount => cart.fold(0, (sum, item) => sum + item.qty.toInt());
  double get cartProfit => cart.fold(0.0, (sum, item) => sum + item.profit);

  PosState copyWith({
    Shift? Function()? currentShift,
    List<CartItem>? cart,
    bool? isLoading,
    Sale? Function()? lastCompletedSale,
    String? Function()? errorMessage,
    String? Function()? infoMessage,
  }) {
    return PosState(
      currentShift: currentShift != null ? currentShift() : this.currentShift,
      cart: cart ?? this.cart,
      isLoading: isLoading ?? this.isLoading,
      lastCompletedSale: lastCompletedSale != null ? lastCompletedSale() : this.lastCompletedSale,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      infoMessage: infoMessage != null ? infoMessage() : this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentShift,
        cart,
        isLoading,
        lastCompletedSale,
        errorMessage,
        infoMessage,
      ];
}

// BLOC
class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository posRepository;
  final ProductRepository productRepository;

  PosBloc({
    required this.posRepository,
    required this.productRepository,
  }) : super(const PosState()) {
    on<InitPosEvent>(_onInitPos);
    on<OpenShiftPosEvent>(_onOpenShift);
    on<CloseShiftPosEvent>(_onCloseShift);
    on<AddToCartEvent>(_onAddToCart);
    on<AddByBarcodePosEvent>(_onAddByBarcode);
    on<UpdateCartQtyEvent>(_onUpdateCartQty);
    on<SetCartItemQtyEvent>(_onSetCartItemQty);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<ClearCartEvent>(_onClearCart);
    on<CheckoutPosEvent>(_onCheckout);
    on<ClearLastSaleEvent>(_onClearLastSale);
  }

  Future<void> _onInitPos(InitPosEvent event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final shift = await posRepository.getCurrentShift();
      emit(state.copyWith(
        currentShift: () => shift,
        isLoading: false,
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Ошибка инициализации кассы: $e',
      ));
    }
  }

  Future<void> _onOpenShift(OpenShiftPosEvent event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final shift = await posRepository.openShift(
        startCash: event.startCash,
        cashierName: event.cashierName,
      );
      emit(state.copyWith(
        currentShift: () => shift,
        isLoading: false,
        infoMessage: () => 'Смена успешно открыта',
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Не удалось открыть смену: $e',
      ));
    }
  }

  Future<void> _onCloseShift(CloseShiftPosEvent event, Emitter<PosState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      await posRepository.closeShift(
        shiftId: event.shiftId,
        actualCash: event.actualCash,
      );
      emit(state.copyWith(
        currentShift: () => null,
        cart: const [],
        isLoading: false,
        infoMessage: () => 'Смена закрыта. Z-отчет сформирован.',
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Не удалось закрыть смену: $e',
      ));
    }
  }

  void _onAddToCart(AddToCartEvent event, Emitter<PosState> emit) {
    final existingIndex =
        state.cart.indexWhere((item) => item.product.id == event.product.id);

    List<CartItem> updatedCart;
    if (existingIndex >= 0) {
      updatedCart = List.from(state.cart);
      final current = updatedCart[existingIndex];
      updatedCart[existingIndex] = current.copyWith(qty: current.qty + event.qty);
    } else {
      updatedCart = List.from(state.cart)
        ..add(CartItem(product: event.product, qty: event.qty));
    }

    emit(state.copyWith(
      cart: updatedCart,
      infoMessage: () => '${event.product.name} добавлен в чек',
      errorMessage: () => null,
    ));
  }

  Future<void> _onAddByBarcode(
    AddByBarcodePosEvent event,
    Emitter<PosState> emit,
  ) async {
    try {
      final product = await productRepository.getProductByBarcode(event.barcode);
      if (product != null) {
        add(AddToCartEvent(product));
      } else {
        emit(state.copyWith(
          errorMessage: () => 'Товар со штрихкодом "${event.barcode}" не найден',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Ошибка поиска штрихкода: $e',
      ));
    }
  }

  void _onUpdateCartQty(UpdateCartQtyEvent event, Emitter<PosState> emit) {
    final updatedCart = <CartItem>[];
    for (final item in state.cart) {
      if (item.product.id == event.productId) {
        final newQty = item.qty + event.delta;
        if (newQty > 0) {
          updatedCart.add(item.copyWith(qty: newQty));
        }
      } else {
        updatedCart.add(item);
      }
    }
    emit(state.copyWith(cart: updatedCart));
  }

  void _onSetCartItemQty(SetCartItemQtyEvent event, Emitter<PosState> emit) {
    final updatedCart = <CartItem>[];
    for (final item in state.cart) {
      if (item.product.id == event.productId) {
        if (event.qty > 0) {
          updatedCart.add(item.copyWith(qty: event.qty));
        }
      } else {
        updatedCart.add(item);
      }
    }
    emit(state.copyWith(cart: updatedCart));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<PosState> emit) {
    final updatedCart =
        state.cart.where((item) => item.product.id != event.productId).toList();
    emit(state.copyWith(cart: updatedCart));
  }

  void _onClearCart(ClearCartEvent event, Emitter<PosState> emit) {
    emit(state.copyWith(cart: const []));
  }

  Future<void> _onCheckout(CheckoutPosEvent event, Emitter<PosState> emit) async {
    if (state.cart.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Корзина пуста'));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final saleItems = state.cart.map((c) {
        return SaleItem(
          id: '',
          saleId: '',
          productId: c.product.id,
          productName: c.product.name,
          qty: c.qty,
          costPrice: c.product.costPrice,
          sellPrice: c.price,
        );
      }).toList();

      final sale = await posRepository.createSale(
        items: saleItems,
        paymentType: event.paymentType,
        shiftId: state.currentShift?.id,
      );

      final currentShift = await posRepository.getCurrentShift();

      emit(state.copyWith(
        cart: const [],
        isLoading: false,
        lastCompletedSale: () => sale,
        currentShift: () => currentShift,
        infoMessage: () => 'Чек успешно пробит! Сумма: ${sale.totalAmount.toStringAsFixed(0)}',
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Ошибка при оформлении продажи: $e',
      ));
    }
  }

  void _onClearLastSale(ClearLastSaleEvent event, Emitter<PosState> emit) {
    emit(state.copyWith(lastCompletedSale: () => null));
  }
}
