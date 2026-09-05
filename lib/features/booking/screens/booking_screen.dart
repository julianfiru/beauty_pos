import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/flat_badge.dart';
import '../../../core/widgets/interactive_card.dart';
import '../providers/booking_provider.dart';
import 'booking_form_dialog.dart';
import '../../pos/providers/pos_provider.dart';
import '../../catalog/providers/catalog_provider.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(bookingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Jadwal Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(bookingProvider.notifier).loadBookings(),
          ),
        ],
      ),
      body: bookingsState.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Belum ada jadwal booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Klik tombol di bawah untuk membuat booking baru', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final date = DateTime.parse(booking.bookingDateTime);
              final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);

              Color statusColor = AppColors.primary;
              Color statusBg = AppColors.primaryLight;
              if (booking.status == 'PENDING') {
                statusColor = AppColors.primary;
                statusBg = AppColors.primaryLight;
              } else if (booking.status == 'COMPLETED') {
                statusColor = AppColors.success;
                statusBg = AppColors.successBg;
              } else if (booking.status == 'CANCELLED') {
                statusColor = AppColors.error;
                statusBg = AppColors.errorBg;
              }

              return InteractiveCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.calendar_month_outlined, size: 18, color: AppColors.primaryDark),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              formattedDate,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        FlatBadge(
                          label: booking.status,
                          color: statusColor,
                          backgroundColor: statusBg,
                          fontSize: 11,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    booking.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${booking.customerPhone})',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.spa_outlined, size: 16, color: AppColors.accentPinkDark),
                                  const SizedBox(width: 6),
                                  Text(
                                    booking.serviceName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                                  ),
                                  if (booking.therapistName != null && booking.therapistName!.isNotEmpty) ...[
                                    Text(' • Terapis: ${booking.therapistName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ],
                              ),
                              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Catatan: ${booking.notes}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (booking.status == 'PENDING') ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => _updateStatus(context, ref, booking, 'CANCELLED'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              side: const BorderSide(color: AppColors.errorBg),
                            ),
                            child: const Text('Batalkan', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _completeAndPay(context, ref, booking),
                            icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                            label: const Text('Selesai & Bayar', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (_) => const BookingFormDialog());
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Booking Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, booking, String status) {
    final updated = booking.copyWith(status: status);
    ref.read(bookingProvider.notifier).updateBooking(updated);
  }

  Future<void> _completeAndPay(BuildContext context, WidgetRef ref, booking) async {
    _updateStatus(context, ref, booking, 'COMPLETED');

    final servicesAsync = ref.read(servicesProvider);
    if (servicesAsync is AsyncData) {
      final services = servicesAsync.value!;
      try {
        final serviceItem = services.firstWhere((s) => s.id == booking.serviceId);
        ref.read(cartProvider.notifier).addService(serviceItem);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${booking.serviceName} dimasukkan ke keranjang Kasir!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menemukan jasa di katalog!'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
