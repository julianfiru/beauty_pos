class Booking {
  final int? id;
  final String customerName;
  final String customerPhone;
  final int serviceId;
  final String serviceName;
  final String? therapistName;
  final String bookingDateTime;
  final String status; // 'PENDING', 'COMPLETED', 'CANCELLED'
  final String? notes;
  final String createdAt;

  Booking({
    this.id,
    required this.customerName,
    required this.customerPhone,
    required this.serviceId,
    required this.serviceName,
    this.therapistName,
    required this.bookingDateTime,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'therapistName': therapistName,
      'bookingDateTime': bookingDateTime,
      'status': status,
      'notes': notes,
      'createdAt': createdAt,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      serviceId: map['serviceId'],
      serviceName: map['serviceName'],
      therapistName: map['therapistName'],
      bookingDateTime: map['bookingDateTime'],
      status: map['status'],
      notes: map['notes'],
      createdAt: map['createdAt'],
    );
  }

  Booking copyWith({
    int? id,
    String? customerName,
    String? customerPhone,
    int? serviceId,
    String? serviceName,
    String? therapistName,
    String? bookingDateTime,
    String? status,
    String? notes,
    String? createdAt,
  }) {
    return Booking(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      therapistName: therapistName ?? this.therapistName,
      bookingDateTime: bookingDateTime ?? this.bookingDateTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
