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
  static Future<void> exportPdf(ReportSummary summary) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Laporan BeautyPOS', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Tanggal Cetak: ${DateFormat('dd MMMM yyyy HH:mm').format(DateTime.now())}'),
              pw.SizedBox(height: 24),
              
              pw.Text('Ringkasan Hari Ini', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.Text('Total Pendapatan: ${CurrencyFormat.toIdr(summary.todayRevenue)}'),
              pw.Text('Total Transaksi: ${summary.todayTransactions}'),
              pw.SizedBox(height: 24),
              
              pw.Text('Tren Omzet 7 Hari Terakhir', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Tanggal', 'Omzet'],
                  ...summary.last7DaysRevenue.map((item) => [
                    item.date,
                    CurrencyFormat.toIdr(item.totalRevenue),
                  ]),
                ],
              ),
              pw.SizedBox(height: 24),
              
              pw.Text('Top 5 Barang/Jasa Terlaris', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Divider(),
              pw.TableHelper.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Nama Item', 'Jumlah Terjual'],
                  ...summary.topSellingItems.map((item) => [
                    item.name,
                    '${item.totalQty}',
                  ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final filename = 'laporan_beautypos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    
    if (kIsWeb) {
      await Share.shareXFiles([XFile.fromData(bytes, name: filename, mimeType: 'application/pdf')], text: 'Laporan PDF BeautyPOS');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan PDF BeautyPOS');
    }
  }

  static Future<void> exportCsv(ReportSummary summary) async {
    List<List<dynamic>> rows = [];
    
    // Header Info
    rows.add(['LAPORAN BEAUTYPOS']);
    rows.add(['Dicetak pada:', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())]);
    rows.add([]);
    
    // Summary
    rows.add(['RINGKASAN HARI INI']);
    rows.add(['Pendapatan', summary.todayRevenue]);
    rows.add(['Transaksi', summary.todayTransactions]);
    rows.add([]);
    
    // 7 Days
    rows.add(['TREN OMZET 7 HARI']);
    rows.add(['Tanggal', 'Omzet']);
    for (var r in summary.last7DaysRevenue) {
      rows.add([r.date, r.totalRevenue]);
    }
    rows.add([]);
    
    // Top Items
    rows.add(['TOP SELLING ITEMS']);
    rows.add(['Nama Item', 'Terjual']);
    for (var i in summary.topSellingItems) {
      rows.add([i.name, i.totalQty]);
    }

    String csvString = const ListToCsvConverter().convert(rows);
    final bytes = csvString.codeUnits;
    final filename = 'laporan_beautypos_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    
    if (kIsWeb) {
      await Share.shareXFiles([XFile.fromData(Uint8List.fromList(bytes), name: filename, mimeType: 'text/csv')], text: 'Laporan CSV BeautyPOS');
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsString(csvString);
      await Share.shareXFiles([XFile(file.path)], text: 'Laporan CSV BeautyPOS');
    }
  }
}
