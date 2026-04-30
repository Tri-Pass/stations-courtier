import 'package:equatable/equatable.dart';

class StationEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? city;

  const StationEntity({
    required this.id,
    required this.name,
    this.code,
    this.city,
  });

  @override
  List<Object?> get props => [id];
}

class LineEntity extends Equatable {
  final String id;
  final String origin;
  final String destination;
  final double price;

  const LineEntity({
    required this.id,
    required this.origin,
    required this.destination,
    required this.price,
  });

  String get display => '$origin → $destination';

  @override
  List<Object?> get props => [id];
}

class DriverEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String taxiNumber;
  final String plateNumber;
  final String? permitNumber;
  final double balance;
  final String? nfcTagId;
  final StationEntity? station;
  final List<LineEntity> selectedLines;

  const DriverEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.taxiNumber,
    required this.plateNumber,
    this.permitNumber,
    required this.balance,
    this.nfcTagId,
    this.station,
    this.selectedLines = const [],
  });

  @override
  List<Object?> get props => [id];
}
