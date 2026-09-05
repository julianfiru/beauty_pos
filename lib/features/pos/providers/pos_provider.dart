import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../repositories/pos_repository.dart';
import '../../catalog/models/product.dart';
import '../../catalog/models/service_item.dart';

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepository();
});

final availableProductsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(posRepositoryProvider);
  return repo.getAvailableProducts();
});

final availableServicesProvider = FutureProvider.autoDispose<List<ServiceItem>>((ref) async {
  final repo = ref.watch(posRepositoryProvider);
  return repo.getAvailableServices();
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(Product product) {
    final existingIndex = state.indexWhere((i) => i.itemId == product.id && i.itemType == 'PRODUCT');
    
    if (existingIndex >= 0) {
      final currentItem = state[existingIndex];
      if (currentItem.qty < product.stock) {
        state = [
          ...state.sublist(0, existingIndex),
          currentItem.copyWith(qty: currentItem.qty + 1),
          ...state.sublist(existingIndex + 1),
        ];
      }
    } else {
      if (product.stock > 0) {
        state = [
          ...state,
          CartItem(
            itemId: product.id!,
            itemType: 'PRODUCT',
            name: product.name,
            price: product.price,
          ),
        ];
      }
    }
  }

  void addService(ServiceItem service) {
    final existingIndex = state.indexWhere((i) => i.itemId == service.id && i.itemType == 'SERVICE');
    
    if (existingIndex >= 0) {
      final currentItem = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        currentItem.copyWith(qty: currentItem.qty + 1),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [
        ...state,
        CartItem(
          itemId: service.id!,
          itemType: 'SERVICE',
          name: service.name,
          price: service.price,
        ),
      ];
    }
  }

  void increaseQty(CartItem item, {int? maxStock}) {
    final index = state.indexOf(item);
    if (index >= 0) {
      if (maxStock != null && item.qty >= maxStock) return;
      state = [
        ...state.sublist(0, index),
        item.copyWith(qty: item.qty + 1),
        ...state.sublist(index + 1),
      ];
    }
  }

  void decreaseQty(CartItem item) {
    final index = state.indexOf(item);
    if (index >= 0) {
      if (item.qty > 1) {
        state = [
          ...state.sublist(0, index),
          item.copyWith(qty: item.qty - 1),
          ...state.sublist(index + 1),
        ];
      } else {
        removeItem(item);
      }
    }
  }

  void removeItem(CartItem item) {
    state = state.where((element) => element != item).toList();
  }

  void clearCart() {
    state = [];
  }

  double get cartTotal {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
