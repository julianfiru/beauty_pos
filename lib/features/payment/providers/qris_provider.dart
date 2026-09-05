import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/qris_payment_service.dart';

final qrisServiceProvider = Provider((ref) => QrisPaymentService());

class QrisNotifier extends StateNotifier<AsyncValue<QrisPaymentSession?>> {
  final QrisPaymentService _service;
  Timer? _pollingTimer;

  QrisNotifier(this._service) : super(const AsyncValue.data(null));

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> generateQr(double amount) async {
    state = const AsyncValue.loading();
    try {
      final session = await _service.generateQris(amount: amount);
      state = AsyncValue.data(session);
      _startPolling(session.orderId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startPolling(String orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final status = await _service.checkStatus(orderId);
      
      if (state is AsyncData && state.value != null) {
        final currentSession = state.value!;
        // Update the state if status changed
        if (currentSession.status != status) {
          currentSession.status = status;
          // Trigger rebuild
          state = AsyncValue.data(QrisPaymentSession(
            orderId: currentSession.orderId,
            amount: currentSession.amount,
            qrPayload: currentSession.qrPayload,
            expiresAt: currentSession.expiresAt,
            status: status,
          ));
        }

        if (status == QrisStatus.PAID || status == QrisStatus.FAILED) {
          timer.cancel();
        }
      }
    });
  }

  void simulateSuccess() {
    if (state is AsyncData && state.value != null) {
      final current = state.value!;
      _service.simulatePaymentSuccess(current.orderId);
      _pollingTimer?.cancel();
      state = AsyncValue.data(QrisPaymentSession(
        orderId: current.orderId,
        amount: current.amount,
        qrPayload: current.qrPayload,
        expiresAt: current.expiresAt,
        status: QrisStatus.PAID,
      ));
    }
  }

  void simulateFailure() {
    if (state is AsyncData && state.value != null) {
      final current = state.value!;
      _service.simulatePaymentFailed(current.orderId);
      _pollingTimer?.cancel();
      state = AsyncValue.data(QrisPaymentSession(
        orderId: current.orderId,
        amount: current.amount,
        qrPayload: current.qrPayload,
        expiresAt: current.expiresAt,
        status: QrisStatus.FAILED,
      ));
    }
  }
}

final qrisProvider = StateNotifierProvider<QrisNotifier, AsyncValue<QrisPaymentSession?>>((ref) {
  final service = ref.watch(qrisServiceProvider);
  return QrisNotifier(service);
});
