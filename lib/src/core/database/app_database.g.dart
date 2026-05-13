// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PagesTable extends Pages with TableInfo<$PagesTable, Page> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _canonicalUrlMeta = const VerificationMeta('canonicalUrl');
  @override
  late final GeneratedColumn<String> canonicalUrl = GeneratedColumn<String>(
    'canonical_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastVisitedAtMeta = const VerificationMeta('lastVisitedAt');
  @override
  late final GeneratedColumn<DateTime> lastVisitedAt = GeneratedColumn<DateTime>(
    'last_visited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, url, canonicalUrl, title, createdAt, lastVisitedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(Insertable<Page> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('canonical_url')) {
      context.handle(_canonicalUrlMeta, canonicalUrl.isAcceptableOrUnknown(data['canonical_url']!, _canonicalUrlMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_visited_at')) {
      context.handle(
        _lastVisitedAtMeta,
        lastVisitedAt.isAcceptableOrUnknown(data['last_visited_at']!, _lastVisitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_lastVisitedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Page map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Page(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      canonicalUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}canonical_url']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      lastVisitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_visited_at'],
      )!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class Page extends DataClass implements Insertable<Page> {
  final String id;
  final String url;
  final String? canonicalUrl;
  final String? title;
  final DateTime createdAt;
  final DateTime lastVisitedAt;
  const Page({
    required this.id,
    required this.url,
    this.canonicalUrl,
    this.title,
    required this.createdAt,
    required this.lastVisitedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || canonicalUrl != null) {
      map['canonical_url'] = Variable<String>(canonicalUrl);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_visited_at'] = Variable<DateTime>(lastVisitedAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      url: Value(url),
      canonicalUrl: canonicalUrl == null && nullToAbsent ? const Value.absent() : Value(canonicalUrl),
      title: title == null && nullToAbsent ? const Value.absent() : Value(title),
      createdAt: Value(createdAt),
      lastVisitedAt: Value(lastVisitedAt),
    );
  }

  factory Page.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      canonicalUrl: serializer.fromJson<String?>(json['canonicalUrl']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastVisitedAt: serializer.fromJson<DateTime>(json['lastVisitedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'canonicalUrl': serializer.toJson<String?>(canonicalUrl),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastVisitedAt': serializer.toJson<DateTime>(lastVisitedAt),
    };
  }

  Page copyWith({
    String? id,
    String? url,
    Value<String?> canonicalUrl = const Value.absent(),
    Value<String?> title = const Value.absent(),
    DateTime? createdAt,
    DateTime? lastVisitedAt,
  }) => Page(
    id: id ?? this.id,
    url: url ?? this.url,
    canonicalUrl: canonicalUrl.present ? canonicalUrl.value : this.canonicalUrl,
    title: title.present ? title.value : this.title,
    createdAt: createdAt ?? this.createdAt,
    lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      canonicalUrl: data.canonicalUrl.present ? data.canonicalUrl.value : this.canonicalUrl,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastVisitedAt: data.lastVisitedAt.present ? data.lastVisitedAt.value : this.lastVisitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVisitedAt: $lastVisitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, url, canonicalUrl, title, createdAt, lastVisitedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.url == this.url &&
          other.canonicalUrl == this.canonicalUrl &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.lastVisitedAt == this.lastVisitedAt);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<String> id;
  final Value<String> url;
  final Value<String?> canonicalUrl;
  final Value<String?> title;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastVisitedAt;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastVisitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    required String url,
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    required DateTime createdAt,
    required DateTime lastVisitedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       createdAt = Value(createdAt),
       lastVisitedAt = Value(lastVisitedAt);
  static Insertable<Page> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? canonicalUrl,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastVisitedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (canonicalUrl != null) 'canonical_url': canonicalUrl,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (lastVisitedAt != null) 'last_visited_at': lastVisitedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PagesCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String?>? canonicalUrl,
    Value<String?>? title,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastVisitedAt,
    Value<int>? rowid,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (canonicalUrl.present) {
      map['canonical_url'] = Variable<String>(canonicalUrl.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastVisitedAt.present) {
      map['last_visited_at'] = Variable<DateTime>(lastVisitedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVisitedAt: $lastVisitedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations with TableInfo<$AnnotationsTable, Annotation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<String> pageId = GeneratedColumn<String>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES pages (id)'),
  );
  static const VerificationMeta _motivationMeta = const VerificationMeta('motivation');
  @override
  late final GeneratedColumn<String> motivation = GeneratedColumn<String>(
    'motivation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, pageId, motivation, createdAt, modifiedAt, deletedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(Insertable<Annotation> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(_pageIdMeta, pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta));
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('motivation')) {
      context.handle(_motivationMeta, motivation.isAcceptableOrUnknown(data['motivation']!, _motivationMeta));
    } else if (isInserting) {
      context.missing(_motivationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(_modifiedAtMeta, modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      pageId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}page_id'])!,
      motivation: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}motivation'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      modifiedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}modified_at'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $AnnotationsTable createAlias(String alias) {
    return $AnnotationsTable(attachedDatabase, alias);
  }
}

class Annotation extends DataClass implements Insertable<Annotation> {
  final String id;
  final String pageId;
  final String motivation;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? deletedAt;
  const Annotation({
    required this.id,
    required this.pageId,
    required this.motivation,
    required this.createdAt,
    required this.modifiedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['page_id'] = Variable<String>(pageId);
    map['motivation'] = Variable<String>(motivation);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['modified_at'] = Variable<DateTime>(modifiedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AnnotationsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationsCompanion(
      id: Value(id),
      pageId: Value(pageId),
      motivation: Value(motivation),
      createdAt: Value(createdAt),
      modifiedAt: Value(modifiedAt),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
    );
  }

  factory Annotation.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Annotation(
      id: serializer.fromJson<String>(json['id']),
      pageId: serializer.fromJson<String>(json['pageId']),
      motivation: serializer.fromJson<String>(json['motivation']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      modifiedAt: serializer.fromJson<DateTime>(json['modifiedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'pageId': serializer.toJson<String>(pageId),
      'motivation': serializer.toJson<String>(motivation),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'modifiedAt': serializer.toJson<DateTime>(modifiedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Annotation copyWith({
    String? id,
    String? pageId,
    String? motivation,
    DateTime? createdAt,
    DateTime? modifiedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Annotation(
    id: id ?? this.id,
    pageId: pageId ?? this.pageId,
    motivation: motivation ?? this.motivation,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Annotation copyWithCompanion(AnnotationsCompanion data) {
    return Annotation(
      id: data.id.present ? data.id.value : this.id,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      motivation: data.motivation.present ? data.motivation.value : this.motivation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Annotation(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('motivation: $motivation, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, pageId, motivation, createdAt, modifiedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Annotation &&
          other.id == this.id &&
          other.pageId == this.pageId &&
          other.motivation == this.motivation &&
          other.createdAt == this.createdAt &&
          other.modifiedAt == this.modifiedAt &&
          other.deletedAt == this.deletedAt);
}

class AnnotationsCompanion extends UpdateCompanion<Annotation> {
  final Value<String> id;
  final Value<String> pageId;
  final Value<String> motivation;
  final Value<DateTime> createdAt;
  final Value<DateTime> modifiedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AnnotationsCompanion({
    this.id = const Value.absent(),
    this.pageId = const Value.absent(),
    this.motivation = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationsCompanion.insert({
    required String id,
    required String pageId,
    required String motivation,
    required DateTime createdAt,
    required DateTime modifiedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       pageId = Value(pageId),
       motivation = Value(motivation),
       createdAt = Value(createdAt),
       modifiedAt = Value(modifiedAt);
  static Insertable<Annotation> custom({
    Expression<String>? id,
    Expression<String>? pageId,
    Expression<String>? motivation,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? modifiedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pageId != null) 'page_id': pageId,
      if (motivation != null) 'motivation': motivation,
      if (createdAt != null) 'created_at': createdAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationsCompanion copyWith({
    Value<String>? id,
    Value<String>? pageId,
    Value<String>? motivation,
    Value<DateTime>? createdAt,
    Value<DateTime>? modifiedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AnnotationsCompanion(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      motivation: motivation ?? this.motivation,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<String>(pageId.value);
    }
    if (motivation.present) {
      map['motivation'] = Variable<String>(motivation.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<DateTime>(modifiedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('pageId: $pageId, ')
          ..write('motivation: $motivation, ')
          ..write('createdAt: $createdAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationTargetsTable extends AnnotationTargets with TableInfo<$AnnotationTargetsTable, AnnotationTarget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annotationIdMeta = const VerificationMeta('annotationId');
  @override
  late final GeneratedColumn<String> annotationId = GeneratedColumn<String>(
    'annotation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES annotations (id)'),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta('sourceUrl');
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectorJsonMeta = const VerificationMeta('selectorJson');
  @override
  late final GeneratedColumn<String> selectorJson = GeneratedColumn<String>(
    'selector_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, annotationId, sourceUrl, selectorJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotation_targets';
  @override
  VerificationContext validateIntegrity(Insertable<AnnotationTarget> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('annotation_id')) {
      context.handle(_annotationIdMeta, annotationId.isAcceptableOrUnknown(data['annotation_id']!, _annotationIdMeta));
    } else if (isInserting) {
      context.missing(_annotationIdMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(_sourceUrlMeta, sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta));
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('selector_json')) {
      context.handle(_selectorJsonMeta, selectorJson.isAcceptableOrUnknown(data['selector_json']!, _selectorJsonMeta));
    } else if (isInserting) {
      context.missing(_selectorJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationTarget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationTarget(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      annotationId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}annotation_id'])!,
      sourceUrl: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source_url'])!,
      selectorJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}selector_json'])!,
    );
  }

  @override
  $AnnotationTargetsTable createAlias(String alias) {
    return $AnnotationTargetsTable(attachedDatabase, alias);
  }
}

class AnnotationTarget extends DataClass implements Insertable<AnnotationTarget> {
  final String id;
  final String annotationId;
  final String sourceUrl;
  final String selectorJson;
  const AnnotationTarget({
    required this.id,
    required this.annotationId,
    required this.sourceUrl,
    required this.selectorJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['annotation_id'] = Variable<String>(annotationId);
    map['source_url'] = Variable<String>(sourceUrl);
    map['selector_json'] = Variable<String>(selectorJson);
    return map;
  }

  AnnotationTargetsCompanion toCompanion(bool nullToAbsent) {
    return AnnotationTargetsCompanion(
      id: Value(id),
      annotationId: Value(annotationId),
      sourceUrl: Value(sourceUrl),
      selectorJson: Value(selectorJson),
    );
  }

  factory AnnotationTarget.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationTarget(
      id: serializer.fromJson<String>(json['id']),
      annotationId: serializer.fromJson<String>(json['annotationId']),
      sourceUrl: serializer.fromJson<String>(json['sourceUrl']),
      selectorJson: serializer.fromJson<String>(json['selectorJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'annotationId': serializer.toJson<String>(annotationId),
      'sourceUrl': serializer.toJson<String>(sourceUrl),
      'selectorJson': serializer.toJson<String>(selectorJson),
    };
  }

  AnnotationTarget copyWith({String? id, String? annotationId, String? sourceUrl, String? selectorJson}) =>
      AnnotationTarget(
        id: id ?? this.id,
        annotationId: annotationId ?? this.annotationId,
        sourceUrl: sourceUrl ?? this.sourceUrl,
        selectorJson: selectorJson ?? this.selectorJson,
      );
  AnnotationTarget copyWithCompanion(AnnotationTargetsCompanion data) {
    return AnnotationTarget(
      id: data.id.present ? data.id.value : this.id,
      annotationId: data.annotationId.present ? data.annotationId.value : this.annotationId,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      selectorJson: data.selectorJson.present ? data.selectorJson.value : this.selectorJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationTarget(')
          ..write('id: $id, ')
          ..write('annotationId: $annotationId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('selectorJson: $selectorJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, annotationId, sourceUrl, selectorJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationTarget &&
          other.id == this.id &&
          other.annotationId == this.annotationId &&
          other.sourceUrl == this.sourceUrl &&
          other.selectorJson == this.selectorJson);
}

class AnnotationTargetsCompanion extends UpdateCompanion<AnnotationTarget> {
  final Value<String> id;
  final Value<String> annotationId;
  final Value<String> sourceUrl;
  final Value<String> selectorJson;
  final Value<int> rowid;
  const AnnotationTargetsCompanion({
    this.id = const Value.absent(),
    this.annotationId = const Value.absent(),
    this.sourceUrl = const Value.absent(),
    this.selectorJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationTargetsCompanion.insert({
    required String id,
    required String annotationId,
    required String sourceUrl,
    required String selectorJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       annotationId = Value(annotationId),
       sourceUrl = Value(sourceUrl),
       selectorJson = Value(selectorJson);
  static Insertable<AnnotationTarget> custom({
    Expression<String>? id,
    Expression<String>? annotationId,
    Expression<String>? sourceUrl,
    Expression<String>? selectorJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (annotationId != null) 'annotation_id': annotationId,
      if (sourceUrl != null) 'source_url': sourceUrl,
      if (selectorJson != null) 'selector_json': selectorJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationTargetsCompanion copyWith({
    Value<String>? id,
    Value<String>? annotationId,
    Value<String>? sourceUrl,
    Value<String>? selectorJson,
    Value<int>? rowid,
  }) {
    return AnnotationTargetsCompanion(
      id: id ?? this.id,
      annotationId: annotationId ?? this.annotationId,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      selectorJson: selectorJson ?? this.selectorJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (annotationId.present) {
      map['annotation_id'] = Variable<String>(annotationId.value);
    }
    if (sourceUrl.present) {
      map['source_url'] = Variable<String>(sourceUrl.value);
    }
    if (selectorJson.present) {
      map['selector_json'] = Variable<String>(selectorJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationTargetsCompanion(')
          ..write('id: $id, ')
          ..write('annotationId: $annotationId, ')
          ..write('sourceUrl: $sourceUrl, ')
          ..write('selectorJson: $selectorJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationBodiesTable extends AnnotationBodies with TableInfo<$AnnotationBodiesTable, AnnotationBody> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnotationBodiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _annotationIdMeta = const VerificationMeta('annotationId');
  @override
  late final GeneratedColumn<String> annotationId = GeneratedColumn<String>(
    'annotation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES annotations (id)'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, annotationId, type, format, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotation_bodies';
  @override
  VerificationContext validateIntegrity(Insertable<AnnotationBody> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('annotation_id')) {
      context.handle(_annotationIdMeta, annotationId.isAcceptableOrUnknown(data['annotation_id']!, _annotationIdMeta));
    } else if (isInserting) {
      context.missing(_annotationIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(_typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta, format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnnotationBody map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnotationBody(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      annotationId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}annotation_id'])!,
      type: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      format: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}format']),
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AnnotationBodiesTable createAlias(String alias) {
    return $AnnotationBodiesTable(attachedDatabase, alias);
  }
}

class AnnotationBody extends DataClass implements Insertable<AnnotationBody> {
  final String id;
  final String annotationId;
  final String type;
  final String? format;
  final String value;
  const AnnotationBody({
    required this.id,
    required this.annotationId,
    required this.type,
    this.format,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['annotation_id'] = Variable<String>(annotationId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    map['value'] = Variable<String>(value);
    return map;
  }

  AnnotationBodiesCompanion toCompanion(bool nullToAbsent) {
    return AnnotationBodiesCompanion(
      id: Value(id),
      annotationId: Value(annotationId),
      type: Value(type),
      format: format == null && nullToAbsent ? const Value.absent() : Value(format),
      value: Value(value),
    );
  }

  factory AnnotationBody.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnotationBody(
      id: serializer.fromJson<String>(json['id']),
      annotationId: serializer.fromJson<String>(json['annotationId']),
      type: serializer.fromJson<String>(json['type']),
      format: serializer.fromJson<String?>(json['format']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'annotationId': serializer.toJson<String>(annotationId),
      'type': serializer.toJson<String>(type),
      'format': serializer.toJson<String?>(format),
      'value': serializer.toJson<String>(value),
    };
  }

  AnnotationBody copyWith({
    String? id,
    String? annotationId,
    String? type,
    Value<String?> format = const Value.absent(),
    String? value,
  }) => AnnotationBody(
    id: id ?? this.id,
    annotationId: annotationId ?? this.annotationId,
    type: type ?? this.type,
    format: format.present ? format.value : this.format,
    value: value ?? this.value,
  );
  AnnotationBody copyWithCompanion(AnnotationBodiesCompanion data) {
    return AnnotationBody(
      id: data.id.present ? data.id.value : this.id,
      annotationId: data.annotationId.present ? data.annotationId.value : this.annotationId,
      type: data.type.present ? data.type.value : this.type,
      format: data.format.present ? data.format.value : this.format,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnotationBody(')
          ..write('id: $id, ')
          ..write('annotationId: $annotationId, ')
          ..write('type: $type, ')
          ..write('format: $format, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, annotationId, type, format, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnotationBody &&
          other.id == this.id &&
          other.annotationId == this.annotationId &&
          other.type == this.type &&
          other.format == this.format &&
          other.value == this.value);
}

class AnnotationBodiesCompanion extends UpdateCompanion<AnnotationBody> {
  final Value<String> id;
  final Value<String> annotationId;
  final Value<String> type;
  final Value<String?> format;
  final Value<String> value;
  final Value<int> rowid;
  const AnnotationBodiesCompanion({
    this.id = const Value.absent(),
    this.annotationId = const Value.absent(),
    this.type = const Value.absent(),
    this.format = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnotationBodiesCompanion.insert({
    required String id,
    required String annotationId,
    required String type,
    this.format = const Value.absent(),
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       annotationId = Value(annotationId),
       type = Value(type),
       value = Value(value);
  static Insertable<AnnotationBody> custom({
    Expression<String>? id,
    Expression<String>? annotationId,
    Expression<String>? type,
    Expression<String>? format,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (annotationId != null) 'annotation_id': annotationId,
      if (type != null) 'type': type,
      if (format != null) 'format': format,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnotationBodiesCompanion copyWith({
    Value<String>? id,
    Value<String>? annotationId,
    Value<String>? type,
    Value<String?>? format,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AnnotationBodiesCompanion(
      id: id ?? this.id,
      annotationId: annotationId ?? this.annotationId,
      type: type ?? this.type,
      format: format ?? this.format,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (annotationId.present) {
      map['annotation_id'] = Variable<String>(annotationId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
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
    return (StringBuffer('AnnotationBodiesCompanion(')
          ..write('id: $id, ')
          ..write('annotationId: $annotationId, ')
          ..write('type: $type, ')
          ..write('format: $format, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, url, title, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(Insertable<Bookmark> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(_urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
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
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      url: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}url'])!,
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String url;
  final String? title;
  final DateTime createdAt;
  const Bookmark({required this.id, required this.url, this.title, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      url: Value(url),
      title: title == null && nullToAbsent ? const Value.absent() : Value(title),
      createdAt: Value(createdAt),
    );
  }

  factory Bookmark.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String?>(title),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Bookmark copyWith({String? id, String? url, Value<String?> title = const Value.absent(), DateTime? createdAt}) =>
      Bookmark(
        id: id ?? this.id,
        url: url ?? this.url,
        title: title.present ? title.value : this.title,
        createdAt: createdAt ?? this.createdAt,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, url, title, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String> url;
  final Value<String?> title;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String url,
    this.title = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       createdAt = Value(createdAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String?>? title,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $AnnotationsTable annotations = $AnnotationsTable(this);
  late final $AnnotationTargetsTable annotationTargets = $AnnotationTargetsTable(this);
  late final $AnnotationBodiesTable annotationBodies = $AnnotationBodiesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pages,
    annotations,
    annotationTargets,
    annotationBodies,
    bookmarks,
  ];
}

typedef $$PagesTableCreateCompanionBuilder =
    PagesCompanion Function({
      required String id,
      required String url,
      Value<String?> canonicalUrl,
      Value<String?> title,
      required DateTime createdAt,
      required DateTime lastVisitedAt,
      Value<int> rowid,
    });
typedef $$PagesTableUpdateCompanionBuilder =
    PagesCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String?> canonicalUrl,
      Value<String?> title,
      Value<DateTime> createdAt,
      Value<DateTime> lastVisitedAt,
      Value<int> rowid,
    });

final class $$PagesTableReferences extends BaseReferences<_$AppDatabase, $PagesTable, Page> {
  $$PagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnnotationsTable, List<Annotation>> _annotationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.annotations,
        aliasName: $_aliasNameGenerator(db.pages.id, db.annotations.pageId),
      );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalUrl =>
      $composableBuilder(column: $table.canonicalUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastVisitedAt =>
      $composableBuilder(column: $table.lastVisitedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> annotationsRefs(Expression<bool> Function($$AnnotationsTableFilterComposer f) f) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.pageId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableOrderingComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalUrl =>
      $composableBuilder(column: $table.canonicalUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastVisitedAt =>
      $composableBuilder(column: $table.lastVisitedAt, builder: (column) => ColumnOrderings(column));
}

class $$PagesTableAnnotationComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url => $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get canonicalUrl =>
      $composableBuilder(column: $table.canonicalUrl, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVisitedAt =>
      $composableBuilder(column: $table.lastVisitedAt, builder: (column) => column);

  Expression<T> annotationsRefs<T extends Object>(Expression<T> Function($$AnnotationsTableAnnotationComposer a) f) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.pageId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagesTable,
          Page,
          $$PagesTableFilterComposer,
          $$PagesTableOrderingComposer,
          $$PagesTableAnnotationComposer,
          $$PagesTableCreateCompanionBuilder,
          $$PagesTableUpdateCompanionBuilder,
          (Page, $$PagesTableReferences),
          Page,
          PrefetchHooks Function({bool annotationsRefs})
        > {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> canonicalUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastVisitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                createdAt: createdAt,
                lastVisitedAt: lastVisitedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                Value<String?> canonicalUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required DateTime createdAt,
                required DateTime lastVisitedAt,
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                createdAt: createdAt,
                lastVisitedAt: lastVisitedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$PagesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({annotationsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (annotationsRefs) db.annotations],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (annotationsRefs)
                    await $_getPrefetchedData<Page, $PagesTable, Annotation>(
                      currentTable: table,
                      referencedTable: $$PagesTableReferences._annotationsRefsTable(db),
                      managerFromTypedResult: (p0) => $$PagesTableReferences(db, table, p0).annotationsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.pageId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagesTable,
      Page,
      $$PagesTableFilterComposer,
      $$PagesTableOrderingComposer,
      $$PagesTableAnnotationComposer,
      $$PagesTableCreateCompanionBuilder,
      $$PagesTableUpdateCompanionBuilder,
      (Page, $$PagesTableReferences),
      Page,
      PrefetchHooks Function({bool annotationsRefs})
    >;
typedef $$AnnotationsTableCreateCompanionBuilder =
    AnnotationsCompanion Function({
      required String id,
      required String pageId,
      required String motivation,
      required DateTime createdAt,
      required DateTime modifiedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AnnotationsTableUpdateCompanionBuilder =
    AnnotationsCompanion Function({
      Value<String> id,
      Value<String> pageId,
      Value<String> motivation,
      Value<DateTime> createdAt,
      Value<DateTime> modifiedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$AnnotationsTableReferences extends BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias($_aliasNameGenerator(db.annotations.pageId, db.pages.id));

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableManager($_db, $_db.pages).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AnnotationTargetsTable, List<AnnotationTarget>> _annotationTargetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.annotationTargets,
    aliasName: $_aliasNameGenerator(db.annotations.id, db.annotationTargets.annotationId),
  );

  $$AnnotationTargetsTableProcessedTableManager get annotationTargetsRefs {
    final manager = $$AnnotationTargetsTableTableManager(
      $_db,
      $_db.annotationTargets,
    ).filter((f) => f.annotationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationTargetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AnnotationBodiesTable, List<AnnotationBody>> _annotationBodiesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.annotationBodies,
    aliasName: $_aliasNameGenerator(db.annotations.id, db.annotationBodies.annotationId),
  );

  $$AnnotationBodiesTableProcessedTableManager get annotationBodiesRefs {
    final manager = $$AnnotationBodiesTableTableManager(
      $_db,
      $_db.annotationBodies,
    ).filter((f) => f.annotationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationBodiesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AnnotationsTableFilterComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get motivation =>
      $composableBuilder(column: $table.motivation, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get modifiedAt =>
      $composableBuilder(column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> annotationTargetsRefs(Expression<bool> Function($$AnnotationTargetsTableFilterComposer f) f) {
    final $$AnnotationTargetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationTargets,
      getReferencedColumn: (t) => t.annotationId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationTargetsTableFilterComposer(
            $db: $db,
            $table: $db.annotationTargets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationBodiesRefs(Expression<bool> Function($$AnnotationBodiesTableFilterComposer f) f) {
    final $$AnnotationBodiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationBodies,
      getReferencedColumn: (t) => t.annotationId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationBodiesTableFilterComposer(
            $db: $db,
            $table: $db.annotationBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnnotationsTableOrderingComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get motivation =>
      $composableBuilder(column: $table.motivation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get modifiedAt =>
      $composableBuilder(column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get motivation => $composableBuilder(column: $table.motivation, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt =>
      $composableBuilder(column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> annotationTargetsRefs<T extends Object>(
    Expression<T> Function($$AnnotationTargetsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationTargetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationTargets,
      getReferencedColumn: (t) => t.annotationId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationTargetsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotationTargets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> annotationBodiesRefs<T extends Object>(
    Expression<T> Function($$AnnotationBodiesTableAnnotationComposer a) f,
  ) {
    final $$AnnotationBodiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationBodies,
      getReferencedColumn: (t) => t.annotationId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationBodiesTableAnnotationComposer(
            $db: $db,
            $table: $db.annotationBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnnotationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationsTable,
          Annotation,
          $$AnnotationsTableFilterComposer,
          $$AnnotationsTableOrderingComposer,
          $$AnnotationsTableAnnotationComposer,
          $$AnnotationsTableCreateCompanionBuilder,
          $$AnnotationsTableUpdateCompanionBuilder,
          (Annotation, $$AnnotationsTableReferences),
          Annotation,
          PrefetchHooks Function({bool pageId, bool annotationTargetsRefs, bool annotationBodiesRefs})
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> pageId = const Value.absent(),
                Value<String> motivation = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> modifiedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion(
                id: id,
                pageId: pageId,
                motivation: motivation,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String pageId,
                required String motivation,
                required DateTime createdAt,
                required DateTime modifiedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationsCompanion.insert(
                id: id,
                pageId: pageId,
                motivation: motivation,
                createdAt: createdAt,
                modifiedAt: modifiedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$AnnotationsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({pageId = false, annotationTargetsRefs = false, annotationBodiesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (annotationTargetsRefs) db.annotationTargets,
                if (annotationBodiesRefs) db.annotationBodies,
              ],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable: $$AnnotationsTableReferences._pageIdTable(db),
                                referencedColumn: $$AnnotationsTableReferences._pageIdTable(db).id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (annotationTargetsRefs)
                    await $_getPrefetchedData<Annotation, $AnnotationsTable, AnnotationTarget>(
                      currentTable: table,
                      referencedTable: $$AnnotationsTableReferences._annotationTargetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$AnnotationsTableReferences(db, table, p0).annotationTargetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.annotationId == item.id),
                      typedResults: items,
                    ),
                  if (annotationBodiesRefs)
                    await $_getPrefetchedData<Annotation, $AnnotationsTable, AnnotationBody>(
                      currentTable: table,
                      referencedTable: $$AnnotationsTableReferences._annotationBodiesRefsTable(db),
                      managerFromTypedResult: (p0) => $$AnnotationsTableReferences(db, table, p0).annotationBodiesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.annotationId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationsTable,
      Annotation,
      $$AnnotationsTableFilterComposer,
      $$AnnotationsTableOrderingComposer,
      $$AnnotationsTableAnnotationComposer,
      $$AnnotationsTableCreateCompanionBuilder,
      $$AnnotationsTableUpdateCompanionBuilder,
      (Annotation, $$AnnotationsTableReferences),
      Annotation,
      PrefetchHooks Function({bool pageId, bool annotationTargetsRefs, bool annotationBodiesRefs})
    >;
typedef $$AnnotationTargetsTableCreateCompanionBuilder =
    AnnotationTargetsCompanion Function({
      required String id,
      required String annotationId,
      required String sourceUrl,
      required String selectorJson,
      Value<int> rowid,
    });
typedef $$AnnotationTargetsTableUpdateCompanionBuilder =
    AnnotationTargetsCompanion Function({
      Value<String> id,
      Value<String> annotationId,
      Value<String> sourceUrl,
      Value<String> selectorJson,
      Value<int> rowid,
    });

final class $$AnnotationTargetsTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationTargetsTable, AnnotationTarget> {
  $$AnnotationTargetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AnnotationsTable _annotationIdTable(_$AppDatabase db) =>
      db.annotations.createAlias($_aliasNameGenerator(db.annotationTargets.annotationId, db.annotations.id));

  $$AnnotationsTableProcessedTableManager get annotationId {
    final $_column = $_itemColumn<String>('annotation_id')!;

    final manager = $$AnnotationsTableTableManager($_db, $_db.annotations).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_annotationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AnnotationTargetsTableFilterComposer extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get selectorJson =>
      $composableBuilder(column: $table.selectorJson, builder: (column) => ColumnFilters(column));

  $$AnnotationsTableFilterComposer get annotationId {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationTargetsTableOrderingComposer extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get selectorJson =>
      $composableBuilder(column: $table.selectorJson, builder: (column) => ColumnOrderings(column));

  $$AnnotationsTableOrderingComposer get annotationId {
    final $$AnnotationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableOrderingComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationTargetsTableAnnotationComposer extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl => $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get selectorJson =>
      $composableBuilder(column: $table.selectorJson, builder: (column) => column);

  $$AnnotationsTableAnnotationComposer get annotationId {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationTargetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationTargetsTable,
          AnnotationTarget,
          $$AnnotationTargetsTableFilterComposer,
          $$AnnotationTargetsTableOrderingComposer,
          $$AnnotationTargetsTableAnnotationComposer,
          $$AnnotationTargetsTableCreateCompanionBuilder,
          $$AnnotationTargetsTableUpdateCompanionBuilder,
          (AnnotationTarget, $$AnnotationTargetsTableReferences),
          AnnotationTarget,
          PrefetchHooks Function({bool annotationId})
        > {
  $$AnnotationTargetsTableTableManager(_$AppDatabase db, $AnnotationTargetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AnnotationTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AnnotationTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AnnotationTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> annotationId = const Value.absent(),
                Value<String> sourceUrl = const Value.absent(),
                Value<String> selectorJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationTargetsCompanion(
                id: id,
                annotationId: annotationId,
                sourceUrl: sourceUrl,
                selectorJson: selectorJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String annotationId,
                required String sourceUrl,
                required String selectorJson,
                Value<int> rowid = const Value.absent(),
              }) => AnnotationTargetsCompanion.insert(
                id: id,
                annotationId: annotationId,
                sourceUrl: sourceUrl,
                selectorJson: selectorJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$AnnotationTargetsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({annotationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (annotationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.annotationId,
                                referencedTable: $$AnnotationTargetsTableReferences._annotationIdTable(db),
                                referencedColumn: $$AnnotationTargetsTableReferences._annotationIdTable(db).id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationTargetsTable,
      AnnotationTarget,
      $$AnnotationTargetsTableFilterComposer,
      $$AnnotationTargetsTableOrderingComposer,
      $$AnnotationTargetsTableAnnotationComposer,
      $$AnnotationTargetsTableCreateCompanionBuilder,
      $$AnnotationTargetsTableUpdateCompanionBuilder,
      (AnnotationTarget, $$AnnotationTargetsTableReferences),
      AnnotationTarget,
      PrefetchHooks Function({bool annotationId})
    >;
typedef $$AnnotationBodiesTableCreateCompanionBuilder =
    AnnotationBodiesCompanion Function({
      required String id,
      required String annotationId,
      required String type,
      Value<String?> format,
      required String value,
      Value<int> rowid,
    });
typedef $$AnnotationBodiesTableUpdateCompanionBuilder =
    AnnotationBodiesCompanion Function({
      Value<String> id,
      Value<String> annotationId,
      Value<String> type,
      Value<String?> format,
      Value<String> value,
      Value<int> rowid,
    });

final class $$AnnotationBodiesTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationBodiesTable, AnnotationBody> {
  $$AnnotationBodiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AnnotationsTable _annotationIdTable(_$AppDatabase db) =>
      db.annotations.createAlias($_aliasNameGenerator(db.annotationBodies.annotationId, db.annotations.id));

  $$AnnotationsTableProcessedTableManager get annotationId {
    final $_column = $_itemColumn<String>('annotation_id')!;

    final manager = $$AnnotationsTableTableManager($_db, $_db.annotations).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_annotationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AnnotationBodiesTableFilterComposer extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  $$AnnotationsTableFilterComposer get annotationId {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationBodiesTableOrderingComposer extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  $$AnnotationsTableOrderingComposer get annotationId {
    final $$AnnotationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableOrderingComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationBodiesTableAnnotationComposer extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type => $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get format => $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  $$AnnotationsTableAnnotationComposer get annotationId {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationBodiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnnotationBodiesTable,
          AnnotationBody,
          $$AnnotationBodiesTableFilterComposer,
          $$AnnotationBodiesTableOrderingComposer,
          $$AnnotationBodiesTableAnnotationComposer,
          $$AnnotationBodiesTableCreateCompanionBuilder,
          $$AnnotationBodiesTableUpdateCompanionBuilder,
          (AnnotationBody, $$AnnotationBodiesTableReferences),
          AnnotationBody,
          PrefetchHooks Function({bool annotationId})
        > {
  $$AnnotationBodiesTableTableManager(_$AppDatabase db, $AnnotationBodiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$AnnotationBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$AnnotationBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$AnnotationBodiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> annotationId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnotationBodiesCompanion(
                id: id,
                annotationId: annotationId,
                type: type,
                format: format,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String annotationId,
                required String type,
                Value<String?> format = const Value.absent(),
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AnnotationBodiesCompanion.insert(
                id: id,
                annotationId: annotationId,
                type: type,
                format: format,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), $$AnnotationBodiesTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({annotationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (annotationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.annotationId,
                                referencedTable: $$AnnotationBodiesTableReferences._annotationIdTable(db),
                                referencedColumn: $$AnnotationBodiesTableReferences._annotationIdTable(db).id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AnnotationBodiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnnotationBodiesTable,
      AnnotationBody,
      $$AnnotationBodiesTableFilterComposer,
      $$AnnotationBodiesTableOrderingComposer,
      $$AnnotationBodiesTableAnnotationComposer,
      $$AnnotationBodiesTableCreateCompanionBuilder,
      $$AnnotationBodiesTableUpdateCompanionBuilder,
      (AnnotationBody, $$AnnotationBodiesTableReferences),
      AnnotationBody,
      PrefetchHooks Function({bool annotationId})
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String url,
      Value<String?> title,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String?> title,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BookmarksTableFilterComposer extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$BookmarksTableOrderingComposer extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$BookmarksTableAnnotationComposer extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url => $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(id: id, url: url, title: title, createdAt: createdAt, rowid: rowid),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                Value<String?> title = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(id: id, url: url, title: title, createdAt: createdAt, rowid: rowid),
          withReferenceMapper: (p0) => p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PagesTableTableManager get pages => $$PagesTableTableManager(_db, _db.pages);
  $$AnnotationsTableTableManager get annotations => $$AnnotationsTableTableManager(_db, _db.annotations);
  $$AnnotationTargetsTableTableManager get annotationTargets =>
      $$AnnotationTargetsTableTableManager(_db, _db.annotationTargets);
  $$AnnotationBodiesTableTableManager get annotationBodies =>
      $$AnnotationBodiesTableTableManager(_db, _db.annotationBodies);
  $$BookmarksTableTableManager get bookmarks => $$BookmarksTableTableManager(_db, _db.bookmarks);
}
