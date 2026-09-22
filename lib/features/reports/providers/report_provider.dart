import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

class ReportNotifier extends StateNotifier<AsyncValue<ReportSummary>> {
  final ReportRepository repository;
  DateRangePreset _preset = DateRangePreset.last7Days;
  DateTimeRange? _customRange;

  DateRangePreset get preset => _preset;
  DateTimeRange? get customRange => _customRange;

  ReportNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadReport();
  }

  Future<void> selectPreset(DateRangePreset preset) async {
    _preset = preset;
    if (preset != DateRangePreset.custom) {
      _customRange = null;
    }
    await loadReport();
  }

  Future<void> selectCustomRange(DateTimeRange range) async {
    _preset = DateRangePreset.custom;
    _customRange = range;
    await loadReport();
  }

  Future<void> loadReport() async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime start;
      DateTime end = today;
      String label;

      switch (_preset) {
        case DateRangePreset.last7Days:
          start = today.subtract(const Duration(days: 6));
          label = '7 Hari Terakhir';
          break;
        case DateRangePreset.last30Days:
          start = today.subtract(const Duration(days: 29));
          label = '30 Hari Terakhir';
          break;
        case DateRangePreset.thisMonth:
          start = DateTime(now.year, now.month, 1);
          label = 'Bulan Ini (${DateFormat('MMMM yyyy').format(now)})';
          break;
        case DateRangePreset.custom:
          if (_customRange != null) {
            start = DateTime(_customRange!.start.year, _customRange!.start.month, _customRange!.start.day);
            end = DateTime(_customRange!.end.year, _customRange!.end.month, _customRange!.end.day);
            label = '${DateFormat('d MMM yyyy').format(start)} - ${DateFormat('d MMM yyyy').format(end)}';
          } else {
            start = today.subtract(const Duration(days: 6));
            label = '7 Hari Terakhir';
          }
          break;
      }

      final summary = await repository.getReportSummary(
        startDate: start,
        endDate: end,
        rangeLabel: label,
        preset: _preset,
      );
      state = AsyncValue.data(summary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<ReportSummary>>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return ReportNotifier(repository);
});
