
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';

class DailyRevenue {
  final String date;
  final double totalRevenue;
  final int transactionCount;

  DailyRevenue(this.date, this.totalRevenue, {this.transactionCount = 0});
}

class TopSellingItem {
  final String name;
  final int totalQty;
  final String itemType;
  final double totalRevenue;

  TopSellingItem(
    this.name,
    this.totalQty, {
    this.itemType = 'PRODUCT',
    this.totalRevenue = 0.0,
  });
}

enum DateRangePreset {
  last7Days('7 Hari'),
  last30Days('30 Hari'),
  thisMonth('Bulan Ini'),
  custom('Kustom');

  final String label;
  const DateRangePreset(this.label);
}

class ReportSummary {
  final DateRangePreset preset;
  final DateTime startDate;
  final DateTime endDate;
  final String rangeLabel;
  final double todayRevenue;
  final int todayTransactions;
  final int periodTransactions;
  final List<DailyRevenue> periodRevenue;
  final List<TopSellingItem> topSellingItems;
  final double productRevenue;
  final double serviceRevenue;
  final int productQty;
  final int serviceQty;

  ReportSummary({
    this.preset = DateRangePreset.last7Days,
    required this.startDate,
    required this.endDate,
    required this.rangeLabel,
    required this.todayRevenue,
    required this.todayTransactions,
    required this.periodTransactions,
    required this.periodRevenue,
    required this.topSellingItems,
    this.productRevenue = 0.0,
    this.serviceRevenue = 0.0,
    this.productQty = 0,
    this.serviceQty = 0,
  });

  // Backward compatibility getters
  List<DailyRevenue> get last7DaysRevenue => periodRevenue;
  double get weeklyTotal => periodRevenue.fold(0.0, (sum, e) => sum + e.totalRevenue);
  double get totalRevenue => weeklyTotal;
  double get weeklyAverage => periodRevenue.isEmpty ? 0.0 : (weeklyTotal / periodRevenue.length);
  DailyRevenue get peakDay => periodRevenue.isEmpty
      ? DailyRevenue('', 0.0)
      : periodRevenue.reduce((a, b) => a.totalRevenue >= b.totalRevenue ? a : b);
}

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ReportSummary> getReportSummary({
    DateTime? startDate,
    DateTime? endDate,
    String? rangeLabel,
    DateRangePreset preset = DateRangePreset.last7Days,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final end = endDate ?? DateTime(now.year, now.month, now.day);
    final start = startDate ?? end.subtract(const Duration(days: 6));
    final label = rangeLabel ??
        (startDate == null && endDate == null
            ? '7 Hari Terakhir'
            : '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}');

    // 1. Today's Revenue and Transaction Count
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayResult = await db.rawQuery('''
      SELECT COUNT(id) as trx_count, SUM(totalAmount) as total_revenue
      FROM transactions
      WHERE date(createdAt) = ?
    ''', [todayStr]);

    int todayTrx = todayResult.first['trx_count'] as int? ?? 0;
    double todayRev = (todayResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // 2. Period Revenue and Transactions (day by day)
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);

    final periodResult = await db.rawQuery('''
      SELECT date(createdAt) as order_date, COUNT(id) as daily_trx, SUM(totalAmount) as daily_revenue
      FROM transactions
      WHERE date(createdAt) >= ? AND date(createdAt) <= ?
      GROUP BY date(createdAt)
      ORDER BY date(createdAt) ASC
    ''', [startStr, endStr]);

    // Fill all days between start and end
    final daysCount = end.difference(start).inDays + 1;
    Map<String, Map<String, dynamic>> dailyMap = {};
    for (int i = 0; i < daysCount; i++) {
      final d = start.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(d);
      dailyMap[dateStr] = {
        'revenue': 0.0,
        'trx': 0,
      };
    }

    int totalPeriodTrx = 0;
    for (var row in periodResult) {
      final date = row['order_date'] as String;
      final rev = (row['daily_revenue'] as num?)?.toDouble() ?? 0.0;
      final trx = (row['daily_trx'] as num?)?.toInt() ?? 0;
      dailyMap[date] = {
        'revenue': rev,
        'trx': trx,
      };
      totalPeriodTrx += trx;
    }

    List<DailyRevenue> periodDays = dailyMap.entries
        .map((e) => DailyRevenue(
              e.key,
              (e.value['revenue'] as num).toDouble(),
              transactionCount: (e.value['trx'] as num).toInt(),
            ))
        .toList();
    periodDays.sort((a, b) => a.date.compareTo(b.date));

    // 3. Top Selling Items within the period
    final topSellingResult = await db.rawQuery('''
      SELECT ti.itemName, ti.itemType, SUM(ti.qty) as total_qty, SUM(ti.subtotal) as total_revenue
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionId = t.id
      WHERE date(t.createdAt) >= ? AND date(t.createdAt) <= ?
      GROUP BY ti.itemName, ti.itemType
      ORDER BY total_qty DESC
      LIMIT 5
    ''', [startStr, endStr]);

    List<TopSellingItem> topItems = topSellingResult
        .map((e) => TopSellingItem(
              e['itemName'] as String,
              (e['total_qty'] as num).toInt(),
              itemType: (e['itemType'] as String?) ?? 'PRODUCT',
              totalRevenue: (e['total_revenue'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();

    // 4. Breakdown: Product vs Service within the period
    final categoryResult = await db.rawQuery('''
      SELECT ti.itemType, SUM(ti.subtotal) as type_revenue, SUM(ti.qty) as type_qty
      FROM transaction_items ti
      JOIN transactions t ON ti.transactionId = t.id
      WHERE date(t.createdAt) >= ? AND date(t.createdAt) <= ?
      GROUP BY ti.itemType
    ''', [startStr, endStr]);

    double prodRev = 0.0;
    double servRev = 0.0;
    int prodQty = 0;
    int servQty = 0;

    for (var row in categoryResult) {
      final type = row['itemType'] as String?;
      final rev = (row['type_revenue'] as num?)?.toDouble() ?? 0.0;
      final qty = (row['type_qty'] as num?)?.toInt() ?? 0;
      if (type == 'PRODUCT') {
        prodRev = rev;
        prodQty = qty;
      } else if (type == 'SERVICE') {
        servRev = rev;
        servQty = qty;
      }
    }

    return ReportSummary(
      preset: preset,
      startDate: start,
      endDate: end,
      rangeLabel: label,
      todayRevenue: todayRev,
      todayTransactions: todayTrx,
      periodTransactions: totalPeriodTrx,
      periodRevenue: periodDays,
      topSellingItems: topItems,
      productRevenue: prodRev,
      serviceRevenue: servRev,
      productQty: prodQty,
      serviceQty: servQty,
    );
  }
}
