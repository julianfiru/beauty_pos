import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../providers/pos_provider.dart';
import '../../payment/screens/qris_dialog.dart';
import 'success_dialog.dart';

class CheckoutDialog extends ConsumerStatefulWidget {
  final double totalAmount;

  const CheckoutDialog({super.key, required this.totalAmount});

  @override
  ConsumerState<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends ConsumerState<CheckoutDialog> {
  double _amountTendered = 0;

  void _addAmount(double amount) {
    setState(() {
      if (_amountTendered == 0 && amount == widget.totalAmount) {
        _amountTendered = amount;
      } else {
        _amountTendered += amount;
      }
    });
  }

  void _setExactAmount() {
    setState(() {
      _amountTendered = widget.totalAmount;
    });
  }

  void _clearAmount() {
    setState(() {
      _amountTendered = 0;
    });
  }

  Future<void> _processPayment() async {
    final changeAmount = _amountTendered - widget.totalAmount;
    final repo = ref.read(posRepositoryProvider);
    final items = ref.read(cartProvider);

    try {
      final orderNumber = await repo.processCheckout(
        items: items,
        totalAmount: widget.totalAmount,
        amountTendered: _amountTendered,
        changeAmount: changeAmount,
      );

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => SuccessDialog(
            orderNumber: orderNumber,
            changeAmount: changeAmount,
            totalAmount: widget.totalAmount,
            amountTendered: _amountTendered,
            items: items,
            paymentMethod: 'TUNAI',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _amountTendered - widget.totalAmount;
    final isEnough = _amountTendered >= widget.totalAmount;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pembayaran Kasir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Amount Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Tagihan', style: TextStyle(color: AppColors.primaryDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('Wajib Dibayar', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                  Text(
                    CurrencyFormat.toIdr(widget.totalAmount),
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Amount Tendered & Change Row
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Uang Diterima', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Row(
                        children: [
                          Text(
                            CurrencyFormat.toIdr(_amountTendered),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                          ),
                          if (_amountTendered > 0) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _clearAmount,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.refresh, size: 18, color: AppColors.error),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(
                        change < 0 ? 'Rp 0' : CurrencyFormat.toIdr(change),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: change < 0 ? AppColors.textMuted : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Quick preset chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton('Uang Pas', _setExactAmount, isHighlight: true),
                _buildPresetButton('+10.000', () => _addAmount(10000)),
                _buildPresetButton('+20.000', () => _addAmount(20000)),
                _buildPresetButton('+50.000', () => _addAmount(50000)),
                _buildPresetButton('+100.000', () => _addAmount(100000)),
              ],
            ),
            const SizedBox(height: 28),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => QrisDialog(totalAmount: widget.totalAmount),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                    label: const Text('Pakai QRIS'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnough ? AppColors.success : Colors.grey[300],
                        foregroundColor: isEnough ? Colors.white : Colors.grey[600],
                      ),
                      onPressed: isEnough ? _processPayment : null,
                      child: const Text('Bayar Tunai'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap, {bool isHighlight = false}) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.secondary.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isHighlight ? AppColors.secondaryDark.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isHighlight ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
