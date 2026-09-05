
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../catalog/models/product.dart';
import '../../catalog/models/service_item.dart';
import '../models/cart_item.dart';

class PosRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Product>> getAvailableProducts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('products', where: 'stock > 0');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  Future<List<ServiceItem>> getAvailableServices() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('services');
    return maps.map((e) => ServiceItem.fromMap(e)).toList();
  }

  Future<String> processCheckout({
    required List<CartItem> items,
    required double totalAmount,
    required double amountTendered,
    required double changeAmount,
  }) async {
    final db = await _dbHelper.database;
    final orderNumber = 'TRX-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      // 1. Insert Transaction
      final transactionId = await txn.insert('transactions', {
        'orderNumber': orderNumber,
        'totalAmount': totalAmount,
        'paymentMethod': 'CASH',
        'amountTendered': amountTendered,
        'changeAmount': changeAmount,
        'status': 'COMPLETED',
        'createdAt': now,
      });

      // 2. Insert Transaction Items & Decrease Stock
      for (final item in items) {
        await txn.insert('transaction_items', {
          'transactionId': transactionId,
          'itemId': item.itemId,
          'itemType': item.itemType,
          'itemName': item.name,
          'qty': item.qty,
          'price': item.price,
          'subtotal': item.subtotal,
        });

        // If it's a product, decrease stock and record movement
        if (item.itemType == 'PRODUCT') {
          // Check current stock to avoid negative
          final productMap = await txn.query('products', where: 'id = ?', whereArgs: [item.itemId], limit: 1);
          if (productMap.isNotEmpty) {
            final currentStock = productMap.first['stock'] as int;
            final newStock = currentStock - item.qty;
            
            await txn.update(
              'products',
              {'stock': newStock},
              where: 'id = ?',
              whereArgs: [item.itemId],
            );

            // Record stock movement
            await txn.insert('stock_movements', {
              'productId': item.itemId,
              'type': 'OUT',
              'qty': item.qty,
              'reference': 'Sale $orderNumber',
              'createdAt': now,
            });
          }
        }
      }
    });

    return orderNumber;
  }
}
