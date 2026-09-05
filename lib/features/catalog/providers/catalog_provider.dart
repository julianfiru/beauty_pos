import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/service_item.dart';
import '../repositories/catalog_repository.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository();
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final CatalogRepository repository;

  ProductsNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await repository.getProducts();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      await repository.insertProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      await repository.updateProduct(product);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await repository.deleteProduct(id);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }
}

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return ProductsNotifier(repository);
});

class ServicesNotifier extends StateNotifier<AsyncValue<List<ServiceItem>>> {
  final CatalogRepository repository;

  ServicesNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadServices();
  }

  Future<void> loadServices() async {
    state = const AsyncValue.loading();
    try {
      final services = await repository.getServices();
      state = AsyncValue.data(services);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addService(ServiceItem service) async {
    try {
      await repository.insertService(service);
      await loadServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateService(ServiceItem service) async {
    try {
      await repository.updateService(service);
      await loadServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await repository.deleteService(id);
      await loadServices();
    } catch (e) {
      rethrow;
    }
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, AsyncValue<List<ServiceItem>>>((ref) {
  final repository = ref.watch(catalogRepositoryProvider);
  return ServicesNotifier(repository);
});
