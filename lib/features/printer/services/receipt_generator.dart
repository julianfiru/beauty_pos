import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/currency_format.dart';
import '../../pos/models/cart_item.dart';

class ReceiptGenerator {
  static Future<List<int>> generateReceiptBytes({
    required String orderNumber,
    required List<CartItem> items,
    required double total,
    required double amountTendered,
    required double change,
    required String paymentMethod,
    bool is80mm = false,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text('BEAUTY POS & CLINIC', styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.text('Jl. Sudirman No. 123, Jakarta', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Telp: 0812-3456-7890', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.emptyLines(1);
    
    // Receipt Info
    bytes += generator.text('No Order : $orderNumber');
    bytes += generator.text('Tanggal  : ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}');
    bytes += generator.text('Kasir    : Admin');
    bytes += generator.emptyLines(1);
    bytes += generator.hr();

    // Items
    for (var item in items) {
      bytes += generator.text(item.name, styles: const PosStyles(bold: true));
      bytes += generator.row([
        PosColumn(
          text: '${item.qty} x ${CurrencyFormat.toIdr(item.price)}',
          width: 6,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: CurrencyFormat.toIdr(item.qty * item.price),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    
    bytes += generator.hr();
    
    // Totals
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: CurrencyFormat.toIdr(total), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    
    bytes += generator.row([
      PosColumn(text: paymentMethod == 'QRIS' ? 'BAYAR (QRIS)' : 'TUNAI', width: 6),
      PosColumn(text: CurrencyFormat.toIdr(amountTendered), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.row([
      PosColumn(text: 'KEMBALI', width: 6),
      PosColumn(text: CurrencyFormat.toIdr(change), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.emptyLines(1);
    bytes += generator.hr(ch: '=');
    bytes += generator.text('Terima Kasih Atas Kunjungan Anda!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Barang yang sudah dibeli', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('tidak dapat ditukar/dikembalikan', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.emptyLines(2);
    bytes += generator.feed(2);
    bytes += generator.cut();
    
    return bytes;
  }
}
