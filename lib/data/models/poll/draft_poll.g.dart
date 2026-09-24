// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_poll.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDraftPollCollection on Isar {
  IsarCollection<DraftPoll> get draftPolls => this.collection();
}

const DraftPollSchema = CollectionSchema(
  name: r'DraftPoll',
  id: 6857586145710565015,
  properties: {
    r'allowComments': PropertySchema(
      id: 0,
      name: r'allowComments',
      type: IsarType.bool,
    ),
    r'expiryDays': PropertySchema(
      id: 1,
      name: r'expiryDays',
      type: IsarType.long,
    ),
    r'options': PropertySchema(
      id: 2,
      name: r'options',
      type: IsarType.stringList,
    ),
    r'question': PropertySchema(
      id: 3,
      name: r'question',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _draftPollEstimateSize,
  serialize: _draftPollSerialize,
  deserialize: _draftPollDeserialize,
  deserializeProp: _draftPollDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _draftPollGetId,
  getLinks: _draftPollGetLinks,
  attach: _draftPollAttach,
  version: '3.3.2',
);

int _draftPollEstimateSize(
  DraftPoll object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.options.length * 3;
  {
    for (var i = 0; i < object.options.length; i++) {
      final value = object.options[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.question.length * 3;
  return bytesCount;
}

void _draftPollSerialize(
  DraftPoll object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.allowComments);
  writer.writeLong(offsets[1], object.expiryDays);
  writer.writeStringList(offsets[2], object.options);
  writer.writeString(offsets[3], object.question);
  writer.writeDateTime(offsets[4], object.updatedAt);
}

DraftPoll _draftPollDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DraftPoll();
  object.allowComments = reader.readBool(offsets[0]);
  object.expiryDays = reader.readLong(offsets[1]);
  object.id = id;
  object.options = reader.readStringList(offsets[2]) ?? [];
  object.question = reader.readString(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
  return object;
}

P _draftPollDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _draftPollGetId(DraftPoll object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _draftPollGetLinks(DraftPoll object) {
  return [];
}

void _draftPollAttach(IsarCollection<dynamic> col, Id id, DraftPoll object) {
  object.id = id;
}

extension DraftPollQueryWhereSort
    on QueryBuilder<DraftPoll, DraftPoll, QWhere> {
  QueryBuilder<DraftPoll, DraftPoll, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DraftPollQueryWhere
    on QueryBuilder<DraftPoll, DraftPoll, QWhereClause> {
  QueryBuilder<DraftPoll, DraftPoll, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<DraftPoll, DraftPoll, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DraftPollQueryFilter
    on QueryBuilder<DraftPoll, DraftPoll, QFilterCondition> {
  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  allowCommentsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'allowComments', value: value),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> expiryDaysEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'expiryDays', value: value),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  expiryDaysGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'expiryDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> expiryDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'expiryDays',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> expiryDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'expiryDays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'options',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'options',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'options',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'options', value: ''),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'options', value: ''),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'options', length, true, length, true);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> optionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'options', 0, true, 0, true);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'options', 0, false, 999999, true);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'options', 0, true, length, include);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'options', length, include, 999999, true);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  optionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'options',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'question',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'question',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'question',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> questionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'question', value: ''),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  questionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'question', value: ''),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> updatedAtEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterFilterCondition> updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DraftPollQueryObject
    on QueryBuilder<DraftPoll, DraftPoll, QFilterCondition> {}

extension DraftPollQueryLinks
    on QueryBuilder<DraftPoll, DraftPoll, QFilterCondition> {}

extension DraftPollQuerySortBy on QueryBuilder<DraftPoll, DraftPoll, QSortBy> {
  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByAllowComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowComments', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByAllowCommentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowComments', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByExpiryDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDays', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByExpiryDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDays', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DraftPollQuerySortThenBy
    on QueryBuilder<DraftPoll, DraftPoll, QSortThenBy> {
  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByAllowComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowComments', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByAllowCommentsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'allowComments', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByExpiryDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDays', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByExpiryDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDays', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByQuestion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByQuestionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'question', Sort.desc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DraftPollQueryWhereDistinct
    on QueryBuilder<DraftPoll, DraftPoll, QDistinct> {
  QueryBuilder<DraftPoll, DraftPoll, QDistinct> distinctByAllowComments() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowComments');
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QDistinct> distinctByExpiryDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDays');
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QDistinct> distinctByOptions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'options');
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QDistinct> distinctByQuestion({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'question', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DraftPoll, DraftPoll, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DraftPollQueryProperty
    on QueryBuilder<DraftPoll, DraftPoll, QQueryProperty> {
  QueryBuilder<DraftPoll, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DraftPoll, bool, QQueryOperations> allowCommentsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowComments');
    });
  }

  QueryBuilder<DraftPoll, int, QQueryOperations> expiryDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDays');
    });
  }

  QueryBuilder<DraftPoll, List<String>, QQueryOperations> optionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'options');
    });
  }

  QueryBuilder<DraftPoll, String, QQueryOperations> questionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'question');
    });
  }

  QueryBuilder<DraftPoll, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
