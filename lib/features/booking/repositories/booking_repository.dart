
import '../../../core/database/database_helper.dart';
import '../models/booking.dart';

class BookingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Booking>> getBookings() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      orderBy: 'bookingDateTime ASC',
    );
    return maps.map((e) => Booking.fromMap(e)).toList();
  }

  Future<int> insertBooking(Booking booking) async {
    final db = await _dbHelper.database;
    return await db.insert('bookings', booking.toMap());
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await _dbHelper.database;
    return await db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
