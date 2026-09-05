import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/report_repository.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

class ReportNotifier extends StateNotifier<AsyncValue<ReportSummary>> {
  final ReportRepository repository;

  ReportNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = const AsyncValue.loading();
    try {
      final summary = await repository.getReportSummary();
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
