import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/flat_badge.dart';
import '../../../core/widgets/interactive_card.dart';
import '../providers/report_provider.dart';
import '../repositories/report_repository.dart';
import '../services/export_service.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  // 0: Grafik Tren Visual, 1: Tabel Data Terstruktur
  int _activeViewIndex = 0;

  static const List<String> _daysIndo = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];

  String _getDayName(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return '-';
    return _daysIndo[d.weekday % 7];
  }

  Future<void> _pickCustomDateRange(ReportSummary summary) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: summary.startDate, end: summary.endDate),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(reportProvider.notifier).selectCustomRange(picked);
    }
  }

  Future<void> _exportReport(String type, ReportSummary summary) async {
    try {
      if (type == 'pdf') {
        await ExportService.exportPdf(summary);
      } else if (type == 'csv') {
        await ExportService.exportCsv(summary);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengekspor: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan & Analitik'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(reportProvider.notifier).loadReport(),
          ),
          reportState.maybeWhen(
            data: (summary) => PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              onSelected: (value) => _exportReport(value, summary),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart_outlined, size: 18, color: AppColors.success),
                      SizedBox(width: 10),
                      Text('Ekspor Data CSV (Excel)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 10),
                      Text('Ekspor Dokumen PDF'),
                    ],
                  ),
                ),
              ],
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: reportState.when(
        data: (summary) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selector Rentang Tanggal
                _buildDateRangeFilterBar(summary),
                const SizedBox(height: 16),

                // 2. Kartu Metrik Utama (KPI Cards)
                _buildOverviewCards(summary),
                const SizedBox(height: 20),

                // 3. Switcher Tampilan: Grafik Visual vs Tabel Data
                _buildViewModeToggle(summary),
                const SizedBox(height: 14),

                // 4. Konten Utama (Grafik atau Tabel)
                if (_activeViewIndex == 0) ...[
                  _buildRevenueChart(summary),
                  const SizedBox(height: 20),
                  _buildCategoryBreakdown(summary),
                  const SizedBox(height: 20),
                  const Text(
                    'Top 5 Barang & Jasa Terlaris',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _buildTopSellingList(summary.topSellingItems),
                ] else ...[
                  _buildTabularSection(summary),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Terjadi kesalahan memuat data: $e', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(reportProvider.notifier).loadReport(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bar pemilih rentang tanggal (7 Hari, 30 Hari, Bulan Ini, Kustom)
  Widget _buildDateRangeFilterBar(ReportSummary summary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Rentang Waktu Laporan',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${DateFormat('dd/MM/yy').format(summary.startDate)} - ${DateFormat('dd/MM/yy').format(summary.endDate)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: '7 Hari Terakhir',
                  isSelected: summary.preset == DateRangePreset.last7Days,
                  onTap: () => ref.read(reportProvider.notifier).selectPreset(DateRangePreset.last7Days),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: '30 Hari Terakhir',
                  isSelected: summary.preset == DateRangePreset.last30Days,
                  onTap: () => ref.read(reportProvider.notifier).selectPreset(DateRangePreset.last30Days),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Bulan Ini',
                  isSelected: summary.preset == DateRangePreset.thisMonth,
                  onTap: () => ref.read(reportProvider.notifier).selectPreset(DateRangePreset.thisMonth),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: summary.preset == DateRangePreset.custom ? 'Kustom (Terpilih)' : 'Pilih Tanggal...',
                  icon: Icons.calendar_today_outlined,
                  isSelected: summary.preset == DateRangePreset.custom,
                  onTap: () => _pickCustomDateRange(summary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu ringkasan metrik eksekutif
  Widget _buildOverviewCards(ReportSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;

        final cardPeriodRevenue = InteractiveCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Total Omzet (${summary.rangeLabel})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormat.toIdr(summary.totalRevenue),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rata-rata: ${CurrencyFormat.toCompactIdr(summary.weeklyAverage)} / hari',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );

        final cardTransactions = InteractiveCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Transaksi',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.primaryDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '${summary.periodTransactions} Transaksi',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'AOV: ${CurrencyFormat.toCompactIdr(summary.periodTransactions > 0 ? (summary.totalRevenue / summary.periodTransactions) : 0)} / trx',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );

        final cardToday = InteractiveCard(
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Omzet Hari Ini',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppColors.accentPink.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.trending_up_rounded, size: 16, color: AppColors.accentPinkDark),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormat.toIdr(summary.todayRevenue),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accentPinkDark),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.todayTransactions} Transaksi hari ini',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: cardPeriodRevenue),
              const SizedBox(width: 12),
              Expanded(child: cardTransactions),
              const SizedBox(width: 12),
              Expanded(child: cardToday),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardPeriodRevenue),
                  const SizedBox(width: 12),
                  Expanded(child: cardTransactions),
                ],
              ),
              const SizedBox(height: 12),
              cardToday,
            ],
          );
        }
      },
    );
  }

  /// Switcher antara Grafik Visual dan Format Tabel Terstruktur
  Widget _buildViewModeToggle(ReportSummary summary) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewIndex = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeViewIndex == 0 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 16,
                      color: _activeViewIndex == 0 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Grafik Visual',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _activeViewIndex == 0 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeViewIndex = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeViewIndex == 1 ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart_rounded,
                      size: 16,
                      color: _activeViewIndex == 1 ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Format Tabel (CSV)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _activeViewIndex == 1 ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Grafik Tren Omzet dengan adaptasi jumlah hari (7, 14, 30 hari)
  Widget _buildRevenueChart(ReportSummary summary) {
    final data = summary.periodRevenue;
    if (data.isEmpty || data.every((e) => e.totalRevenue == 0)) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 10),
              Text(
                'Belum ada riwayat transaksi pada ${summary.rangeLabel}',
                style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text('Lakukan transaksi kasir untuk melihat grafik omzet',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    final double maxRev = data.map((e) => e.totalRevenue).fold(0.0, (a, b) => a > b ? a : b);
    final double maxY = maxRev > 0 ? (maxRev * 1.25) : 100000;
    final double rawInterval = maxY / 4;
    final double interval = rawInterval > 0 ? rawInterval : 25000;

    final totalDays = data.length;
    final double barWidth = totalDays <= 7
        ? 18.0
        : (totalDays <= 14 ? 12.0 : (totalDays <= 31 ? 7.0 : 5.0));

    final double bottomInterval = totalDays <= 7
        ? 1.0
        : (totalDays <= 14 ? 2.0 : (totalDays <= 31 ? 5.0 : 7.0));

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final date = DateTime.tryParse(item.date) ?? DateTime.now();
      final now = DateTime.now();
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      final isPeak = maxRev > 0 && item.totalRevenue == maxRev;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: item.totalRevenue,
              gradient: LinearGradient(
                colors: isToday
                    ? [AppColors.primary, AppColors.accentPinkDark]
                    : (isPeak
                        ? [AppColors.secondaryDark, AppColors.primary]
                        : [AppColors.primary.withValues(alpha: 0.85), AppColors.secondary.withValues(alpha: 0.65)]),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              width: barWidth,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxY,
                color: const Color(0xFFFBF8F8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormat.toIdr(summary.totalRevenue),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rata-rata: ${CurrencyFormat.toCompactIdr(summary.weeklyAverage)} / hari',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              FlatBadge(
                label: summary.rangeLabel,
                icon: Icons.date_range_outlined,
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                fontSize: 11.5,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF2C2828),
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (groupIndex < 0 || groupIndex >= data.length) return null;
                      final item = data[groupIndex];
                      final date = DateTime.tryParse(item.date) ?? DateTime.now();
                      final dayFull = _daysIndo[date.weekday % 7];
                      return BarTooltipItem(
                        '$dayFull, ${DateFormat('dd MMM').format(date)}\n',
                        const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: '${CurrencyFormat.toIdr(rod.toY)}\n',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          TextSpan(
                            text: '${item.transactionCount} Transaksi',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.w400,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final dateStr = data[index].date;
                          final date = DateTime.tryParse(dateStr) ?? DateTime.now();
                          final now = DateTime.now();
                          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                          final dayShort = _daysIndo[date.weekday % 7].substring(0, 3);

                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (totalDays <= 14)
                                  Text(
                                    dayShort,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                                      color: isToday ? AppColors.primary : AppColors.textSecondary,
                                    ),
                                  ),
                                Text(
                                  '${date.day}/${date.month}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                                    color: isToday ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 64,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value > maxY) return const SizedBox();
                        if (value >= meta.max * 0.98 && value > 0) return const SizedBox();
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              CurrencyFormat.toCompactIdr(value),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  checkToShowHorizontalLine: (val) => val > 0 && val < maxY,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Color(0xFFF1ECEB),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tampilan Tabel Terstruktur yang menjadi basis data CSV
  Widget _buildTabularSection(ReportSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Tabel Rincian Harian
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tabel Rincian Omzet Harian',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.periodRevenue.length} data hari • ${summary.rangeLabel}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _exportReport('csv', summary),
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Unduh CSV'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFFAF6F6)),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  columnSpacing: 22,
                  columns: const [
                    DataColumn(label: Text('No')),
                    DataColumn(label: Text('Tanggal')),
                    DataColumn(label: Text('Hari')),
                    DataColumn(label: Text('Transaksi'), numeric: true),
                    DataColumn(label: Text('Total Omzet'), numeric: true),
                    DataColumn(label: Text('Rata-rata/Trx'), numeric: true),
                  ],
                  rows: [
                    ...summary.periodRevenue.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      final avgTrx =
                          item.transactionCount > 0 ? (item.totalRevenue / item.transactionCount).round() : 0;
                      final isEven = i % 2 == 0;

                      return DataRow(
                        color: WidgetStateProperty.all(isEven ? Colors.white : const Color(0xFFFDFBFB)),
                        cells: [
                          DataCell(Text('${i + 1}')),
                          DataCell(Text(item.date)),
                          DataCell(Text(_getDayName(item.date))),
                          DataCell(Text('${item.transactionCount}')),
                          DataCell(Text(
                            CurrencyFormat.toIdr(item.totalRevenue),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          DataCell(Text(CurrencyFormat.toIdr(avgTrx))),
                        ],
                      );
                    }),
                    // Baris Total Akumulatif
                    DataRow(
                      color: WidgetStateProperty.all(AppColors.primaryLight.withValues(alpha: 0.5)),
                      cells: [
                        const DataCell(Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary))),
                        DataCell(Text(
                          '${summary.periodRevenue.length} Hari',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                        )),
                        const DataCell(Text('-')),
                        DataCell(Text(
                          '${summary.periodTransactions}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        )),
                        DataCell(Text(
                          CurrencyFormat.toIdr(summary.totalRevenue),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        )),
                        DataCell(Text(
                          CurrencyFormat.toIdr(summary.periodTransactions > 0
                              ? (summary.totalRevenue / summary.periodTransactions).round()
                              : 0),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Card Tabel Top Items Terlaris
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tabel Top Barang & Jasa Terlaris',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    FlatBadge(
                      label: '${summary.topSellingItems.length} Item',
                      color: AppColors.primary,
                      backgroundColor: AppColors.primaryLight,
                      fontSize: 11,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (summary.topSellingItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: Text('Belum ada data barang/jasa terjual pada periode ini',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFFAF6F6)),
                    headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    columnSpacing: 22,
                    columns: const [
                      DataColumn(label: Text('Rank')),
                      DataColumn(label: Text('Nama Item')),
                      DataColumn(label: Text('Kategori')),
                      DataColumn(label: Text('Qty Terjual'), numeric: true),
                      DataColumn(label: Text('Total Omzet'), numeric: true),
                      DataColumn(label: Text('Kontribusi'), numeric: true),
                    ],
                    rows: summary.topSellingItems.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final item = entry.value;
                      final isService = item.itemType == 'SERVICE';
                      final pct = summary.totalRevenue > 0
                          ? ((item.totalRevenue / summary.totalRevenue) * 100).toStringAsFixed(1)
                          : '0.0';

                      return DataRow(
                        cells: [
                          DataCell(Text('$rank', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isService
                                    ? AppColors.accentPink.withValues(alpha: 0.3)
                                    : AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isService ? 'Treatment' : 'Produk',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isService ? AppColors.accentPinkDark : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text('${item.totalQty}')),
                          DataCell(Text(CurrencyFormat.toIdr(item.totalRevenue),
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text('$pct%')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Komposisi Penjualan: Treatment vs Produk
  Widget _buildCategoryBreakdown(ReportSummary summary) {
    final totalRevenue = summary.productRevenue + summary.serviceRevenue;
    final productPercent = totalRevenue > 0 ? (summary.productRevenue / totalRevenue) : 0.0;
    final servicePercent = totalRevenue > 0 ? (summary.serviceRevenue / totalRevenue) : 0.0;

    return InteractiveCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Komposisi Penjualan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              FlatBadge(
                label: summary.rangeLabel,
                color: AppColors.textSecondary,
                backgroundColor: AppColors.background,
                fontSize: 11,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: (servicePercent * 100)
                        .toInt()
                        .clamp(totalRevenue > 0 && summary.serviceRevenue > 0 ? 5 : 0, 100),
                    child: Container(color: AppColors.accentPinkDark),
                  ),
                  Expanded(
                    flex: (productPercent * 100)
                        .toInt()
                        .clamp(totalRevenue > 0 && summary.productRevenue > 0 ? 5 : 0, 100),
                    child: Container(color: AppColors.primary),
                  ),
                  if (totalRevenue == 0)
                    Expanded(
                      child: Container(color: AppColors.border),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accentPinkDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Treatment (${(servicePercent * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${summary.serviceQty} sesi • ${CurrencyFormat.toCompactIdr(summary.serviceRevenue)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Produk (${(productPercent * 100).toStringAsFixed(0)}%)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            '${summary.productQty} item • ${CurrencyFormat.toCompactIdr(summary.productRevenue)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Daftar Top 5 Barang & Jasa Terlaris
  Widget _buildTopSellingList(List<TopSellingItem> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Belum ada data barang/jasa terjual', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isService = item.itemType == 'SERVICE';

        return InteractiveCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: index == 0
                      ? AppColors.primary
                      : (index == 1 ? AppColors.secondaryDark : AppColors.background),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index < 2 ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isService
                                ? AppColors.accentPink.withValues(alpha: 0.25)
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isService ? 'Treatment' : 'Produk',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isService ? AppColors.accentPinkDark : AppColors.primary,
                            ),
                          ),
                        ),
                        if (item.totalRevenue > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            CurrencyFormat.toIdr(item.totalRevenue),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              FlatBadge(
                label: '${item.totalQty} Terjual',
                color: AppColors.primary,
                backgroundColor: AppColors.primaryLight,
                fontSize: 12,
              ),
            ],
          ),
        );
      },
    );
  }
}
