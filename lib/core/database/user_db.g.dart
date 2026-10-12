// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_db.dart';

// ignore_for_file: type=lint
class $BookmarksTable extends Bookmarks with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
    'word_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _labelSnapshotMeta = const VerificationMeta('labelSnapshot');
  @override
  late final GeneratedColumn<String> labelSnapshot = GeneratedColumn<String>(
    'label_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, deletedAt, syncStatus, id, wordId, labelSnapshot, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta, wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('label_snapshot')) {
      context.handle(
        _labelSnapshotMeta,
        labelSnapshot.isAcceptableOrUnknown(data['label_snapshot']!, _labelSnapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_labelSnapshotMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      labelSnapshot: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}label_snapshot'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String updatedAt;
  final String? deletedAt;
  final int syncStatus;
  final String id;
  final int wordId;
  final String labelSnapshot;
  final String createdAt;
  const Bookmark({
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.id,
    required this.wordId,
    required this.labelSnapshot,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['id'] = Variable<String>(id);
    map['word_id'] = Variable<int>(wordId);
    map['label_snapshot'] = Variable<String>(labelSnapshot);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      syncStatus: Value(syncStatus),
      id: Value(id),
      wordId: Value(wordId),
      labelSnapshot: Value(labelSnapshot),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      id: serializer.fromJson<String>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      labelSnapshot: serializer.fromJson<String>(json['labelSnapshot']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'id': serializer.toJson<String>(id),
      'wordId': serializer.toJson<int>(wordId),
      'labelSnapshot': serializer.toJson<String>(labelSnapshot),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Bookmark copyWith({
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    int? syncStatus,
    String? id,
    int? wordId,
    String? labelSnapshot,
    String? createdAt,
  }) => Bookmark(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    id: id ?? this.id,
    wordId: wordId ?? this.wordId,
    labelSnapshot: labelSnapshot ?? this.labelSnapshot,
    createdAt: createdAt ?? this.createdAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      labelSnapshot: data.labelSnapshot.present ? data.labelSnapshot.value : this.labelSnapshot,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, syncStatus, id, wordId, labelSnapshot, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.labelSnapshot == this.labelSnapshot &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> syncStatus;
  final Value<String> id;
  final Value<int> wordId;
  final Value<String> labelSnapshot;
  final Value<String> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String id,
    required int wordId,
    required String labelSnapshot,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       wordId = Value(wordId),
       labelSnapshot = Value(labelSnapshot),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? syncStatus,
    Expression<String>? id,
    Expression<int>? wordId,
    Expression<String>? labelSnapshot,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (labelSnapshot != null) 'label_snapshot': labelSnapshot,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? syncStatus,
    Value<String>? id,
    Value<int>? wordId,
    Value<String>? labelSnapshot,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      labelSnapshot: labelSnapshot ?? this.labelSnapshot,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (labelSnapshot.present) {
      map['label_snapshot'] = Variable<String>(labelSnapshot.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SrsCardsTable extends SrsCards with TableInfo<$SrsCardsTable, SrsCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardTypeMeta = const VerificationMeta('cardType');
  @override
  late final GeneratedColumn<String> cardType = GeneratedColumn<String>(
    'card_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _directionMeta = const VerificationMeta('direction');
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('jp_to_meaning'),
  );
  static const VerificationMeta _labelSnapshotMeta = const VerificationMeta('labelSnapshot');
  @override
  late final GeneratedColumn<String> labelSnapshot = GeneratedColumn<String>(
    'label_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<String> dueAt = GeneratedColumn<String>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta('intervalDays');
  @override
  late final GeneratedColumn<double> intervalDays = GeneratedColumn<double>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeMeta = const VerificationMeta('ease');
  @override
  late final GeneratedColumn<double> ease = GeneratedColumn<double>(
    'ease',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isOrphanMeta = const VerificationMeta('isOrphan');
  @override
  late final GeneratedColumn<int> isOrphan = GeneratedColumn<int>(
    'is_orphan',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    updatedAt,
    deletedAt,
    syncStatus,
    id,
    cardType,
    itemId,
    direction,
    labelSnapshot,
    state,
    dueAt,
    intervalDays,
    ease,
    reps,
    lapses,
    isOrphan,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'srs_cards';
  @override
  VerificationContext validateIntegrity(Insertable<SrsCard> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_type')) {
      context.handle(_cardTypeMeta, cardType.isAcceptableOrUnknown(data['card_type']!, _cardTypeMeta));
    } else if (isInserting) {
      context.missing(_cardTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(_directionMeta, direction.isAcceptableOrUnknown(data['direction']!, _directionMeta));
    }
    if (data.containsKey('label_snapshot')) {
      context.handle(
        _labelSnapshotMeta,
        labelSnapshot.isAcceptableOrUnknown(data['label_snapshot']!, _labelSnapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_labelSnapshotMeta);
    }
    if (data.containsKey('state')) {
      context.handle(_stateMeta, state.isAcceptableOrUnknown(data['state']!, _stateMeta));
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('due_at')) {
      context.handle(_dueAtMeta, dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta));
    }
    if (data.containsKey('interval_days')) {
      context.handle(_intervalDaysMeta, intervalDays.isAcceptableOrUnknown(data['interval_days']!, _intervalDaysMeta));
    }
    if (data.containsKey('ease')) {
      context.handle(_easeMeta, ease.isAcceptableOrUnknown(data['ease']!, _easeMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(_repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta, lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('is_orphan')) {
      context.handle(_isOrphanMeta, isOrphan.isAcceptableOrUnknown(data['is_orphan']!, _isOrphanMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cardType, itemId, direction},
  ];
  @override
  SrsCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SrsCard(
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cardType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}card_type'])!,
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      direction: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}direction'])!,
      labelSnapshot: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}label_snapshot'])!,
      state: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      dueAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}due_at']),
      intervalDays: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}interval_days'])!,
      ease: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}ease'])!,
      reps: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps'])!,
      lapses: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      isOrphan: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}is_orphan'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SrsCardsTable createAlias(String alias) {
    return $SrsCardsTable(attachedDatabase, alias);
  }
}

class SrsCard extends DataClass implements Insertable<SrsCard> {
  final String updatedAt;
  final String? deletedAt;
  final int syncStatus;
  final String id;
  final String cardType;
  final String itemId;
  final String direction;
  final String labelSnapshot;
  final String state;
  final String? dueAt;
  final double intervalDays;
  final double ease;
  final int reps;
  final int lapses;
  final int isOrphan;
  final String createdAt;
  const SrsCard({
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.id,
    required this.cardType,
    required this.itemId,
    required this.direction,
    required this.labelSnapshot,
    required this.state,
    this.dueAt,
    required this.intervalDays,
    required this.ease,
    required this.reps,
    required this.lapses,
    required this.isOrphan,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['id'] = Variable<String>(id);
    map['card_type'] = Variable<String>(cardType);
    map['item_id'] = Variable<String>(itemId);
    map['direction'] = Variable<String>(direction);
    map['label_snapshot'] = Variable<String>(labelSnapshot);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<String>(dueAt);
    }
    map['interval_days'] = Variable<double>(intervalDays);
    map['ease'] = Variable<double>(ease);
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['is_orphan'] = Variable<int>(isOrphan);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SrsCardsCompanion toCompanion(bool nullToAbsent) {
    return SrsCardsCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      syncStatus: Value(syncStatus),
      id: Value(id),
      cardType: Value(cardType),
      itemId: Value(itemId),
      direction: Value(direction),
      labelSnapshot: Value(labelSnapshot),
      state: Value(state),
      dueAt: dueAt == null && nullToAbsent ? const Value.absent() : Value(dueAt),
      intervalDays: Value(intervalDays),
      ease: Value(ease),
      reps: Value(reps),
      lapses: Value(lapses),
      isOrphan: Value(isOrphan),
      createdAt: Value(createdAt),
    );
  }

  factory SrsCard.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SrsCard(
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      id: serializer.fromJson<String>(json['id']),
      cardType: serializer.fromJson<String>(json['cardType']),
      itemId: serializer.fromJson<String>(json['itemId']),
      direction: serializer.fromJson<String>(json['direction']),
      labelSnapshot: serializer.fromJson<String>(json['labelSnapshot']),
      state: serializer.fromJson<String>(json['state']),
      dueAt: serializer.fromJson<String?>(json['dueAt']),
      intervalDays: serializer.fromJson<double>(json['intervalDays']),
      ease: serializer.fromJson<double>(json['ease']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      isOrphan: serializer.fromJson<int>(json['isOrphan']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'id': serializer.toJson<String>(id),
      'cardType': serializer.toJson<String>(cardType),
      'itemId': serializer.toJson<String>(itemId),
      'direction': serializer.toJson<String>(direction),
      'labelSnapshot': serializer.toJson<String>(labelSnapshot),
      'state': serializer.toJson<String>(state),
      'dueAt': serializer.toJson<String?>(dueAt),
      'intervalDays': serializer.toJson<double>(intervalDays),
      'ease': serializer.toJson<double>(ease),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'isOrphan': serializer.toJson<int>(isOrphan),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  SrsCard copyWith({
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    int? syncStatus,
    String? id,
    String? cardType,
    String? itemId,
    String? direction,
    String? labelSnapshot,
    String? state,
    Value<String?> dueAt = const Value.absent(),
    double? intervalDays,
    double? ease,
    int? reps,
    int? lapses,
    int? isOrphan,
    String? createdAt,
  }) => SrsCard(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    id: id ?? this.id,
    cardType: cardType ?? this.cardType,
    itemId: itemId ?? this.itemId,
    direction: direction ?? this.direction,
    labelSnapshot: labelSnapshot ?? this.labelSnapshot,
    state: state ?? this.state,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    intervalDays: intervalDays ?? this.intervalDays,
    ease: ease ?? this.ease,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    isOrphan: isOrphan ?? this.isOrphan,
    createdAt: createdAt ?? this.createdAt,
  );
  SrsCard copyWithCompanion(SrsCardsCompanion data) {
    return SrsCard(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      id: data.id.present ? data.id.value : this.id,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      direction: data.direction.present ? data.direction.value : this.direction,
      labelSnapshot: data.labelSnapshot.present ? data.labelSnapshot.value : this.labelSnapshot,
      state: data.state.present ? data.state.value : this.state,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalDays: data.intervalDays.present ? data.intervalDays.value : this.intervalDays,
      ease: data.ease.present ? data.ease.value : this.ease,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      isOrphan: data.isOrphan.present ? data.isOrphan.value : this.isOrphan,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SrsCard(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('cardType: $cardType, ')
          ..write('itemId: $itemId, ')
          ..write('direction: $direction, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('state: $state, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('isOrphan: $isOrphan, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    updatedAt,
    deletedAt,
    syncStatus,
    id,
    cardType,
    itemId,
    direction,
    labelSnapshot,
    state,
    dueAt,
    intervalDays,
    ease,
    reps,
    lapses,
    isOrphan,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SrsCard &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.id == this.id &&
          other.cardType == this.cardType &&
          other.itemId == this.itemId &&
          other.direction == this.direction &&
          other.labelSnapshot == this.labelSnapshot &&
          other.state == this.state &&
          other.dueAt == this.dueAt &&
          other.intervalDays == this.intervalDays &&
          other.ease == this.ease &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.isOrphan == this.isOrphan &&
          other.createdAt == this.createdAt);
}

class SrsCardsCompanion extends UpdateCompanion<SrsCard> {
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> syncStatus;
  final Value<String> id;
  final Value<String> cardType;
  final Value<String> itemId;
  final Value<String> direction;
  final Value<String> labelSnapshot;
  final Value<String> state;
  final Value<String?> dueAt;
  final Value<double> intervalDays;
  final Value<double> ease;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> isOrphan;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SrsCardsCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.id = const Value.absent(),
    this.cardType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.direction = const Value.absent(),
    this.labelSnapshot = const Value.absent(),
    this.state = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.ease = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.isOrphan = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SrsCardsCompanion.insert({
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String id,
    required String cardType,
    required String itemId,
    this.direction = const Value.absent(),
    required String labelSnapshot,
    required String state,
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.ease = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.isOrphan = const Value.absent(),
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       cardType = Value(cardType),
       itemId = Value(itemId),
       labelSnapshot = Value(labelSnapshot),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<SrsCard> custom({
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? syncStatus,
    Expression<String>? id,
    Expression<String>? cardType,
    Expression<String>? itemId,
    Expression<String>? direction,
    Expression<String>? labelSnapshot,
    Expression<String>? state,
    Expression<String>? dueAt,
    Expression<double>? intervalDays,
    Expression<double>? ease,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? isOrphan,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (id != null) 'id': id,
      if (cardType != null) 'card_type': cardType,
      if (itemId != null) 'item_id': itemId,
      if (direction != null) 'direction': direction,
      if (labelSnapshot != null) 'label_snapshot': labelSnapshot,
      if (state != null) 'state': state,
      if (dueAt != null) 'due_at': dueAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (ease != null) 'ease': ease,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (isOrphan != null) 'is_orphan': isOrphan,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SrsCardsCompanion copyWith({
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? syncStatus,
    Value<String>? id,
    Value<String>? cardType,
    Value<String>? itemId,
    Value<String>? direction,
    Value<String>? labelSnapshot,
    Value<String>? state,
    Value<String?>? dueAt,
    Value<double>? intervalDays,
    Value<double>? ease,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? isOrphan,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SrsCardsCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      id: id ?? this.id,
      cardType: cardType ?? this.cardType,
      itemId: itemId ?? this.itemId,
      direction: direction ?? this.direction,
      labelSnapshot: labelSnapshot ?? this.labelSnapshot,
      state: state ?? this.state,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      ease: ease ?? this.ease,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      isOrphan: isOrphan ?? this.isOrphan,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<String>(cardType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (labelSnapshot.present) {
      map['label_snapshot'] = Variable<String>(labelSnapshot.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<String>(dueAt.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<double>(intervalDays.value);
    }
    if (ease.present) {
      map['ease'] = Variable<double>(ease.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (isOrphan.present) {
      map['is_orphan'] = Variable<int>(isOrphan.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SrsCardsCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('cardType: $cardType, ')
          ..write('itemId: $itemId, ')
          ..write('direction: $direction, ')
          ..write('labelSnapshot: $labelSnapshot, ')
          ..write('state: $state, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('ease: $ease, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('isOrphan: $isOrphan, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonProgressTable extends LessonProgress with TableInfo<$LessonProgressTable, LessonProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, deletedAt, syncStatus, id, lessonId, status, score, completedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_progress';
  @override
  VerificationContext validateIntegrity(Insertable<LessonProgressRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta, lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('score')) {
      context.handle(_scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonProgressRow(
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lessonId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      score: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}score']),
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $LessonProgressTable createAlias(String alias) {
    return $LessonProgressTable(attachedDatabase, alias);
  }
}

class LessonProgressRow extends DataClass implements Insertable<LessonProgressRow> {
  final String updatedAt;
  final String? deletedAt;
  final int syncStatus;
  final String id;
  final String lessonId;
  final String status;
  final double? score;
  final String? completedAt;
  const LessonProgressRow({
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.id,
    required this.lessonId,
    required this.status,
    this.score,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['id'] = Variable<String>(id);
    map['lesson_id'] = Variable<String>(lessonId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    return map;
  }

  LessonProgressCompanion toCompanion(bool nullToAbsent) {
    return LessonProgressCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      syncStatus: Value(syncStatus),
      id: Value(id),
      lessonId: Value(lessonId),
      status: Value(status),
      score: score == null && nullToAbsent ? const Value.absent() : Value(score),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
    );
  }

  factory LessonProgressRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonProgressRow(
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      id: serializer.fromJson<String>(json['id']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      status: serializer.fromJson<String>(json['status']),
      score: serializer.fromJson<double?>(json['score']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'id': serializer.toJson<String>(id),
      'lessonId': serializer.toJson<String>(lessonId),
      'status': serializer.toJson<String>(status),
      'score': serializer.toJson<double?>(score),
      'completedAt': serializer.toJson<String?>(completedAt),
    };
  }

  LessonProgressRow copyWith({
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    int? syncStatus,
    String? id,
    String? lessonId,
    String? status,
    Value<double?> score = const Value.absent(),
    Value<String?> completedAt = const Value.absent(),
  }) => LessonProgressRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    id: id ?? this.id,
    lessonId: lessonId ?? this.lessonId,
    status: status ?? this.status,
    score: score.present ? score.value : this.score,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  LessonProgressRow copyWithCompanion(LessonProgressCompanion data) {
    return LessonProgressRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      score: data.score.present ? data.score.value : this.score,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, syncStatus, id, lessonId, status, score, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonProgressRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.score == this.score &&
          other.completedAt == this.completedAt);
}

class LessonProgressCompanion extends UpdateCompanion<LessonProgressRow> {
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> syncStatus;
  final Value<String> id;
  final Value<String> lessonId;
  final Value<String> status;
  final Value<double?> score;
  final Value<String?> completedAt;
  final Value<int> rowid;
  const LessonProgressCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonProgressCompanion.insert({
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String id,
    required String lessonId,
    required String status,
    this.score = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       lessonId = Value(lessonId),
       status = Value(status);
  static Insertable<LessonProgressRow> custom({
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? syncStatus,
    Expression<String>? id,
    Expression<String>? lessonId,
    Expression<String>? status,
    Expression<double>? score,
    Expression<String>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonProgressCompanion copyWith({
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? syncStatus,
    Value<String>? id,
    Value<String>? lessonId,
    Value<String>? status,
    Value<double?>? score,
    Value<String?>? completedAt,
    Value<int>? rowid,
  }) {
    return LessonProgressCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      score: score ?? this.score,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonProgressCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress with TableInfo<$ReadingProgressTable, ReadingProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storyIdMeta = const VerificationMeta('storyId');
  @override
  late final GeneratedColumn<String> storyId = GeneratedColumn<String>(
    'story_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<double> score = GeneratedColumn<double>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, deletedAt, syncStatus, id, storyId, status, score];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(Insertable<ReadingProgressRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('story_id')) {
      context.handle(_storyIdMeta, storyId.isAcceptableOrUnknown(data['story_id']!, _storyIdMeta));
    } else if (isInserting) {
      context.missing(_storyIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta, status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('score')) {
      context.handle(_scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressRow(
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      storyId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}story_id'])!,
      status: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      score: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}score']),
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressRow extends DataClass implements Insertable<ReadingProgressRow> {
  final String updatedAt;
  final String? deletedAt;
  final int syncStatus;
  final String id;
  final String storyId;
  final String status;
  final double? score;
  const ReadingProgressRow({
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.id,
    required this.storyId,
    required this.status,
    this.score,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['id'] = Variable<String>(id);
    map['story_id'] = Variable<String>(storyId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<double>(score);
    }
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      syncStatus: Value(syncStatus),
      id: Value(id),
      storyId: Value(storyId),
      status: Value(status),
      score: score == null && nullToAbsent ? const Value.absent() : Value(score),
    );
  }

  factory ReadingProgressRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressRow(
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      id: serializer.fromJson<String>(json['id']),
      storyId: serializer.fromJson<String>(json['storyId']),
      status: serializer.fromJson<String>(json['status']),
      score: serializer.fromJson<double?>(json['score']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'id': serializer.toJson<String>(id),
      'storyId': serializer.toJson<String>(storyId),
      'status': serializer.toJson<String>(status),
      'score': serializer.toJson<double?>(score),
    };
  }

  ReadingProgressRow copyWith({
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    int? syncStatus,
    String? id,
    String? storyId,
    String? status,
    Value<double?> score = const Value.absent(),
  }) => ReadingProgressRow(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    id: id ?? this.id,
    storyId: storyId ?? this.storyId,
    status: status ?? this.status,
    score: score.present ? score.value : this.score,
  );
  ReadingProgressRow copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressRow(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      id: data.id.present ? data.id.value : this.id,
      storyId: data.storyId.present ? data.storyId.value : this.storyId,
      status: data.status.present ? data.status.value : this.status,
      score: data.score.present ? data.score.value : this.score,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressRow(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('status: $status, ')
          ..write('score: $score')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, syncStatus, id, storyId, status, score);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressRow &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.id == this.id &&
          other.storyId == this.storyId &&
          other.status == this.status &&
          other.score == this.score);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressRow> {
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> syncStatus;
  final Value<String> id;
  final Value<String> storyId;
  final Value<String> status;
  final Value<double?> score;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.id = const Value.absent(),
    this.storyId = const Value.absent(),
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String id,
    required String storyId,
    required String status,
    this.score = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       storyId = Value(storyId),
       status = Value(status);
  static Insertable<ReadingProgressRow> custom({
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? syncStatus,
    Expression<String>? id,
    Expression<String>? storyId,
    Expression<String>? status,
    Expression<double>? score,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (id != null) 'id': id,
      if (storyId != null) 'story_id': storyId,
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? syncStatus,
    Value<String>? id,
    Value<String>? storyId,
    Value<String>? status,
    Value<double?>? score,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      status: status ?? this.status,
      score: score ?? this.score,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storyId.present) {
      map['story_id'] = Variable<String>(storyId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (score.present) {
      map['score'] = Variable<double>(score.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('storyId: $storyId, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserAchievementsTable extends UserAchievements with TableInfo<$UserAchievementsTable, UserAchievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserAchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievementIdMeta = const VerificationMeta('achievementId');
  @override
  late final GeneratedColumn<String> achievementId = GeneratedColumn<String>(
    'achievement_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta('unlockedAt');
  @override
  late final GeneratedColumn<String> unlockedAt = GeneratedColumn<String>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, achievementId, unlockedAt, updatedAt, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_achievements';
  @override
  VerificationContext validateIntegrity(Insertable<UserAchievement> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('achievement_id')) {
      context.handle(
        _achievementIdMeta,
        achievementId.isAcceptableOrUnknown(data['achievement_id']!, _achievementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_achievementIdMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(_unlockedAtMeta, unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta));
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserAchievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserAchievement(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      achievementId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}achievement_id'])!,
      unlockedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}unlocked_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $UserAchievementsTable createAlias(String alias) {
    return $UserAchievementsTable(attachedDatabase, alias);
  }
}

class UserAchievement extends DataClass implements Insertable<UserAchievement> {
  final String id;
  final String achievementId;
  final String unlockedAt;
  final String updatedAt;
  final int syncStatus;
  const UserAchievement({
    required this.id,
    required this.achievementId,
    required this.unlockedAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['achievement_id'] = Variable<String>(achievementId);
    map['unlocked_at'] = Variable<String>(unlockedAt);
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  UserAchievementsCompanion toCompanion(bool nullToAbsent) {
    return UserAchievementsCompanion(
      id: Value(id),
      achievementId: Value(achievementId),
      unlockedAt: Value(unlockedAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserAchievement(
      id: serializer.fromJson<String>(json['id']),
      achievementId: serializer.fromJson<String>(json['achievementId']),
      unlockedAt: serializer.fromJson<String>(json['unlockedAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'achievementId': serializer.toJson<String>(achievementId),
      'unlockedAt': serializer.toJson<String>(unlockedAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  UserAchievement copyWith({
    String? id,
    String? achievementId,
    String? unlockedAt,
    String? updatedAt,
    int? syncStatus,
  }) => UserAchievement(
    id: id ?? this.id,
    achievementId: achievementId ?? this.achievementId,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  UserAchievement copyWithCompanion(UserAchievementsCompanion data) {
    return UserAchievement(
      id: data.id.present ? data.id.value : this.id,
      achievementId: data.achievementId.present ? data.achievementId.value : this.achievementId,
      unlockedAt: data.unlockedAt.present ? data.unlockedAt.value : this.unlockedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserAchievement(')
          ..write('id: $id, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, achievementId, unlockedAt, updatedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserAchievement &&
          other.id == this.id &&
          other.achievementId == this.achievementId &&
          other.unlockedAt == this.unlockedAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class UserAchievementsCompanion extends UpdateCompanion<UserAchievement> {
  final Value<String> id;
  final Value<String> achievementId;
  final Value<String> unlockedAt;
  final Value<String> updatedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const UserAchievementsCompanion({
    this.id = const Value.absent(),
    this.achievementId = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserAchievementsCompanion.insert({
    required String id,
    required String achievementId,
    required String unlockedAt,
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       achievementId = Value(achievementId),
       unlockedAt = Value(unlockedAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserAchievement> custom({
    Expression<String>? id,
    Expression<String>? achievementId,
    Expression<String>? unlockedAt,
    Expression<String>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (achievementId != null) 'achievement_id': achievementId,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserAchievementsCompanion copyWith({
    Value<String>? id,
    Value<String>? achievementId,
    Value<String>? unlockedAt,
    Value<String>? updatedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return UserAchievementsCompanion(
      id: id ?? this.id,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (achievementId.present) {
      map['achievement_id'] = Variable<String>(achievementId.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<String>(unlockedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserAchievementsCompanion(')
          ..write('id: $id, ')
          ..write('achievementId: $achievementId, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(Insertable<UserSetting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value']),
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final String key;
  final String? value;
  final String updatedAt;
  final int syncStatus;
  const UserSetting({required this.key, this.value, required this.updatedAt, required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent ? const Value.absent() : Value(value),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory UserSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  UserSetting copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
    String? updatedAt,
    int? syncStatus,
  }) => UserSetting(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<String> updatedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const UserSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       updatedAt = Value(updatedAt);
  static Insertable<UserSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserSettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<String>? updatedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return UserSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs with TableInfo<$ReviewLogsTable, ReviewLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<String> reviewedAt = GeneratedColumn<String>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyDateMeta = const VerificationMeta('studyDate');
  @override
  late final GeneratedColumn<String> studyDate = GeneratedColumn<String>(
    'study_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prevStateMeta = const VerificationMeta('prevState');
  @override
  late final GeneratedColumn<String> prevState = GeneratedColumn<String>(
    'prev_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prevIntervalMeta = const VerificationMeta('prevInterval');
  @override
  late final GeneratedColumn<double> prevInterval = GeneratedColumn<double>(
    'prev_interval',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newIntervalMeta = const VerificationMeta('newInterval');
  @override
  late final GeneratedColumn<double> newInterval = GeneratedColumn<double>(
    'new_interval',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    rating,
    reviewedAt,
    studyDate,
    prevState,
    prevInterval,
    newInterval,
    durationMs,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewLog> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta, cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta, rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(_reviewedAtMeta, reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('study_date')) {
      context.handle(_studyDateMeta, studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta));
    } else if (isInserting) {
      context.missing(_studyDateMeta);
    }
    if (data.containsKey('prev_state')) {
      context.handle(_prevStateMeta, prevState.isAcceptableOrUnknown(data['prev_state']!, _prevStateMeta));
    }
    if (data.containsKey('prev_interval')) {
      context.handle(_prevIntervalMeta, prevInterval.isAcceptableOrUnknown(data['prev_interval']!, _prevIntervalMeta));
    }
    if (data.containsKey('new_interval')) {
      context.handle(_newIntervalMeta, newInterval.isAcceptableOrUnknown(data['new_interval']!, _newIntervalMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLog(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}card_id'])!,
      rating: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rating'])!,
      reviewedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reviewed_at'])!,
      studyDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}study_date'])!,
      prevState: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}prev_state']),
      prevInterval: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}prev_interval']),
      newInterval: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}new_interval']),
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLog extends DataClass implements Insertable<ReviewLog> {
  final String id;
  final String cardId;
  final int rating;
  final String reviewedAt;
  final String studyDate;
  final String? prevState;
  final double? prevInterval;
  final double? newInterval;
  final int? durationMs;
  final int syncStatus;
  const ReviewLog({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.reviewedAt,
    required this.studyDate,
    this.prevState,
    this.prevInterval,
    this.newInterval,
    this.durationMs,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<String>(reviewedAt);
    map['study_date'] = Variable<String>(studyDate);
    if (!nullToAbsent || prevState != null) {
      map['prev_state'] = Variable<String>(prevState);
    }
    if (!nullToAbsent || prevInterval != null) {
      map['prev_interval'] = Variable<double>(prevInterval);
    }
    if (!nullToAbsent || newInterval != null) {
      map['new_interval'] = Variable<double>(newInterval);
    }
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      studyDate: Value(studyDate),
      prevState: prevState == null && nullToAbsent ? const Value.absent() : Value(prevState),
      prevInterval: prevInterval == null && nullToAbsent ? const Value.absent() : Value(prevInterval),
      newInterval: newInterval == null && nullToAbsent ? const Value.absent() : Value(newInterval),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      syncStatus: Value(syncStatus),
    );
  }

  factory ReviewLog.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLog(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<String>(json['reviewedAt']),
      studyDate: serializer.fromJson<String>(json['studyDate']),
      prevState: serializer.fromJson<String?>(json['prevState']),
      prevInterval: serializer.fromJson<double?>(json['prevInterval']),
      newInterval: serializer.fromJson<double?>(json['newInterval']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<String>(reviewedAt),
      'studyDate': serializer.toJson<String>(studyDate),
      'prevState': serializer.toJson<String?>(prevState),
      'prevInterval': serializer.toJson<double?>(prevInterval),
      'newInterval': serializer.toJson<double?>(newInterval),
      'durationMs': serializer.toJson<int?>(durationMs),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ReviewLog copyWith({
    String? id,
    String? cardId,
    int? rating,
    String? reviewedAt,
    String? studyDate,
    Value<String?> prevState = const Value.absent(),
    Value<double?> prevInterval = const Value.absent(),
    Value<double?> newInterval = const Value.absent(),
    Value<int?> durationMs = const Value.absent(),
    int? syncStatus,
  }) => ReviewLog(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    studyDate: studyDate ?? this.studyDate,
    prevState: prevState.present ? prevState.value : this.prevState,
    prevInterval: prevInterval.present ? prevInterval.value : this.prevInterval,
    newInterval: newInterval.present ? newInterval.value : this.newInterval,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ReviewLog copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLog(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
      prevState: data.prevState.present ? data.prevState.value : this.prevState,
      prevInterval: data.prevInterval.present ? data.prevInterval.value : this.prevInterval,
      newInterval: data.newInterval.present ? data.newInterval.value : this.newInterval,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLog(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('studyDate: $studyDate, ')
          ..write('prevState: $prevState, ')
          ..write('prevInterval: $prevInterval, ')
          ..write('newInterval: $newInterval, ')
          ..write('durationMs: $durationMs, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    rating,
    reviewedAt,
    studyDate,
    prevState,
    prevInterval,
    newInterval,
    durationMs,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLog &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.studyDate == this.studyDate &&
          other.prevState == this.prevState &&
          other.prevInterval == this.prevInterval &&
          other.newInterval == this.newInterval &&
          other.durationMs == this.durationMs &&
          other.syncStatus == this.syncStatus);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLog> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<int> rating;
  final Value<String> reviewedAt;
  final Value<String> studyDate;
  final Value<String?> prevState;
  final Value<double?> prevInterval;
  final Value<double?> newInterval;
  final Value<int?> durationMs;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.prevState = const Value.absent(),
    this.prevInterval = const Value.absent(),
    this.newInterval = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String cardId,
    required int rating,
    required String reviewedAt,
    required String studyDate,
    this.prevState = const Value.absent(),
    this.prevInterval = const Value.absent(),
    this.newInterval = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt),
       studyDate = Value(studyDate);
  static Insertable<ReviewLog> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<int>? rating,
    Expression<String>? reviewedAt,
    Expression<String>? studyDate,
    Expression<String>? prevState,
    Expression<double>? prevInterval,
    Expression<double>? newInterval,
    Expression<int>? durationMs,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (studyDate != null) 'study_date': studyDate,
      if (prevState != null) 'prev_state': prevState,
      if (prevInterval != null) 'prev_interval': prevInterval,
      if (newInterval != null) 'new_interval': newInterval,
      if (durationMs != null) 'duration_ms': durationMs,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<int>? rating,
    Value<String>? reviewedAt,
    Value<String>? studyDate,
    Value<String?>? prevState,
    Value<double?>? prevInterval,
    Value<double?>? newInterval,
    Value<int?>? durationMs,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      studyDate: studyDate ?? this.studyDate,
      prevState: prevState ?? this.prevState,
      prevInterval: prevInterval ?? this.prevInterval,
      newInterval: newInterval ?? this.newInterval,
      durationMs: durationMs ?? this.durationMs,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<String>(reviewedAt.value);
    }
    if (studyDate.present) {
      map['study_date'] = Variable<String>(studyDate.value);
    }
    if (prevState.present) {
      map['prev_state'] = Variable<String>(prevState.value);
    }
    if (prevInterval.present) {
      map['prev_interval'] = Variable<double>(prevInterval.value);
    }
    if (newInterval.present) {
      map['new_interval'] = Variable<double>(newInterval.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('studyDate: $studyDate, ')
          ..write('prevState: $prevState, ')
          ..write('prevInterval: $prevInterval, ')
          ..write('newInterval: $newInterval, ')
          ..write('durationMs: $durationMs, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExerciseAttemptsTable extends ExerciseAttempts with TableInfo<$ExerciseAttemptsTable, ExerciseAttempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseTypeMeta = const VerificationMeta('exerciseType');
  @override
  late final GeneratedColumn<String> exerciseType = GeneratedColumn<String>(
    'exercise_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta('correct');
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta('answeredAt');
  @override
  late final GeneratedColumn<String> answeredAt = GeneratedColumn<String>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _studyDateMeta = const VerificationMeta('studyDate');
  @override
  late final GeneratedColumn<String> studyDate = GeneratedColumn<String>(
    'study_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseType,
    itemId,
    correct,
    answeredAt,
    studyDate,
    durationMs,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_attempts';
  @override
  VerificationContext validateIntegrity(Insertable<ExerciseAttempt> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('exercise_type')) {
      context.handle(_exerciseTypeMeta, exerciseType.isAcceptableOrUnknown(data['exercise_type']!, _exerciseTypeMeta));
    } else if (isInserting) {
      context.missing(_exerciseTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    }
    if (data.containsKey('correct')) {
      context.handle(_correctMeta, correct.isAcceptableOrUnknown(data['correct']!, _correctMeta));
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('answered_at')) {
      context.handle(_answeredAtMeta, answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta));
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    if (data.containsKey('study_date')) {
      context.handle(_studyDateMeta, studyDate.isAcceptableOrUnknown(data['study_date']!, _studyDateMeta));
    } else if (isInserting) {
      context.missing(_studyDateMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(_durationMsMeta, durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseAttempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseAttempt(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      exerciseType: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_type'])!,
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id']),
      correct: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct'])!,
      answeredAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}answered_at'])!,
      studyDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}study_date'])!,
      durationMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_ms']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $ExerciseAttemptsTable createAlias(String alias) {
    return $ExerciseAttemptsTable(attachedDatabase, alias);
  }
}

class ExerciseAttempt extends DataClass implements Insertable<ExerciseAttempt> {
  final String id;
  final String exerciseType;
  final String? itemId;
  final int correct;
  final String answeredAt;
  final String studyDate;
  final int? durationMs;
  final int syncStatus;
  const ExerciseAttempt({
    required this.id,
    required this.exerciseType,
    this.itemId,
    required this.correct,
    required this.answeredAt,
    required this.studyDate,
    this.durationMs,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['exercise_type'] = Variable<String>(exerciseType);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<String>(itemId);
    }
    map['correct'] = Variable<int>(correct);
    map['answered_at'] = Variable<String>(answeredAt);
    map['study_date'] = Variable<String>(studyDate);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  ExerciseAttemptsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseAttemptsCompanion(
      id: Value(id),
      exerciseType: Value(exerciseType),
      itemId: itemId == null && nullToAbsent ? const Value.absent() : Value(itemId),
      correct: Value(correct),
      answeredAt: Value(answeredAt),
      studyDate: Value(studyDate),
      durationMs: durationMs == null && nullToAbsent ? const Value.absent() : Value(durationMs),
      syncStatus: Value(syncStatus),
    );
  }

  factory ExerciseAttempt.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseAttempt(
      id: serializer.fromJson<String>(json['id']),
      exerciseType: serializer.fromJson<String>(json['exerciseType']),
      itemId: serializer.fromJson<String?>(json['itemId']),
      correct: serializer.fromJson<int>(json['correct']),
      answeredAt: serializer.fromJson<String>(json['answeredAt']),
      studyDate: serializer.fromJson<String>(json['studyDate']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'exerciseType': serializer.toJson<String>(exerciseType),
      'itemId': serializer.toJson<String?>(itemId),
      'correct': serializer.toJson<int>(correct),
      'answeredAt': serializer.toJson<String>(answeredAt),
      'studyDate': serializer.toJson<String>(studyDate),
      'durationMs': serializer.toJson<int?>(durationMs),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  ExerciseAttempt copyWith({
    String? id,
    String? exerciseType,
    Value<String?> itemId = const Value.absent(),
    int? correct,
    String? answeredAt,
    String? studyDate,
    Value<int?> durationMs = const Value.absent(),
    int? syncStatus,
  }) => ExerciseAttempt(
    id: id ?? this.id,
    exerciseType: exerciseType ?? this.exerciseType,
    itemId: itemId.present ? itemId.value : this.itemId,
    correct: correct ?? this.correct,
    answeredAt: answeredAt ?? this.answeredAt,
    studyDate: studyDate ?? this.studyDate,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ExerciseAttempt copyWithCompanion(ExerciseAttemptsCompanion data) {
    return ExerciseAttempt(
      id: data.id.present ? data.id.value : this.id,
      exerciseType: data.exerciseType.present ? data.exerciseType.value : this.exerciseType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      correct: data.correct.present ? data.correct.value : this.correct,
      answeredAt: data.answeredAt.present ? data.answeredAt.value : this.answeredAt,
      studyDate: data.studyDate.present ? data.studyDate.value : this.studyDate,
      durationMs: data.durationMs.present ? data.durationMs.value : this.durationMs,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttempt(')
          ..write('id: $id, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('itemId: $itemId, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('studyDate: $studyDate, ')
          ..write('durationMs: $durationMs, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseType, itemId, correct, answeredAt, studyDate, durationMs, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseAttempt &&
          other.id == this.id &&
          other.exerciseType == this.exerciseType &&
          other.itemId == this.itemId &&
          other.correct == this.correct &&
          other.answeredAt == this.answeredAt &&
          other.studyDate == this.studyDate &&
          other.durationMs == this.durationMs &&
          other.syncStatus == this.syncStatus);
}

class ExerciseAttemptsCompanion extends UpdateCompanion<ExerciseAttempt> {
  final Value<String> id;
  final Value<String> exerciseType;
  final Value<String?> itemId;
  final Value<int> correct;
  final Value<String> answeredAt;
  final Value<String> studyDate;
  final Value<int?> durationMs;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const ExerciseAttemptsCompanion({
    this.id = const Value.absent(),
    this.exerciseType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.correct = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.studyDate = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExerciseAttemptsCompanion.insert({
    required String id,
    required String exerciseType,
    this.itemId = const Value.absent(),
    required int correct,
    required String answeredAt,
    required String studyDate,
    this.durationMs = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       exerciseType = Value(exerciseType),
       correct = Value(correct),
       answeredAt = Value(answeredAt),
       studyDate = Value(studyDate);
  static Insertable<ExerciseAttempt> custom({
    Expression<String>? id,
    Expression<String>? exerciseType,
    Expression<String>? itemId,
    Expression<int>? correct,
    Expression<String>? answeredAt,
    Expression<String>? studyDate,
    Expression<int>? durationMs,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseType != null) 'exercise_type': exerciseType,
      if (itemId != null) 'item_id': itemId,
      if (correct != null) 'correct': correct,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (studyDate != null) 'study_date': studyDate,
      if (durationMs != null) 'duration_ms': durationMs,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExerciseAttemptsCompanion copyWith({
    Value<String>? id,
    Value<String>? exerciseType,
    Value<String?>? itemId,
    Value<int>? correct,
    Value<String>? answeredAt,
    Value<String>? studyDate,
    Value<int?>? durationMs,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return ExerciseAttemptsCompanion(
      id: id ?? this.id,
      exerciseType: exerciseType ?? this.exerciseType,
      itemId: itemId ?? this.itemId,
      correct: correct ?? this.correct,
      answeredAt: answeredAt ?? this.answeredAt,
      studyDate: studyDate ?? this.studyDate,
      durationMs: durationMs ?? this.durationMs,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (exerciseType.present) {
      map['exercise_type'] = Variable<String>(exerciseType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<String>(answeredAt.value);
    }
    if (studyDate.present) {
      map['study_date'] = Variable<String>(studyDate.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('exerciseType: $exerciseType, ')
          ..write('itemId: $itemId, ')
          ..write('correct: $correct, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('studyDate: $studyDate, ')
          ..write('durationMs: $durationMs, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GameScoresTable extends GameScores with TableInfo<$GameScoresTable, GameScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GameScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gameMeta = const VerificationMeta('game');
  @override
  late final GeneratedColumn<String> game = GeneratedColumn<String>(
    'game',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta('playedAt');
  @override
  late final GeneratedColumn<String> playedAt = GeneratedColumn<String>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, game, score, accuracy, playedAt, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'game_scores';
  @override
  VerificationContext validateIntegrity(Insertable<GameScore> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('game')) {
      context.handle(_gameMeta, game.isAcceptableOrUnknown(data['game']!, _gameMeta));
    } else if (isInserting) {
      context.missing(_gameMeta);
    }
    if (data.containsKey('score')) {
      context.handle(_scoreMeta, score.isAcceptableOrUnknown(data['score']!, _scoreMeta));
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta, accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('played_at')) {
      context.handle(_playedAtMeta, playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta));
    } else if (isInserting) {
      context.missing(_playedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GameScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GameScore(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      game: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}game'])!,
      score: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}score'])!,
      accuracy: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}accuracy']),
      playedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}played_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $GameScoresTable createAlias(String alias) {
    return $GameScoresTable(attachedDatabase, alias);
  }
}

class GameScore extends DataClass implements Insertable<GameScore> {
  final String id;
  final String game;
  final int score;
  final double? accuracy;
  final String playedAt;
  final int syncStatus;
  const GameScore({
    required this.id,
    required this.game,
    required this.score,
    this.accuracy,
    required this.playedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['game'] = Variable<String>(game);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    map['played_at'] = Variable<String>(playedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  GameScoresCompanion toCompanion(bool nullToAbsent) {
    return GameScoresCompanion(
      id: Value(id),
      game: Value(game),
      score: Value(score),
      accuracy: accuracy == null && nullToAbsent ? const Value.absent() : Value(accuracy),
      playedAt: Value(playedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory GameScore.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GameScore(
      id: serializer.fromJson<String>(json['id']),
      game: serializer.fromJson<String>(json['game']),
      score: serializer.fromJson<int>(json['score']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      playedAt: serializer.fromJson<String>(json['playedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'game': serializer.toJson<String>(game),
      'score': serializer.toJson<int>(score),
      'accuracy': serializer.toJson<double?>(accuracy),
      'playedAt': serializer.toJson<String>(playedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  GameScore copyWith({
    String? id,
    String? game,
    int? score,
    Value<double?> accuracy = const Value.absent(),
    String? playedAt,
    int? syncStatus,
  }) => GameScore(
    id: id ?? this.id,
    game: game ?? this.game,
    score: score ?? this.score,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    playedAt: playedAt ?? this.playedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  GameScore copyWithCompanion(GameScoresCompanion data) {
    return GameScore(
      id: data.id.present ? data.id.value : this.id,
      game: data.game.present ? data.game.value : this.game,
      score: data.score.present ? data.score.value : this.score,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GameScore(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('score: $score, ')
          ..write('accuracy: $accuracy, ')
          ..write('playedAt: $playedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, game, score, accuracy, playedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GameScore &&
          other.id == this.id &&
          other.game == this.game &&
          other.score == this.score &&
          other.accuracy == this.accuracy &&
          other.playedAt == this.playedAt &&
          other.syncStatus == this.syncStatus);
}

class GameScoresCompanion extends UpdateCompanion<GameScore> {
  final Value<String> id;
  final Value<String> game;
  final Value<int> score;
  final Value<double?> accuracy;
  final Value<String> playedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const GameScoresCompanion({
    this.id = const Value.absent(),
    this.game = const Value.absent(),
    this.score = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GameScoresCompanion.insert({
    required String id,
    required String game,
    required int score,
    this.accuracy = const Value.absent(),
    required String playedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       game = Value(game),
       score = Value(score),
       playedAt = Value(playedAt);
  static Insertable<GameScore> custom({
    Expression<String>? id,
    Expression<String>? game,
    Expression<int>? score,
    Expression<double>? accuracy,
    Expression<String>? playedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (game != null) 'game': game,
      if (score != null) 'score': score,
      if (accuracy != null) 'accuracy': accuracy,
      if (playedAt != null) 'played_at': playedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GameScoresCompanion copyWith({
    Value<String>? id,
    Value<String>? game,
    Value<int>? score,
    Value<double?>? accuracy,
    Value<String>? playedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return GameScoresCompanion(
      id: id ?? this.id,
      game: game ?? this.game,
      score: score ?? this.score,
      accuracy: accuracy ?? this.accuracy,
      playedAt: playedAt ?? this.playedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (game.present) {
      map['game'] = Variable<String>(game.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<String>(playedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GameScoresCompanion(')
          ..write('id: $id, ')
          ..write('game: $game, ')
          ..write('score: $score, ')
          ..write('accuracy: $accuracy, ')
          ..write('playedAt: $playedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakFreezesTable extends StreakFreezes with TableInfo<$StreakFreezesTable, StreakFreeze> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakFreezesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coveredDateMeta = const VerificationMeta('coveredDate');
  @override
  late final GeneratedColumn<String> coveredDate = GeneratedColumn<String>(
    'covered_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, coveredDate, createdAt, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_freezes';
  @override
  VerificationContext validateIntegrity(Insertable<StreakFreeze> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('covered_date')) {
      context.handle(_coveredDateMeta, coveredDate.isAcceptableOrUnknown(data['covered_date']!, _coveredDateMeta));
    } else if (isInserting) {
      context.missing(_coveredDateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakFreeze map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakFreeze(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      coveredDate: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}covered_date'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $StreakFreezesTable createAlias(String alias) {
    return $StreakFreezesTable(attachedDatabase, alias);
  }
}

class StreakFreeze extends DataClass implements Insertable<StreakFreeze> {
  final String id;
  final String coveredDate;
  final String createdAt;
  final int syncStatus;
  const StreakFreeze({required this.id, required this.coveredDate, required this.createdAt, required this.syncStatus});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['covered_date'] = Variable<String>(coveredDate);
    map['created_at'] = Variable<String>(createdAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  StreakFreezesCompanion toCompanion(bool nullToAbsent) {
    return StreakFreezesCompanion(
      id: Value(id),
      coveredDate: Value(coveredDate),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory StreakFreeze.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakFreeze(
      id: serializer.fromJson<String>(json['id']),
      coveredDate: serializer.fromJson<String>(json['coveredDate']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'coveredDate': serializer.toJson<String>(coveredDate),
      'createdAt': serializer.toJson<String>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  StreakFreeze copyWith({String? id, String? coveredDate, String? createdAt, int? syncStatus}) => StreakFreeze(
    id: id ?? this.id,
    coveredDate: coveredDate ?? this.coveredDate,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  StreakFreeze copyWithCompanion(StreakFreezesCompanion data) {
    return StreakFreeze(
      id: data.id.present ? data.id.value : this.id,
      coveredDate: data.coveredDate.present ? data.coveredDate.value : this.coveredDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakFreeze(')
          ..write('id: $id, ')
          ..write('coveredDate: $coveredDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, coveredDate, createdAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakFreeze &&
          other.id == this.id &&
          other.coveredDate == this.coveredDate &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class StreakFreezesCompanion extends UpdateCompanion<StreakFreeze> {
  final Value<String> id;
  final Value<String> coveredDate;
  final Value<String> createdAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const StreakFreezesCompanion({
    this.id = const Value.absent(),
    this.coveredDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StreakFreezesCompanion.insert({
    required String id,
    required String coveredDate,
    required String createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       coveredDate = Value(coveredDate),
       createdAt = Value(createdAt);
  static Insertable<StreakFreeze> custom({
    Expression<String>? id,
    Expression<String>? coveredDate,
    Expression<String>? createdAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (coveredDate != null) 'covered_date': coveredDate,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StreakFreezesCompanion copyWith({
    Value<String>? id,
    Value<String>? coveredDate,
    Value<String>? createdAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return StreakFreezesCompanion(
      id: id ?? this.id,
      coveredDate: coveredDate ?? this.coveredDate,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (coveredDate.present) {
      map['covered_date'] = Variable<String>(coveredDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakFreezesCompanion(')
          ..write('id: $id, ')
          ..write('coveredDate: $coveredDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CoinLedgerTable extends CoinLedger with TableInfo<$CoinLedgerTable, CoinLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoinLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [id, delta, reason, refId, createdAt, syncStatus];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'coin_ledger';
  @override
  VerificationContext validateIntegrity(Insertable<CoinLedgerData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(_deltaMeta, delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta));
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta, reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(_refIdMeta, refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CoinLedgerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CoinLedgerData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      delta: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}delta'])!,
      reason: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      refId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}ref_id']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}created_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $CoinLedgerTable createAlias(String alias) {
    return $CoinLedgerTable(attachedDatabase, alias);
  }
}

class CoinLedgerData extends DataClass implements Insertable<CoinLedgerData> {
  final String id;
  final int delta;
  final String reason;
  final String? refId;
  final String createdAt;
  final int syncStatus;
  const CoinLedgerData({
    required this.id,
    required this.delta,
    required this.reason,
    this.refId,
    required this.createdAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['delta'] = Variable<int>(delta);
    map['reason'] = Variable<String>(reason);
    if (!nullToAbsent || refId != null) {
      map['ref_id'] = Variable<String>(refId);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  CoinLedgerCompanion toCompanion(bool nullToAbsent) {
    return CoinLedgerCompanion(
      id: Value(id),
      delta: Value(delta),
      reason: Value(reason),
      refId: refId == null && nullToAbsent ? const Value.absent() : Value(refId),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory CoinLedgerData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CoinLedgerData(
      id: serializer.fromJson<String>(json['id']),
      delta: serializer.fromJson<int>(json['delta']),
      reason: serializer.fromJson<String>(json['reason']),
      refId: serializer.fromJson<String?>(json['refId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'delta': serializer.toJson<int>(delta),
      'reason': serializer.toJson<String>(reason),
      'refId': serializer.toJson<String?>(refId),
      'createdAt': serializer.toJson<String>(createdAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  CoinLedgerData copyWith({
    String? id,
    int? delta,
    String? reason,
    Value<String?> refId = const Value.absent(),
    String? createdAt,
    int? syncStatus,
  }) => CoinLedgerData(
    id: id ?? this.id,
    delta: delta ?? this.delta,
    reason: reason ?? this.reason,
    refId: refId.present ? refId.value : this.refId,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  CoinLedgerData copyWithCompanion(CoinLedgerCompanion data) {
    return CoinLedgerData(
      id: data.id.present ? data.id.value : this.id,
      delta: data.delta.present ? data.delta.value : this.delta,
      reason: data.reason.present ? data.reason.value : this.reason,
      refId: data.refId.present ? data.refId.value : this.refId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CoinLedgerData(')
          ..write('id: $id, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, delta, reason, refId, createdAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CoinLedgerData &&
          other.id == this.id &&
          other.delta == this.delta &&
          other.reason == this.reason &&
          other.refId == this.refId &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus);
}

class CoinLedgerCompanion extends UpdateCompanion<CoinLedgerData> {
  final Value<String> id;
  final Value<int> delta;
  final Value<String> reason;
  final Value<String?> refId;
  final Value<String> createdAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const CoinLedgerCompanion({
    this.id = const Value.absent(),
    this.delta = const Value.absent(),
    this.reason = const Value.absent(),
    this.refId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CoinLedgerCompanion.insert({
    required String id,
    required int delta,
    required String reason,
    this.refId = const Value.absent(),
    required String createdAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       delta = Value(delta),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<CoinLedgerData> custom({
    Expression<String>? id,
    Expression<int>? delta,
    Expression<String>? reason,
    Expression<String>? refId,
    Expression<String>? createdAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (delta != null) 'delta': delta,
      if (reason != null) 'reason': reason,
      if (refId != null) 'ref_id': refId,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CoinLedgerCompanion copyWith({
    Value<String>? id,
    Value<int>? delta,
    Value<String>? reason,
    Value<String?>? refId,
    Value<String>? createdAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return CoinLedgerCompanion(
      id: id ?? this.id,
      delta: delta ?? this.delta,
      reason: reason ?? this.reason,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoinLedgerCompanion(')
          ..write('id: $id, ')
          ..write('delta: $delta, ')
          ..write('reason: $reason, ')
          ..write('refId: $refId, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyStatsTable extends DailyStats with TableInfo<$DailyStatsTable, DailyStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _newCountMeta = const VerificationMeta('newCount');
  @override
  late final GeneratedColumn<int> newCount = GeneratedColumn<int>(
    'new_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta('reviewCount');
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _studyMsMeta = const VerificationMeta('studyMs');
  @override
  late final GeneratedColumn<int> studyMs = GeneratedColumn<int>(
    'study_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _xpMeta = const VerificationMeta('xp');
  @override
  late final GeneratedColumn<int> xp = GeneratedColumn<int>(
    'xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    deviceId,
    newCount,
    reviewCount,
    correctCount,
    studyMs,
    xp,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_stats';
  @override
  VerificationContext validateIntegrity(Insertable<DailyStat> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('new_count')) {
      context.handle(_newCountMeta, newCount.isAcceptableOrUnknown(data['new_count']!, _newCountMeta));
    }
    if (data.containsKey('review_count')) {
      context.handle(_reviewCountMeta, reviewCount.isAcceptableOrUnknown(data['review_count']!, _reviewCountMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(_correctCountMeta, correctCount.isAcceptableOrUnknown(data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('study_ms')) {
      context.handle(_studyMsMeta, studyMs.isAcceptableOrUnknown(data['study_ms']!, _studyMsMeta));
    }
    if (data.containsKey('xp')) {
      context.handle(_xpMeta, xp.isAcceptableOrUnknown(data['xp']!, _xpMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, deviceId};
  @override
  DailyStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyStat(
      date: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      newCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}new_count'])!,
      reviewCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}review_count'])!,
      correctCount: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      studyMs: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}study_ms'])!,
      xp: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}xp'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
    );
  }

  @override
  $DailyStatsTable createAlias(String alias) {
    return $DailyStatsTable(attachedDatabase, alias);
  }
}

class DailyStat extends DataClass implements Insertable<DailyStat> {
  final String date;
  final String deviceId;
  final int newCount;
  final int reviewCount;
  final int correctCount;
  final int studyMs;
  final int xp;
  final String updatedAt;
  final int syncStatus;
  const DailyStat({
    required this.date,
    required this.deviceId,
    required this.newCount,
    required this.reviewCount,
    required this.correctCount,
    required this.studyMs,
    required this.xp,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['device_id'] = Variable<String>(deviceId);
    map['new_count'] = Variable<int>(newCount);
    map['review_count'] = Variable<int>(reviewCount);
    map['correct_count'] = Variable<int>(correctCount);
    map['study_ms'] = Variable<int>(studyMs);
    map['xp'] = Variable<int>(xp);
    map['updated_at'] = Variable<String>(updatedAt);
    map['sync_status'] = Variable<int>(syncStatus);
    return map;
  }

  DailyStatsCompanion toCompanion(bool nullToAbsent) {
    return DailyStatsCompanion(
      date: Value(date),
      deviceId: Value(deviceId),
      newCount: Value(newCount),
      reviewCount: Value(reviewCount),
      correctCount: Value(correctCount),
      studyMs: Value(studyMs),
      xp: Value(xp),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory DailyStat.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyStat(
      date: serializer.fromJson<String>(json['date']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      newCount: serializer.fromJson<int>(json['newCount']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      studyMs: serializer.fromJson<int>(json['studyMs']),
      xp: serializer.fromJson<int>(json['xp']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'deviceId': serializer.toJson<String>(deviceId),
      'newCount': serializer.toJson<int>(newCount),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'correctCount': serializer.toJson<int>(correctCount),
      'studyMs': serializer.toJson<int>(studyMs),
      'xp': serializer.toJson<int>(xp),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
    };
  }

  DailyStat copyWith({
    String? date,
    String? deviceId,
    int? newCount,
    int? reviewCount,
    int? correctCount,
    int? studyMs,
    int? xp,
    String? updatedAt,
    int? syncStatus,
  }) => DailyStat(
    date: date ?? this.date,
    deviceId: deviceId ?? this.deviceId,
    newCount: newCount ?? this.newCount,
    reviewCount: reviewCount ?? this.reviewCount,
    correctCount: correctCount ?? this.correctCount,
    studyMs: studyMs ?? this.studyMs,
    xp: xp ?? this.xp,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  DailyStat copyWithCompanion(DailyStatsCompanion data) {
    return DailyStat(
      date: data.date.present ? data.date.value : this.date,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      newCount: data.newCount.present ? data.newCount.value : this.newCount,
      reviewCount: data.reviewCount.present ? data.reviewCount.value : this.reviewCount,
      correctCount: data.correctCount.present ? data.correctCount.value : this.correctCount,
      studyMs: data.studyMs.present ? data.studyMs.value : this.studyMs,
      xp: data.xp.present ? data.xp.value : this.xp,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyStat(')
          ..write('date: $date, ')
          ..write('deviceId: $deviceId, ')
          ..write('newCount: $newCount, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('studyMs: $studyMs, ')
          ..write('xp: $xp, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, deviceId, newCount, reviewCount, correctCount, studyMs, xp, updatedAt, syncStatus);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyStat &&
          other.date == this.date &&
          other.deviceId == this.deviceId &&
          other.newCount == this.newCount &&
          other.reviewCount == this.reviewCount &&
          other.correctCount == this.correctCount &&
          other.studyMs == this.studyMs &&
          other.xp == this.xp &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class DailyStatsCompanion extends UpdateCompanion<DailyStat> {
  final Value<String> date;
  final Value<String> deviceId;
  final Value<int> newCount;
  final Value<int> reviewCount;
  final Value<int> correctCount;
  final Value<int> studyMs;
  final Value<int> xp;
  final Value<String> updatedAt;
  final Value<int> syncStatus;
  final Value<int> rowid;
  const DailyStatsCompanion({
    this.date = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.newCount = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.studyMs = const Value.absent(),
    this.xp = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyStatsCompanion.insert({
    required String date,
    required String deviceId,
    this.newCount = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.studyMs = const Value.absent(),
    this.xp = const Value.absent(),
    required String updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt);
  static Insertable<DailyStat> custom({
    Expression<String>? date,
    Expression<String>? deviceId,
    Expression<int>? newCount,
    Expression<int>? reviewCount,
    Expression<int>? correctCount,
    Expression<int>? studyMs,
    Expression<int>? xp,
    Expression<String>? updatedAt,
    Expression<int>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (deviceId != null) 'device_id': deviceId,
      if (newCount != null) 'new_count': newCount,
      if (reviewCount != null) 'review_count': reviewCount,
      if (correctCount != null) 'correct_count': correctCount,
      if (studyMs != null) 'study_ms': studyMs,
      if (xp != null) 'xp': xp,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyStatsCompanion copyWith({
    Value<String>? date,
    Value<String>? deviceId,
    Value<int>? newCount,
    Value<int>? reviewCount,
    Value<int>? correctCount,
    Value<int>? studyMs,
    Value<int>? xp,
    Value<String>? updatedAt,
    Value<int>? syncStatus,
    Value<int>? rowid,
  }) {
    return DailyStatsCompanion(
      date: date ?? this.date,
      deviceId: deviceId ?? this.deviceId,
      newCount: newCount ?? this.newCount,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      studyMs: studyMs ?? this.studyMs,
      xp: xp ?? this.xp,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (newCount.present) {
      map['new_count'] = Variable<int>(newCount.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (studyMs.present) {
      map['study_ms'] = Variable<int>(studyMs.value);
    }
    if (xp.present) {
      map['xp'] = Variable<int>(xp.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyStatsCompanion(')
          ..write('date: $date, ')
          ..write('deviceId: $deviceId, ')
          ..write('newCount: $newCount, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('correctCount: $correctCount, ')
          ..write('studyMs: $studyMs, ')
          ..write('xp: $xp, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IslandInventoryTable extends IslandInventory with TableInfo<$IslandInventoryTable, IslandInventoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IslandInventoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta('syncStatus');
  @override
  late final GeneratedColumn<int> syncStatus = GeneratedColumn<int>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xMeta = const VerificationMeta('x');
  @override
  late final GeneratedColumn<double> x = GeneratedColumn<double>(
    'x',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yMeta = const VerificationMeta('y');
  @override
  late final GeneratedColumn<double> y = GeneratedColumn<double>(
    'y',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placedMeta = const VerificationMeta('placed');
  @override
  late final GeneratedColumn<int> placed = GeneratedColumn<int>(
    'placed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [updatedAt, deletedAt, syncStatus, id, itemId, x, y, placed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'island_inventory';
  @override
  VerificationContext validateIntegrity(Insertable<IslandInventoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('sync_status')) {
      context.handle(_syncStatusMeta, syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta, itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('x')) {
      context.handle(_xMeta, x.isAcceptableOrUnknown(data['x']!, _xMeta));
    }
    if (data.containsKey('y')) {
      context.handle(_yMeta, y.isAcceptableOrUnknown(data['y']!, _yMeta));
    }
    if (data.containsKey('placed')) {
      context.handle(_placedMeta, placed.isAcceptableOrUnknown(data['placed']!, _placedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IslandInventoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IslandInventoryData(
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}deleted_at']),
      syncStatus: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}sync_status'])!,
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      itemId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      x: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}x']),
      y: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}y']),
      placed: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}placed'])!,
    );
  }

  @override
  $IslandInventoryTable createAlias(String alias) {
    return $IslandInventoryTable(attachedDatabase, alias);
  }
}

class IslandInventoryData extends DataClass implements Insertable<IslandInventoryData> {
  final String updatedAt;
  final String? deletedAt;
  final int syncStatus;
  final String id;
  final String itemId;
  final double? x;
  final double? y;
  final int placed;
  const IslandInventoryData({
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.id,
    required this.itemId,
    this.x,
    this.y,
    required this.placed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['sync_status'] = Variable<int>(syncStatus);
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    if (!nullToAbsent || x != null) {
      map['x'] = Variable<double>(x);
    }
    if (!nullToAbsent || y != null) {
      map['y'] = Variable<double>(y);
    }
    map['placed'] = Variable<int>(placed);
    return map;
  }

  IslandInventoryCompanion toCompanion(bool nullToAbsent) {
    return IslandInventoryCompanion(
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      syncStatus: Value(syncStatus),
      id: Value(id),
      itemId: Value(itemId),
      x: x == null && nullToAbsent ? const Value.absent() : Value(x),
      y: y == null && nullToAbsent ? const Value.absent() : Value(y),
      placed: Value(placed),
    );
  }

  factory IslandInventoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IslandInventoryData(
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      syncStatus: serializer.fromJson<int>(json['syncStatus']),
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      x: serializer.fromJson<double?>(json['x']),
      y: serializer.fromJson<double?>(json['y']),
      placed: serializer.fromJson<int>(json['placed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'syncStatus': serializer.toJson<int>(syncStatus),
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'x': serializer.toJson<double?>(x),
      'y': serializer.toJson<double?>(y),
      'placed': serializer.toJson<int>(placed),
    };
  }

  IslandInventoryData copyWith({
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    int? syncStatus,
    String? id,
    String? itemId,
    Value<double?> x = const Value.absent(),
    Value<double?> y = const Value.absent(),
    int? placed,
  }) => IslandInventoryData(
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    x: x.present ? x.value : this.x,
    y: y.present ? y.value : this.y,
    placed: placed ?? this.placed,
  );
  IslandInventoryData copyWithCompanion(IslandInventoryCompanion data) {
    return IslandInventoryData(
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      syncStatus: data.syncStatus.present ? data.syncStatus.value : this.syncStatus,
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      x: data.x.present ? data.x.value : this.x,
      y: data.y.present ? data.y.value : this.y,
      placed: data.placed.present ? data.placed.value : this.placed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IslandInventoryData(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('placed: $placed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(updatedAt, deletedAt, syncStatus, id, itemId, x, y, placed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IslandInventoryData &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.syncStatus == this.syncStatus &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.x == this.x &&
          other.y == this.y &&
          other.placed == this.placed);
}

class IslandInventoryCompanion extends UpdateCompanion<IslandInventoryData> {
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> syncStatus;
  final Value<String> id;
  final Value<String> itemId;
  final Value<double?> x;
  final Value<double?> y;
  final Value<int> placed;
  final Value<int> rowid;
  const IslandInventoryCompanion({
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.placed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IslandInventoryCompanion.insert({
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required String id,
    required String itemId,
    this.x = const Value.absent(),
    this.y = const Value.absent(),
    this.placed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : updatedAt = Value(updatedAt),
       id = Value(id),
       itemId = Value(itemId);
  static Insertable<IslandInventoryData> custom({
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? syncStatus,
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<double>? x,
    Expression<double>? y,
    Expression<int>? placed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (placed != null) 'placed': placed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IslandInventoryCompanion copyWith({
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? syncStatus,
    Value<String>? id,
    Value<String>? itemId,
    Value<double?>? x,
    Value<double?>? y,
    Value<int>? placed,
    Value<int>? rowid,
  }) {
    return IslandInventoryCompanion(
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      x: x ?? this.x,
      y: y ?? this.y,
      placed: placed ?? this.placed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<int>(syncStatus.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (x.present) {
      map['x'] = Variable<double>(x.value);
    }
    if (y.present) {
      map['y'] = Variable<double>(y.value);
    }
    if (placed.present) {
      map['placed'] = Variable<int>(placed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IslandInventoryCompanion(')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('x: $x, ')
          ..write('y: $y, ')
          ..write('placed: $placed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakStateTable extends StreakState with TableInfo<$StreakStateTable, StreakStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentMeta = const VerificationMeta('current');
  @override
  late final GeneratedColumn<int> current = GeneratedColumn<int>(
    'current',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longestMeta = const VerificationMeta('longest');
  @override
  late final GeneratedColumn<int> longest = GeneratedColumn<int>(
    'longest',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastActiveDateMeta = const VerificationMeta('lastActiveDate');
  @override
  late final GeneratedColumn<String> lastActiveDate = GeneratedColumn<String>(
    'last_active_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, current, longest, lastActiveDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_state';
  @override
  VerificationContext validateIntegrity(Insertable<StreakStateData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current')) {
      context.handle(_currentMeta, current.isAcceptableOrUnknown(data['current']!, _currentMeta));
    }
    if (data.containsKey('longest')) {
      context.handle(_longestMeta, longest.isAcceptableOrUnknown(data['longest']!, _longestMeta));
    }
    if (data.containsKey('last_active_date')) {
      context.handle(
        _lastActiveDateMeta,
        lastActiveDate.isAcceptableOrUnknown(data['last_active_date']!, _lastActiveDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakStateData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      current: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}current']),
      longest: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}longest']),
      lastActiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_active_date'],
      ),
    );
  }

  @override
  $StreakStateTable createAlias(String alias) {
    return $StreakStateTable(attachedDatabase, alias);
  }
}

class StreakStateData extends DataClass implements Insertable<StreakStateData> {
  final int id;
  final int? current;
  final int? longest;
  final String? lastActiveDate;
  const StreakStateData({required this.id, this.current, this.longest, this.lastActiveDate});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || current != null) {
      map['current'] = Variable<int>(current);
    }
    if (!nullToAbsent || longest != null) {
      map['longest'] = Variable<int>(longest);
    }
    if (!nullToAbsent || lastActiveDate != null) {
      map['last_active_date'] = Variable<String>(lastActiveDate);
    }
    return map;
  }

  StreakStateCompanion toCompanion(bool nullToAbsent) {
    return StreakStateCompanion(
      id: Value(id),
      current: current == null && nullToAbsent ? const Value.absent() : Value(current),
      longest: longest == null && nullToAbsent ? const Value.absent() : Value(longest),
      lastActiveDate: lastActiveDate == null && nullToAbsent ? const Value.absent() : Value(lastActiveDate),
    );
  }

  factory StreakStateData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakStateData(
      id: serializer.fromJson<int>(json['id']),
      current: serializer.fromJson<int?>(json['current']),
      longest: serializer.fromJson<int?>(json['longest']),
      lastActiveDate: serializer.fromJson<String?>(json['lastActiveDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'current': serializer.toJson<int?>(current),
      'longest': serializer.toJson<int?>(longest),
      'lastActiveDate': serializer.toJson<String?>(lastActiveDate),
    };
  }

  StreakStateData copyWith({
    int? id,
    Value<int?> current = const Value.absent(),
    Value<int?> longest = const Value.absent(),
    Value<String?> lastActiveDate = const Value.absent(),
  }) => StreakStateData(
    id: id ?? this.id,
    current: current.present ? current.value : this.current,
    longest: longest.present ? longest.value : this.longest,
    lastActiveDate: lastActiveDate.present ? lastActiveDate.value : this.lastActiveDate,
  );
  StreakStateData copyWithCompanion(StreakStateCompanion data) {
    return StreakStateData(
      id: data.id.present ? data.id.value : this.id,
      current: data.current.present ? data.current.value : this.current,
      longest: data.longest.present ? data.longest.value : this.longest,
      lastActiveDate: data.lastActiveDate.present ? data.lastActiveDate.value : this.lastActiveDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakStateData(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('lastActiveDate: $lastActiveDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, current, longest, lastActiveDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakStateData &&
          other.id == this.id &&
          other.current == this.current &&
          other.longest == this.longest &&
          other.lastActiveDate == this.lastActiveDate);
}

class StreakStateCompanion extends UpdateCompanion<StreakStateData> {
  final Value<int> id;
  final Value<int?> current;
  final Value<int?> longest;
  final Value<String?> lastActiveDate;
  const StreakStateCompanion({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.lastActiveDate = const Value.absent(),
  });
  StreakStateCompanion.insert({
    this.id = const Value.absent(),
    this.current = const Value.absent(),
    this.longest = const Value.absent(),
    this.lastActiveDate = const Value.absent(),
  });
  static Insertable<StreakStateData> custom({
    Expression<int>? id,
    Expression<int>? current,
    Expression<int>? longest,
    Expression<String>? lastActiveDate,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (current != null) 'current': current,
      if (longest != null) 'longest': longest,
      if (lastActiveDate != null) 'last_active_date': lastActiveDate,
    });
  }

  StreakStateCompanion copyWith({
    Value<int>? id,
    Value<int?>? current,
    Value<int?>? longest,
    Value<String?>? lastActiveDate,
  }) {
    return StreakStateCompanion(
      id: id ?? this.id,
      current: current ?? this.current,
      longest: longest ?? this.longest,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (current.present) {
      map['current'] = Variable<int>(current.value);
    }
    if (longest.present) {
      map['longest'] = Variable<int>(longest.value);
    }
    if (lastActiveDate.present) {
      map['last_active_date'] = Variable<String>(lastActiveDate.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakStateCompanion(')
          ..write('id: $id, ')
          ..write('current: $current, ')
          ..write('longest: $longest, ')
          ..write('lastActiveDate: $lastActiveDate')
          ..write(')'))
        .toString();
  }
}

class $LocalMetaTable extends LocalMeta with TableInfo<$LocalMetaTable, LocalMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_meta';
  @override
  VerificationContext validateIntegrity(Insertable<LocalMetaData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMetaData(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $LocalMetaTable createAlias(String alias) {
    return $LocalMetaTable(attachedDatabase, alias);
  }
}

class LocalMetaData extends DataClass implements Insertable<LocalMetaData> {
  final String key;
  final String? value;
  const LocalMetaData({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  LocalMetaCompanion toCompanion(bool nullToAbsent) {
    return LocalMetaCompanion(
      key: Value(key),
      value: value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory LocalMetaData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String?>(value)};
  }

  LocalMetaData copyWith({String? key, Value<String?> value = const Value.absent()}) =>
      LocalMetaData(key: key ?? this.key, value: value.present ? value.value : this.value);
  LocalMetaData copyWithCompanion(LocalMetaCompanion data) {
    return LocalMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LocalMetaData && other.key == this.key && other.value == this.value);
}

class LocalMetaCompanion extends UpdateCompanion<LocalMetaData> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const LocalMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMetaCompanion.insert({required String key, this.value = const Value.absent(), this.rowid = const Value.absent()})
    : key = Value(key);
  static Insertable<LocalMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMetaCompanion copyWith({Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return LocalMetaCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableName_Meta = const VerificationMeta('tableName_');
  @override
  late final GeneratedColumn<String> tableName_ = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta('lastPullAt');
  @override
  late final GeneratedColumn<String> lastPullAt = GeneratedColumn<String>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [tableName_, lastPullAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(Insertable<SyncStateData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(_tableName_Meta, tableName_.isAcceptableOrUnknown(data['table_name']!, _tableName_Meta));
    } else if (isInserting) {
      context.missing(_tableName_Meta);
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(_lastPullAtMeta, lastPullAt.isAcceptableOrUnknown(data['last_pull_at']!, _lastPullAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tableName_};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      tableName_: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      lastPullAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}last_pull_at']),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String tableName_;
  final String? lastPullAt;
  const SyncStateData({required this.tableName_, this.lastPullAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_name'] = Variable<String>(tableName_);
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<String>(lastPullAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      tableName_: Value(tableName_),
      lastPullAt: lastPullAt == null && nullToAbsent ? const Value.absent() : Value(lastPullAt),
    );
  }

  factory SyncStateData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      tableName_: serializer.fromJson<String>(json['tableName_']),
      lastPullAt: serializer.fromJson<String?>(json['lastPullAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableName_': serializer.toJson<String>(tableName_),
      'lastPullAt': serializer.toJson<String?>(lastPullAt),
    };
  }

  SyncStateData copyWith({String? tableName_, Value<String?> lastPullAt = const Value.absent()}) => SyncStateData(
    tableName_: tableName_ ?? this.tableName_,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      tableName_: data.tableName_.present ? data.tableName_.value : this.tableName_,
      lastPullAt: data.lastPullAt.present ? data.lastPullAt.value : this.lastPullAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('tableName_: $tableName_, ')
          ..write('lastPullAt: $lastPullAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tableName_, lastPullAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData && other.tableName_ == this.tableName_ && other.lastPullAt == this.lastPullAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> tableName_;
  final Value<String?> lastPullAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.tableName_ = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String tableName_,
    this.lastPullAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : tableName_ = Value(tableName_);
  static Insertable<SyncStateData> custom({
    Expression<String>? tableName_,
    Expression<String>? lastPullAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableName_ != null) 'table_name': tableName_,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({Value<String>? tableName_, Value<String?>? lastPullAt, Value<int>? rowid}) {
    return SyncStateCompanion(
      tableName_: tableName_ ?? this.tableName_,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableName_.present) {
      map['table_name'] = Variable<String>(tableName_.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<String>(lastPullAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('tableName_: $tableName_, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentPacksTable extends ContentPacks with TableInfo<$ContentPacksTable, ContentPack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentPacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta('version');
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta('installedAt');
  @override
  late final GeneratedColumn<String> installedAt = GeneratedColumn<String>(
    'installed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, installedAt, checksum];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'content_packs';
  @override
  VerificationContext validateIntegrity(Insertable<ContentPack> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta, version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('installed_at')) {
      context.handle(_installedAtMeta, installedAt.isAcceptableOrUnknown(data['installed_at']!, _installedAtMeta));
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta, checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentPack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentPack(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      version: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}version']),
      installedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}installed_at']),
      checksum: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}checksum']),
    );
  }

  @override
  $ContentPacksTable createAlias(String alias) {
    return $ContentPacksTable(attachedDatabase, alias);
  }
}

class ContentPack extends DataClass implements Insertable<ContentPack> {
  final String id;
  final String? version;
  final String? installedAt;
  final String? checksum;
  const ContentPack({required this.id, this.version, this.installedAt, this.checksum});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || installedAt != null) {
      map['installed_at'] = Variable<String>(installedAt);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    return map;
  }

  ContentPacksCompanion toCompanion(bool nullToAbsent) {
    return ContentPacksCompanion(
      id: Value(id),
      version: version == null && nullToAbsent ? const Value.absent() : Value(version),
      installedAt: installedAt == null && nullToAbsent ? const Value.absent() : Value(installedAt),
      checksum: checksum == null && nullToAbsent ? const Value.absent() : Value(checksum),
    );
  }

  factory ContentPack.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentPack(
      id: serializer.fromJson<String>(json['id']),
      version: serializer.fromJson<String?>(json['version']),
      installedAt: serializer.fromJson<String?>(json['installedAt']),
      checksum: serializer.fromJson<String?>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'version': serializer.toJson<String?>(version),
      'installedAt': serializer.toJson<String?>(installedAt),
      'checksum': serializer.toJson<String?>(checksum),
    };
  }

  ContentPack copyWith({
    String? id,
    Value<String?> version = const Value.absent(),
    Value<String?> installedAt = const Value.absent(),
    Value<String?> checksum = const Value.absent(),
  }) => ContentPack(
    id: id ?? this.id,
    version: version.present ? version.value : this.version,
    installedAt: installedAt.present ? installedAt.value : this.installedAt,
    checksum: checksum.present ? checksum.value : this.checksum,
  );
  ContentPack copyWithCompanion(ContentPacksCompanion data) {
    return ContentPack(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      installedAt: data.installedAt.present ? data.installedAt.value : this.installedAt,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentPack(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, installedAt, checksum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentPack &&
          other.id == this.id &&
          other.version == this.version &&
          other.installedAt == this.installedAt &&
          other.checksum == this.checksum);
}

class ContentPacksCompanion extends UpdateCompanion<ContentPack> {
  final Value<String> id;
  final Value<String?> version;
  final Value<String?> installedAt;
  final Value<String?> checksum;
  final Value<int> rowid;
  const ContentPacksCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentPacksCompanion.insert({
    required String id,
    this.version = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ContentPack> custom({
    Expression<String>? id,
    Expression<String>? version,
    Expression<String>? installedAt,
    Expression<String>? checksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (installedAt != null) 'installed_at': installedAt,
      if (checksum != null) 'checksum': checksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentPacksCompanion copyWith({
    Value<String>? id,
    Value<String?>? version,
    Value<String?>? installedAt,
    Value<String?>? checksum,
    Value<int>? rowid,
  }) {
    return ContentPacksCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      installedAt: installedAt ?? this.installedAt,
      checksum: checksum ?? this.checksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<String>(installedAt.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentPacksCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('installedAt: $installedAt, ')
          ..write('checksum: $checksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchHistoryTable extends SearchHistory with TableInfo<$SearchHistoryTable, SearchHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta('searchedAt');
  @override
  late final GeneratedColumn<String> searchedAt = GeneratedColumn<String>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, query, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_history';
  @override
  VerificationContext validateIntegrity(Insertable<SearchHistoryData> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('query')) {
      context.handle(_queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(_searchedAtMeta, searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta));
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SearchHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryData(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      query: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}query'])!,
      searchedAt: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}searched_at'])!,
    );
  }

  @override
  $SearchHistoryTable createAlias(String alias) {
    return $SearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryData extends DataClass implements Insertable<SearchHistoryData> {
  final int id;
  final String query;
  final String searchedAt;
  const SearchHistoryData({required this.id, required this.query, required this.searchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['query'] = Variable<String>(query);
    map['searched_at'] = Variable<String>(searchedAt);
    return map;
  }

  SearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return SearchHistoryCompanion(id: Value(id), query: Value(query), searchedAt: Value(searchedAt));
  }

  factory SearchHistoryData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryData(
      id: serializer.fromJson<int>(json['id']),
      query: serializer.fromJson<String>(json['query']),
      searchedAt: serializer.fromJson<String>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'query': serializer.toJson<String>(query),
      'searchedAt': serializer.toJson<String>(searchedAt),
    };
  }

  SearchHistoryData copyWith({int? id, String? query, String? searchedAt}) =>
      SearchHistoryData(id: id ?? this.id, query: query ?? this.query, searchedAt: searchedAt ?? this.searchedAt);
  SearchHistoryData copyWithCompanion(SearchHistoryCompanion data) {
    return SearchHistoryData(
      id: data.id.present ? data.id.value : this.id,
      query: data.query.present ? data.query.value : this.query,
      searchedAt: data.searchedAt.present ? data.searchedAt.value : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryData(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, query, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryData &&
          other.id == this.id &&
          other.query == this.query &&
          other.searchedAt == this.searchedAt);
}

class SearchHistoryCompanion extends UpdateCompanion<SearchHistoryData> {
  final Value<int> id;
  final Value<String> query;
  final Value<String> searchedAt;
  const SearchHistoryCompanion({
    this.id = const Value.absent(),
    this.query = const Value.absent(),
    this.searchedAt = const Value.absent(),
  });
  SearchHistoryCompanion.insert({this.id = const Value.absent(), required String query, required String searchedAt})
    : query = Value(query),
      searchedAt = Value(searchedAt);
  static Insertable<SearchHistoryData> custom({
    Expression<int>? id,
    Expression<String>? query,
    Expression<String>? searchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (query != null) 'query': query,
      if (searchedAt != null) 'searched_at': searchedAt,
    });
  }

  SearchHistoryCompanion copyWith({Value<int>? id, Value<String>? query, Value<String>? searchedAt}) {
    return SearchHistoryCompanion(
      id: id ?? this.id,
      query: query ?? this.query,
      searchedAt: searchedAt ?? this.searchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<String>(searchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryCompanion(')
          ..write('id: $id, ')
          ..write('query: $query, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDb extends GeneratedDatabase {
  _$UserDb(QueryExecutor e) : super(e);
  $UserDbManager get managers => $UserDbManager(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $SrsCardsTable srsCards = $SrsCardsTable(this);
  late final $LessonProgressTable lessonProgress = $LessonProgressTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(this);
  late final $UserAchievementsTable userAchievements = $UserAchievementsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $ExerciseAttemptsTable exerciseAttempts = $ExerciseAttemptsTable(this);
  late final $GameScoresTable gameScores = $GameScoresTable(this);
  late final $StreakFreezesTable streakFreezes = $StreakFreezesTable(this);
  late final $CoinLedgerTable coinLedger = $CoinLedgerTable(this);
  late final $DailyStatsTable dailyStats = $DailyStatsTable(this);
  late final $IslandInventoryTable islandInventory = $IslandInventoryTable(this);
  late final $StreakStateTable streakState = $StreakStateTable(this);
  late final $LocalMetaTable localMeta = $LocalMetaTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $ContentPacksTable contentPacks = $ContentPacksTable(this);
  late final $SearchHistoryTable searchHistory = $SearchHistoryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bookmarks,
    srsCards,
    lessonProgress,
    readingProgress,
    userAchievements,
    userSettings,
    reviewLogs,
    exerciseAttempts,
    gameScores,
    streakFreezes,
    coinLedger,
    dailyStats,
    islandInventory,
    streakState,
    localMeta,
    syncState,
    contentPacks,
    searchHistory,
  ];
}

typedef $$BookmarksTableCreateCompanionBuilder = BookmarksCompanion Function({
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  required String id,
  required int wordId,
  required String labelSnapshot,
  required String createdAt,
  Value<int> rowid,
});
typedef $$BookmarksTableUpdateCompanionBuilder = BookmarksCompanion Function({
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  Value<String> id,
  Value<int> wordId,
  Value<String> labelSnapshot,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$BookmarksTableFilterComposer extends Composer<_$UserDb, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BookmarksTableOrderingComposer extends Composer<_$UserDb, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wordId =>
      $composableBuilder(column: $table.wordId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookmarksTableAnnotationComposer extends Composer<_$UserDb, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get wordId => $composableBuilder(column: $table.wordId, builder: (column) => column);

  GeneratedColumn<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => column);

  GeneratedColumn<String> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$UserDb, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$UserDb db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> wordId = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                wordId: wordId,
                labelSnapshot: labelSnapshot,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String id,
                required int wordId,
                required String labelSnapshot,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                wordId: wordId,
                labelSnapshot: labelSnapshot,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BookmarksTable, Bookmark>(table),
                  BaseReferences<_$UserDb, $BookmarksTable, Bookmark>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$UserDb, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$SrsCardsTableCreateCompanionBuilder = SrsCardsCompanion Function({
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  required String id,
  required String cardType,
  required String itemId,
  Value<String> direction,
  required String labelSnapshot,
  required String state,
  Value<String?> dueAt,
  Value<double> intervalDays,
  Value<double> ease,
  Value<int> reps,
  Value<int> lapses,
  Value<int> isOrphan,
  required String createdAt,
  Value<int> rowid,
});
typedef $$SrsCardsTableUpdateCompanionBuilder = SrsCardsCompanion Function({
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  Value<String> id,
  Value<String> cardType,
  Value<String> itemId,
  Value<String> direction,
  Value<String> labelSnapshot,
  Value<String> state,
  Value<String?> dueAt,
  Value<double> intervalDays,
  Value<double> ease,
  Value<int> reps,
  Value<int> lapses,
  Value<int> isOrphan,
  Value<String> createdAt,
  Value<int> rowid,
});

class $$SrsCardsTableFilterComposer extends Composer<_$UserDb, $SrsCardsTable> {
  $$SrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get intervalDays =>
      $composableBuilder(column: $table.intervalDays, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ease => $composableBuilder(column: $table.ease, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get isOrphan =>
      $composableBuilder(column: $table.isOrphan, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$SrsCardsTableOrderingComposer extends Composer<_$UserDb, $SrsCardsTable> {
  $$SrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get intervalDays =>
      $composableBuilder(column: $table.intervalDays, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ease =>
      $composableBuilder(column: $table.ease, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get isOrphan =>
      $composableBuilder(column: $table.isOrphan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SrsCardsTableAnnotationComposer extends Composer<_$UserDb, $SrsCardsTable> {
  $$SrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardType => $composableBuilder(column: $table.cardType, builder: (column) => column);

  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get direction => $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<String> get labelSnapshot =>
      $composableBuilder(column: $table.labelSnapshot, builder: (column) => column);

  GeneratedColumn<String> get state => $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get dueAt => $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<double> get intervalDays =>
      $composableBuilder(column: $table.intervalDays, builder: (column) => column);

  GeneratedColumn<double> get ease => $composableBuilder(column: $table.ease, builder: (column) => column);

  GeneratedColumn<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses => $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get isOrphan => $composableBuilder(column: $table.isOrphan, builder: (column) => column);

  GeneratedColumn<String> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SrsCardsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SrsCardsTable,
          SrsCard,
          $$SrsCardsTableFilterComposer,
          $$SrsCardsTableOrderingComposer,
          $$SrsCardsTableAnnotationComposer,
          $$SrsCardsTableCreateCompanionBuilder,
          $$SrsCardsTableUpdateCompanionBuilder,
          (SrsCard, BaseReferences<_$UserDb, $SrsCardsTable, SrsCard>),
          SrsCard,
          PrefetchHooks Function()
        > {
  $$SrsCardsTableTableManager(_$UserDb db, $SrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> cardType = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<String> labelSnapshot = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> dueAt = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> isOrphan = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SrsCardsCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                cardType: cardType,
                itemId: itemId,
                direction: direction,
                labelSnapshot: labelSnapshot,
                state: state,
                dueAt: dueAt,
                intervalDays: intervalDays,
                ease: ease,
                reps: reps,
                lapses: lapses,
                isOrphan: isOrphan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String id,
                required String cardType,
                required String itemId,
                Value<String> direction = const Value.absent(),
                required String labelSnapshot,
                required String state,
                Value<String?> dueAt = const Value.absent(),
                Value<double> intervalDays = const Value.absent(),
                Value<double> ease = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> isOrphan = const Value.absent(),
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SrsCardsCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                cardType: cardType,
                itemId: itemId,
                direction: direction,
                labelSnapshot: labelSnapshot,
                state: state,
                dueAt: dueAt,
                intervalDays: intervalDays,
                ease: ease,
                reps: reps,
                lapses: lapses,
                isOrphan: isOrphan,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SrsCardsTable, SrsCard>(table),
                  BaseReferences<_$UserDb, $SrsCardsTable, SrsCard>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SrsCardsTable,
      SrsCard,
      $$SrsCardsTableFilterComposer,
      $$SrsCardsTableOrderingComposer,
      $$SrsCardsTableAnnotationComposer,
      $$SrsCardsTableCreateCompanionBuilder,
      $$SrsCardsTableUpdateCompanionBuilder,
      (SrsCard, BaseReferences<_$UserDb, $SrsCardsTable, SrsCard>),
      SrsCard,
      PrefetchHooks Function()
    >;
typedef $$LessonProgressTableCreateCompanionBuilder = LessonProgressCompanion Function({
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  required String id,
  required String lessonId,
  required String status,
  Value<double?> score,
  Value<String?> completedAt,
  Value<int> rowid,
});
typedef $$LessonProgressTableUpdateCompanionBuilder = LessonProgressCompanion Function({
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  Value<String> id,
  Value<String> lessonId,
  Value<String> status,
  Value<double?> score,
  Value<String?> completedAt,
  Value<int> rowid,
});

class $$LessonProgressTableFilterComposer extends Composer<_$UserDb, $LessonProgressTable> {
  $$LessonProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$LessonProgressTableOrderingComposer extends Composer<_$UserDb, $LessonProgressTable> {
  $$LessonProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$LessonProgressTableAnnotationComposer extends Composer<_$UserDb, $LessonProgressTable> {
  $$LessonProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lessonId => $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get score => $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<String> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => column);
}

class $$LessonProgressTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $LessonProgressTable,
          LessonProgressRow,
          $$LessonProgressTableFilterComposer,
          $$LessonProgressTableOrderingComposer,
          $$LessonProgressTableAnnotationComposer,
          $$LessonProgressTableCreateCompanionBuilder,
          $$LessonProgressTableUpdateCompanionBuilder,
          (LessonProgressRow, BaseReferences<_$UserDb, $LessonProgressTable, LessonProgressRow>),
          LessonProgressRow,
          PrefetchHooks Function()
        > {
  $$LessonProgressTableTableManager(_$UserDb db, $LessonProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LessonProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LessonProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LessonProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                lessonId: lessonId,
                status: status,
                score: score,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String id,
                required String lessonId,
                required String status,
                Value<double?> score = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LessonProgressCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                lessonId: lessonId,
                status: status,
                score: score,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LessonProgressTable, LessonProgressRow>(table),
                  BaseReferences<_$UserDb, $LessonProgressTable, LessonProgressRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LessonProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $LessonProgressTable,
      LessonProgressRow,
      $$LessonProgressTableFilterComposer,
      $$LessonProgressTableOrderingComposer,
      $$LessonProgressTableAnnotationComposer,
      $$LessonProgressTableCreateCompanionBuilder,
      $$LessonProgressTableUpdateCompanionBuilder,
      (LessonProgressRow, BaseReferences<_$UserDb, $LessonProgressTable, LessonProgressRow>),
      LessonProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder = ReadingProgressCompanion Function({
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  required String id,
  required String storyId,
  required String status,
  Value<double?> score,
  Value<int> rowid,
});
typedef $$ReadingProgressTableUpdateCompanionBuilder = ReadingProgressCompanion Function({
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  Value<String> id,
  Value<String> storyId,
  Value<String> status,
  Value<double?> score,
  Value<int> rowid,
});

class $$ReadingProgressTableFilterComposer extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnFilters(column));
}

class $$ReadingProgressTableOrderingComposer extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get storyId =>
      $composableBuilder(column: $table.storyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnOrderings(column));
}

class $$ReadingProgressTableAnnotationComposer extends Composer<_$UserDb, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storyId => $composableBuilder(column: $table.storyId, builder: (column) => column);

  GeneratedColumn<String> get status => $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get score => $composableBuilder(column: $table.score, builder: (column) => column);
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $ReadingProgressTable,
          ReadingProgressRow,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (ReadingProgressRow, BaseReferences<_$UserDb, $ReadingProgressTable, ReadingProgressRow>),
          ReadingProgressRow,
          PrefetchHooks Function()
        > {
  $$ReadingProgressTableTableManager(_$UserDb db, $ReadingProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> storyId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                storyId: storyId,
                status: status,
                score: score,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String id,
                required String storyId,
                required String status,
                Value<double?> score = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                storyId: storyId,
                status: status,
                score: score,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReadingProgressTable, ReadingProgressRow>(table),
                  BaseReferences<_$UserDb, $ReadingProgressTable, ReadingProgressRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $ReadingProgressTable,
      ReadingProgressRow,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (ReadingProgressRow, BaseReferences<_$UserDb, $ReadingProgressTable, ReadingProgressRow>),
      ReadingProgressRow,
      PrefetchHooks Function()
    >;
typedef $$UserAchievementsTableCreateCompanionBuilder = UserAchievementsCompanion Function({
  required String id,
  required String achievementId,
  required String unlockedAt,
  required String updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$UserAchievementsTableUpdateCompanionBuilder = UserAchievementsCompanion Function({
  Value<String> id,
  Value<String> achievementId,
  Value<String> unlockedAt,
  Value<String> updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$UserAchievementsTableFilterComposer extends Composer<_$UserDb, $UserAchievementsTable> {
  $$UserAchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get achievementId =>
      $composableBuilder(column: $table.achievementId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unlockedAt =>
      $composableBuilder(column: $table.unlockedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$UserAchievementsTableOrderingComposer extends Composer<_$UserDb, $UserAchievementsTable> {
  $$UserAchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get achievementId =>
      $composableBuilder(column: $table.achievementId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unlockedAt =>
      $composableBuilder(column: $table.unlockedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$UserAchievementsTableAnnotationComposer extends Composer<_$UserDb, $UserAchievementsTable> {
  $$UserAchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get achievementId =>
      $composableBuilder(column: $table.achievementId, builder: (column) => column);

  GeneratedColumn<String> get unlockedAt => $composableBuilder(column: $table.unlockedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$UserAchievementsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $UserAchievementsTable,
          UserAchievement,
          $$UserAchievementsTableFilterComposer,
          $$UserAchievementsTableOrderingComposer,
          $$UserAchievementsTableAnnotationComposer,
          $$UserAchievementsTableCreateCompanionBuilder,
          $$UserAchievementsTableUpdateCompanionBuilder,
          (UserAchievement, BaseReferences<_$UserDb, $UserAchievementsTable, UserAchievement>),
          UserAchievement,
          PrefetchHooks Function()
        > {
  $$UserAchievementsTableTableManager(_$UserDb db, $UserAchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$UserAchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$UserAchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$UserAchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> achievementId = const Value.absent(),
                Value<String> unlockedAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserAchievementsCompanion(
                id: id,
                achievementId: achievementId,
                unlockedAt: unlockedAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String achievementId,
                required String unlockedAt,
                required String updatedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserAchievementsCompanion.insert(
                id: id,
                achievementId: achievementId,
                unlockedAt: unlockedAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserAchievementsTable, UserAchievement>(table),
                  BaseReferences<_$UserDb, $UserAchievementsTable, UserAchievement>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserAchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $UserAchievementsTable,
      UserAchievement,
      $$UserAchievementsTableFilterComposer,
      $$UserAchievementsTableOrderingComposer,
      $$UserAchievementsTableAnnotationComposer,
      $$UserAchievementsTableCreateCompanionBuilder,
      $$UserAchievementsTableUpdateCompanionBuilder,
      (UserAchievement, BaseReferences<_$UserDb, $UserAchievementsTable, UserAchievement>),
      UserAchievement,
      PrefetchHooks Function()
    >;
typedef $$UserSettingsTableCreateCompanionBuilder = UserSettingsCompanion Function({
  required String key,
  Value<String?> value,
  required String updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$UserSettingsTableUpdateCompanionBuilder = UserSettingsCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<String> updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$UserSettingsTableFilterComposer extends Composer<_$UserDb, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$UserSettingsTableOrderingComposer extends Composer<_$UserDb, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$UserSettingsTableAnnotationComposer extends Composer<_$UserDb, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (UserSetting, BaseReferences<_$UserDb, $UserSettingsTable, UserSetting>),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$UserDb db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                required String updatedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserSettingsTable, UserSetting>(table),
                  BaseReferences<_$UserDb, $UserSettingsTable, UserSetting>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (UserSetting, BaseReferences<_$UserDb, $UserSettingsTable, UserSetting>),
      UserSetting,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder = ReviewLogsCompanion Function({
  required String id,
  required String cardId,
  required int rating,
  required String reviewedAt,
  required String studyDate,
  Value<String?> prevState,
  Value<double?> prevInterval,
  Value<double?> newInterval,
  Value<int?> durationMs,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$ReviewLogsTableUpdateCompanionBuilder = ReviewLogsCompanion Function({
  Value<String> id,
  Value<String> cardId,
  Value<int> rating,
  Value<String> reviewedAt,
  Value<String> studyDate,
  Value<String?> prevState,
  Value<double?> prevInterval,
  Value<double?> newInterval,
  Value<int?> durationMs,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$ReviewLogsTableFilterComposer extends Composer<_$UserDb, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reviewedAt =>
      $composableBuilder(column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prevState =>
      $composableBuilder(column: $table.prevState, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get prevInterval =>
      $composableBuilder(column: $table.prevInterval, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get newInterval =>
      $composableBuilder(column: $table.newInterval, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$ReviewLogsTableOrderingComposer extends Composer<_$UserDb, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reviewedAt =>
      $composableBuilder(column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prevState =>
      $composableBuilder(column: $table.prevState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get prevInterval =>
      $composableBuilder(column: $table.prevInterval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get newInterval =>
      $composableBuilder(column: $table.newInterval, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$ReviewLogsTableAnnotationComposer extends Composer<_$UserDb, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId => $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<int> get rating => $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get reviewedAt => $composableBuilder(column: $table.reviewedAt, builder: (column) => column);

  GeneratedColumn<String> get studyDate => $composableBuilder(column: $table.studyDate, builder: (column) => column);

  GeneratedColumn<String> get prevState => $composableBuilder(column: $table.prevState, builder: (column) => column);

  GeneratedColumn<double> get prevInterval =>
      $composableBuilder(column: $table.prevInterval, builder: (column) => column);

  GeneratedColumn<double> get newInterval =>
      $composableBuilder(column: $table.newInterval, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $ReviewLogsTable,
          ReviewLog,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (ReviewLog, BaseReferences<_$UserDb, $ReviewLogsTable, ReviewLog>),
          ReviewLog,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$UserDb db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> reviewedAt = const Value.absent(),
                Value<String> studyDate = const Value.absent(),
                Value<String?> prevState = const Value.absent(),
                Value<double?> prevInterval = const Value.absent(),
                Value<double?> newInterval = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewedAt: reviewedAt,
                studyDate: studyDate,
                prevState: prevState,
                prevInterval: prevInterval,
                newInterval: newInterval,
                durationMs: durationMs,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required int rating,
                required String reviewedAt,
                required String studyDate,
                Value<String?> prevState = const Value.absent(),
                Value<double?> prevInterval = const Value.absent(),
                Value<double?> newInterval = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                rating: rating,
                reviewedAt: reviewedAt,
                studyDate: studyDate,
                prevState: prevState,
                prevInterval: prevInterval,
                newInterval: newInterval,
                durationMs: durationMs,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReviewLogsTable, ReviewLog>(table),
                  BaseReferences<_$UserDb, $ReviewLogsTable, ReviewLog>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $ReviewLogsTable,
      ReviewLog,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (ReviewLog, BaseReferences<_$UserDb, $ReviewLogsTable, ReviewLog>),
      ReviewLog,
      PrefetchHooks Function()
    >;
typedef $$ExerciseAttemptsTableCreateCompanionBuilder = ExerciseAttemptsCompanion Function({
  required String id,
  required String exerciseType,
  Value<String?> itemId,
  required int correct,
  required String answeredAt,
  required String studyDate,
  Value<int?> durationMs,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$ExerciseAttemptsTableUpdateCompanionBuilder = ExerciseAttemptsCompanion Function({
  Value<String> id,
  Value<String> exerciseType,
  Value<String?> itemId,
  Value<int> correct,
  Value<String> answeredAt,
  Value<String> studyDate,
  Value<int?> durationMs,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$ExerciseAttemptsTableFilterComposer extends Composer<_$UserDb, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseType =>
      $composableBuilder(column: $table.exerciseType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answeredAt =>
      $composableBuilder(column: $table.answeredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$ExerciseAttemptsTableOrderingComposer extends Composer<_$UserDb, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseType =>
      $composableBuilder(column: $table.exerciseType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answeredAt =>
      $composableBuilder(column: $table.answeredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get studyDate =>
      $composableBuilder(column: $table.studyDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs =>
      $composableBuilder(column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$ExerciseAttemptsTableAnnotationComposer extends Composer<_$UserDb, $ExerciseAttemptsTable> {
  $$ExerciseAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseType =>
      $composableBuilder(column: $table.exerciseType, builder: (column) => column);

  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get correct => $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<String> get answeredAt => $composableBuilder(column: $table.answeredAt, builder: (column) => column);

  GeneratedColumn<String> get studyDate => $composableBuilder(column: $table.studyDate, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$ExerciseAttemptsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $ExerciseAttemptsTable,
          ExerciseAttempt,
          $$ExerciseAttemptsTableFilterComposer,
          $$ExerciseAttemptsTableOrderingComposer,
          $$ExerciseAttemptsTableAnnotationComposer,
          $$ExerciseAttemptsTableCreateCompanionBuilder,
          $$ExerciseAttemptsTableUpdateCompanionBuilder,
          (ExerciseAttempt, BaseReferences<_$UserDb, $ExerciseAttemptsTable, ExerciseAttempt>),
          ExerciseAttempt,
          PrefetchHooks Function()
        > {
  $$ExerciseAttemptsTableTableManager(_$UserDb db, $ExerciseAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ExerciseAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ExerciseAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ExerciseAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> exerciseType = const Value.absent(),
                Value<String?> itemId = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<String> answeredAt = const Value.absent(),
                Value<String> studyDate = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAttemptsCompanion(
                id: id,
                exerciseType: exerciseType,
                itemId: itemId,
                correct: correct,
                answeredAt: answeredAt,
                studyDate: studyDate,
                durationMs: durationMs,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String exerciseType,
                Value<String?> itemId = const Value.absent(),
                required int correct,
                required String answeredAt,
                required String studyDate,
                Value<int?> durationMs = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExerciseAttemptsCompanion.insert(
                id: id,
                exerciseType: exerciseType,
                itemId: itemId,
                correct: correct,
                answeredAt: answeredAt,
                studyDate: studyDate,
                durationMs: durationMs,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseAttemptsTable, ExerciseAttempt>(table),
                  BaseReferences<_$UserDb, $ExerciseAttemptsTable, ExerciseAttempt>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $ExerciseAttemptsTable,
      ExerciseAttempt,
      $$ExerciseAttemptsTableFilterComposer,
      $$ExerciseAttemptsTableOrderingComposer,
      $$ExerciseAttemptsTableAnnotationComposer,
      $$ExerciseAttemptsTableCreateCompanionBuilder,
      $$ExerciseAttemptsTableUpdateCompanionBuilder,
      (ExerciseAttempt, BaseReferences<_$UserDb, $ExerciseAttemptsTable, ExerciseAttempt>),
      ExerciseAttempt,
      PrefetchHooks Function()
    >;
typedef $$GameScoresTableCreateCompanionBuilder = GameScoresCompanion Function({
  required String id,
  required String game,
  required int score,
  Value<double?> accuracy,
  required String playedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$GameScoresTableUpdateCompanionBuilder = GameScoresCompanion Function({
  Value<String> id,
  Value<String> game,
  Value<int> score,
  Value<double?> accuracy,
  Value<String> playedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$GameScoresTableFilterComposer extends Composer<_$UserDb, $GameScoresTable> {
  $$GameScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get game => $composableBuilder(column: $table.game, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get score => $composableBuilder(column: $table.score, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$GameScoresTableOrderingComposer extends Composer<_$UserDb, $GameScoresTable> {
  $$GameScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get game =>
      $composableBuilder(column: $table.game, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$GameScoresTableAnnotationComposer extends Composer<_$UserDb, $GameScoresTable> {
  $$GameScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get game => $composableBuilder(column: $table.game, builder: (column) => column);

  GeneratedColumn<int> get score => $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<double> get accuracy => $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<String> get playedAt => $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$GameScoresTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $GameScoresTable,
          GameScore,
          $$GameScoresTableFilterComposer,
          $$GameScoresTableOrderingComposer,
          $$GameScoresTableAnnotationComposer,
          $$GameScoresTableCreateCompanionBuilder,
          $$GameScoresTableUpdateCompanionBuilder,
          (GameScore, BaseReferences<_$UserDb, $GameScoresTable, GameScore>),
          GameScore,
          PrefetchHooks Function()
        > {
  $$GameScoresTableTableManager(_$UserDb db, $GameScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$GameScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$GameScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$GameScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> game = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<String> playedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameScoresCompanion(
                id: id,
                game: game,
                score: score,
                accuracy: accuracy,
                playedAt: playedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String game,
                required int score,
                Value<double?> accuracy = const Value.absent(),
                required String playedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GameScoresCompanion.insert(
                id: id,
                game: game,
                score: score,
                accuracy: accuracy,
                playedAt: playedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GameScoresTable, GameScore>(table),
                  BaseReferences<_$UserDb, $GameScoresTable, GameScore>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GameScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $GameScoresTable,
      GameScore,
      $$GameScoresTableFilterComposer,
      $$GameScoresTableOrderingComposer,
      $$GameScoresTableAnnotationComposer,
      $$GameScoresTableCreateCompanionBuilder,
      $$GameScoresTableUpdateCompanionBuilder,
      (GameScore, BaseReferences<_$UserDb, $GameScoresTable, GameScore>),
      GameScore,
      PrefetchHooks Function()
    >;
typedef $$StreakFreezesTableCreateCompanionBuilder = StreakFreezesCompanion Function({
  required String id,
  required String coveredDate,
  required String createdAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$StreakFreezesTableUpdateCompanionBuilder = StreakFreezesCompanion Function({
  Value<String> id,
  Value<String> coveredDate,
  Value<String> createdAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$StreakFreezesTableFilterComposer extends Composer<_$UserDb, $StreakFreezesTable> {
  $$StreakFreezesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coveredDate =>
      $composableBuilder(column: $table.coveredDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$StreakFreezesTableOrderingComposer extends Composer<_$UserDb, $StreakFreezesTable> {
  $$StreakFreezesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coveredDate =>
      $composableBuilder(column: $table.coveredDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$StreakFreezesTableAnnotationComposer extends Composer<_$UserDb, $StreakFreezesTable> {
  $$StreakFreezesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get coveredDate =>
      $composableBuilder(column: $table.coveredDate, builder: (column) => column);

  GeneratedColumn<String> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$StreakFreezesTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $StreakFreezesTable,
          StreakFreeze,
          $$StreakFreezesTableFilterComposer,
          $$StreakFreezesTableOrderingComposer,
          $$StreakFreezesTableAnnotationComposer,
          $$StreakFreezesTableCreateCompanionBuilder,
          $$StreakFreezesTableUpdateCompanionBuilder,
          (StreakFreeze, BaseReferences<_$UserDb, $StreakFreezesTable, StreakFreeze>),
          StreakFreeze,
          PrefetchHooks Function()
        > {
  $$StreakFreezesTableTableManager(_$UserDb db, $StreakFreezesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StreakFreezesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StreakFreezesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StreakFreezesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> coveredDate = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreakFreezesCompanion(
                id: id,
                coveredDate: coveredDate,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String coveredDate,
                required String createdAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StreakFreezesCompanion.insert(
                id: id,
                coveredDate: coveredDate,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StreakFreezesTable, StreakFreeze>(table),
                  BaseReferences<_$UserDb, $StreakFreezesTable, StreakFreeze>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakFreezesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $StreakFreezesTable,
      StreakFreeze,
      $$StreakFreezesTableFilterComposer,
      $$StreakFreezesTableOrderingComposer,
      $$StreakFreezesTableAnnotationComposer,
      $$StreakFreezesTableCreateCompanionBuilder,
      $$StreakFreezesTableUpdateCompanionBuilder,
      (StreakFreeze, BaseReferences<_$UserDb, $StreakFreezesTable, StreakFreeze>),
      StreakFreeze,
      PrefetchHooks Function()
    >;
typedef $$CoinLedgerTableCreateCompanionBuilder = CoinLedgerCompanion Function({
  required String id,
  required int delta,
  required String reason,
  Value<String?> refId,
  required String createdAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$CoinLedgerTableUpdateCompanionBuilder = CoinLedgerCompanion Function({
  Value<String> id,
  Value<int> delta,
  Value<String> reason,
  Value<String?> refId,
  Value<String> createdAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$CoinLedgerTableFilterComposer extends Composer<_$UserDb, $CoinLedgerTable> {
  $$CoinLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get delta => $composableBuilder(column: $table.delta, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$CoinLedgerTableOrderingComposer extends Composer<_$UserDb, $CoinLedgerTable> {
  $$CoinLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$CoinLedgerTableAnnotationComposer extends Composer<_$UserDb, $CoinLedgerTable> {
  $$CoinLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get delta => $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<String> get reason => $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get refId => $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$CoinLedgerTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $CoinLedgerTable,
          CoinLedgerData,
          $$CoinLedgerTableFilterComposer,
          $$CoinLedgerTableOrderingComposer,
          $$CoinLedgerTableAnnotationComposer,
          $$CoinLedgerTableCreateCompanionBuilder,
          $$CoinLedgerTableUpdateCompanionBuilder,
          (CoinLedgerData, BaseReferences<_$UserDb, $CoinLedgerTable, CoinLedgerData>),
          CoinLedgerData,
          PrefetchHooks Function()
        > {
  $$CoinLedgerTableTableManager(_$UserDb db, $CoinLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CoinLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CoinLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CoinLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<String?> refId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoinLedgerCompanion(
                id: id,
                delta: delta,
                reason: reason,
                refId: refId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int delta,
                required String reason,
                Value<String?> refId = const Value.absent(),
                required String createdAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CoinLedgerCompanion.insert(
                id: id,
                delta: delta,
                reason: reason,
                refId: refId,
                createdAt: createdAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CoinLedgerTable, CoinLedgerData>(table),
                  BaseReferences<_$UserDb, $CoinLedgerTable, CoinLedgerData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CoinLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $CoinLedgerTable,
      CoinLedgerData,
      $$CoinLedgerTableFilterComposer,
      $$CoinLedgerTableOrderingComposer,
      $$CoinLedgerTableAnnotationComposer,
      $$CoinLedgerTableCreateCompanionBuilder,
      $$CoinLedgerTableUpdateCompanionBuilder,
      (CoinLedgerData, BaseReferences<_$UserDb, $CoinLedgerTable, CoinLedgerData>),
      CoinLedgerData,
      PrefetchHooks Function()
    >;
typedef $$DailyStatsTableCreateCompanionBuilder = DailyStatsCompanion Function({
  required String date,
  required String deviceId,
  Value<int> newCount,
  Value<int> reviewCount,
  Value<int> correctCount,
  Value<int> studyMs,
  Value<int> xp,
  required String updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});
typedef $$DailyStatsTableUpdateCompanionBuilder = DailyStatsCompanion Function({
  Value<String> date,
  Value<String> deviceId,
  Value<int> newCount,
  Value<int> reviewCount,
  Value<int> correctCount,
  Value<int> studyMs,
  Value<int> xp,
  Value<String> updatedAt,
  Value<int> syncStatus,
  Value<int> rowid,
});

class $$DailyStatsTableFilterComposer extends Composer<_$UserDb, $DailyStatsTable> {
  $$DailyStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewCount =>
      $composableBuilder(column: $table.reviewCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount =>
      $composableBuilder(column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get studyMs =>
      $composableBuilder(column: $table.studyMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xp => $composableBuilder(column: $table.xp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));
}

class $$DailyStatsTableOrderingComposer extends Composer<_$UserDb, $DailyStatsTable> {
  $$DailyStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewCount =>
      $composableBuilder(column: $table.reviewCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount =>
      $composableBuilder(column: $table.correctCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get studyMs =>
      $composableBuilder(column: $table.studyMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xp => $composableBuilder(column: $table.xp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));
}

class $$DailyStatsTableAnnotationComposer extends Composer<_$UserDb, $DailyStatsTable> {
  $$DailyStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get deviceId => $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get newCount => $composableBuilder(column: $table.newCount, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(column: $table.reviewCount, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get studyMs => $composableBuilder(column: $table.studyMs, builder: (column) => column);

  GeneratedColumn<int> get xp => $composableBuilder(column: $table.xp, builder: (column) => column);

  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);
}

class $$DailyStatsTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $DailyStatsTable,
          DailyStat,
          $$DailyStatsTableFilterComposer,
          $$DailyStatsTableOrderingComposer,
          $$DailyStatsTableAnnotationComposer,
          $$DailyStatsTableCreateCompanionBuilder,
          $$DailyStatsTableUpdateCompanionBuilder,
          (DailyStat, BaseReferences<_$UserDb, $DailyStatsTable, DailyStat>),
          DailyStat,
          PrefetchHooks Function()
        > {
  $$DailyStatsTableTableManager(_$UserDb db, $DailyStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$DailyStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$DailyStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$DailyStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> newCount = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> studyMs = const Value.absent(),
                Value<int> xp = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion(
                date: date,
                deviceId: deviceId,
                newCount: newCount,
                reviewCount: reviewCount,
                correctCount: correctCount,
                studyMs: studyMs,
                xp: xp,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String deviceId,
                Value<int> newCount = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> studyMs = const Value.absent(),
                Value<int> xp = const Value.absent(),
                required String updatedAt,
                Value<int> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyStatsCompanion.insert(
                date: date,
                deviceId: deviceId,
                newCount: newCount,
                reviewCount: reviewCount,
                correctCount: correctCount,
                studyMs: studyMs,
                xp: xp,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyStatsTable, DailyStat>(table),
                  BaseReferences<_$UserDb, $DailyStatsTable, DailyStat>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $DailyStatsTable,
      DailyStat,
      $$DailyStatsTableFilterComposer,
      $$DailyStatsTableOrderingComposer,
      $$DailyStatsTableAnnotationComposer,
      $$DailyStatsTableCreateCompanionBuilder,
      $$DailyStatsTableUpdateCompanionBuilder,
      (DailyStat, BaseReferences<_$UserDb, $DailyStatsTable, DailyStat>),
      DailyStat,
      PrefetchHooks Function()
    >;
typedef $$IslandInventoryTableCreateCompanionBuilder = IslandInventoryCompanion Function({
  required String updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  required String id,
  required String itemId,
  Value<double?> x,
  Value<double?> y,
  Value<int> placed,
  Value<int> rowid,
});
typedef $$IslandInventoryTableUpdateCompanionBuilder = IslandInventoryCompanion Function({
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<int> syncStatus,
  Value<String> id,
  Value<String> itemId,
  Value<double?> x,
  Value<double?> y,
  Value<int> placed,
  Value<int> rowid,
});

class $$IslandInventoryTableFilterComposer extends Composer<_$UserDb, $IslandInventoryTable> {
  $$IslandInventoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get x => $composableBuilder(column: $table.x, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get y => $composableBuilder(column: $table.y, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get placed =>
      $composableBuilder(column: $table.placed, builder: (column) => ColumnFilters(column));
}

class $$IslandInventoryTableOrderingComposer extends Composer<_$UserDb, $IslandInventoryTable> {
  $$IslandInventoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get syncStatus =>
      $composableBuilder(column: $table.syncStatus, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get x => $composableBuilder(column: $table.x, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get y => $composableBuilder(column: $table.y, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get placed =>
      $composableBuilder(column: $table.placed, builder: (column) => ColumnOrderings(column));
}

class $$IslandInventoryTableAnnotationComposer extends Composer<_$UserDb, $IslandInventoryTable> {
  $$IslandInventoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get syncStatus => $composableBuilder(column: $table.syncStatus, builder: (column) => column);

  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId => $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<double> get x => $composableBuilder(column: $table.x, builder: (column) => column);

  GeneratedColumn<double> get y => $composableBuilder(column: $table.y, builder: (column) => column);

  GeneratedColumn<int> get placed => $composableBuilder(column: $table.placed, builder: (column) => column);
}

class $$IslandInventoryTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $IslandInventoryTable,
          IslandInventoryData,
          $$IslandInventoryTableFilterComposer,
          $$IslandInventoryTableOrderingComposer,
          $$IslandInventoryTableAnnotationComposer,
          $$IslandInventoryTableCreateCompanionBuilder,
          $$IslandInventoryTableUpdateCompanionBuilder,
          (IslandInventoryData, BaseReferences<_$UserDb, $IslandInventoryTable, IslandInventoryData>),
          IslandInventoryData,
          PrefetchHooks Function()
        > {
  $$IslandInventoryTableTableManager(_$UserDb db, $IslandInventoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$IslandInventoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$IslandInventoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$IslandInventoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int> placed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IslandInventoryCompanion(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                itemId: itemId,
                x: x,
                y: y,
                placed: placed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> syncStatus = const Value.absent(),
                required String id,
                required String itemId,
                Value<double?> x = const Value.absent(),
                Value<double?> y = const Value.absent(),
                Value<int> placed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IslandInventoryCompanion.insert(
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                syncStatus: syncStatus,
                id: id,
                itemId: itemId,
                x: x,
                y: y,
                placed: placed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IslandInventoryTable, IslandInventoryData>(table),
                  BaseReferences<_$UserDb, $IslandInventoryTable, IslandInventoryData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IslandInventoryTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $IslandInventoryTable,
      IslandInventoryData,
      $$IslandInventoryTableFilterComposer,
      $$IslandInventoryTableOrderingComposer,
      $$IslandInventoryTableAnnotationComposer,
      $$IslandInventoryTableCreateCompanionBuilder,
      $$IslandInventoryTableUpdateCompanionBuilder,
      (IslandInventoryData, BaseReferences<_$UserDb, $IslandInventoryTable, IslandInventoryData>),
      IslandInventoryData,
      PrefetchHooks Function()
    >;
typedef $$StreakStateTableCreateCompanionBuilder = StreakStateCompanion Function({
  Value<int> id,
  Value<int?> current,
  Value<int?> longest,
  Value<String?> lastActiveDate,
});
typedef $$StreakStateTableUpdateCompanionBuilder = StreakStateCompanion Function({
  Value<int> id,
  Value<int?> current,
  Value<int?> longest,
  Value<String?> lastActiveDate,
});

class $$StreakStateTableFilterComposer extends Composer<_$UserDb, $StreakStateTable> {
  $$StreakStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get current =>
      $composableBuilder(column: $table.current, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longest =>
      $composableBuilder(column: $table.longest, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastActiveDate =>
      $composableBuilder(column: $table.lastActiveDate, builder: (column) => ColumnFilters(column));
}

class $$StreakStateTableOrderingComposer extends Composer<_$UserDb, $StreakStateTable> {
  $$StreakStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get current =>
      $composableBuilder(column: $table.current, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longest =>
      $composableBuilder(column: $table.longest, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastActiveDate =>
      $composableBuilder(column: $table.lastActiveDate, builder: (column) => ColumnOrderings(column));
}

class $$StreakStateTableAnnotationComposer extends Composer<_$UserDb, $StreakStateTable> {
  $$StreakStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get current => $composableBuilder(column: $table.current, builder: (column) => column);

  GeneratedColumn<int> get longest => $composableBuilder(column: $table.longest, builder: (column) => column);

  GeneratedColumn<String> get lastActiveDate =>
      $composableBuilder(column: $table.lastActiveDate, builder: (column) => column);
}

class $$StreakStateTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $StreakStateTable,
          StreakStateData,
          $$StreakStateTableFilterComposer,
          $$StreakStateTableOrderingComposer,
          $$StreakStateTableAnnotationComposer,
          $$StreakStateTableCreateCompanionBuilder,
          $$StreakStateTableUpdateCompanionBuilder,
          (StreakStateData, BaseReferences<_$UserDb, $StreakStateTable, StreakStateData>),
          StreakStateData,
          PrefetchHooks Function()
        > {
  $$StreakStateTableTableManager(_$UserDb db, $StreakStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$StreakStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$StreakStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$StreakStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> current = const Value.absent(),
            Value<int?> longest = const Value.absent(),
            Value<String?> lastActiveDate = const Value.absent(),
          }) => StreakStateCompanion(id: id, current: current, longest: longest, lastActiveDate: lastActiveDate),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> current = const Value.absent(),
            Value<int?> longest = const Value.absent(),
            Value<String?> lastActiveDate = const Value.absent(),
          }) => StreakStateCompanion.insert(id: id, current: current, longest: longest, lastActiveDate: lastActiveDate),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StreakStateTable, StreakStateData>(table),
                  BaseReferences<_$UserDb, $StreakStateTable, StreakStateData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakStateTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $StreakStateTable,
      StreakStateData,
      $$StreakStateTableFilterComposer,
      $$StreakStateTableOrderingComposer,
      $$StreakStateTableAnnotationComposer,
      $$StreakStateTableCreateCompanionBuilder,
      $$StreakStateTableUpdateCompanionBuilder,
      (StreakStateData, BaseReferences<_$UserDb, $StreakStateTable, StreakStateData>),
      StreakStateData,
      PrefetchHooks Function()
    >;
typedef $$LocalMetaTableCreateCompanionBuilder = LocalMetaCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$LocalMetaTableUpdateCompanionBuilder = LocalMetaCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$LocalMetaTableFilterComposer extends Composer<_$UserDb, $LocalMetaTable> {
  $$LocalMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$LocalMetaTableOrderingComposer extends Composer<_$UserDb, $LocalMetaTable> {
  $$LocalMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$LocalMetaTableAnnotationComposer extends Composer<_$UserDb, $LocalMetaTable> {
  $$LocalMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalMetaTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $LocalMetaTable,
          LocalMetaData,
          $$LocalMetaTableFilterComposer,
          $$LocalMetaTableOrderingComposer,
          $$LocalMetaTableAnnotationComposer,
          $$LocalMetaTableCreateCompanionBuilder,
          $$LocalMetaTableUpdateCompanionBuilder,
          (LocalMetaData, BaseReferences<_$UserDb, $LocalMetaTable, LocalMetaData>),
          LocalMetaData,
          PrefetchHooks Function()
        > {
  $$LocalMetaTableTableManager(_$UserDb db, $LocalMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$LocalMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$LocalMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$LocalMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMetaTable, LocalMetaData>(table),
                  BaseReferences<_$UserDb, $LocalMetaTable, LocalMetaData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $LocalMetaTable,
      LocalMetaData,
      $$LocalMetaTableFilterComposer,
      $$LocalMetaTableOrderingComposer,
      $$LocalMetaTableAnnotationComposer,
      $$LocalMetaTableCreateCompanionBuilder,
      $$LocalMetaTableUpdateCompanionBuilder,
      (LocalMetaData, BaseReferences<_$UserDb, $LocalMetaTable, LocalMetaData>),
      LocalMetaData,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String tableName_,
  Value<String?> lastPullAt,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> tableName_,
  Value<String?> lastPullAt,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer extends Composer<_$UserDb, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tableName_ =>
      $composableBuilder(column: $table.tableName_, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastPullAt =>
      $composableBuilder(column: $table.lastPullAt, builder: (column) => ColumnFilters(column));
}

class $$SyncStateTableOrderingComposer extends Composer<_$UserDb, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tableName_ =>
      $composableBuilder(column: $table.tableName_, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastPullAt =>
      $composableBuilder(column: $table.lastPullAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncStateTableAnnotationComposer extends Composer<_$UserDb, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tableName_ => $composableBuilder(column: $table.tableName_, builder: (column) => column);

  GeneratedColumn<String> get lastPullAt => $composableBuilder(column: $table.lastPullAt, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (SyncStateData, BaseReferences<_$UserDb, $SyncStateTable, SyncStateData>),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$UserDb db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> tableName_ = const Value.absent(),
            Value<String?> lastPullAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion(tableName_: tableName_, lastPullAt: lastPullAt, rowid: rowid),
          createCompanionCallback: ({
            required String tableName_,
            Value<String?> lastPullAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion.insert(tableName_: tableName_, lastPullAt: lastPullAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$UserDb, $SyncStateTable, SyncStateData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (SyncStateData, BaseReferences<_$UserDb, $SyncStateTable, SyncStateData>),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$ContentPacksTableCreateCompanionBuilder = ContentPacksCompanion Function({
  required String id,
  Value<String?> version,
  Value<String?> installedAt,
  Value<String?> checksum,
  Value<int> rowid,
});
typedef $$ContentPacksTableUpdateCompanionBuilder = ContentPacksCompanion Function({
  Value<String> id,
  Value<String?> version,
  Value<String?> installedAt,
  Value<String?> checksum,
  Value<int> rowid,
});

class $$ContentPacksTableFilterComposer extends Composer<_$UserDb, $ContentPacksTable> {
  $$ContentPacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => ColumnFilters(column));
}

class $$ContentPacksTableOrderingComposer extends Composer<_$UserDb, $ContentPacksTable> {
  $$ContentPacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => ColumnOrderings(column));
}

class $$ContentPacksTableAnnotationComposer extends Composer<_$UserDb, $ContentPacksTable> {
  $$ContentPacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get version => $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get installedAt =>
      $composableBuilder(column: $table.installedAt, builder: (column) => column);

  GeneratedColumn<String> get checksum => $composableBuilder(column: $table.checksum, builder: (column) => column);
}

class $$ContentPacksTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $ContentPacksTable,
          ContentPack,
          $$ContentPacksTableFilterComposer,
          $$ContentPacksTableOrderingComposer,
          $$ContentPacksTableAnnotationComposer,
          $$ContentPacksTableCreateCompanionBuilder,
          $$ContentPacksTableUpdateCompanionBuilder,
          (ContentPack, BaseReferences<_$UserDb, $ContentPacksTable, ContentPack>),
          ContentPack,
          PrefetchHooks Function()
        > {
  $$ContentPacksTableTableManager(_$UserDb db, $ContentPacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ContentPacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ContentPacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ContentPacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> installedAt = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPacksCompanion(
                id: id,
                version: version,
                installedAt: installedAt,
                checksum: checksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> version = const Value.absent(),
                Value<String?> installedAt = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentPacksCompanion.insert(
                id: id,
                version: version,
                installedAt: installedAt,
                checksum: checksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContentPacksTable, ContentPack>(table),
                  BaseReferences<_$UserDb, $ContentPacksTable, ContentPack>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContentPacksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $ContentPacksTable,
      ContentPack,
      $$ContentPacksTableFilterComposer,
      $$ContentPacksTableOrderingComposer,
      $$ContentPacksTableAnnotationComposer,
      $$ContentPacksTableCreateCompanionBuilder,
      $$ContentPacksTableUpdateCompanionBuilder,
      (ContentPack, BaseReferences<_$UserDb, $ContentPacksTable, ContentPack>),
      ContentPack,
      PrefetchHooks Function()
    >;
typedef $$SearchHistoryTableCreateCompanionBuilder = SearchHistoryCompanion Function({
  Value<int> id,
  required String query,
  required String searchedAt,
});
typedef $$SearchHistoryTableUpdateCompanionBuilder = SearchHistoryCompanion Function({
  Value<int> id,
  Value<String> query,
  Value<String> searchedAt,
});

class $$SearchHistoryTableFilterComposer extends Composer<_$UserDb, $SearchHistoryTable> {
  $$SearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnFilters(column));
}

class $$SearchHistoryTableOrderingComposer extends Composer<_$UserDb, $SearchHistoryTable> {
  $$SearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get searchedAt =>
      $composableBuilder(column: $table.searchedAt, builder: (column) => ColumnOrderings(column));
}

class $$SearchHistoryTableAnnotationComposer extends Composer<_$UserDb, $SearchHistoryTable> {
  $$SearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get query => $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<String> get searchedAt => $composableBuilder(column: $table.searchedAt, builder: (column) => column);
}

class $$SearchHistoryTableTableManager
    extends
        RootTableManager<
          _$UserDb,
          $SearchHistoryTable,
          SearchHistoryData,
          $$SearchHistoryTableFilterComposer,
          $$SearchHistoryTableOrderingComposer,
          $$SearchHistoryTableAnnotationComposer,
          $$SearchHistoryTableCreateCompanionBuilder,
          $$SearchHistoryTableUpdateCompanionBuilder,
          (SearchHistoryData, BaseReferences<_$UserDb, $SearchHistoryTable, SearchHistoryData>),
          SearchHistoryData,
          PrefetchHooks Function()
        > {
  $$SearchHistoryTableTableManager(_$UserDb db, $SearchHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$SearchHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SearchHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SearchHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> query = const Value.absent(),
            Value<String> searchedAt = const Value.absent(),
          }) => SearchHistoryCompanion(id: id, query: query, searchedAt: searchedAt),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String query,
            required String searchedAt,
          }) => SearchHistoryCompanion.insert(id: id, query: query, searchedAt: searchedAt),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SearchHistoryTable, SearchHistoryData>(table),
                  BaseReferences<_$UserDb, $SearchHistoryTable, SearchHistoryData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDb,
      $SearchHistoryTable,
      SearchHistoryData,
      $$SearchHistoryTableFilterComposer,
      $$SearchHistoryTableOrderingComposer,
      $$SearchHistoryTableAnnotationComposer,
      $$SearchHistoryTableCreateCompanionBuilder,
      $$SearchHistoryTableUpdateCompanionBuilder,
      (SearchHistoryData, BaseReferences<_$UserDb, $SearchHistoryTable, SearchHistoryData>),
      SearchHistoryData,
      PrefetchHooks Function()
    >;

class $UserDbManager {
  final _$UserDb _db;
  $UserDbManager(this._db);
  $$BookmarksTableTableManager get bookmarks => $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$SrsCardsTableTableManager get srsCards => $$SrsCardsTableTableManager(_db, _db.srsCards);
  $$LessonProgressTableTableManager get lessonProgress => $$LessonProgressTableTableManager(_db, _db.lessonProgress);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$UserAchievementsTableTableManager get userAchievements =>
      $$UserAchievementsTableTableManager(_db, _db.userAchievements);
  $$UserSettingsTableTableManager get userSettings => $$UserSettingsTableTableManager(_db, _db.userSettings);
  $$ReviewLogsTableTableManager get reviewLogs => $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$ExerciseAttemptsTableTableManager get exerciseAttempts =>
      $$ExerciseAttemptsTableTableManager(_db, _db.exerciseAttempts);
  $$GameScoresTableTableManager get gameScores => $$GameScoresTableTableManager(_db, _db.gameScores);
  $$StreakFreezesTableTableManager get streakFreezes => $$StreakFreezesTableTableManager(_db, _db.streakFreezes);
  $$CoinLedgerTableTableManager get coinLedger => $$CoinLedgerTableTableManager(_db, _db.coinLedger);
  $$DailyStatsTableTableManager get dailyStats => $$DailyStatsTableTableManager(_db, _db.dailyStats);
  $$IslandInventoryTableTableManager get islandInventory =>
      $$IslandInventoryTableTableManager(_db, _db.islandInventory);
  $$StreakStateTableTableManager get streakState => $$StreakStateTableTableManager(_db, _db.streakState);
  $$LocalMetaTableTableManager get localMeta => $$LocalMetaTableTableManager(_db, _db.localMeta);
  $$SyncStateTableTableManager get syncState => $$SyncStateTableTableManager(_db, _db.syncState);
  $$ContentPacksTableTableManager get contentPacks => $$ContentPacksTableTableManager(_db, _db.contentPacks);
  $$SearchHistoryTableTableManager get searchHistory => $$SearchHistoryTableTableManager(_db, _db.searchHistory);
}
