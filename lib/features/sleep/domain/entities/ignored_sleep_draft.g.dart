// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ignored_sleep_draft.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetIgnoredSleepDraftCollection on Isar {
  IsarCollection<IgnoredSleepDraft> get ignoredSleepDrafts => this.collection();
}

const IgnoredSleepDraftSchema = CollectionSchema(
  name: r'IgnoredSleepDraft',
  id: -8521634276520112436,
  properties: {
    r'ignoredAt': PropertySchema(
      id: 0,
      name: r'ignoredAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(
      id: 1,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _ignoredSleepDraftEstimateSize,
  serialize: _ignoredSleepDraftSerialize,
  deserialize: _ignoredSleepDraftDeserialize,
  deserializeProp: _ignoredSleepDraftDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _ignoredSleepDraftGetId,
  getLinks: _ignoredSleepDraftGetLinks,
  attach: _ignoredSleepDraftAttach,
  version: '3.1.0+1',
);

int _ignoredSleepDraftEstimateSize(
  IgnoredSleepDraft object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _ignoredSleepDraftSerialize(
  IgnoredSleepDraft object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.ignoredAt);
  writer.writeString(offsets[1], object.uuid);
}

IgnoredSleepDraft _ignoredSleepDraftDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = IgnoredSleepDraft();
  object.id = id;
  object.ignoredAt = reader.readDateTime(offsets[0]);
  object.uuid = reader.readString(offsets[1]);
  return object;
}

P _ignoredSleepDraftDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _ignoredSleepDraftGetId(IgnoredSleepDraft object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _ignoredSleepDraftGetLinks(
    IgnoredSleepDraft object) {
  return [];
}

void _ignoredSleepDraftAttach(
    IsarCollection<dynamic> col, Id id, IgnoredSleepDraft object) {
  object.id = id;
}

extension IgnoredSleepDraftByIndex on IsarCollection<IgnoredSleepDraft> {
  Future<IgnoredSleepDraft?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  IgnoredSleepDraft? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<IgnoredSleepDraft?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<IgnoredSleepDraft?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(IgnoredSleepDraft object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(IgnoredSleepDraft object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<IgnoredSleepDraft> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<IgnoredSleepDraft> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension IgnoredSleepDraftQueryWhereSort
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QWhere> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension IgnoredSleepDraftQueryWhere
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QWhereClause> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      idNotEqualTo(Id id) {
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

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      uuidEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterWhereClause>
      uuidNotEqualTo(String uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
    });
  }
}

extension IgnoredSleepDraftQueryFilter
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QFilterCondition> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
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

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      idLessThan(
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

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      idBetween(
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

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      ignoredAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ignoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      ignoredAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ignoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      ignoredAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ignoredAt',
        value: value,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      ignoredAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ignoredAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension IgnoredSleepDraftQueryObject
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QFilterCondition> {}

extension IgnoredSleepDraftQueryLinks
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QFilterCondition> {}

extension IgnoredSleepDraftQuerySortBy
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QSortBy> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      sortByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.asc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      sortByIgnoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.desc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension IgnoredSleepDraftQuerySortThenBy
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QSortThenBy> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      thenByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.asc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      thenByIgnoredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoredAt', Sort.desc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QAfterSortBy>
      thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension IgnoredSleepDraftQueryWhereDistinct
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QDistinct> {
  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QDistinct>
      distinctByIgnoredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ignoredAt');
    });
  }

  QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension IgnoredSleepDraftQueryProperty
    on QueryBuilder<IgnoredSleepDraft, IgnoredSleepDraft, QQueryProperty> {
  QueryBuilder<IgnoredSleepDraft, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<IgnoredSleepDraft, DateTime, QQueryOperations>
      ignoredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ignoredAt');
    });
  }

  QueryBuilder<IgnoredSleepDraft, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
