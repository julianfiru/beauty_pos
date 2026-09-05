import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking.dart';
import '../repositories/booking_repository.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final BookingRepository repository;

  BookingNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await repository.getBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBooking(Booking booking) async {
    try {
      await repository.insertBooking(booking);
      await loadBookings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBooking(Booking booking) async {
    try {
      await repository.updateBooking(booking);
      await loadBookings();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBooking(int id) async {
    try {
      await repository.deleteBooking(id);
      await loadBookings();
    } catch (e) {
      rethrow;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<Booking>>>((ref) {
  final repository = ref.watch(bookingRepositoryProvider);
  return BookingNotifier(repository);
});
