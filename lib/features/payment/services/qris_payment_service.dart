import 'dart:async';
import 'package:uuid/uuid.dart';

enum QrisStatus { PENDING, PAID, FAILED }

class QrisPaymentSession {
  final String orderId;
  final double amount;
  final String qrPayload;
  final DateTime expiresAt;
  QrisStatus status;

  QrisPaymentSession({
    required this.orderId,
    required this.amount,
    required this.qrPayload,
    required this.expiresAt,
    this.status = QrisStatus.PENDING,
  });
}

class QrisPaymentService {
  // Simulator storage
  final Map<String, QrisPaymentSession> _sessions = {};

  Future<QrisPaymentSession> generateQris({required double amount}) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    
    final orderId = 'QRIS-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final qrPayload = '00020101021126570014ID.CO.QRIS.WWW01189360091530000216010214227364803730225112520441115802ID5910BEAUTY POS6007JAKARTA61051212362140110${orderId}6304';
    
    final session = QrisPaymentSession(
      orderId: orderId,
      amount: amount,
      qrPayload: qrPayload,
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    
    _sessions[orderId] = session;
    return session;
  }

  Future<QrisStatus> checkStatus(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API polling
    
    final session = _sessions[orderId];
    if (session == null) return QrisStatus.FAILED;

    if (DateTime.now().isAfter(session.expiresAt) && session.status == QrisStatus.PENDING) {
      session.status = QrisStatus.FAILED;
    }
    
    return session.status;
  }

  // --- SIMULATOR ONLY METHODS ---
  void simulatePaymentSuccess(String orderId) {
    if (_sessions.containsKey(orderId)) {
      _sessions[orderId]!.status = QrisStatus.PAID;
    }
  }

  void simulatePaymentFailed(String orderId) {
    if (_sessions.containsKey(orderId)) {
      _sessions[orderId]!.status = QrisStatus.FAILED;
    }
  }
}
