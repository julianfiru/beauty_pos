import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/flat_badge.dart';
import '../../printer/providers/printer_provider.dart';
import '../../printer/services/receipt_generator.dart';
import '../models/cart_item.dart';

class SuccessDialog extends ConsumerWidget {
  final String orderNumber;
  final double changeAmount;
  final double totalAmount;
  final double amountTendered;
  final List<CartItem> items;
  final String paymentMethod;

  const SuccessDialog({
    super.key,
    required this.orderNumber,
    required this.changeAmount,
    required this.totalAmount,
    required this.amountTendered,
    required this.items,
    this.paymentMethod = 'TUNAI',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final printerState = ref.watch(printerProvider);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              FlatBadge(
                label: 'Order #$orderNumber • $paymentMethod',
                color: AppColors.textSecondary,
                backgroundColor: AppColors.background,
                fontSize: 12,
              ),
              const SizedBox(height: 20),
              // Change Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text('Uang Kembalian', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        CurrencyFormat.toIdr(changeAmount),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Selesai'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: printerState.value?.isConnected == true
                        ? () async {
                            final bytes = await ReceiptGenerator.generateReceiptBytes(
                              orderNumber: orderNumber,
                              items: items,
                              total: totalAmount,
                              amountTendered: amountTendered,
                              change: changeAmount,
                              paymentMethod: paymentMethod,
                            );
                            final success = await ref.read(printerServiceProvider).printBytes(bytes);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Struk berhasil dicetak!' : 'Gagal mencetak struk.'),
                                  backgroundColor: success ? AppColors.success : AppColors.error,
                                ),
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Cetak Struk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
            if (printerState.value?.isConnected != true) ...[
              const SizedBox(height: 12),
              const Text(
                'Printer belum terhubung di Pengaturan',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}
