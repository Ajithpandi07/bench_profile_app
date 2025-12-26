// lib/features/health_metrics/domain/entities/health_metrics.dart

import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Query;
import 'package:health/health.dart';

part 'health_metrics.g.dart';

@Collection(accessor: 'healthMetrics', ignore: const {'props', 'stringify'})
class HealthMetrics extends Equatable {
  /// Isar ID – must NOT be final so Isar can assign it
  Id id = Isar.autoIncrement;

  /// unique id from Health API (or generated)
  // removed @Index for now to avoid generator issues
  late String uuid;

  /// metric info
  late String type;
  late double value;
  late String unit;
  late DateTime dateFrom;
  late DateTime dateTo;
  late String sourceName;
  late String sourceId;

  /// Sync metadata
  bool synced = false;
  DateTime? syncedAt;
  DateTime? lastSyncedAt;

  /// Audit timestamps
  late DateTime createdAt;
  late DateTime updatedAt;

  /// last local modification time (use for conflict resolution)
  late DateTime lastModified;

  HealthMetrics({
    this.id = Isar.autoIncrement,
    required this.uuid,
    required this.type,
    required this.value,
    required this.unit,
    required this.dateFrom,
    required this.dateTo,
    required this.sourceName,
    required this.sourceId,
    this.synced = false,
    this.syncedAt,
    this.lastModified = const _DefaultDateTime(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    this.createdAt = createdAt ?? now;
    this.updatedAt = updatedAt ?? now;
  }

  /// Create from a Health package data point safely
  static HealthMetrics? tryParse(HealthDataPoint p) {
    double? extractedValue;

    if (p.value is NumericHealthValue) {
      extractedValue = (p.value as NumericHealthValue).numericValue.toDouble();
    } else {
      // Handle other types or ignore
      return null;
    }

    // When parsing new data from device, it's effectively "created" now in our system
    // unless we had source creation time (which HealthPoint doesn't explicitly give us easily in same format)
    return HealthMetrics(
      uuid: p.uuid,
      value: extractedValue,
      unit: p.unit.name,
      dateFrom: p.dateFrom,
      dateTo: p.dateTo,
      type: p.type.name,
      sourceName: p.sourceName,
      sourceId: p.sourceId,
      lastModified: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Deprecated: Use tryParse instead
  factory HealthMetrics.fromHealthDataPoint(HealthDataPoint p) {
    final m = tryParse(p);
    if (m == null) {
      throw FormatException(
          'Unsupported HealthValue type: ${p.value.runtimeType}');
    }
    return m;
  }

  /// Create from Firestore map / document
  factory HealthMetrics.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v == null) throw ArgumentError('Missing date value in map');
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Unsupported date type: ${v.runtimeType}');
    }

    DateTime parseOptionalDate(dynamic v, DateTime fallback) {
      if (v == null) return fallback;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      return fallback;
    }

    return HealthMetrics(
      uuid: map['uuid'] as String,
      type: map['type'] as String,
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String,
      dateFrom: parseDate(map['dateFrom']),
      dateTo: parseDate(map['dateTo']),
      sourceName: map['sourceName'] as String,
      sourceId: map['sourceId'] as String,
      synced: (map['synced'] as bool?) ?? false,
      syncedAt: map['syncedAt'] is Timestamp
          ? (map['syncedAt'] as Timestamp).toDate()
          : (map['syncedAt'] as DateTime?),
      lastModified: parseOptionalDate(map['lastModified'], DateTime.now()),
      createdAt: parseOptionalDate(map['createdAt'], DateTime.now()),
      updatedAt: parseOptionalDate(map['updatedAt'], DateTime.now()),
    );
  }

  HealthMetrics copyWith({
    Id? id,
    String? uuid,
    String? type,
    double? value,
    String? unit,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sourceName,
    String? sourceId,
    bool? synced,
    DateTime? syncedAt,
    DateTime? lastModified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthMetrics(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      sourceName: sourceName ?? this.sourceName,
      sourceId: sourceId ?? this.sourceId,
      synced: synced ?? this.synced,
      syncedAt: syncedAt ?? this.syncedAt,
      lastModified: lastModified ?? this.lastModified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

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
      'synced': synced,
      'syncedAt': syncedAt != null ? Timestamp.fromDate(syncedAt!) : null,
      'lastModified': Timestamp.fromDate(lastModified),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [
        id,
        uuid,
        type,
        value,
        unit,
        dateFrom,
        dateTo,
        sourceName,
        sourceId,
        synced,
        syncedAt,
        lastModified,
        createdAt,
        updatedAt,
      ];
}

/// Helper class to provide a default DateTime value in a const context.
class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.now();
}
