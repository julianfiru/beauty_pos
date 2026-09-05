import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/flat_badge.dart';
import '../providers/qris_provider.dart';
import '../services/qris_payment_service.dart';
import '../../pos/providers/pos_provider.dart';
import '../../pos/screens/success_dialog.dart';

class QrisDialog extends ConsumerStatefulWidget {
  final double totalAmount;

  const QrisDialog({super.key, required this.totalAmount});

  @override
  ConsumerState<QrisDialog> createState() => _QrisDialogState();
}

class _QrisDialogState extends ConsumerState<QrisDialog> {
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrisProvider.notifier).generateQr(widget.totalAmount);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _processCompletedTransaction(QrisPaymentSession session) async {
    final repo = ref.read(posRepositoryProvider);
    final items = ref.read(cartProvider);

    try {
      final orderNumber = await repo.processCheckout(
        items: items,
        totalAmount: session.amount,
        amountTendered: session.amount,
        changeAmount: 0,
      );

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(
            orderNumber: orderNumber,
            changeAmount: 0,
            totalAmount: session.amount,
            amountTendered: session.amount,
            items: items,
            paymentMethod: 'QRIS',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencatat transaksi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrisState = ref.watch(qrisProvider);

    ref.listen<AsyncValue<QrisPaymentSession?>>(qrisProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        if (next.value!.status == QrisStatus.PAID) {
          _processCompletedTransaction(next.value!);
        } else if (next.value!.status == QrisStatus.FAILED) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Waktu pembayaran QRIS habis/gagal.'), backgroundColor: AppColors.error),
          );
          Navigator.pop(context);
        }
      }
    });

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QRIS Dinamis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                FlatBadge(
                  label: _formattedTime,
                  icon: Icons.timer_outlined,
                  color: AppColors.error,
                  backgroundColor: AppColors.errorBg,
                  fontSize: 12,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan QR code dengan aplikasi M-Banking atau e-Wallet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            // QR Frame
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: qrisState.when(
                data: (session) {
                  if (session == null) {
                    return const SizedBox(
                      width: 190,
                      height: 190,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return Column(
                    children: [
                      QrImageView(
                        data: session.qrPayload,
                        version: QrVersions.auto,
                        size: 190.0,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.textPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        CurrencyFormat.toIdr(session.amount),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  width: 190,
                  height: 190,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => SizedBox(
                  width: 190,
                  height: 190,
                  child: Center(child: Text('Gagal memuat QR: $e', style: const TextStyle(color: AppColors.error))),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Menunggu pembayaran otomatis...',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Simulator Panel
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Text('Panel Simulator (Pengujian)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => ref.read(qrisProvider.notifier).simulateFailure(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppColors.errorBg),
                          ),
                          child: const Text('Simulasi Gagal', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => ref.read(qrisProvider.notifier).simulateSuccess(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Simulasi Lunas', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batalkan', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
