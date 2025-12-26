import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import '../../domain/entities/health_metrics.dart';

class HealthMetricsModel extends HealthMetrics {
  HealthMetricsModel({
    required String uuid,
    required String type,
    required double value,
    required String unit,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String sourceName,
    required String sourceId,
  }) : super(
          uuid: uuid,
          type: type,
          value: value,
          unit: unit,
          dateFrom: dateFrom,
          dateTo: dateTo,
          sourceName: sourceName,
          sourceId: sourceId,
        );

  /// Creates a model instance from a raw [HealthDataPoint] from the health package.
  factory HealthMetricsModel.fromHealthDataPoint(HealthDataPoint p) {
    return HealthMetricsModel(
      uuid: p.uuid,
      // Ensure value is always double, handling different numeric types from HealthValue
      value: (p.value as NumericHealthValue).numericValue.toDouble(),
      unit: p.unit.name,
      dateFrom: p.dateFrom,
      dateTo: p.dateTo,
      type: p.type.name,
      sourceName: p.sourceName,
      sourceId: p.sourceId,
    );
  }

  /// Creates a model instance from a Firestore [DocumentSnapshot].
  factory HealthMetricsModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HealthMetricsModel(
      uuid: data['uuid'],
      type: data['type'],
      value: (data['value'] as num).toDouble(),
      unit: data['unit'],
      dateFrom: (data['dateFrom'] as Timestamp).toDate(),
      dateTo: (data['dateTo'] as Timestamp).toDate(),
      sourceName: data['sourceName'],
      sourceId: data['sourceId'],
    );
  }

  /// Converts the model instance to a Map suitable for Firestore.
  /// This is identical to the method in the parent entity.
  @override
  Map<String, dynamic> toMap() {
    return {
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
}