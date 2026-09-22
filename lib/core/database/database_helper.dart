import 'dart:io' show Platform, Directory;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('beauty_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    Database db;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      db = await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = join(docDir.path, 'BeautyPOS', filePath);
      
      // Ensure directory exists
      final dir = Directory(join(docDir.path, 'BeautyPOS'));
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      
      db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: _createDB,
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    }

    // Safe migration check for existing databases
    await _ensureServicesImageUrlColumn(db);

    return db;
  }

  Future<void> _ensureServicesImageUrlColumn(Database db) async {
    try {
      final columns = await db.rawQuery('PRAGMA table_info(services)');
      final hasImageUrl = columns.any((col) => col['name'] == 'imageUrl');
      if (!hasImageUrl) {
        await db.execute('ALTER TABLE services ADD COLUMN imageUrl TEXT');
      }
    } catch (e) {
      debugPrint('Error ensuring services imageUrl column: $e');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Products Table (Fisik)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        costPrice REAL NOT NULL,
        stock INTEGER NOT NULL,
        barcode TEXT,
        imageUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 2. Services Table (Jasa Perawatan)
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        durationMinutes INTEGER NOT NULL,
        description TEXT,
        imageUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 3. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderNumber TEXT NOT NULL UNIQUE,
        totalAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        amountTendered REAL,
        changeAmount REAL,
        status TEXT NOT NULL,
        customerName TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 4. Transaction Items Table
    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        itemId INTEGER NOT NULL,
        itemType TEXT NOT NULL,
        itemName TEXT NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions (id) ON DELETE CASCADE
      )
    ''');

    // 5. Bookings Table (Jadwal Treatment)
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerName TEXT NOT NULL,
        customerPhone TEXT NOT NULL,
        serviceId INTEGER NOT NULL,
        serviceName TEXT NOT NULL,
        therapistName TEXT,
        bookingDateTime TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (serviceId) REFERENCES services (id)
      )
    ''');

    // 6. Payments Table (QRIS & Logs)
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId TEXT NOT NULL UNIQUE,
        amount REAL NOT NULL,
        status TEXT NOT NULL,
        qrString TEXT,
        paidAt TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // 7. Stock Movements (Kartu Stok)
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        type TEXT NOT NULL,
        qty INTEGER NOT NULL,
        reference TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // 8. Users & Staff (Multi-Role)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        pin TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // Seed Dummy Data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Seed Products
    await db.insert('products', {
      'name': 'Facial Glow Serum 30ml',
      'category': 'Skincare',
      'price': 185000.0,
      'costPrice': 110000.0,
      'stock': 25,
      'barcode': '8991001',
      'createdAt': now,
    });

    await db.insert('products', {
      'name': 'Hydrating Rose Water Toner',
      'category': 'Skincare',
      'price': 95000.0,
      'costPrice': 55000.0,
      'stock': 40,
      'barcode': '8991002',
      'createdAt': now,
    });

    await db.insert('products', {
      'name': 'Argan Hair Vitamin Oil',
      'category': 'Hair Care',
      'price': 135000.0,
      'costPrice': 80000.0,
      'stock': 15,
      'barcode': '8991003',
      'createdAt': now,
    });

    // Seed Services
    await db.insert('services', {
      'name': 'Signature Facial Glowing',
      'category': 'Facial Treatment',
      'price': 250000.0,
      'durationMinutes': 60,
      'description': 'Pembersihan mendalam, ekstraksi komedo, dan masker glowing.',
      'createdAt': now,
    });

    await db.insert('services', {
      'name': 'Relaxing Body Massage & Scrub',
      'category': 'Spa & Massage',
      'price': 320000.0,
      'durationMinutes': 90,
      'description': 'Pijat relaksasi seluruh tubuh dengan minyak aromaterapi.',
      'createdAt': now,
    });

    await db.insert('services', {
      'name': 'Korean Hair Spa & Blowout',
      'category': 'Hair Treatment',
      'price': 175000.0,
      'durationMinutes': 45,
      'description': 'Nutrisi batang rambut kering dan styling blowout.',
      'createdAt': now,
    });

    // Seed User Admin
    await db.insert('users', {
      'name': 'Owner Salon',
      'role': 'ADMIN',
      'pin': '1234',
      'createdAt': now,
    });

    await db.insert('users', {
      'name': 'Kasir Utama',
      'role': 'CASHIER',
      'pin': '0000',
      'createdAt': now,
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
