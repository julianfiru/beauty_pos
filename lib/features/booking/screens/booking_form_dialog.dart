import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';

class BookingFormDialog extends ConsumerStatefulWidget {
  const BookingFormDialog({super.key});

  @override
  ConsumerState<BookingFormDialog> createState() => _BookingFormDialogState();
}

class _BookingFormDialogState extends ConsumerState<BookingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _therapistNameController = TextEditingController();
  final _notesController = TextEditingController();

  int? _selectedServiceId;
  String? _selectedServiceName;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _therapistNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveBooking() {
    if (_formKey.currentState!.validate()) {
      if (_selectedServiceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih jasa treatment')),
        );
        return;
      }

      final bookingDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final newBooking = Booking(
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        serviceId: _selectedServiceId!,
        serviceName: _selectedServiceName!,
        therapistName: _therapistNameController.text.trim().isEmpty ? null : _therapistNameController.text.trim(),
        bookingDateTime: bookingDateTime.toIso8601String(),
        status: 'PENDING',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );

      ref.read(bookingProvider.notifier).addBooking(newBooking);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buat Booking Baru',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _customerNameController,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan', prefixIcon: Icon(Icons.person_outline, size: 20)),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerPhoneController,
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                servicesAsync.when(
                  data: (services) {
                    return DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Pilih Jasa Treatment', prefixIcon: Icon(Icons.spa_outlined, size: 20)),
                      initialValue: _selectedServiceId,
                      items: services.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.id,
                          child: Text('${s.name} (${s.durationMinutes} mnt)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedServiceId = val;
                          _selectedServiceName = services.firstWhere((s) => s.id == val).name;
                        });
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Gagal memuat jasa'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _therapistNameController,
                  decoration: const InputDecoration(labelText: 'Nama Terapis / Stylist (Opsional)', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_outlined, size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Catatan Khusus (Opsional)', prefixIcon: Icon(Icons.note_alt_outlined, size: 20)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveBooking,
                    child: const Text('Simpan Jadwal Booking'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
