import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../repositories/report_repository.dart';
import '../../../core/utils/currency_format.dart';

class ExportService {
  static const List<String> _daysIndo = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  static String _getDayName(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '-';
    return _daysIndo[d.weekday % 7];
  }

  /// Ekspor dokumen PDF dengan format tabel yang rapi dan profesional
  static Future<void> exportPdf(ReportSummary summary) async {
    final pdf = pw.Document();

    final dateRangeFormatted =
        '${DateFormat('dd/MM/yyyy').format(summary.startDate)} - ${DateFormat('dd/MM/yyyy').format(summary.endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            // Header Dokumen
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LAPORAN PENJUALAN & ANALITIK',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.pink900)),
                    pw.SizedBox(height: 2),
                    pw.Text('BeautyPOS Salon & Clinic',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Periode: ${summary.rangeLabel}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Rentang: $dateRangeFormatted',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Dicetak: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.pink200),
            pw.SizedBox(height: 12),

            // Ringkasan Eksekutif
            pw.Text('Ringkasan Eksekutif', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: <String>['Indikator', 'Nilai', 'Keterangan'],
              data: <List<String>>[
                ['Total Omzet Periode', CurrencyFormat.toIdr(summary.totalRevenue), 'Total penjualan kotor'],
                ['Total Transaksi', '${summary.periodTransactions}', 'Jumlah pesanan / transaksi selesai'],
                ['Rata-rata Omzet / Hari', CurrencyFormat.toIdr(summary.weeklyAverage), 'Rata-rata harian'],
                [
                  'Rata-rata / Transaksi (AOV)',
                  CurrencyFormat.toIdr(summary.periodTransactions > 0 ? (summary.totalRevenue / summary.periodTransactions) : 0),
                  'Nilai belanja rata-rata per transaksi'
                ],
                ['Omzet Treatment (Jasa)', CurrencyFormat.toIdr(summary.serviceRevenue), '${summary.serviceQty} sesi layanan'],
                ['Omzet Penjualan Produk', CurrencyFormat.toIdr(summary.productRevenue), '${summary.productQty} pcs item produk'],
                ['Omzet Hari Ini', CurrencyFormat.toIdr(summary.todayRevenue), '${summary.todayTransactions} transaksi hari ini'],
              ],
            ),
            pw.SizedBox(height: 18),

            // Tabel Rincian Omzet Harian
            pw.Text('Tabel Rincian Omzet Harian', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.TableHelper.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.pink800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              headers: <String>['No', 'Tanggal', 'Hari', 'Transaksi', 'Omzet (Rp)', 'Rata-rata / Trx (Rp)'],
              data: <List<String>>[
                ...summary.periodRevenue.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final avgTrx = item.transactionCount > 0 ? (item.totalRevenue / item.transactionCount) : 0.0;
                  return [
                    '${i + 1}',
                    item.date,
                    _getDayName(item.date),
                    '${item.transactionCount}',
                    CurrencyFormat.toIdr(item.totalRevenue),
                    CurrencyFormat.toIdr(avgTrx),
                  ];
                }),
                // Total Row
                [
                  'TOTAL',
                  summary.rangeLabel,
                  '-',
                  '${summary.periodTransactions}',
                  CurrencyFormat.toIdr(summary.totalRevenue),
                  CurrencyFormat.toIdr(summary.periodTransactions > 0 ? (summary.totalRevenue / summary.periodTransactions) : 0),
                ],
              ],
            ),
            pw.SizedBox(height: 18),

            // Tabel Top 5 Barang & Jasa Terlaris
            pw.Text('Top Barang & Jasa Terlaris', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            if (summary.topSellingItems.isEmpty)
              pw.Text('Tidak ada item terjual dalam periode ini.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
            else
              pw.TableHelper.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.pink800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                headers: <String>['Peringkat', 'Nama Item', 'Tipe', 'Qty Terjual', 'Total Omzet (Rp)', 'Kontribusi'],
                data: <List<String>>[
                  ...summary.topSellingItems.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final item = entry.value;
                    final pct = summary.totalRevenue > 0
                        ? ((item.totalRevenue / summary.totalRevenue) * 100).toStringAsFixed(1)
                        : '0.0';
                    return [
                      '$rank',
                      item.name,
                      item.itemType == 'SERVICE' ? 'Treatment' : 'Produk',
                      '${item.totalQty}',
                      CurrencyFormat.toIdr(item.totalRevenue),
                      '$pct%',
                    ];
                  }),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'laporan_beautypos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')],
        text: 'Laporan PDF BeautyPOS',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan PDF BeautyPOS');
    }
  }

  /// Ekspor CSV dengan landasan tabel formatting yang baku, konsisten, dan kompatibel dengan Excel / Google Sheets
  static Future<void> exportCsv(ReportSummary summary) async {
    List<List<dynamic>> rows = [];

    // ==========================================
    // 1. INFORMASI METADATA LAPORAN
    // ==========================================
    rows.add(['LAPORAN PENJUALAN & ANALITIK BEAUTYPOS']);
    rows.add(['Periode Laporan', summary.rangeLabel]);
    rows.add([
      'Rentang Tanggal',
      '${DateFormat('yyyy-MM-dd').format(summary.startDate)} s/d ${DateFormat('yyyy-MM-dd').format(summary.endDate)}'
    ]);
    rows.add(['Waktu Ekspor', DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())]);
    rows.add([]); // Baris kosong pemisah

    // ==========================================
    // 2. TABEL RINGKASAN EKSEKUTIF
    // ==========================================
    rows.add(['RINGKASAN EKSEKUTIF']);
    rows.add(['Indikator', 'Nilai', 'Keterangan']);
    rows.add(['Total Omzet Periode', summary.totalRevenue, 'Total pendapatan kotor selama periode']);
    rows.add(['Total Transaksi Selesai', summary.periodTransactions, 'Jumlah transaksi berhasil']);
    rows.add(['Rata-rata Omzet / Hari', summary.weeklyAverage.round(), 'Rata-rata pendapatan per hari']);
    rows.add([
      'Rata-rata Nilai Transaksi (AOV)',
      summary.periodTransactions > 0 ? (summary.totalRevenue / summary.periodTransactions).round() : 0,
      'Nilai belanja rata-rata per transaksi'
    ]);
    rows.add(['Omzet Treatment (Jasa)', summary.serviceRevenue, '${summary.serviceQty} sesi perawatan']);
    rows.add(['Omzet Penjualan Produk', summary.productRevenue, '${summary.productQty} item produk']);
    rows.add(['Omzet Hari Ini', summary.todayRevenue, '${summary.todayTransactions} transaksi pada tanggal hari ini']);
    rows.add([]); // Baris kosong pemisah

    // ==========================================
    // 3. TABEL RINCIAN OMZET HARIAN
    // ==========================================
    rows.add(['TABEL RINCIAN OMZET HARIAN']);
    rows.add(['No', 'Tanggal', 'Hari', 'Jumlah Transaksi', 'Total Omzet (Rp)', 'Rata-rata / Transaksi (Rp)']);

    for (int i = 0; i < summary.periodRevenue.length; i++) {
      final item = summary.periodRevenue[i];
      final avgTrx = item.transactionCount > 0 ? (item.totalRevenue / item.transactionCount).round() : 0;

      rows.add([
        i + 1,
        item.date,
        _getDayName(item.date),
        item.transactionCount,
        item.totalRevenue,
        avgTrx,
      ]);
    }

    // Baris Total Ringkasan Harian
    final avgTotalTrx = summary.periodTransactions > 0 ? (summary.totalRevenue / summary.periodTransactions).round() : 0;
    rows.add([
      'TOTAL',
      '${DateFormat('yyyy-MM-dd').format(summary.startDate)} s/d ${DateFormat('yyyy-MM-dd').format(summary.endDate)}',
      '-',
      summary.periodTransactions,
      summary.totalRevenue,
      avgTotalTrx,
    ]);
    rows.add([]); // Baris kosong pemisah

    // ==========================================
    // 4. TABEL TOP BARANG & JASA TERLARIS
    // ==========================================
    rows.add(['TABEL TOP PRODUK & JASA TERLARIS']);
    rows.add(['Peringkat', 'Nama Item', 'Tipe Item', 'Jumlah Terjual', 'Total Penjualan (Rp)', 'Kontribusi Omzet (%)']);

    int sumTopQty = 0;
    double sumTopRevenue = 0.0;

    for (int j = 0; j < summary.topSellingItems.length; j++) {
      final it = summary.topSellingItems[j];
      sumTopQty += it.totalQty;
      sumTopRevenue += it.totalRevenue;

      final contributionPct = summary.totalRevenue > 0
          ? ((it.totalRevenue / summary.totalRevenue) * 100).toStringAsFixed(1)
          : '0.0';

      rows.add([
        j + 1,
        it.name,
        it.itemType == 'SERVICE' ? 'Treatment / Jasa' : 'Produk',
        it.totalQty,
        it.totalRevenue,
        '$contributionPct%',
      ]);
    }

    // Baris Total Top Items
    if (summary.topSellingItems.isNotEmpty) {
      final topContrib = summary.totalRevenue > 0
          ? ((sumTopRevenue / summary.totalRevenue) * 100).toStringAsFixed(1)
          : '0.0';
      rows.add(['TOTAL TOP ITEM', '-', '-', sumTopQty, sumTopRevenue, '$topContrib%']);
    }

    // Konversi ke string CSV
    final csvString = const ListToCsvConverter().convert(rows);

    // Prepend UTF-8 BOM (\uFEFF) agar Microsoft Excel di Windows membuka karakter dengan benar
    final bytes = utf8.encode('\uFEFF$csvString');
    final filename = 'laporan_beautypos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), name: filename, mimeType: 'text/csv')],
        text: 'Laporan CSV BeautyPOS',
      );
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan CSV BeautyPOS');
    }
  }
}
