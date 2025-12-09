// lib/features/health_metrics/data/models/health_model.dart
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/health_metrics.dart';

class HealthModel extends HealthMetrics {
  HealthModel({
    Id id = Isar.autoIncrement,
    required String uuid,
    required String type,
    required double value,
    required String unit,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String sourceName,
    required String sourceId,
  }) : super(
          id: id,
          uuid: uuid,
          type: type,
          value: value,
          unit: unit,
          dateFrom: dateFrom,
          dateTo: dateTo,
          sourceName: sourceName,
          sourceId: sourceId,
        );

  /// Create from a Firestore map (or any map using the same keys).
  factory HealthModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) throw ArgumentError('Missing date value');
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Unsupported date type for value: $v');
    }

    return HealthModel(
      id: map['id'] is int ? map['id'] as int : Isar.autoIncrement,
      uuid: map['uuid'] as String,
      type: map['type'] as String,
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      dateFrom: parseDate(map['dateFrom']),
      dateTo: parseDate(map['dateTo']),
      sourceName: map['sourceName'] as String,
      sourceId: map['sourceId'] as String,
    );
  }

  /// Convert back to Firestore-friendly map (matches your entity.toMap).
  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'type': type,
        'value': value,
        'unit': unit,
        'dateFrom': Timestamp.fromDate(dateFrom),
        'dateTo': Timestamp.fromDate(dateTo),
        'sourceName': sourceName,
        'sourceId': sourceId,
      };
}
