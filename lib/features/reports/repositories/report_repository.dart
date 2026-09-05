
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';

class DailyRevenue {
  final String date;
  final double totalRevenue;

  DailyRevenue(this.date, this.totalRevenue);
}

class TopSellingItem {
  final String name;
  final int totalQty;

  TopSellingItem(this.name, this.totalQty);
}

class ReportSummary {
  final double todayRevenue;
  final int todayTransactions;
  final List<DailyRevenue> last7DaysRevenue;
  final List<TopSellingItem> topSellingItems;

  ReportSummary({
    required this.todayRevenue,
    required this.todayTransactions,
    required this.last7DaysRevenue,
    required this.topSellingItems,
  });
}

class ReportRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<ReportSummary> getReportSummary() async {
    final db = await _dbHelper.database;
    
    // 1. Today's Revenue and Transaction Count
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayResult = await db.rawQuery('''
      SELECT COUNT(id) as trx_count, SUM(totalAmount) as total_revenue
      FROM transactions
      WHERE date(createdAt) = ?
    ''', [todayStr]);

    int todayTrx = todayResult.first['trx_count'] as int? ?? 0;
    double todayRev = (todayResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;

    // 2. Last 7 Days Revenue
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 6));
    final sevenDaysAgoStr = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

    final weeklyResult = await db.rawQuery('''
      SELECT date(createdAt) as order_date, SUM(totalAmount) as daily_revenue
      FROM transactions
      WHERE date(createdAt) >= ?
      GROUP BY date(createdAt)
      ORDER BY date(createdAt) ASC
    ''', [sevenDaysAgoStr]);

    // Fill missing days with 0
    Map<String, double> revenueMap = {};
    for (int i = 0; i < 7; i++) {
      final date = sevenDaysAgo.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      revenueMap[dateStr] = 0.0;
    }

    for (var row in weeklyResult) {
      final date = row['order_date'] as String;
      final rev = (row['daily_revenue'] as num?)?.toDouble() ?? 0.0;
      revenueMap[date] = rev;
    }

    List<DailyRevenue> last7Days = revenueMap.entries
        .map((e) => DailyRevenue(e.key, e.value))
        .toList();
    last7Days.sort((a, b) => a.date.compareTo(b.date));

    // 3. Top Selling Items (Products and Services combined from order_items)
    final topSellingResult = await db.rawQuery('''
      SELECT itemName, SUM(qty) as total_qty
      FROM transaction_items
      GROUP BY itemName
      ORDER BY total_qty DESC
      LIMIT 5
    ''');

    List<TopSellingItem> topItems = topSellingResult
        .map((e) => TopSellingItem(e['itemName'] as String, e['total_qty'] as int))
        .toList();

    return ReportSummary(
      todayRevenue: todayRev,
      todayTransactions: todayTrx,
      last7DaysRevenue: last7Days,
      topSellingItems: topItems,
    );
  }
}
