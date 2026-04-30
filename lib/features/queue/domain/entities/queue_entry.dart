class Line {
  final String id;
  final String origin;
  final String destination;
  final int price;

  const Line({
    required this.id,
    required this.origin,
    required this.destination,
    required this.price,
  });

  String get label => '$origin → $destination';

  factory Line.fromJson(Map<String, dynamic> j) => Line(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        origin: (j['origin'] ?? '') as String,
        destination: (j['destination'] ?? '') as String,
        price: (j['price'] as num?)?.toInt() ?? 0,
      );
}

class QueueEntry {
  final String id;
  final String taxiNumber;
  final String plateNumber;
  final String driverName;
  final String driverPhone;
  final String driverId;
  final String lineId;
  final String lineOrigin;
  final String lineDestination;
  final String status; // queued | filling | full
  final int queuePosition;
  final int seatsTotal;
  final int seatsOccupied;

  const QueueEntry({
    required this.id,
    required this.taxiNumber,
    required this.plateNumber,
    required this.driverName,
    required this.driverPhone,
    required this.driverId,
    required this.lineId,
    required this.lineOrigin,
    required this.lineDestination,
    required this.status,
    required this.queuePosition,
    required this.seatsTotal,
    required this.seatsOccupied,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> j) {
    final line = j['line'] as Map<String, dynamic>? ?? {};
    return QueueEntry(
      id: (j['_id'] ?? j['id'] ?? '') as String,
      taxiNumber: (j['taxiNumber'] ?? '') as String,
      plateNumber: (j['plateNumber'] ?? '') as String,
      driverName: (j['driverName'] ?? '') as String,
      driverPhone: (j['driverPhone'] ?? '') as String,
      driverId: (j['driverId'] ?? '') as String,
      lineId: (line['_id'] ?? '') as String,
      lineOrigin: (line['origin'] ?? '') as String,
      lineDestination: (line['destination'] ?? '') as String,
      status: (j['status'] ?? '') as String,
      queuePosition: (j['queuePosition'] as num?)?.toInt() ?? 0,
      seatsTotal: (j['seatsTotal'] as num?)?.toInt() ?? 6,
      seatsOccupied: (j['seatsOccupied'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverInfo {
  final String id;
  final String name;
  final String phone;
  final String driverCode;
  final String? taxiNumber;
  final String? plateNumber;
  final String? nfcId;
  final bool nfcLinked;

  const DriverInfo({
    required this.id,
    required this.name,
    required this.phone,
    required this.driverCode,
    this.taxiNumber,
    this.plateNumber,
    this.nfcId,
    this.nfcLinked = false,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> j) => DriverInfo(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        driverCode: (j['driverCode'] ?? '') as String,
        taxiNumber: j['taxiNumber'] as String?,
        plateNumber: j['plateNumber'] as String?,
        nfcId: j['nfc_id'] as String?,
        nfcLinked: (j['nfcLinked'] as bool?) ?? false,
      );
}

class NfcDriverInfo {
  final String id;
  final String name;
  final String taxiNumber;
  final String phone;
  final String destination;
  final int seatsTotal;

  const NfcDriverInfo({
    required this.id,
    required this.name,
    required this.taxiNumber,
    required this.phone,
    required this.destination,
    required this.seatsTotal,
  });

  factory NfcDriverInfo.fromJson(Map<String, dynamic> j) => NfcDriverInfo(
        id: (j['_id'] ?? j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        taxiNumber: (j['taxiNumber'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        destination: (j['destination'] ?? '') as String,
        seatsTotal: (j['seatsTotal'] as num?)?.toInt() ?? 6,
      );
}
