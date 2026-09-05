
import '../../../core/database/database_helper.dart';
import '../models/product.dart';
import '../models/service_item.dart';

class CatalogRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- PRODUCTS ---
  
  Future<List<Product>> getProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.insert('products', product.toMap());
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- SERVICES ---

  Future<List<ServiceItem>> getServices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('services', orderBy: 'name ASC');
    return maps.map((e) => ServiceItem.fromMap(e)).toList();
  }

  Future<int> insertService(ServiceItem service) async {
    final db = await _dbHelper.database;
    return await db.insert('services', service.toMap());
  }

  Future<int> updateService(ServiceItem service) async {
    final db = await _dbHelper.database;
    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
