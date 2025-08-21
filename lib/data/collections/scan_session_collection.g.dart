// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_session_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScanSessionCollectionCollection on Isar {
  IsarCollection<ScanSessionCollection> get scanSessionCollections =>
      this.collection();
}

const ScanSessionCollectionSchema = CollectionSchema(
  name: r'ScanSessionCollection',
  id: -3778861466776021077,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'detectedEmotion': PropertySchema(
      id: 1,
      name: r'detectedEmotion',
      type: IsarType.string,
    )
  },
  estimateSize: _scanSessionCollectionEstimateSize,
  serialize: _scanSessionCollectionSerialize,
  deserialize: _scanSessionCollectionDeserialize,
  deserializeProp: _scanSessionCollectionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'sensorData': LinkSchema(
      id: -8784333392882100217,
      name: r'sensorData',
      target: r'SensorDataCollection',
      single: false,
      linkName: r'scanSession',
    )
  },
  embeddedSchemas: {},
  getId: _scanSessionCollectionGetId,
  getLinks: _scanSessionCollectionGetLinks,
  attach: _scanSessionCollectionAttach,
  version: '3.1.8',
);

int _scanSessionCollectionEstimateSize(
  ScanSessionCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.detectedEmotion;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _scanSessionCollectionSerialize(
  ScanSessionCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.detectedEmotion);
}

ScanSessionCollection _scanSessionCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ScanSessionCollection(
    detectedEmotion: reader.readStringOrNull(offsets[1]),
  );
  object.createdAt = reader.readDateTime(offsets[0]);
  object.id = id;
  return object;
}

P _scanSessionCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _scanSessionCollectionGetId(ScanSessionCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _scanSessionCollectionGetLinks(
    ScanSessionCollection object) {
  return [object.sensorData];
}

void _scanSessionCollectionAttach(
    IsarCollection<dynamic> col, Id id, ScanSessionCollection object) {
  object.id = id;
  object.sensorData.attach(
      col, col.isar.collection<SensorDataCollection>(), r'sensorData', id);
}

extension ScanSessionCollectionQueryWhereSort
    on QueryBuilder<ScanSessionCollection, ScanSessionCollection, QWhere> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ScanSessionCollectionQueryWhere on QueryBuilder<ScanSessionCollection,
    ScanSessionCollection, QWhereClause> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhereClause>
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

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterWhereClause>
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
}

extension ScanSessionCollectionQueryFilter on QueryBuilder<
    ScanSessionCollection, ScanSessionCollection, QFilterCondition> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'detectedEmotion',
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'detectedEmotion',
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'detectedEmotion',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
          QAfterFilterCondition>
      detectedEmotionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'detectedEmotion',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
          QAfterFilterCondition>
      detectedEmotionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'detectedEmotion',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'detectedEmotion',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> detectedEmotionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'detectedEmotion',
        value: '',
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> idBetween(
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
}

extension ScanSessionCollectionQueryObject on QueryBuilder<
    ScanSessionCollection, ScanSessionCollection, QFilterCondition> {}

extension ScanSessionCollectionQueryLinks on QueryBuilder<ScanSessionCollection,
    ScanSessionCollection, QFilterCondition> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorData(FilterQuery<SensorDataCollection> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'sensorData');
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sensorData', length, true, length, true);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sensorData', 0, true, 0, true);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sensorData', 0, false, 999999, true);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sensorData', 0, true, length, include);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'sensorData', length, include, 999999, true);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection,
      QAfterFilterCondition> sensorDataLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'sensorData', lower, includeLower, upper, includeUpper);
    });
  }
}

extension ScanSessionCollectionQuerySortBy
    on QueryBuilder<ScanSessionCollection, ScanSessionCollection, QSortBy> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      sortByDetectedEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.asc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      sortByDetectedEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.desc);
    });
  }
}

extension ScanSessionCollectionQuerySortThenBy
    on QueryBuilder<ScanSessionCollection, ScanSessionCollection, QSortThenBy> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenByDetectedEmotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.asc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenByDetectedEmotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'detectedEmotion', Sort.desc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension ScanSessionCollectionQueryWhereDistinct
    on QueryBuilder<ScanSessionCollection, ScanSessionCollection, QDistinct> {
  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ScanSessionCollection, ScanSessionCollection, QDistinct>
      distinctByDetectedEmotion({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'detectedEmotion',
          caseSensitive: caseSensitive);
    });
  }
}

extension ScanSessionCollectionQueryProperty on QueryBuilder<
    ScanSessionCollection, ScanSessionCollection, QQueryProperty> {
  QueryBuilder<ScanSessionCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ScanSessionCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ScanSessionCollection, String?, QQueryOperations>
      detectedEmotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'detectedEmotion');
    });
  }
}
