// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_metrics.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHealthMetricsCollection on Isar {
  IsarCollection<HealthMetrics> get healthMetrics => this.collection();
}

const HealthMetricsSchema = CollectionSchema(
  name: r'HealthMetrics',
  id: -3348921803634179751,
  properties: {
    r'activeEnergyBurned': PropertySchema(
      id: 0,
      name: r'activeEnergyBurned',
      type: IsarType.double,
    ),
    r'basalEnergyBurned': PropertySchema(
      id: 1,
      name: r'basalEnergyBurned',
      type: IsarType.double,
    ),
    r'bloodGlucose': PropertySchema(
      id: 2,
      name: r'bloodGlucose',
      type: IsarType.double,
    ),
    r'bloodOxygen': PropertySchema(
      id: 3,
      name: r'bloodOxygen',
      type: IsarType.double,
    ),
    r'bloodPressureDiastolic': PropertySchema(
      id: 4,
      name: r'bloodPressureDiastolic',
      type: IsarType.double,
    ),
    r'bloodPressureSystolic': PropertySchema(
      id: 5,
      name: r'bloodPressureSystolic',
      type: IsarType.double,
    ),
    r'bodyFatPercentage': PropertySchema(
      id: 6,
      name: r'bodyFatPercentage',
      type: IsarType.double,
    ),
    r'bodyMassIndex': PropertySchema(
      id: 7,
      name: r'bodyMassIndex',
      type: IsarType.double,
    ),
    r'caloriesBurned': PropertySchema(
      id: 8,
      name: r'caloriesBurned',
      type: IsarType.double,
    ),
    r'dietaryEnergyConsumed': PropertySchema(
      id: 9,
      name: r'dietaryEnergyConsumed',
      type: IsarType.double,
    ),
    r'distanceWalkingRunning': PropertySchema(
      id: 10,
      name: r'distanceWalkingRunning',
      type: IsarType.double,
    ),
    r'flightsClimbed': PropertySchema(
      id: 11,
      name: r'flightsClimbed',
      type: IsarType.long,
    ),
    r'heartRate': PropertySchema(
      id: 12,
      name: r'heartRate',
      type: IsarType.double,
    ),
    r'heartRateVariabilitySdnn': PropertySchema(
      id: 13,
      name: r'heartRateVariabilitySdnn',
      type: IsarType.double,
    ),
    r'height': PropertySchema(
      id: 14,
      name: r'height',
      type: IsarType.double,
    ),
    r'restingHeartRate': PropertySchema(
      id: 15,
      name: r'restingHeartRate',
      type: IsarType.double,
    ),
    r'sleepAsleep': PropertySchema(
      id: 16,
      name: r'sleepAsleep',
      type: IsarType.double,
    ),
    r'sleepAwake': PropertySchema(
      id: 17,
      name: r'sleepAwake',
      type: IsarType.double,
    ),
    r'sleepDeep': PropertySchema(
      id: 18,
      name: r'sleepDeep',
      type: IsarType.double,
    ),
    r'sleepInBed': PropertySchema(
      id: 19,
      name: r'sleepInBed',
      type: IsarType.double,
    ),
    r'sleepLight': PropertySchema(
      id: 20,
      name: r'sleepLight',
      type: IsarType.double,
    ),
    r'sleepRem': PropertySchema(
      id: 21,
      name: r'sleepRem',
      type: IsarType.double,
    ),
    r'source': PropertySchema(
      id: 22,
      name: r'source',
      type: IsarType.string,
    ),
    r'steps': PropertySchema(
      id: 23,
      name: r'steps',
      type: IsarType.long,
    ),
    r'timestamp': PropertySchema(
      id: 24,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'water': PropertySchema(
      id: 25,
      name: r'water',
      type: IsarType.double,
    ),
    r'weight': PropertySchema(
      id: 26,
      name: r'weight',
      type: IsarType.double,
    )
  },
  estimateSize: _healthMetricsEstimateSize,
  serialize: _healthMetricsSerialize,
  deserialize: _healthMetricsDeserialize,
  deserializeProp: _healthMetricsDeserializeProp,
  idName: r'id',
  indexes: {
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _healthMetricsGetId,
  getLinks: _healthMetricsGetLinks,
  attach: _healthMetricsAttach,
  version: '3.1.0+1',
);

int _healthMetricsEstimateSize(
  HealthMetrics object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.source.length * 3;
  return bytesCount;
}

void _healthMetricsSerialize(
  HealthMetrics object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.activeEnergyBurned);
  writer.writeDouble(offsets[1], object.basalEnergyBurned);
  writer.writeDouble(offsets[2], object.bloodGlucose);
  writer.writeDouble(offsets[3], object.bloodOxygen);
  writer.writeDouble(offsets[4], object.bloodPressureDiastolic);
  writer.writeDouble(offsets[5], object.bloodPressureSystolic);
  writer.writeDouble(offsets[6], object.bodyFatPercentage);
  writer.writeDouble(offsets[7], object.bodyMassIndex);
  writer.writeDouble(offsets[8], object.caloriesBurned);
  writer.writeDouble(offsets[9], object.dietaryEnergyConsumed);
  writer.writeDouble(offsets[10], object.distanceWalkingRunning);
  writer.writeLong(offsets[11], object.flightsClimbed);
  writer.writeDouble(offsets[12], object.heartRate);
  writer.writeDouble(offsets[13], object.heartRateVariabilitySdnn);
  writer.writeDouble(offsets[14], object.height);
  writer.writeDouble(offsets[15], object.restingHeartRate);
  writer.writeDouble(offsets[16], object.sleepAsleep);
  writer.writeDouble(offsets[17], object.sleepAwake);
  writer.writeDouble(offsets[18], object.sleepDeep);
  writer.writeDouble(offsets[19], object.sleepInBed);
  writer.writeDouble(offsets[20], object.sleepLight);
  writer.writeDouble(offsets[21], object.sleepRem);
  writer.writeString(offsets[22], object.source);
  writer.writeLong(offsets[23], object.steps);
  writer.writeDateTime(offsets[24], object.timestamp);
  writer.writeDouble(offsets[25], object.water);
  writer.writeDouble(offsets[26], object.weight);
}

HealthMetrics _healthMetricsDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HealthMetrics(
    activeEnergyBurned: reader.readDoubleOrNull(offsets[0]),
    basalEnergyBurned: reader.readDoubleOrNull(offsets[1]),
    bloodGlucose: reader.readDoubleOrNull(offsets[2]),
    bloodOxygen: reader.readDoubleOrNull(offsets[3]),
    bloodPressureDiastolic: reader.readDoubleOrNull(offsets[4]),
    bloodPressureSystolic: reader.readDoubleOrNull(offsets[5]),
    bodyFatPercentage: reader.readDoubleOrNull(offsets[6]),
    bodyMassIndex: reader.readDoubleOrNull(offsets[7]),
    caloriesBurned: reader.readDoubleOrNull(offsets[8]),
    dietaryEnergyConsumed: reader.readDoubleOrNull(offsets[9]),
    distanceWalkingRunning: reader.readDoubleOrNull(offsets[10]),
    flightsClimbed: reader.readLongOrNull(offsets[11]),
    heartRate: reader.readDoubleOrNull(offsets[12]),
    heartRateVariabilitySdnn: reader.readDoubleOrNull(offsets[13]),
    height: reader.readDoubleOrNull(offsets[14]),
    restingHeartRate: reader.readDoubleOrNull(offsets[15]),
    sleepAsleep: reader.readDoubleOrNull(offsets[16]),
    sleepAwake: reader.readDoubleOrNull(offsets[17]),
    sleepDeep: reader.readDoubleOrNull(offsets[18]),
    sleepInBed: reader.readDoubleOrNull(offsets[19]),
    sleepLight: reader.readDoubleOrNull(offsets[20]),
    sleepRem: reader.readDoubleOrNull(offsets[21]),
    source: reader.readString(offsets[22]),
    steps: reader.readLongOrNull(offsets[23]) ?? 0,
    timestamp: reader.readDateTime(offsets[24]),
    water: reader.readDoubleOrNull(offsets[25]),
    weight: reader.readDoubleOrNull(offsets[26]),
  );
  object.id = id;
  return object;
}

P _healthMetricsDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDoubleOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readDoubleOrNull(offset)) as P;
    case 4:
      return (reader.readDoubleOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readDoubleOrNull(offset)) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readDoubleOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDoubleOrNull(offset)) as P;
    case 19:
      return (reader.readDoubleOrNull(offset)) as P;
    case 20:
      return (reader.readDoubleOrNull(offset)) as P;
    case 21:
      return (reader.readDoubleOrNull(offset)) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 24:
      return (reader.readDateTime(offset)) as P;
    case 25:
      return (reader.readDoubleOrNull(offset)) as P;
    case 26:
      return (reader.readDoubleOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _healthMetricsGetId(HealthMetrics object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _healthMetricsGetLinks(HealthMetrics object) {
  return [];
}

void _healthMetricsAttach(
    IsarCollection<dynamic> col, Id id, HealthMetrics object) {
  object.id = id;
}

extension HealthMetricsQueryWhereSort
    on QueryBuilder<HealthMetrics, HealthMetrics, QWhere> {
  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }
}

extension HealthMetricsQueryWhere
    on QueryBuilder<HealthMetrics, HealthMetrics, QWhereClause> {
  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause>
      timestampEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause>
      timestampNotEqualTo(DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause>
      timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause>
      timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterWhereClause>
      timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HealthMetricsQueryFilter
    on QueryBuilder<HealthMetrics, HealthMetrics, QFilterCondition> {
  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'activeEnergyBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'activeEnergyBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'activeEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'activeEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'activeEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      activeEnergyBurnedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'activeEnergyBurned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'basalEnergyBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'basalEnergyBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basalEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basalEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basalEnergyBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      basalEnergyBurnedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basalEnergyBurned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bloodGlucose',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bloodGlucose',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bloodGlucose',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bloodGlucose',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bloodGlucose',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodGlucoseBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bloodGlucose',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bloodOxygen',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bloodOxygen',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bloodOxygen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bloodOxygen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bloodOxygen',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodOxygenBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bloodOxygen',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bloodPressureDiastolic',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bloodPressureDiastolic',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bloodPressureDiastolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bloodPressureDiastolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bloodPressureDiastolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureDiastolicBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bloodPressureDiastolic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bloodPressureSystolic',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bloodPressureSystolic',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bloodPressureSystolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bloodPressureSystolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bloodPressureSystolic',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bloodPressureSystolicBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bloodPressureSystolic',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyFatPercentage',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyFatPercentage',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyFatPercentage',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyFatPercentageBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyFatPercentage',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'bodyMassIndex',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'bodyMassIndex',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bodyMassIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bodyMassIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bodyMassIndex',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      bodyMassIndexBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bodyMassIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'caloriesBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'caloriesBurned',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'caloriesBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'caloriesBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'caloriesBurned',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      caloriesBurnedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'caloriesBurned',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dietaryEnergyConsumed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dietaryEnergyConsumed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dietaryEnergyConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dietaryEnergyConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dietaryEnergyConsumed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      dietaryEnergyConsumedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dietaryEnergyConsumed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'distanceWalkingRunning',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'distanceWalkingRunning',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'distanceWalkingRunning',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'distanceWalkingRunning',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'distanceWalkingRunning',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      distanceWalkingRunningBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'distanceWalkingRunning',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'flightsClimbed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'flightsClimbed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'flightsClimbed',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'flightsClimbed',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'flightsClimbed',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      flightsClimbedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'flightsClimbed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'heartRate',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'heartRate',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'heartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'heartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'heartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'heartRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'heartRateVariabilitySdnn',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'heartRateVariabilitySdnn',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'heartRateVariabilitySdnn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'heartRateVariabilitySdnn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'heartRateVariabilitySdnn',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heartRateVariabilitySdnnBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'heartRateVariabilitySdnn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'height',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'height',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      heightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'height',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'restingHeartRate',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'restingHeartRate',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'restingHeartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'restingHeartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'restingHeartRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      restingHeartRateBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'restingHeartRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepAsleep',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepAsleep',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepAsleep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepAsleep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepAsleep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAsleepBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepAsleep',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepAwake',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepAwake',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepAwake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepAwake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepAwake',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepAwakeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepAwake',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepDeep',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepDeep',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepDeep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepDeep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepDeep',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepDeepBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepDeep',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepInBed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepInBed',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepInBed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepInBed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepInBed',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepInBedBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepInBed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepLight',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepLight',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepLight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepLight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepLight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepLightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepLight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sleepRem',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sleepRem',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sleepRem',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sleepRem',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sleepRem',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sleepRemBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sleepRem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'source',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'source',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'source',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'source',
        value: '',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      stepsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      stepsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      stepsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      stepsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'water',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'water',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'water',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'water',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'water',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      waterBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'water',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'weight',
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterFilterCondition>
      weightBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension HealthMetricsQueryObject
    on QueryBuilder<HealthMetrics, HealthMetrics, QFilterCondition> {}

extension HealthMetricsQueryLinks
    on QueryBuilder<HealthMetrics, HealthMetrics, QFilterCondition> {}

extension HealthMetricsQuerySortBy
    on QueryBuilder<HealthMetrics, HealthMetrics, QSortBy> {
  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByActiveEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeEnergyBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByActiveEnergyBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeEnergyBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBasalEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basalEnergyBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBasalEnergyBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basalEnergyBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodGlucose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodGlucose', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodGlucoseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodGlucose', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByBloodOxygen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodOxygen', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodOxygenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodOxygen', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodPressureDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureDiastolic', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodPressureDiastolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureDiastolic', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodPressureSystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureSystolic', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBloodPressureSystolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureSystolic', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBodyFatPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBodyMassIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyMassIndex', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByBodyMassIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyMassIndex', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByCaloriesBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByDietaryEnergyConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dietaryEnergyConsumed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByDietaryEnergyConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dietaryEnergyConsumed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByDistanceWalkingRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceWalkingRunning', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByDistanceWalkingRunningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceWalkingRunning', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByFlightsClimbed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flightsClimbed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByFlightsClimbedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flightsClimbed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRate', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRate', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByHeartRateVariabilitySdnn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRateVariabilitySdnn', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByHeartRateVariabilitySdnnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRateVariabilitySdnn', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByRestingHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restingHeartRate', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByRestingHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restingHeartRate', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepAsleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAsleep', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepAsleepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAsleep', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepAwake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAwake', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepAwakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAwake', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepDeep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepDeep', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepDeepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepDeep', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepInBed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepInBed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepInBedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepInBed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepLight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepLight', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepLightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepLight', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySleepRem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepRem', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortBySleepRemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepRem', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'water', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByWaterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'water', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension HealthMetricsQuerySortThenBy
    on QueryBuilder<HealthMetrics, HealthMetrics, QSortThenBy> {
  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByActiveEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeEnergyBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByActiveEnergyBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'activeEnergyBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBasalEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basalEnergyBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBasalEnergyBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basalEnergyBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodGlucose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodGlucose', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodGlucoseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodGlucose', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByBloodOxygen() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodOxygen', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodOxygenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodOxygen', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodPressureDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureDiastolic', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodPressureDiastolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureDiastolic', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodPressureSystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureSystolic', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBloodPressureSystolicDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bloodPressureSystolic', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBodyFatPercentageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyFatPercentage', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBodyMassIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyMassIndex', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByBodyMassIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bodyMassIndex', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByCaloriesBurnedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'caloriesBurned', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByDietaryEnergyConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dietaryEnergyConsumed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByDietaryEnergyConsumedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dietaryEnergyConsumed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByDistanceWalkingRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceWalkingRunning', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByDistanceWalkingRunningDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanceWalkingRunning', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByFlightsClimbed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flightsClimbed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByFlightsClimbedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'flightsClimbed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRate', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRate', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByHeartRateVariabilitySdnn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRateVariabilitySdnn', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByHeartRateVariabilitySdnnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'heartRateVariabilitySdnn', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByHeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'height', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByRestingHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restingHeartRate', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByRestingHeartRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'restingHeartRate', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepAsleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAsleep', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepAsleepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAsleep', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepAwake() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAwake', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepAwakeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepAwake', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepDeep() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepDeep', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepDeepDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepDeep', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepInBed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepInBed', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepInBedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepInBed', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepLight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepLight', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepLightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepLight', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySleepRem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepRem', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenBySleepRemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sleepRem', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByStepsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'steps', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy>
      thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'water', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByWaterDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'water', Sort.desc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension HealthMetricsQueryWhereDistinct
    on QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> {
  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByActiveEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'activeEnergyBurned');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBasalEnergyBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basalEnergyBurned');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBloodGlucose() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bloodGlucose');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBloodOxygen() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bloodOxygen');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBloodPressureDiastolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bloodPressureDiastolic');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBloodPressureSystolic() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bloodPressureSystolic');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBodyFatPercentage() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyFatPercentage');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByBodyMassIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bodyMassIndex');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByCaloriesBurned() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'caloriesBurned');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByDietaryEnergyConsumed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dietaryEnergyConsumed');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByDistanceWalkingRunning() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanceWalkingRunning');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByFlightsClimbed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'flightsClimbed');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctByHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'heartRate');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByHeartRateVariabilitySdnn() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'heartRateVariabilitySdnn');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctByHeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'height');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctByRestingHeartRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'restingHeartRate');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct>
      distinctBySleepAsleep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepAsleep');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySleepAwake() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepAwake');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySleepDeep() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepDeep');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySleepInBed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepInBed');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySleepLight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepLight');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySleepRem() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sleepRem');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctByWater() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'water');
    });
  }

  QueryBuilder<HealthMetrics, HealthMetrics, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension HealthMetricsQueryProperty
    on QueryBuilder<HealthMetrics, HealthMetrics, QQueryProperty> {
  QueryBuilder<HealthMetrics, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      activeEnergyBurnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'activeEnergyBurned');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      basalEnergyBurnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basalEnergyBurned');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      bloodGlucoseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bloodGlucose');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> bloodOxygenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bloodOxygen');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      bloodPressureDiastolicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bloodPressureDiastolic');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      bloodPressureSystolicProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bloodPressureSystolic');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      bodyFatPercentageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyFatPercentage');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      bodyMassIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bodyMassIndex');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      caloriesBurnedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'caloriesBurned');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      dietaryEnergyConsumedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dietaryEnergyConsumed');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      distanceWalkingRunningProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanceWalkingRunning');
    });
  }

  QueryBuilder<HealthMetrics, int?, QQueryOperations> flightsClimbedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'flightsClimbed');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> heartRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'heartRate');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      heartRateVariabilitySdnnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'heartRateVariabilitySdnn');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> heightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'height');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations>
      restingHeartRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'restingHeartRate');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepAsleepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepAsleep');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepAwakeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepAwake');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepDeepProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepDeep');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepInBedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepInBed');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepLightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepLight');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> sleepRemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sleepRem');
    });
  }

  QueryBuilder<HealthMetrics, String, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<HealthMetrics, int, QQueryOperations> stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }

  QueryBuilder<HealthMetrics, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> waterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'water');
    });
  }

  QueryBuilder<HealthMetrics, double?, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
