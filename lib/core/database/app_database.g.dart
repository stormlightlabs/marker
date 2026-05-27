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
  static const VerificationMeta _canonicalUrlMeta = const VerificationMeta(
    'canonicalUrl',
  );
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faviconUrlMeta = const VerificationMeta(
    'faviconUrl',
  );
  @override
  late final GeneratedColumn<String> faviconUrl = GeneratedColumn<String>(
    'favicon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _faviconFilePathMeta = const VerificationMeta(
    'faviconFilePath',
  );
  @override
  late final GeneratedColumn<String> faviconFilePath = GeneratedColumn<String>(
    'favicon_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastVisitedAtMeta = const VerificationMeta(
    'lastVisitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVisitedAt =
      GeneratedColumn<DateTime>(
        'last_visited_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    canonicalUrl,
    title,
    description,
    faviconUrl,
    faviconFilePath,
    createdAt,
    lastVisitedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Page> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('canonical_url')) {
      context.handle(
        _canonicalUrlMeta,
        canonicalUrl.isAcceptableOrUnknown(
          data['canonical_url']!,
          _canonicalUrlMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('favicon_url')) {
      context.handle(
        _faviconUrlMeta,
        faviconUrl.isAcceptableOrUnknown(data['favicon_url']!, _faviconUrlMeta),
      );
    }
    if (data.containsKey('favicon_file_path')) {
      context.handle(
        _faviconFilePathMeta,
        faviconFilePath.isAcceptableOrUnknown(
          data['favicon_file_path']!,
          _faviconFilePathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_visited_at')) {
      context.handle(
        _lastVisitedAtMeta,
        lastVisitedAt.isAcceptableOrUnknown(
          data['last_visited_at']!,
          _lastVisitedAtMeta,
        ),
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      canonicalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      faviconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favicon_url'],
      ),
      faviconFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}favicon_file_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
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
  final String? description;
  final String? faviconUrl;
  final String? faviconFilePath;
  final DateTime createdAt;
  final DateTime lastVisitedAt;
  const Page({
    required this.id,
    required this.url,
    this.canonicalUrl,
    this.title,
    this.description,
    this.faviconUrl,
    this.faviconFilePath,
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
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || faviconUrl != null) {
      map['favicon_url'] = Variable<String>(faviconUrl);
    }
    if (!nullToAbsent || faviconFilePath != null) {
      map['favicon_file_path'] = Variable<String>(faviconFilePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['last_visited_at'] = Variable<DateTime>(lastVisitedAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      url: Value(url),
      canonicalUrl: canonicalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalUrl),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      faviconUrl: faviconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(faviconUrl),
      faviconFilePath: faviconFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(faviconFilePath),
      createdAt: Value(createdAt),
      lastVisitedAt: Value(lastVisitedAt),
    );
  }

  factory Page.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      canonicalUrl: serializer.fromJson<String?>(json['canonicalUrl']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      faviconUrl: serializer.fromJson<String?>(json['faviconUrl']),
      faviconFilePath: serializer.fromJson<String?>(json['faviconFilePath']),
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
      'description': serializer.toJson<String?>(description),
      'faviconUrl': serializer.toJson<String?>(faviconUrl),
      'faviconFilePath': serializer.toJson<String?>(faviconFilePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastVisitedAt': serializer.toJson<DateTime>(lastVisitedAt),
    };
  }

  Page copyWith({
    String? id,
    String? url,
    Value<String?> canonicalUrl = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> faviconUrl = const Value.absent(),
    Value<String?> faviconFilePath = const Value.absent(),
    DateTime? createdAt,
    DateTime? lastVisitedAt,
  }) => Page(
    id: id ?? this.id,
    url: url ?? this.url,
    canonicalUrl: canonicalUrl.present ? canonicalUrl.value : this.canonicalUrl,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    faviconUrl: faviconUrl.present ? faviconUrl.value : this.faviconUrl,
    faviconFilePath: faviconFilePath.present
        ? faviconFilePath.value
        : this.faviconFilePath,
    createdAt: createdAt ?? this.createdAt,
    lastVisitedAt: lastVisitedAt ?? this.lastVisitedAt,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      canonicalUrl: data.canonicalUrl.present
          ? data.canonicalUrl.value
          : this.canonicalUrl,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      faviconUrl: data.faviconUrl.present
          ? data.faviconUrl.value
          : this.faviconUrl,
      faviconFilePath: data.faviconFilePath.present
          ? data.faviconFilePath.value
          : this.faviconFilePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastVisitedAt: data.lastVisitedAt.present
          ? data.lastVisitedAt.value
          : this.lastVisitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('faviconUrl: $faviconUrl, ')
          ..write('faviconFilePath: $faviconFilePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVisitedAt: $lastVisitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    canonicalUrl,
    title,
    description,
    faviconUrl,
    faviconFilePath,
    createdAt,
    lastVisitedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.url == this.url &&
          other.canonicalUrl == this.canonicalUrl &&
          other.title == this.title &&
          other.description == this.description &&
          other.faviconUrl == this.faviconUrl &&
          other.faviconFilePath == this.faviconFilePath &&
          other.createdAt == this.createdAt &&
          other.lastVisitedAt == this.lastVisitedAt);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<String> id;
  final Value<String> url;
  final Value<String?> canonicalUrl;
  final Value<String?> title;
  final Value<String?> description;
  final Value<String?> faviconUrl;
  final Value<String?> faviconFilePath;
  final Value<DateTime> createdAt;
  final Value<DateTime> lastVisitedAt;
  final Value<int> rowid;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.faviconUrl = const Value.absent(),
    this.faviconFilePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastVisitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PagesCompanion.insert({
    required String id,
    required String url,
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.faviconUrl = const Value.absent(),
    this.faviconFilePath = const Value.absent(),
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
    Expression<String>? description,
    Expression<String>? faviconUrl,
    Expression<String>? faviconFilePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastVisitedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (canonicalUrl != null) 'canonical_url': canonicalUrl,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (faviconUrl != null) 'favicon_url': faviconUrl,
      if (faviconFilePath != null) 'favicon_file_path': faviconFilePath,
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
    Value<String?>? description,
    Value<String?>? faviconUrl,
    Value<String?>? faviconFilePath,
    Value<DateTime>? createdAt,
    Value<DateTime>? lastVisitedAt,
    Value<int>? rowid,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      faviconFilePath: faviconFilePath ?? this.faviconFilePath,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (faviconUrl.present) {
      map['favicon_url'] = Variable<String>(faviconUrl.value);
    }
    if (faviconFilePath.present) {
      map['favicon_file_path'] = Variable<String>(faviconFilePath.value);
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
          ..write('description: $description, ')
          ..write('faviconUrl: $faviconUrl, ')
          ..write('faviconFilePath: $faviconFilePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastVisitedAt: $lastVisitedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnotationsTable extends Annotations
    with TableInfo<$AnnotationsTable, Annotation> {
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id)',
    ),
  );
  static const VerificationMeta _motivationMeta = const VerificationMeta(
    'motivation',
  );
  @override
  late final GeneratedColumn<String> motivation = GeneratedColumn<String>(
    'motivation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> modifiedAt = GeneratedColumn<DateTime>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pageId,
    motivation,
    createdAt,
    modifiedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Annotation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('motivation')) {
      context.handle(
        _motivationMeta,
        motivation.isAcceptableOrUnknown(data['motivation']!, _motivationMeta),
      );
    } else if (isInserting) {
      context.missing(_motivationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Annotation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Annotation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_id'],
      )!,
      motivation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivation'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}modified_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
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
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Annotation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      motivation: data.motivation.present
          ? data.motivation.value
          : this.motivation,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
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
  int get hashCode =>
      Object.hash(id, pageId, motivation, createdAt, modifiedAt, deletedAt);
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

class $AnnotationTargetsTable extends AnnotationTargets
    with TableInfo<$AnnotationTargetsTable, AnnotationTarget> {
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
  static const VerificationMeta _annotationIdMeta = const VerificationMeta(
    'annotationId',
  );
  @override
  late final GeneratedColumn<String> annotationId = GeneratedColumn<String>(
    'annotation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES annotations (id)',
    ),
  );
  static const VerificationMeta _sourceUrlMeta = const VerificationMeta(
    'sourceUrl',
  );
  @override
  late final GeneratedColumn<String> sourceUrl = GeneratedColumn<String>(
    'source_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectorJsonMeta = const VerificationMeta(
    'selectorJson',
  );
  @override
  late final GeneratedColumn<String> selectorJson = GeneratedColumn<String>(
    'selector_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    annotationId,
    sourceUrl,
    selectorJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'annotation_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnotationTarget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('annotation_id')) {
      context.handle(
        _annotationIdMeta,
        annotationId.isAcceptableOrUnknown(
          data['annotation_id']!,
          _annotationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annotationIdMeta);
    }
    if (data.containsKey('source_url')) {
      context.handle(
        _sourceUrlMeta,
        sourceUrl.isAcceptableOrUnknown(data['source_url']!, _sourceUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUrlMeta);
    }
    if (data.containsKey('selector_json')) {
      context.handle(
        _selectorJsonMeta,
        selectorJson.isAcceptableOrUnknown(
          data['selector_json']!,
          _selectorJsonMeta,
        ),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      annotationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation_id'],
      )!,
      sourceUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_url'],
      )!,
      selectorJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selector_json'],
      )!,
    );
  }

  @override
  $AnnotationTargetsTable createAlias(String alias) {
    return $AnnotationTargetsTable(attachedDatabase, alias);
  }
}

class AnnotationTarget extends DataClass
    implements Insertable<AnnotationTarget> {
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

  factory AnnotationTarget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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

  AnnotationTarget copyWith({
    String? id,
    String? annotationId,
    String? sourceUrl,
    String? selectorJson,
  }) => AnnotationTarget(
    id: id ?? this.id,
    annotationId: annotationId ?? this.annotationId,
    sourceUrl: sourceUrl ?? this.sourceUrl,
    selectorJson: selectorJson ?? this.selectorJson,
  );
  AnnotationTarget copyWithCompanion(AnnotationTargetsCompanion data) {
    return AnnotationTarget(
      id: data.id.present ? data.id.value : this.id,
      annotationId: data.annotationId.present
          ? data.annotationId.value
          : this.annotationId,
      sourceUrl: data.sourceUrl.present ? data.sourceUrl.value : this.sourceUrl,
      selectorJson: data.selectorJson.present
          ? data.selectorJson.value
          : this.selectorJson,
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

class $AnnotationBodiesTable extends AnnotationBodies
    with TableInfo<$AnnotationBodiesTable, AnnotationBody> {
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
  static const VerificationMeta _annotationIdMeta = const VerificationMeta(
    'annotationId',
  );
  @override
  late final GeneratedColumn<String> annotationId = GeneratedColumn<String>(
    'annotation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES annotations (id)',
    ),
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
  VerificationContext validateIntegrity(
    Insertable<AnnotationBody> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('annotation_id')) {
      context.handle(
        _annotationIdMeta,
        annotationId.isAcceptableOrUnknown(
          data['annotation_id']!,
          _annotationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_annotationIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
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
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      annotationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}annotation_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
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
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      value: Value(value),
    );
  }

  factory AnnotationBody.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
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
      annotationId: data.annotationId.present
          ? data.annotationId.value
          : this.annotationId,
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

class $BookmarkFoldersTable extends BookmarkFolders
    with TableInfo<$BookmarkFoldersTable, BookmarkFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bookmark_folders (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessTypeMeta = const VerificationMeta(
    'accessType',
  );
  @override
  late final GeneratedColumn<String> accessType = GeneratedColumn<String>(
    'access_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CLOSED'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    title,
    description,
    accessType,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmark_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('access_type')) {
      context.handle(
        _accessTypeMeta,
        accessType.isAcceptableOrUnknown(data['access_type']!, _accessTypeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      accessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_type'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BookmarkFoldersTable createAlias(String alias) {
    return $BookmarkFoldersTable(attachedDatabase, alias);
  }
}

class BookmarkFolder extends DataClass implements Insertable<BookmarkFolder> {
  final String id;
  final String? parentId;
  final String title;
  final String? description;
  final String accessType;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const BookmarkFolder({
    required this.id,
    this.parentId,
    required this.title,
    this.description,
    required this.accessType,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['access_type'] = Variable<String>(accessType);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BookmarkFoldersCompanion toCompanion(bool nullToAbsent) {
    return BookmarkFoldersCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      accessType: Value(accessType),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BookmarkFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkFolder(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      accessType: serializer.fromJson<String>(json['accessType']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'accessType': serializer.toJson<String>(accessType),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BookmarkFolder copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    String? accessType,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BookmarkFolder(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    accessType: accessType ?? this.accessType,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BookmarkFolder copyWithCompanion(BookmarkFoldersCompanion data) {
    return BookmarkFolder(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      accessType: data.accessType.present
          ? data.accessType.value
          : this.accessType,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkFolder(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('accessType: $accessType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    title,
    description,
    accessType,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkFolder &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.title == this.title &&
          other.description == this.description &&
          other.accessType == this.accessType &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BookmarkFoldersCompanion extends UpdateCompanion<BookmarkFolder> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> accessType;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BookmarkFoldersCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.accessType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarkFoldersCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.accessType = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BookmarkFolder> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? accessType,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (accessType != null) 'access_type': accessType,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarkFoldersCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? accessType,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BookmarkFoldersCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      accessType: accessType ?? this.accessType,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (accessType.present) {
      map['access_type'] = Variable<String>(accessType.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
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
    return (StringBuffer('BookmarkFoldersCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('accessType: $accessType, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
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
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bookmark_folders (id)',
    ),
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
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    folderId,
    url,
    title,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final String id;
  final String? folderId;
  final String url;
  final String? title;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Bookmark({
    required this.id,
    this.folderId,
    required this.url,
    this.title,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || folderId != null) {
      map['folder_id'] = Variable<String>(folderId);
    }
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      folderId: folderId == null && nullToAbsent
          ? const Value.absent()
          : Value(folderId),
      url: Value(url),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<String>(json['id']),
      folderId: serializer.fromJson<String?>(json['folderId']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'folderId': serializer.toJson<String?>(folderId),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String?>(title),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Bookmark copyWith({
    String? id,
    Value<String?> folderId = const Value.absent(),
    String? url,
    Value<String?> title = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Bookmark(
    id: id ?? this.id,
    folderId: folderId.present ? folderId.value : this.folderId,
    url: url ?? this.url,
    title: title.present ? title.value : this.title,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    folderId,
    url,
    title,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.folderId == this.folderId &&
          other.url == this.url &&
          other.title == this.title &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<String> id;
  final Value<String?> folderId;
  final Value<String> url;
  final Value<String?> title;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.folderId = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    this.folderId = const Value.absent(),
    required String url,
    this.title = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Bookmark> custom({
    Expression<String>? id,
    Expression<String>? folderId,
    Expression<String>? url,
    Expression<String>? title,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (folderId != null) 'folder_id': folderId,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String?>? folderId,
    Value<String>? url,
    Value<String?>? title,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      url: url ?? this.url,
      title: title ?? this.title,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
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
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('folderId: $folderId, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarkCollectionLinksTable extends BookmarkCollectionLinks
    with TableInfo<$BookmarkCollectionLinksTable, BookmarkCollectionLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarkCollectionLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookmarkIdMeta = const VerificationMeta(
    'bookmarkId',
  );
  @override
  late final GeneratedColumn<String> bookmarkId = GeneratedColumn<String>(
    'bookmark_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bookmarks (id)',
    ),
  );
  static const VerificationMeta _folderIdMeta = const VerificationMeta(
    'folderId',
  );
  @override
  late final GeneratedColumn<String> folderId = GeneratedColumn<String>(
    'folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bookmark_folders (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bookmarkId,
    folderId,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmark_collection_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkCollectionLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bookmark_id')) {
      context.handle(
        _bookmarkIdMeta,
        bookmarkId.isAcceptableOrUnknown(data['bookmark_id']!, _bookmarkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookmarkIdMeta);
    }
    if (data.containsKey('folder_id')) {
      context.handle(
        _folderIdMeta,
        folderId.isAcceptableOrUnknown(data['folder_id']!, _folderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_folderIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {bookmarkId, folderId},
  ];
  @override
  BookmarkCollectionLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkCollectionLink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bookmarkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bookmark_id'],
      )!,
      folderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $BookmarkCollectionLinksTable createAlias(String alias) {
    return $BookmarkCollectionLinksTable(attachedDatabase, alias);
  }
}

class BookmarkCollectionLink extends DataClass
    implements Insertable<BookmarkCollectionLink> {
  final String id;
  final String bookmarkId;
  final String folderId;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const BookmarkCollectionLink({
    required this.id,
    required this.bookmarkId,
    required this.folderId,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bookmark_id'] = Variable<String>(bookmarkId);
    map['folder_id'] = Variable<String>(folderId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  BookmarkCollectionLinksCompanion toCompanion(bool nullToAbsent) {
    return BookmarkCollectionLinksCompanion(
      id: Value(id),
      bookmarkId: Value(bookmarkId),
      folderId: Value(folderId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory BookmarkCollectionLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkCollectionLink(
      id: serializer.fromJson<String>(json['id']),
      bookmarkId: serializer.fromJson<String>(json['bookmarkId']),
      folderId: serializer.fromJson<String>(json['folderId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookmarkId': serializer.toJson<String>(bookmarkId),
      'folderId': serializer.toJson<String>(folderId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  BookmarkCollectionLink copyWith({
    String? id,
    String? bookmarkId,
    String? folderId,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => BookmarkCollectionLink(
    id: id ?? this.id,
    bookmarkId: bookmarkId ?? this.bookmarkId,
    folderId: folderId ?? this.folderId,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  BookmarkCollectionLink copyWithCompanion(
    BookmarkCollectionLinksCompanion data,
  ) {
    return BookmarkCollectionLink(
      id: data.id.present ? data.id.value : this.id,
      bookmarkId: data.bookmarkId.present
          ? data.bookmarkId.value
          : this.bookmarkId,
      folderId: data.folderId.present ? data.folderId.value : this.folderId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkCollectionLink(')
          ..write('id: $id, ')
          ..write('bookmarkId: $bookmarkId, ')
          ..write('folderId: $folderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bookmarkId,
    folderId,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkCollectionLink &&
          other.id == this.id &&
          other.bookmarkId == this.bookmarkId &&
          other.folderId == this.folderId &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class BookmarkCollectionLinksCompanion
    extends UpdateCompanion<BookmarkCollectionLink> {
  final Value<String> id;
  final Value<String> bookmarkId;
  final Value<String> folderId;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const BookmarkCollectionLinksCompanion({
    this.id = const Value.absent(),
    this.bookmarkId = const Value.absent(),
    this.folderId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarkCollectionLinksCompanion.insert({
    required String id,
    required String bookmarkId,
    required String folderId,
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bookmarkId = Value(bookmarkId),
       folderId = Value(folderId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<BookmarkCollectionLink> custom({
    Expression<String>? id,
    Expression<String>? bookmarkId,
    Expression<String>? folderId,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookmarkId != null) 'bookmark_id': bookmarkId,
      if (folderId != null) 'folder_id': folderId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarkCollectionLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? bookmarkId,
    Value<String>? folderId,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return BookmarkCollectionLinksCompanion(
      id: id ?? this.id,
      bookmarkId: bookmarkId ?? this.bookmarkId,
      folderId: folderId ?? this.folderId,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (bookmarkId.present) {
      map['bookmark_id'] = Variable<String>(bookmarkId.value);
    }
    if (folderId.present) {
      map['folder_id'] = Variable<String>(folderId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
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
    return (StringBuffer('BookmarkCollectionLinksCompanion(')
          ..write('id: $id, ')
          ..write('bookmarkId: $bookmarkId, ')
          ..write('folderId: $folderId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrowserHistoryEntriesTable extends BrowserHistoryEntries
    with TableInfo<$BrowserHistoryEntriesTable, BrowserHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrowserHistoryEntriesTable(this.attachedDatabase, [this._alias]);
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
  );
  static const VerificationMeta _canonicalUrlMeta = const VerificationMeta(
    'canonicalUrl',
  );
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visitedAtMeta = const VerificationMeta(
    'visitedAt',
  );
  @override
  late final GeneratedColumn<DateTime> visitedAt = GeneratedColumn<DateTime>(
    'visited_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    canonicalUrl,
    title,
    description,
    visitedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'browser_history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrowserHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('canonical_url')) {
      context.handle(
        _canonicalUrlMeta,
        canonicalUrl.isAcceptableOrUnknown(
          data['canonical_url']!,
          _canonicalUrlMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('visited_at')) {
      context.handle(
        _visitedAtMeta,
        visitedAt.isAcceptableOrUnknown(data['visited_at']!, _visitedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_visitedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BrowserHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrowserHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      canonicalUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_url'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      visitedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}visited_at'],
      )!,
    );
  }

  @override
  $BrowserHistoryEntriesTable createAlias(String alias) {
    return $BrowserHistoryEntriesTable(attachedDatabase, alias);
  }
}

class BrowserHistoryEntry extends DataClass
    implements Insertable<BrowserHistoryEntry> {
  final String id;
  final String url;
  final String? canonicalUrl;
  final String? title;
  final String? description;
  final DateTime visitedAt;
  const BrowserHistoryEntry({
    required this.id,
    required this.url,
    this.canonicalUrl,
    this.title,
    this.description,
    required this.visitedAt,
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
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['visited_at'] = Variable<DateTime>(visitedAt);
    return map;
  }

  BrowserHistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return BrowserHistoryEntriesCompanion(
      id: Value(id),
      url: Value(url),
      canonicalUrl: canonicalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalUrl),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      visitedAt: Value(visitedAt),
    );
  }

  factory BrowserHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrowserHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      canonicalUrl: serializer.fromJson<String?>(json['canonicalUrl']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      visitedAt: serializer.fromJson<DateTime>(json['visitedAt']),
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
      'description': serializer.toJson<String?>(description),
      'visitedAt': serializer.toJson<DateTime>(visitedAt),
    };
  }

  BrowserHistoryEntry copyWith({
    String? id,
    String? url,
    Value<String?> canonicalUrl = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? visitedAt,
  }) => BrowserHistoryEntry(
    id: id ?? this.id,
    url: url ?? this.url,
    canonicalUrl: canonicalUrl.present ? canonicalUrl.value : this.canonicalUrl,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    visitedAt: visitedAt ?? this.visitedAt,
  );
  BrowserHistoryEntry copyWithCompanion(BrowserHistoryEntriesCompanion data) {
    return BrowserHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      canonicalUrl: data.canonicalUrl.present
          ? data.canonicalUrl.value
          : this.canonicalUrl,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      visitedAt: data.visitedAt.present ? data.visitedAt.value : this.visitedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrowserHistoryEntry(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('visitedAt: $visitedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, url, canonicalUrl, title, description, visitedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrowserHistoryEntry &&
          other.id == this.id &&
          other.url == this.url &&
          other.canonicalUrl == this.canonicalUrl &&
          other.title == this.title &&
          other.description == this.description &&
          other.visitedAt == this.visitedAt);
}

class BrowserHistoryEntriesCompanion
    extends UpdateCompanion<BrowserHistoryEntry> {
  final Value<String> id;
  final Value<String> url;
  final Value<String?> canonicalUrl;
  final Value<String?> title;
  final Value<String?> description;
  final Value<DateTime> visitedAt;
  final Value<int> rowid;
  const BrowserHistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.visitedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrowserHistoryEntriesCompanion.insert({
    required String id,
    required String url,
    this.canonicalUrl = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    required DateTime visitedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       visitedAt = Value(visitedAt);
  static Insertable<BrowserHistoryEntry> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? canonicalUrl,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? visitedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (canonicalUrl != null) 'canonical_url': canonicalUrl,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (visitedAt != null) 'visited_at': visitedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrowserHistoryEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String?>? canonicalUrl,
    Value<String?>? title,
    Value<String?>? description,
    Value<DateTime>? visitedAt,
    Value<int>? rowid,
  }) {
    return BrowserHistoryEntriesCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      visitedAt: visitedAt ?? this.visitedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (visitedAt.present) {
      map['visited_at'] = Variable<DateTime>(visitedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrowserHistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('canonicalUrl: $canonicalUrl, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('visitedAt: $visitedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AtprotoAccountsTable extends AtprotoAccounts
    with TableInfo<$AtprotoAccountsTable, AtprotoAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtprotoAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _didMeta = const VerificationMeta('did');
  @override
  late final GeneratedColumn<String> did = GeneratedColumn<String>(
    'did',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _handleMeta = const VerificationMeta('handle');
  @override
  late final GeneratedColumn<String> handle = GeneratedColumn<String>(
    'handle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdsEndpointMeta = const VerificationMeta(
    'pdsEndpoint',
  );
  @override
  late final GeneratedColumn<String> pdsEndpoint = GeneratedColumn<String>(
    'pds_endpoint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authMethodMeta = const VerificationMeta(
    'authMethod',
  );
  @override
  late final GeneratedColumn<String> authMethod = GeneratedColumn<String>(
    'auth_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    did,
    handle,
    pdsEndpoint,
    authMethod,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atproto_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtprotoAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('did')) {
      context.handle(
        _didMeta,
        did.isAcceptableOrUnknown(data['did']!, _didMeta),
      );
    } else if (isInserting) {
      context.missing(_didMeta);
    }
    if (data.containsKey('handle')) {
      context.handle(
        _handleMeta,
        handle.isAcceptableOrUnknown(data['handle']!, _handleMeta),
      );
    }
    if (data.containsKey('pds_endpoint')) {
      context.handle(
        _pdsEndpointMeta,
        pdsEndpoint.isAcceptableOrUnknown(
          data['pds_endpoint']!,
          _pdsEndpointMeta,
        ),
      );
    }
    if (data.containsKey('auth_method')) {
      context.handle(
        _authMethodMeta,
        authMethod.isAcceptableOrUnknown(data['auth_method']!, _authMethodMeta),
      );
    } else if (isInserting) {
      context.missing(_authMethodMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {did};
  @override
  AtprotoAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtprotoAccount(
      did: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}did'],
      )!,
      handle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}handle'],
      ),
      pdsEndpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pds_endpoint'],
      ),
      authMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_method'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AtprotoAccountsTable createAlias(String alias) {
    return $AtprotoAccountsTable(attachedDatabase, alias);
  }
}

class AtprotoAccount extends DataClass implements Insertable<AtprotoAccount> {
  final String did;
  final String? handle;
  final String? pdsEndpoint;
  final String authMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AtprotoAccount({
    required this.did,
    this.handle,
    this.pdsEndpoint,
    required this.authMethod,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['did'] = Variable<String>(did);
    if (!nullToAbsent || handle != null) {
      map['handle'] = Variable<String>(handle);
    }
    if (!nullToAbsent || pdsEndpoint != null) {
      map['pds_endpoint'] = Variable<String>(pdsEndpoint);
    }
    map['auth_method'] = Variable<String>(authMethod);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AtprotoAccountsCompanion toCompanion(bool nullToAbsent) {
    return AtprotoAccountsCompanion(
      did: Value(did),
      handle: handle == null && nullToAbsent
          ? const Value.absent()
          : Value(handle),
      pdsEndpoint: pdsEndpoint == null && nullToAbsent
          ? const Value.absent()
          : Value(pdsEndpoint),
      authMethod: Value(authMethod),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AtprotoAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtprotoAccount(
      did: serializer.fromJson<String>(json['did']),
      handle: serializer.fromJson<String?>(json['handle']),
      pdsEndpoint: serializer.fromJson<String?>(json['pdsEndpoint']),
      authMethod: serializer.fromJson<String>(json['authMethod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'did': serializer.toJson<String>(did),
      'handle': serializer.toJson<String?>(handle),
      'pdsEndpoint': serializer.toJson<String?>(pdsEndpoint),
      'authMethod': serializer.toJson<String>(authMethod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AtprotoAccount copyWith({
    String? did,
    Value<String?> handle = const Value.absent(),
    Value<String?> pdsEndpoint = const Value.absent(),
    String? authMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AtprotoAccount(
    did: did ?? this.did,
    handle: handle.present ? handle.value : this.handle,
    pdsEndpoint: pdsEndpoint.present ? pdsEndpoint.value : this.pdsEndpoint,
    authMethod: authMethod ?? this.authMethod,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AtprotoAccount copyWithCompanion(AtprotoAccountsCompanion data) {
    return AtprotoAccount(
      did: data.did.present ? data.did.value : this.did,
      handle: data.handle.present ? data.handle.value : this.handle,
      pdsEndpoint: data.pdsEndpoint.present
          ? data.pdsEndpoint.value
          : this.pdsEndpoint,
      authMethod: data.authMethod.present
          ? data.authMethod.value
          : this.authMethod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoAccount(')
          ..write('did: $did, ')
          ..write('handle: $handle, ')
          ..write('pdsEndpoint: $pdsEndpoint, ')
          ..write('authMethod: $authMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(did, handle, pdsEndpoint, authMethod, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtprotoAccount &&
          other.did == this.did &&
          other.handle == this.handle &&
          other.pdsEndpoint == this.pdsEndpoint &&
          other.authMethod == this.authMethod &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AtprotoAccountsCompanion extends UpdateCompanion<AtprotoAccount> {
  final Value<String> did;
  final Value<String?> handle;
  final Value<String?> pdsEndpoint;
  final Value<String> authMethod;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AtprotoAccountsCompanion({
    this.did = const Value.absent(),
    this.handle = const Value.absent(),
    this.pdsEndpoint = const Value.absent(),
    this.authMethod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtprotoAccountsCompanion.insert({
    required String did,
    this.handle = const Value.absent(),
    this.pdsEndpoint = const Value.absent(),
    required String authMethod,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : did = Value(did),
       authMethod = Value(authMethod),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AtprotoAccount> custom({
    Expression<String>? did,
    Expression<String>? handle,
    Expression<String>? pdsEndpoint,
    Expression<String>? authMethod,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (did != null) 'did': did,
      if (handle != null) 'handle': handle,
      if (pdsEndpoint != null) 'pds_endpoint': pdsEndpoint,
      if (authMethod != null) 'auth_method': authMethod,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtprotoAccountsCompanion copyWith({
    Value<String>? did,
    Value<String?>? handle,
    Value<String?>? pdsEndpoint,
    Value<String>? authMethod,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AtprotoAccountsCompanion(
      did: did ?? this.did,
      handle: handle ?? this.handle,
      pdsEndpoint: pdsEndpoint ?? this.pdsEndpoint,
      authMethod: authMethod ?? this.authMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (did.present) {
      map['did'] = Variable<String>(did.value);
    }
    if (handle.present) {
      map['handle'] = Variable<String>(handle.value);
    }
    if (pdsEndpoint.present) {
      map['pds_endpoint'] = Variable<String>(pdsEndpoint.value);
    }
    if (authMethod.present) {
      map['auth_method'] = Variable<String>(authMethod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoAccountsCompanion(')
          ..write('did: $did, ')
          ..write('handle: $handle, ')
          ..write('pdsEndpoint: $pdsEndpoint, ')
          ..write('authMethod: $authMethod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AtprotoRecordMirrorsTable extends AtprotoRecordMirrors
    with TableInfo<$AtprotoRecordMirrorsTable, AtprotoRecordMirror> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtprotoRecordMirrorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountDidMeta = const VerificationMeta(
    'accountDid',
  );
  @override
  late final GeneratedColumn<String> accountDid = GeneratedColumn<String>(
    'account_did',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES atproto_accounts (did)',
    ),
  );
  static const VerificationMeta _localTableMeta = const VerificationMeta(
    'localTable',
  );
  @override
  late final GeneratedColumn<String> localTable = GeneratedColumn<String>(
    'local_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rkeyMeta = const VerificationMeta('rkey');
  @override
  late final GeneratedColumn<String> rkey = GeneratedColumn<String>(
    'rkey',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _uriMeta = const VerificationMeta('uri');
  @override
  late final GeneratedColumn<String> uri = GeneratedColumn<String>(
    'uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cidMeta = const VerificationMeta('cid');
  @override
  late final GeneratedColumn<String> cid = GeneratedColumn<String>(
    'cid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedRecordJsonMeta =
      const VerificationMeta('lastSyncedRecordJson');
  @override
  late final GeneratedColumn<String> lastSyncedRecordJson =
      GeneratedColumn<String>(
        'last_synced_record_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncedHashMeta = const VerificationMeta(
    'lastSyncedHash',
  );
  @override
  late final GeneratedColumn<String> lastSyncedHash = GeneratedColumn<String>(
    'last_synced_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyAtMeta = const VerificationMeta(
    'dirtyAt',
  );
  @override
  late final GeneratedColumn<DateTime> dirtyAt = GeneratedColumn<DateTime>(
    'dirty_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountDid,
    localTable,
    localId,
    collection,
    rkey,
    uri,
    cid,
    lastSyncedRecordJson,
    lastSyncedHash,
    lastSyncedAt,
    dirtyAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atproto_record_mirrors';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtprotoRecordMirror> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_did')) {
      context.handle(
        _accountDidMeta,
        accountDid.isAcceptableOrUnknown(data['account_did']!, _accountDidMeta),
      );
    } else if (isInserting) {
      context.missing(_accountDidMeta);
    }
    if (data.containsKey('local_table')) {
      context.handle(
        _localTableMeta,
        localTable.isAcceptableOrUnknown(data['local_table']!, _localTableMeta),
      );
    } else if (isInserting) {
      context.missing(_localTableMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('rkey')) {
      context.handle(
        _rkeyMeta,
        rkey.isAcceptableOrUnknown(data['rkey']!, _rkeyMeta),
      );
    } else if (isInserting) {
      context.missing(_rkeyMeta);
    }
    if (data.containsKey('uri')) {
      context.handle(
        _uriMeta,
        uri.isAcceptableOrUnknown(data['uri']!, _uriMeta),
      );
    } else if (isInserting) {
      context.missing(_uriMeta);
    }
    if (data.containsKey('cid')) {
      context.handle(
        _cidMeta,
        cid.isAcceptableOrUnknown(data['cid']!, _cidMeta),
      );
    }
    if (data.containsKey('last_synced_record_json')) {
      context.handle(
        _lastSyncedRecordJsonMeta,
        lastSyncedRecordJson.isAcceptableOrUnknown(
          data['last_synced_record_json']!,
          _lastSyncedRecordJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_hash')) {
      context.handle(
        _lastSyncedHashMeta,
        lastSyncedHash.isAcceptableOrUnknown(
          data['last_synced_hash']!,
          _lastSyncedHashMeta,
        ),
      );
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('dirty_at')) {
      context.handle(
        _dirtyAtMeta,
        dirtyAt.isAcceptableOrUnknown(data['dirty_at']!, _dirtyAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountDid, localTable, localId, collection},
    {accountDid, uri},
  ];
  @override
  AtprotoRecordMirror map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtprotoRecordMirror(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountDid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_did'],
      )!,
      localTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_table'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      rkey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rkey'],
      )!,
      uri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uri'],
      )!,
      cid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cid'],
      ),
      lastSyncedRecordJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_synced_record_json'],
      ),
      lastSyncedHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_synced_hash'],
      ),
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      dirtyAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dirty_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $AtprotoRecordMirrorsTable createAlias(String alias) {
    return $AtprotoRecordMirrorsTable(attachedDatabase, alias);
  }
}

class AtprotoRecordMirror extends DataClass
    implements Insertable<AtprotoRecordMirror> {
  final String id;
  final String accountDid;
  final String localTable;
  final String localId;
  final String collection;
  final String rkey;
  final String uri;
  final String? cid;
  final String? lastSyncedRecordJson;
  final String? lastSyncedHash;
  final DateTime? lastSyncedAt;
  final DateTime? dirtyAt;
  final DateTime? deletedAt;
  const AtprotoRecordMirror({
    required this.id,
    required this.accountDid,
    required this.localTable,
    required this.localId,
    required this.collection,
    required this.rkey,
    required this.uri,
    this.cid,
    this.lastSyncedRecordJson,
    this.lastSyncedHash,
    this.lastSyncedAt,
    this.dirtyAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_did'] = Variable<String>(accountDid);
    map['local_table'] = Variable<String>(localTable);
    map['local_id'] = Variable<String>(localId);
    map['collection'] = Variable<String>(collection);
    map['rkey'] = Variable<String>(rkey);
    map['uri'] = Variable<String>(uri);
    if (!nullToAbsent || cid != null) {
      map['cid'] = Variable<String>(cid);
    }
    if (!nullToAbsent || lastSyncedRecordJson != null) {
      map['last_synced_record_json'] = Variable<String>(lastSyncedRecordJson);
    }
    if (!nullToAbsent || lastSyncedHash != null) {
      map['last_synced_hash'] = Variable<String>(lastSyncedHash);
    }
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || dirtyAt != null) {
      map['dirty_at'] = Variable<DateTime>(dirtyAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  AtprotoRecordMirrorsCompanion toCompanion(bool nullToAbsent) {
    return AtprotoRecordMirrorsCompanion(
      id: Value(id),
      accountDid: Value(accountDid),
      localTable: Value(localTable),
      localId: Value(localId),
      collection: Value(collection),
      rkey: Value(rkey),
      uri: Value(uri),
      cid: cid == null && nullToAbsent ? const Value.absent() : Value(cid),
      lastSyncedRecordJson: lastSyncedRecordJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedRecordJson),
      lastSyncedHash: lastSyncedHash == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedHash),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      dirtyAt: dirtyAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dirtyAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory AtprotoRecordMirror.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtprotoRecordMirror(
      id: serializer.fromJson<String>(json['id']),
      accountDid: serializer.fromJson<String>(json['accountDid']),
      localTable: serializer.fromJson<String>(json['localTable']),
      localId: serializer.fromJson<String>(json['localId']),
      collection: serializer.fromJson<String>(json['collection']),
      rkey: serializer.fromJson<String>(json['rkey']),
      uri: serializer.fromJson<String>(json['uri']),
      cid: serializer.fromJson<String?>(json['cid']),
      lastSyncedRecordJson: serializer.fromJson<String?>(
        json['lastSyncedRecordJson'],
      ),
      lastSyncedHash: serializer.fromJson<String?>(json['lastSyncedHash']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      dirtyAt: serializer.fromJson<DateTime?>(json['dirtyAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountDid': serializer.toJson<String>(accountDid),
      'localTable': serializer.toJson<String>(localTable),
      'localId': serializer.toJson<String>(localId),
      'collection': serializer.toJson<String>(collection),
      'rkey': serializer.toJson<String>(rkey),
      'uri': serializer.toJson<String>(uri),
      'cid': serializer.toJson<String?>(cid),
      'lastSyncedRecordJson': serializer.toJson<String?>(lastSyncedRecordJson),
      'lastSyncedHash': serializer.toJson<String?>(lastSyncedHash),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'dirtyAt': serializer.toJson<DateTime?>(dirtyAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  AtprotoRecordMirror copyWith({
    String? id,
    String? accountDid,
    String? localTable,
    String? localId,
    String? collection,
    String? rkey,
    String? uri,
    Value<String?> cid = const Value.absent(),
    Value<String?> lastSyncedRecordJson = const Value.absent(),
    Value<String?> lastSyncedHash = const Value.absent(),
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<DateTime?> dirtyAt = const Value.absent(),
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => AtprotoRecordMirror(
    id: id ?? this.id,
    accountDid: accountDid ?? this.accountDid,
    localTable: localTable ?? this.localTable,
    localId: localId ?? this.localId,
    collection: collection ?? this.collection,
    rkey: rkey ?? this.rkey,
    uri: uri ?? this.uri,
    cid: cid.present ? cid.value : this.cid,
    lastSyncedRecordJson: lastSyncedRecordJson.present
        ? lastSyncedRecordJson.value
        : this.lastSyncedRecordJson,
    lastSyncedHash: lastSyncedHash.present
        ? lastSyncedHash.value
        : this.lastSyncedHash,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    dirtyAt: dirtyAt.present ? dirtyAt.value : this.dirtyAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  AtprotoRecordMirror copyWithCompanion(AtprotoRecordMirrorsCompanion data) {
    return AtprotoRecordMirror(
      id: data.id.present ? data.id.value : this.id,
      accountDid: data.accountDid.present
          ? data.accountDid.value
          : this.accountDid,
      localTable: data.localTable.present
          ? data.localTable.value
          : this.localTable,
      localId: data.localId.present ? data.localId.value : this.localId,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      rkey: data.rkey.present ? data.rkey.value : this.rkey,
      uri: data.uri.present ? data.uri.value : this.uri,
      cid: data.cid.present ? data.cid.value : this.cid,
      lastSyncedRecordJson: data.lastSyncedRecordJson.present
          ? data.lastSyncedRecordJson.value
          : this.lastSyncedRecordJson,
      lastSyncedHash: data.lastSyncedHash.present
          ? data.lastSyncedHash.value
          : this.lastSyncedHash,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      dirtyAt: data.dirtyAt.present ? data.dirtyAt.value : this.dirtyAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoRecordMirror(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('localTable: $localTable, ')
          ..write('localId: $localId, ')
          ..write('collection: $collection, ')
          ..write('rkey: $rkey, ')
          ..write('uri: $uri, ')
          ..write('cid: $cid, ')
          ..write('lastSyncedRecordJson: $lastSyncedRecordJson, ')
          ..write('lastSyncedHash: $lastSyncedHash, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('dirtyAt: $dirtyAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountDid,
    localTable,
    localId,
    collection,
    rkey,
    uri,
    cid,
    lastSyncedRecordJson,
    lastSyncedHash,
    lastSyncedAt,
    dirtyAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtprotoRecordMirror &&
          other.id == this.id &&
          other.accountDid == this.accountDid &&
          other.localTable == this.localTable &&
          other.localId == this.localId &&
          other.collection == this.collection &&
          other.rkey == this.rkey &&
          other.uri == this.uri &&
          other.cid == this.cid &&
          other.lastSyncedRecordJson == this.lastSyncedRecordJson &&
          other.lastSyncedHash == this.lastSyncedHash &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.dirtyAt == this.dirtyAt &&
          other.deletedAt == this.deletedAt);
}

class AtprotoRecordMirrorsCompanion
    extends UpdateCompanion<AtprotoRecordMirror> {
  final Value<String> id;
  final Value<String> accountDid;
  final Value<String> localTable;
  final Value<String> localId;
  final Value<String> collection;
  final Value<String> rkey;
  final Value<String> uri;
  final Value<String?> cid;
  final Value<String?> lastSyncedRecordJson;
  final Value<String?> lastSyncedHash;
  final Value<DateTime?> lastSyncedAt;
  final Value<DateTime?> dirtyAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const AtprotoRecordMirrorsCompanion({
    this.id = const Value.absent(),
    this.accountDid = const Value.absent(),
    this.localTable = const Value.absent(),
    this.localId = const Value.absent(),
    this.collection = const Value.absent(),
    this.rkey = const Value.absent(),
    this.uri = const Value.absent(),
    this.cid = const Value.absent(),
    this.lastSyncedRecordJson = const Value.absent(),
    this.lastSyncedHash = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.dirtyAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtprotoRecordMirrorsCompanion.insert({
    required String id,
    required String accountDid,
    required String localTable,
    required String localId,
    required String collection,
    required String rkey,
    required String uri,
    this.cid = const Value.absent(),
    this.lastSyncedRecordJson = const Value.absent(),
    this.lastSyncedHash = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.dirtyAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountDid = Value(accountDid),
       localTable = Value(localTable),
       localId = Value(localId),
       collection = Value(collection),
       rkey = Value(rkey),
       uri = Value(uri);
  static Insertable<AtprotoRecordMirror> custom({
    Expression<String>? id,
    Expression<String>? accountDid,
    Expression<String>? localTable,
    Expression<String>? localId,
    Expression<String>? collection,
    Expression<String>? rkey,
    Expression<String>? uri,
    Expression<String>? cid,
    Expression<String>? lastSyncedRecordJson,
    Expression<String>? lastSyncedHash,
    Expression<DateTime>? lastSyncedAt,
    Expression<DateTime>? dirtyAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountDid != null) 'account_did': accountDid,
      if (localTable != null) 'local_table': localTable,
      if (localId != null) 'local_id': localId,
      if (collection != null) 'collection': collection,
      if (rkey != null) 'rkey': rkey,
      if (uri != null) 'uri': uri,
      if (cid != null) 'cid': cid,
      if (lastSyncedRecordJson != null)
        'last_synced_record_json': lastSyncedRecordJson,
      if (lastSyncedHash != null) 'last_synced_hash': lastSyncedHash,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (dirtyAt != null) 'dirty_at': dirtyAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtprotoRecordMirrorsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountDid,
    Value<String>? localTable,
    Value<String>? localId,
    Value<String>? collection,
    Value<String>? rkey,
    Value<String>? uri,
    Value<String?>? cid,
    Value<String?>? lastSyncedRecordJson,
    Value<String?>? lastSyncedHash,
    Value<DateTime?>? lastSyncedAt,
    Value<DateTime?>? dirtyAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return AtprotoRecordMirrorsCompanion(
      id: id ?? this.id,
      accountDid: accountDid ?? this.accountDid,
      localTable: localTable ?? this.localTable,
      localId: localId ?? this.localId,
      collection: collection ?? this.collection,
      rkey: rkey ?? this.rkey,
      uri: uri ?? this.uri,
      cid: cid ?? this.cid,
      lastSyncedRecordJson: lastSyncedRecordJson ?? this.lastSyncedRecordJson,
      lastSyncedHash: lastSyncedHash ?? this.lastSyncedHash,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      dirtyAt: dirtyAt ?? this.dirtyAt,
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
    if (accountDid.present) {
      map['account_did'] = Variable<String>(accountDid.value);
    }
    if (localTable.present) {
      map['local_table'] = Variable<String>(localTable.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (rkey.present) {
      map['rkey'] = Variable<String>(rkey.value);
    }
    if (uri.present) {
      map['uri'] = Variable<String>(uri.value);
    }
    if (cid.present) {
      map['cid'] = Variable<String>(cid.value);
    }
    if (lastSyncedRecordJson.present) {
      map['last_synced_record_json'] = Variable<String>(
        lastSyncedRecordJson.value,
      );
    }
    if (lastSyncedHash.present) {
      map['last_synced_hash'] = Variable<String>(lastSyncedHash.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (dirtyAt.present) {
      map['dirty_at'] = Variable<DateTime>(dirtyAt.value);
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
    return (StringBuffer('AtprotoRecordMirrorsCompanion(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('localTable: $localTable, ')
          ..write('localId: $localId, ')
          ..write('collection: $collection, ')
          ..write('rkey: $rkey, ')
          ..write('uri: $uri, ')
          ..write('cid: $cid, ')
          ..write('lastSyncedRecordJson: $lastSyncedRecordJson, ')
          ..write('lastSyncedHash: $lastSyncedHash, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('dirtyAt: $dirtyAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AtprotoSyncStateTable extends AtprotoSyncState
    with TableInfo<$AtprotoSyncStateTable, AtprotoSyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtprotoSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountDidMeta = const VerificationMeta(
    'accountDid',
  );
  @override
  late final GeneratedColumn<String> accountDid = GeneratedColumn<String>(
    'account_did',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES atproto_accounts (did)',
    ),
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessfulSyncAtMeta =
      const VerificationMeta('lastSuccessfulSyncAt');
  @override
  late final GeneratedColumn<DateTime> lastSuccessfulSyncAt =
      GeneratedColumn<DateTime>(
        'last_successful_sync_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountDid,
    collection,
    cursor,
    lastSuccessfulSyncAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atproto_sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtprotoSyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_did')) {
      context.handle(
        _accountDidMeta,
        accountDid.isAcceptableOrUnknown(data['account_did']!, _accountDidMeta),
      );
    } else if (isInserting) {
      context.missing(_accountDidMeta);
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_successful_sync_at')) {
      context.handle(
        _lastSuccessfulSyncAtMeta,
        lastSuccessfulSyncAt.isAcceptableOrUnknown(
          data['last_successful_sync_at']!,
          _lastSuccessfulSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountDid, collection},
  ];
  @override
  AtprotoSyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtprotoSyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountDid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_did'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastSuccessfulSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_successful_sync_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $AtprotoSyncStateTable createAlias(String alias) {
    return $AtprotoSyncStateTable(attachedDatabase, alias);
  }
}

class AtprotoSyncStateData extends DataClass
    implements Insertable<AtprotoSyncStateData> {
  final String id;
  final String accountDid;
  final String collection;
  final String? cursor;
  final DateTime? lastSuccessfulSyncAt;
  final String? lastError;
  const AtprotoSyncStateData({
    required this.id,
    required this.accountDid,
    required this.collection,
    this.cursor,
    this.lastSuccessfulSyncAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_did'] = Variable<String>(accountDid);
    map['collection'] = Variable<String>(collection);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastSuccessfulSyncAt != null) {
      map['last_successful_sync_at'] = Variable<DateTime>(lastSuccessfulSyncAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  AtprotoSyncStateCompanion toCompanion(bool nullToAbsent) {
    return AtprotoSyncStateCompanion(
      id: Value(id),
      accountDid: Value(accountDid),
      collection: Value(collection),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastSuccessfulSyncAt: lastSuccessfulSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessfulSyncAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory AtprotoSyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtprotoSyncStateData(
      id: serializer.fromJson<String>(json['id']),
      accountDid: serializer.fromJson<String>(json['accountDid']),
      collection: serializer.fromJson<String>(json['collection']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastSuccessfulSyncAt: serializer.fromJson<DateTime?>(
        json['lastSuccessfulSyncAt'],
      ),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountDid': serializer.toJson<String>(accountDid),
      'collection': serializer.toJson<String>(collection),
      'cursor': serializer.toJson<String?>(cursor),
      'lastSuccessfulSyncAt': serializer.toJson<DateTime?>(
        lastSuccessfulSyncAt,
      ),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  AtprotoSyncStateData copyWith({
    String? id,
    String? accountDid,
    String? collection,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => AtprotoSyncStateData(
    id: id ?? this.id,
    accountDid: accountDid ?? this.accountDid,
    collection: collection ?? this.collection,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt.present
        ? lastSuccessfulSyncAt.value
        : this.lastSuccessfulSyncAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  AtprotoSyncStateData copyWithCompanion(AtprotoSyncStateCompanion data) {
    return AtprotoSyncStateData(
      id: data.id.present ? data.id.value : this.id,
      accountDid: data.accountDid.present
          ? data.accountDid.value
          : this.accountDid,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSuccessfulSyncAt: data.lastSuccessfulSyncAt.present
          ? data.lastSuccessfulSyncAt.value
          : this.lastSuccessfulSyncAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoSyncStateData(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('collection: $collection, ')
          ..write('cursor: $cursor, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountDid,
    collection,
    cursor,
    lastSuccessfulSyncAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtprotoSyncStateData &&
          other.id == this.id &&
          other.accountDid == this.accountDid &&
          other.collection == this.collection &&
          other.cursor == this.cursor &&
          other.lastSuccessfulSyncAt == this.lastSuccessfulSyncAt &&
          other.lastError == this.lastError);
}

class AtprotoSyncStateCompanion extends UpdateCompanion<AtprotoSyncStateData> {
  final Value<String> id;
  final Value<String> accountDid;
  final Value<String> collection;
  final Value<String?> cursor;
  final Value<DateTime?> lastSuccessfulSyncAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const AtprotoSyncStateCompanion({
    this.id = const Value.absent(),
    this.accountDid = const Value.absent(),
    this.collection = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtprotoSyncStateCompanion.insert({
    required String id,
    required String accountDid,
    required String collection,
    this.cursor = const Value.absent(),
    this.lastSuccessfulSyncAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountDid = Value(accountDid),
       collection = Value(collection);
  static Insertable<AtprotoSyncStateData> custom({
    Expression<String>? id,
    Expression<String>? accountDid,
    Expression<String>? collection,
    Expression<String>? cursor,
    Expression<DateTime>? lastSuccessfulSyncAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountDid != null) 'account_did': accountDid,
      if (collection != null) 'collection': collection,
      if (cursor != null) 'cursor': cursor,
      if (lastSuccessfulSyncAt != null)
        'last_successful_sync_at': lastSuccessfulSyncAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtprotoSyncStateCompanion copyWith({
    Value<String>? id,
    Value<String>? accountDid,
    Value<String>? collection,
    Value<String?>? cursor,
    Value<DateTime?>? lastSuccessfulSyncAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return AtprotoSyncStateCompanion(
      id: id ?? this.id,
      accountDid: accountDid ?? this.accountDid,
      collection: collection ?? this.collection,
      cursor: cursor ?? this.cursor,
      lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountDid.present) {
      map['account_did'] = Variable<String>(accountDid.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastSuccessfulSyncAt.present) {
      map['last_successful_sync_at'] = Variable<DateTime>(
        lastSuccessfulSyncAt.value,
      );
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoSyncStateCompanion(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('collection: $collection, ')
          ..write('cursor: $cursor, ')
          ..write('lastSuccessfulSyncAt: $lastSuccessfulSyncAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AtprotoSyncOutboxTable extends AtprotoSyncOutbox
    with TableInfo<$AtprotoSyncOutboxTable, AtprotoSyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AtprotoSyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountDidMeta = const VerificationMeta(
    'accountDid',
  );
  @override
  late final GeneratedColumn<String> accountDid = GeneratedColumn<String>(
    'account_did',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES atproto_accounts (did)',
    ),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localTableMeta = const VerificationMeta(
    'localTable',
  );
  @override
  late final GeneratedColumn<String> localTable = GeneratedColumn<String>(
    'local_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectionMeta = const VerificationMeta(
    'collection',
  );
  @override
  late final GeneratedColumn<String> collection = GeneratedColumn<String>(
    'collection',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountDid,
    operation,
    localTable,
    localId,
    collection,
    payloadJson,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'atproto_sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<AtprotoSyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_did')) {
      context.handle(
        _accountDidMeta,
        accountDid.isAcceptableOrUnknown(data['account_did']!, _accountDidMeta),
      );
    } else if (isInserting) {
      context.missing(_accountDidMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('local_table')) {
      context.handle(
        _localTableMeta,
        localTable.isAcceptableOrUnknown(data['local_table']!, _localTableMeta),
      );
    } else if (isInserting) {
      context.missing(_localTableMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('collection')) {
      context.handle(
        _collectionMeta,
        collection.isAcceptableOrUnknown(data['collection']!, _collectionMeta),
      );
    } else if (isInserting) {
      context.missing(_collectionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AtprotoSyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AtprotoSyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountDid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_did'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      localTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_table'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      collection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AtprotoSyncOutboxTable createAlias(String alias) {
    return $AtprotoSyncOutboxTable(attachedDatabase, alias);
  }
}

class AtprotoSyncOutboxData extends DataClass
    implements Insertable<AtprotoSyncOutboxData> {
  final String id;
  final String accountDid;
  final String operation;
  final String localTable;
  final String localId;
  final String collection;
  final String? payloadJson;
  final int attemptCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AtprotoSyncOutboxData({
    required this.id,
    required this.accountDid,
    required this.operation,
    required this.localTable,
    required this.localId,
    required this.collection,
    this.payloadJson,
    required this.attemptCount,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_did'] = Variable<String>(accountDid);
    map['operation'] = Variable<String>(operation);
    map['local_table'] = Variable<String>(localTable);
    map['local_id'] = Variable<String>(localId);
    map['collection'] = Variable<String>(collection);
    if (!nullToAbsent || payloadJson != null) {
      map['payload_json'] = Variable<String>(payloadJson);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AtprotoSyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return AtprotoSyncOutboxCompanion(
      id: Value(id),
      accountDid: Value(accountDid),
      operation: Value(operation),
      localTable: Value(localTable),
      localId: Value(localId),
      collection: Value(collection),
      payloadJson: payloadJson == null && nullToAbsent
          ? const Value.absent()
          : Value(payloadJson),
      attemptCount: Value(attemptCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AtprotoSyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtprotoSyncOutboxData(
      id: serializer.fromJson<String>(json['id']),
      accountDid: serializer.fromJson<String>(json['accountDid']),
      operation: serializer.fromJson<String>(json['operation']),
      localTable: serializer.fromJson<String>(json['localTable']),
      localId: serializer.fromJson<String>(json['localId']),
      collection: serializer.fromJson<String>(json['collection']),
      payloadJson: serializer.fromJson<String?>(json['payloadJson']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountDid': serializer.toJson<String>(accountDid),
      'operation': serializer.toJson<String>(operation),
      'localTable': serializer.toJson<String>(localTable),
      'localId': serializer.toJson<String>(localId),
      'collection': serializer.toJson<String>(collection),
      'payloadJson': serializer.toJson<String?>(payloadJson),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AtprotoSyncOutboxData copyWith({
    String? id,
    String? accountDid,
    String? operation,
    String? localTable,
    String? localId,
    String? collection,
    Value<String?> payloadJson = const Value.absent(),
    int? attemptCount,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AtprotoSyncOutboxData(
    id: id ?? this.id,
    accountDid: accountDid ?? this.accountDid,
    operation: operation ?? this.operation,
    localTable: localTable ?? this.localTable,
    localId: localId ?? this.localId,
    collection: collection ?? this.collection,
    payloadJson: payloadJson.present ? payloadJson.value : this.payloadJson,
    attemptCount: attemptCount ?? this.attemptCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AtprotoSyncOutboxData copyWithCompanion(AtprotoSyncOutboxCompanion data) {
    return AtprotoSyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      accountDid: data.accountDid.present
          ? data.accountDid.value
          : this.accountDid,
      operation: data.operation.present ? data.operation.value : this.operation,
      localTable: data.localTable.present
          ? data.localTable.value
          : this.localTable,
      localId: data.localId.present ? data.localId.value : this.localId,
      collection: data.collection.present
          ? data.collection.value
          : this.collection,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoSyncOutboxData(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('operation: $operation, ')
          ..write('localTable: $localTable, ')
          ..write('localId: $localId, ')
          ..write('collection: $collection, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountDid,
    operation,
    localTable,
    localId,
    collection,
    payloadJson,
    attemptCount,
    lastError,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtprotoSyncOutboxData &&
          other.id == this.id &&
          other.accountDid == this.accountDid &&
          other.operation == this.operation &&
          other.localTable == this.localTable &&
          other.localId == this.localId &&
          other.collection == this.collection &&
          other.payloadJson == this.payloadJson &&
          other.attemptCount == this.attemptCount &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AtprotoSyncOutboxCompanion
    extends UpdateCompanion<AtprotoSyncOutboxData> {
  final Value<String> id;
  final Value<String> accountDid;
  final Value<String> operation;
  final Value<String> localTable;
  final Value<String> localId;
  final Value<String> collection;
  final Value<String?> payloadJson;
  final Value<int> attemptCount;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AtprotoSyncOutboxCompanion({
    this.id = const Value.absent(),
    this.accountDid = const Value.absent(),
    this.operation = const Value.absent(),
    this.localTable = const Value.absent(),
    this.localId = const Value.absent(),
    this.collection = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AtprotoSyncOutboxCompanion.insert({
    required String id,
    required String accountDid,
    required String operation,
    required String localTable,
    required String localId,
    required String collection,
    this.payloadJson = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountDid = Value(accountDid),
       operation = Value(operation),
       localTable = Value(localTable),
       localId = Value(localId),
       collection = Value(collection),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AtprotoSyncOutboxData> custom({
    Expression<String>? id,
    Expression<String>? accountDid,
    Expression<String>? operation,
    Expression<String>? localTable,
    Expression<String>? localId,
    Expression<String>? collection,
    Expression<String>? payloadJson,
    Expression<int>? attemptCount,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountDid != null) 'account_did': accountDid,
      if (operation != null) 'operation': operation,
      if (localTable != null) 'local_table': localTable,
      if (localId != null) 'local_id': localId,
      if (collection != null) 'collection': collection,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AtprotoSyncOutboxCompanion copyWith({
    Value<String>? id,
    Value<String>? accountDid,
    Value<String>? operation,
    Value<String>? localTable,
    Value<String>? localId,
    Value<String>? collection,
    Value<String?>? payloadJson,
    Value<int>? attemptCount,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AtprotoSyncOutboxCompanion(
      id: id ?? this.id,
      accountDid: accountDid ?? this.accountDid,
      operation: operation ?? this.operation,
      localTable: localTable ?? this.localTable,
      localId: localId ?? this.localId,
      collection: collection ?? this.collection,
      payloadJson: payloadJson ?? this.payloadJson,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountDid.present) {
      map['account_did'] = Variable<String>(accountDid.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (localTable.present) {
      map['local_table'] = Variable<String>(localTable.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (collection.present) {
      map['collection'] = Variable<String>(collection.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AtprotoSyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('accountDid: $accountDid, ')
          ..write('operation: $operation, ')
          ..write('localTable: $localTable, ')
          ..write('localId: $localId, ')
          ..write('collection: $collection, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const AppSetting({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppSetting copyWith({String? key, String? value, DateTime? updatedAt}) =>
      AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
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
  late final $AnnotationTargetsTable annotationTargets =
      $AnnotationTargetsTable(this);
  late final $AnnotationBodiesTable annotationBodies = $AnnotationBodiesTable(
    this,
  );
  late final $BookmarkFoldersTable bookmarkFolders = $BookmarkFoldersTable(
    this,
  );
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $BookmarkCollectionLinksTable bookmarkCollectionLinks =
      $BookmarkCollectionLinksTable(this);
  late final $BrowserHistoryEntriesTable browserHistoryEntries =
      $BrowserHistoryEntriesTable(this);
  late final $AtprotoAccountsTable atprotoAccounts = $AtprotoAccountsTable(
    this,
  );
  late final $AtprotoRecordMirrorsTable atprotoRecordMirrors =
      $AtprotoRecordMirrorsTable(this);
  late final $AtprotoSyncStateTable atprotoSyncState = $AtprotoSyncStateTable(
    this,
  );
  late final $AtprotoSyncOutboxTable atprotoSyncOutbox =
      $AtprotoSyncOutboxTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pages,
    annotations,
    annotationTargets,
    annotationBodies,
    bookmarkFolders,
    bookmarks,
    bookmarkCollectionLinks,
    browserHistoryEntries,
    atprotoAccounts,
    atprotoRecordMirrors,
    atprotoSyncState,
    atprotoSyncOutbox,
    appSettings,
  ];
}

typedef $$PagesTableCreateCompanionBuilder =
    PagesCompanion Function({
      required String id,
      required String url,
      Value<String?> canonicalUrl,
      Value<String?> title,
      Value<String?> description,
      Value<String?> faviconUrl,
      Value<String?> faviconFilePath,
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
      Value<String?> description,
      Value<String?> faviconUrl,
      Value<String?> faviconFilePath,
      Value<DateTime> createdAt,
      Value<DateTime> lastVisitedAt,
      Value<int> rowid,
    });

final class $$PagesTableReferences
    extends BaseReferences<_$AppDatabase, $PagesTable, Page> {
  $$PagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnnotationsTable, List<Annotation>>
  _annotationsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotations,
    aliasName: $_aliasNameGenerator(db.pages.id, db.annotations.pageId),
  );

  $$AnnotationsTableProcessedTableManager get annotationsRefs {
    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_annotationsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get faviconFilePath => $composableBuilder(
    column: $table.faviconFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVisitedAt => $composableBuilder(
    column: $table.lastVisitedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> annotationsRefs(
    Expression<bool> Function($$AnnotationsTableFilterComposer f) f,
  ) {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get faviconFilePath => $composableBuilder(
    column: $table.faviconFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVisitedAt => $composableBuilder(
    column: $table.lastVisitedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faviconUrl => $composableBuilder(
    column: $table.faviconUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get faviconFilePath => $composableBuilder(
    column: $table.faviconFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastVisitedAt => $composableBuilder(
    column: $table.lastVisitedAt,
    builder: (column) => column,
  );

  Expression<T> annotationsRefs<T extends Object>(
    Expression<T> Function($$AnnotationsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> canonicalUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> faviconUrl = const Value.absent(),
                Value<String?> faviconFilePath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> lastVisitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                description: description,
                faviconUrl: faviconUrl,
                faviconFilePath: faviconFilePath,
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
                Value<String?> description = const Value.absent(),
                Value<String?> faviconUrl = const Value.absent(),
                Value<String?> faviconFilePath = const Value.absent(),
                required DateTime createdAt,
                required DateTime lastVisitedAt,
                Value<int> rowid = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                description: description,
                faviconUrl: faviconUrl,
                faviconFilePath: faviconFilePath,
                createdAt: createdAt,
                lastVisitedAt: lastVisitedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PagesTableReferences(db, table, e)),
              )
              .toList(),
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
                      referencedTable: $$PagesTableReferences
                          ._annotationsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PagesTableReferences(db, table, p0).annotationsRefs,
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

final class $$AnnotationsTableReferences
    extends BaseReferences<_$AppDatabase, $AnnotationsTable, Annotation> {
  $$AnnotationsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PagesTable _pageIdTable(_$AppDatabase db) => db.pages.createAlias(
    $_aliasNameGenerator(db.annotations.pageId, db.pages.id),
  );

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<String>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AnnotationTargetsTable, List<AnnotationTarget>>
  _annotationTargetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.annotationTargets,
        aliasName: $_aliasNameGenerator(
          db.annotations.id,
          db.annotationTargets.annotationId,
        ),
      );

  $$AnnotationTargetsTableProcessedTableManager get annotationTargetsRefs {
    final manager = $$AnnotationTargetsTableTableManager(
      $_db,
      $_db.annotationTargets,
    ).filter((f) => f.annotationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _annotationTargetsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AnnotationBodiesTable, List<AnnotationBody>>
  _annotationBodiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.annotationBodies,
    aliasName: $_aliasNameGenerator(
      db.annotations.id,
      db.annotationBodies.annotationId,
    ),
  );

  $$AnnotationBodiesTableProcessedTableManager get annotationBodiesRefs {
    final manager = $$AnnotationBodiesTableTableManager(
      $_db,
      $_db.annotationBodies,
    ).filter((f) => f.annotationId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _annotationBodiesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> annotationTargetsRefs(
    Expression<bool> Function($$AnnotationTargetsTableFilterComposer f) f,
  ) {
    final $$AnnotationTargetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationTargets,
      getReferencedColumn: (t) => t.annotationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationTargetsTableFilterComposer(
            $db: $db,
            $table: $db.annotationTargets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> annotationBodiesRefs(
    Expression<bool> Function($$AnnotationBodiesTableFilterComposer f) f,
  ) {
    final $$AnnotationBodiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.annotationBodies,
      getReferencedColumn: (t) => t.annotationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationBodiesTableFilterComposer(
            $db: $db,
            $table: $db.annotationBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationsTable> {
  $$AnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get motivation => $composableBuilder(
    column: $table.motivation,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> annotationTargetsRefs<T extends Object>(
    Expression<T> Function($$AnnotationTargetsTableAnnotationComposer a) f,
  ) {
    final $$AnnotationTargetsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.annotationTargets,
          getReferencedColumn: (t) => t.annotationId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AnnotationTargetsTableAnnotationComposer(
                $db: $db,
                $table: $db.annotationTargets,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
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
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationBodiesTableAnnotationComposer(
            $db: $db,
            $table: $db.annotationBodies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
          PrefetchHooks Function({
            bool pageId,
            bool annotationTargetsRefs,
            bool annotationBodiesRefs,
          })
        > {
  $$AnnotationsTableTableManager(_$AppDatabase db, $AnnotationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationsTableAnnotationComposer($db: db, $table: table),
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
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                pageId = false,
                annotationTargetsRefs = false,
                annotationBodiesRefs = false,
              }) {
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
                                    referencedTable:
                                        $$AnnotationsTableReferences
                                            ._pageIdTable(db),
                                    referencedColumn:
                                        $$AnnotationsTableReferences
                                            ._pageIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (annotationTargetsRefs)
                        await $_getPrefetchedData<
                          Annotation,
                          $AnnotationsTable,
                          AnnotationTarget
                        >(
                          currentTable: table,
                          referencedTable: $$AnnotationsTableReferences
                              ._annotationTargetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnnotationsTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationTargetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.annotationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (annotationBodiesRefs)
                        await $_getPrefetchedData<
                          Annotation,
                          $AnnotationsTable,
                          AnnotationBody
                        >(
                          currentTable: table,
                          referencedTable: $$AnnotationsTableReferences
                              ._annotationBodiesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AnnotationsTableReferences(
                                db,
                                table,
                                p0,
                              ).annotationBodiesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.annotationId == item.id,
                              ),
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
      PrefetchHooks Function({
        bool pageId,
        bool annotationTargetsRefs,
        bool annotationBodiesRefs,
      })
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
    extends
        BaseReferences<
          _$AppDatabase,
          $AnnotationTargetsTable,
          AnnotationTarget
        > {
  $$AnnotationTargetsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnnotationsTable _annotationIdTable(_$AppDatabase db) =>
      db.annotations.createAlias(
        $_aliasNameGenerator(
          db.annotationTargets.annotationId,
          db.annotations.id,
        ),
      );

  $$AnnotationsTableProcessedTableManager get annotationId {
    final $_column = $_itemColumn<String>('annotation_id')!;

    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_annotationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationTargetsTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectorJson => $composableBuilder(
    column: $table.selectorJson,
    builder: (column) => ColumnFilters(column),
  );

  $$AnnotationsTableFilterComposer get annotationId {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationTargetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUrl => $composableBuilder(
    column: $table.sourceUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectorJson => $composableBuilder(
    column: $table.selectorJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnnotationsTableOrderingComposer get annotationId {
    final $$AnnotationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableOrderingComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationTargetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationTargetsTable> {
  $$AnnotationTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceUrl =>
      $composableBuilder(column: $table.sourceUrl, builder: (column) => column);

  GeneratedColumn<String> get selectorJson => $composableBuilder(
    column: $table.selectorJson,
    builder: (column) => column,
  );

  $$AnnotationsTableAnnotationComposer get annotationId {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
  $$AnnotationTargetsTableTableManager(
    _$AppDatabase db,
    $AnnotationTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationTargetsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
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
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationTargetsTableReferences(db, table, e),
                ),
              )
              .toList(),
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
                                referencedTable:
                                    $$AnnotationTargetsTableReferences
                                        ._annotationIdTable(db),
                                referencedColumn:
                                    $$AnnotationTargetsTableReferences
                                        ._annotationIdTable(db)
                                        .id,
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
    extends
        BaseReferences<_$AppDatabase, $AnnotationBodiesTable, AnnotationBody> {
  $$AnnotationBodiesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AnnotationsTable _annotationIdTable(_$AppDatabase db) =>
      db.annotations.createAlias(
        $_aliasNameGenerator(
          db.annotationBodies.annotationId,
          db.annotations.id,
        ),
      );

  $$AnnotationsTableProcessedTableManager get annotationId {
    final $_column = $_itemColumn<String>('annotation_id')!;

    final manager = $$AnnotationsTableTableManager(
      $_db,
      $_db.annotations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_annotationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AnnotationBodiesTableFilterComposer
    extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$AnnotationsTableFilterComposer get annotationId {
    final $$AnnotationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableFilterComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationBodiesTableOrderingComposer
    extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$AnnotationsTableOrderingComposer get annotationId {
    final $$AnnotationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableOrderingComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AnnotationBodiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnnotationBodiesTable> {
  $$AnnotationBodiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$AnnotationsTableAnnotationComposer get annotationId {
    final $$AnnotationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.annotationId,
      referencedTable: $db.annotations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AnnotationsTableAnnotationComposer(
            $db: $db,
            $table: $db.annotations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
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
  $$AnnotationBodiesTableTableManager(
    _$AppDatabase db,
    $AnnotationBodiesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnotationBodiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnotationBodiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnotationBodiesTableAnnotationComposer($db: db, $table: table),
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
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AnnotationBodiesTableReferences(db, table, e),
                ),
              )
              .toList(),
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
                                referencedTable:
                                    $$AnnotationBodiesTableReferences
                                        ._annotationIdTable(db),
                                referencedColumn:
                                    $$AnnotationBodiesTableReferences
                                        ._annotationIdTable(db)
                                        .id,
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
typedef $$BookmarkFoldersTableCreateCompanionBuilder =
    BookmarkFoldersCompanion Function({
      required String id,
      Value<String?> parentId,
      required String title,
      Value<String?> description,
      Value<String> accessType,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$BookmarkFoldersTableUpdateCompanionBuilder =
    BookmarkFoldersCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> title,
      Value<String?> description,
      Value<String> accessType,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$BookmarkFoldersTableReferences
    extends
        BaseReferences<_$AppDatabase, $BookmarkFoldersTable, BookmarkFolder> {
  $$BookmarkFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BookmarkFoldersTable _parentIdTable(_$AppDatabase db) =>
      db.bookmarkFolders.createAlias(
        $_aliasNameGenerator(
          db.bookmarkFolders.parentId,
          db.bookmarkFolders.id,
        ),
      );

  $$BookmarkFoldersTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$BookmarkFoldersTableTableManager(
      $_db,
      $_db.bookmarkFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BookmarksTable, List<Bookmark>>
  _bookmarksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bookmarks,
    aliasName: $_aliasNameGenerator(
      db.bookmarkFolders.id,
      db.bookmarks.folderId,
    ),
  );

  $$BookmarksTableProcessedTableManager get bookmarksRefs {
    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_bookmarksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BookmarkCollectionLinksTable,
    List<BookmarkCollectionLink>
  >
  _bookmarkCollectionLinksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bookmarkCollectionLinks,
        aliasName: $_aliasNameGenerator(
          db.bookmarkFolders.id,
          db.bookmarkCollectionLinks.folderId,
        ),
      );

  $$BookmarkCollectionLinksTableProcessedTableManager
  get bookmarkCollectionLinksRefs {
    final manager = $$BookmarkCollectionLinksTableTableManager(
      $_db,
      $_db.bookmarkCollectionLinks,
    ).filter((f) => f.folderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bookmarkCollectionLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BookmarkFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkFoldersTable> {
  $$BookmarkFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BookmarkFoldersTableFilterComposer get parentId {
    final $$BookmarkFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableFilterComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bookmarksRefs(
    Expression<bool> Function($$BookmarksTableFilterComposer f) f,
  ) {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> bookmarkCollectionLinksRefs(
    Expression<bool> Function($$BookmarkCollectionLinksTableFilterComposer f) f,
  ) {
    final $$BookmarkCollectionLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookmarkCollectionLinks,
          getReferencedColumn: (t) => t.folderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookmarkCollectionLinksTableFilterComposer(
                $db: $db,
                $table: $db.bookmarkCollectionLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BookmarkFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkFoldersTable> {
  $$BookmarkFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BookmarkFoldersTableOrderingComposer get parentId {
    final $$BookmarkFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarkFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkFoldersTable> {
  $$BookmarkFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessType => $composableBuilder(
    column: $table.accessType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$BookmarkFoldersTableAnnotationComposer get parentId {
    final $$BookmarkFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bookmarksRefs<T extends Object>(
    Expression<T> Function($$BookmarksTableAnnotationComposer a) f,
  ) {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.folderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> bookmarkCollectionLinksRefs<T extends Object>(
    Expression<T> Function($$BookmarkCollectionLinksTableAnnotationComposer a)
    f,
  ) {
    final $$BookmarkCollectionLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookmarkCollectionLinks,
          getReferencedColumn: (t) => t.folderId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookmarkCollectionLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.bookmarkCollectionLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BookmarkFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarkFoldersTable,
          BookmarkFolder,
          $$BookmarkFoldersTableFilterComposer,
          $$BookmarkFoldersTableOrderingComposer,
          $$BookmarkFoldersTableAnnotationComposer,
          $$BookmarkFoldersTableCreateCompanionBuilder,
          $$BookmarkFoldersTableUpdateCompanionBuilder,
          (BookmarkFolder, $$BookmarkFoldersTableReferences),
          BookmarkFolder,
          PrefetchHooks Function({
            bool parentId,
            bool bookmarksRefs,
            bool bookmarkCollectionLinksRefs,
          })
        > {
  $$BookmarkFoldersTableTableManager(
    _$AppDatabase db,
    $BookmarkFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarkFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarkFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> accessType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarkFoldersCompanion(
                id: id,
                parentId: parentId,
                title: title,
                description: description,
                accessType: accessType,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> accessType = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarkFoldersCompanion.insert(
                id: id,
                parentId: parentId,
                title: title,
                description: description,
                accessType: accessType,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarkFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                parentId = false,
                bookmarksRefs = false,
                bookmarkCollectionLinksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookmarksRefs) db.bookmarks,
                    if (bookmarkCollectionLinksRefs) db.bookmarkCollectionLinks,
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
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable:
                                        $$BookmarkFoldersTableReferences
                                            ._parentIdTable(db),
                                    referencedColumn:
                                        $$BookmarkFoldersTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookmarksRefs)
                        await $_getPrefetchedData<
                          BookmarkFolder,
                          $BookmarkFoldersTable,
                          Bookmark
                        >(
                          currentTable: table,
                          referencedTable: $$BookmarkFoldersTableReferences
                              ._bookmarksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookmarkFoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (bookmarkCollectionLinksRefs)
                        await $_getPrefetchedData<
                          BookmarkFolder,
                          $BookmarkFoldersTable,
                          BookmarkCollectionLink
                        >(
                          currentTable: table,
                          referencedTable: $$BookmarkFoldersTableReferences
                              ._bookmarkCollectionLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookmarkFoldersTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarkCollectionLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.folderId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BookmarkFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarkFoldersTable,
      BookmarkFolder,
      $$BookmarkFoldersTableFilterComposer,
      $$BookmarkFoldersTableOrderingComposer,
      $$BookmarkFoldersTableAnnotationComposer,
      $$BookmarkFoldersTableCreateCompanionBuilder,
      $$BookmarkFoldersTableUpdateCompanionBuilder,
      (BookmarkFolder, $$BookmarkFoldersTableReferences),
      BookmarkFolder,
      PrefetchHooks Function({
        bool parentId,
        bool bookmarksRefs,
        bool bookmarkCollectionLinksRefs,
      })
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      Value<String?> folderId,
      required String url,
      Value<String?> title,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String?> folderId,
      Value<String> url,
      Value<String?> title,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$BookmarksTableReferences
    extends BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark> {
  $$BookmarksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BookmarkFoldersTable _folderIdTable(_$AppDatabase db) =>
      db.bookmarkFolders.createAlias(
        $_aliasNameGenerator(db.bookmarks.folderId, db.bookmarkFolders.id),
      );

  $$BookmarkFoldersTableProcessedTableManager? get folderId {
    final $_column = $_itemColumn<String>('folder_id');
    if ($_column == null) return null;
    final manager = $$BookmarkFoldersTableTableManager(
      $_db,
      $_db.bookmarkFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $BookmarkCollectionLinksTable,
    List<BookmarkCollectionLink>
  >
  _bookmarkCollectionLinksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.bookmarkCollectionLinks,
        aliasName: $_aliasNameGenerator(
          db.bookmarks.id,
          db.bookmarkCollectionLinks.bookmarkId,
        ),
      );

  $$BookmarkCollectionLinksTableProcessedTableManager
  get bookmarkCollectionLinksRefs {
    final manager = $$BookmarkCollectionLinksTableTableManager(
      $_db,
      $_db.bookmarkCollectionLinks,
    ).filter((f) => f.bookmarkId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bookmarkCollectionLinksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BookmarkFoldersTableFilterComposer get folderId {
    final $$BookmarkFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableFilterComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> bookmarkCollectionLinksRefs(
    Expression<bool> Function($$BookmarkCollectionLinksTableFilterComposer f) f,
  ) {
    final $$BookmarkCollectionLinksTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookmarkCollectionLinks,
          getReferencedColumn: (t) => t.bookmarkId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookmarkCollectionLinksTableFilterComposer(
                $db: $db,
                $table: $db.bookmarkCollectionLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BookmarkFoldersTableOrderingComposer get folderId {
    final $$BookmarkFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$BookmarkFoldersTableAnnotationComposer get folderId {
    final $$BookmarkFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> bookmarkCollectionLinksRefs<T extends Object>(
    Expression<T> Function($$BookmarkCollectionLinksTableAnnotationComposer a)
    f,
  ) {
    final $$BookmarkCollectionLinksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.bookmarkCollectionLinks,
          getReferencedColumn: (t) => t.bookmarkId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BookmarkCollectionLinksTableAnnotationComposer(
                $db: $db,
                $table: $db.bookmarkCollectionLinks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (Bookmark, $$BookmarksTableReferences),
          Bookmark,
          PrefetchHooks Function({
            bool folderId,
            bool bookmarkCollectionLinksRefs,
          })
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> folderId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                folderId: folderId,
                url: url,
                title: title,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> folderId = const Value.absent(),
                required String url,
                Value<String?> title = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                folderId: folderId,
                url: url,
                title: title,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({folderId = false, bookmarkCollectionLinksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (bookmarkCollectionLinksRefs) db.bookmarkCollectionLinks,
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
                        if (folderId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.folderId,
                                    referencedTable: $$BookmarksTableReferences
                                        ._folderIdTable(db),
                                    referencedColumn: $$BookmarksTableReferences
                                        ._folderIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (bookmarkCollectionLinksRefs)
                        await $_getPrefetchedData<
                          Bookmark,
                          $BookmarksTable,
                          BookmarkCollectionLink
                        >(
                          currentTable: table,
                          referencedTable: $$BookmarksTableReferences
                              ._bookmarkCollectionLinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BookmarksTableReferences(
                                db,
                                table,
                                p0,
                              ).bookmarkCollectionLinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.bookmarkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Bookmark, $$BookmarksTableReferences),
      Bookmark,
      PrefetchHooks Function({bool folderId, bool bookmarkCollectionLinksRefs})
    >;
typedef $$BookmarkCollectionLinksTableCreateCompanionBuilder =
    BookmarkCollectionLinksCompanion Function({
      required String id,
      required String bookmarkId,
      required String folderId,
      Value<int> sortOrder,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$BookmarkCollectionLinksTableUpdateCompanionBuilder =
    BookmarkCollectionLinksCompanion Function({
      Value<String> id,
      Value<String> bookmarkId,
      Value<String> folderId,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$BookmarkCollectionLinksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BookmarkCollectionLinksTable,
          BookmarkCollectionLink
        > {
  $$BookmarkCollectionLinksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BookmarksTable _bookmarkIdTable(_$AppDatabase db) =>
      db.bookmarks.createAlias(
        $_aliasNameGenerator(
          db.bookmarkCollectionLinks.bookmarkId,
          db.bookmarks.id,
        ),
      );

  $$BookmarksTableProcessedTableManager get bookmarkId {
    final $_column = $_itemColumn<String>('bookmark_id')!;

    final manager = $$BookmarksTableTableManager(
      $_db,
      $_db.bookmarks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_bookmarkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BookmarkFoldersTable _folderIdTable(_$AppDatabase db) =>
      db.bookmarkFolders.createAlias(
        $_aliasNameGenerator(
          db.bookmarkCollectionLinks.folderId,
          db.bookmarkFolders.id,
        ),
      );

  $$BookmarkFoldersTableProcessedTableManager get folderId {
    final $_column = $_itemColumn<String>('folder_id')!;

    final manager = $$BookmarkFoldersTableTableManager(
      $_db,
      $_db.bookmarkFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_folderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BookmarkCollectionLinksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarkCollectionLinksTable> {
  $$BookmarkCollectionLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BookmarksTableFilterComposer get bookmarkId {
    final $$BookmarksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookmarkId,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableFilterComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookmarkFoldersTableFilterComposer get folderId {
    final $$BookmarkFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableFilterComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarkCollectionLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarkCollectionLinksTable> {
  $$BookmarkCollectionLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BookmarksTableOrderingComposer get bookmarkId {
    final $$BookmarksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookmarkId,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableOrderingComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookmarkFoldersTableOrderingComposer get folderId {
    final $$BookmarkFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarkCollectionLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarkCollectionLinksTable> {
  $$BookmarkCollectionLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$BookmarksTableAnnotationComposer get bookmarkId {
    final $$BookmarksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.bookmarkId,
      referencedTable: $db.bookmarks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarksTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BookmarkFoldersTableAnnotationComposer get folderId {
    final $$BookmarkFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.folderId,
      referencedTable: $db.bookmarkFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BookmarkFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.bookmarkFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BookmarkCollectionLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarkCollectionLinksTable,
          BookmarkCollectionLink,
          $$BookmarkCollectionLinksTableFilterComposer,
          $$BookmarkCollectionLinksTableOrderingComposer,
          $$BookmarkCollectionLinksTableAnnotationComposer,
          $$BookmarkCollectionLinksTableCreateCompanionBuilder,
          $$BookmarkCollectionLinksTableUpdateCompanionBuilder,
          (BookmarkCollectionLink, $$BookmarkCollectionLinksTableReferences),
          BookmarkCollectionLink,
          PrefetchHooks Function({bool bookmarkId, bool folderId})
        > {
  $$BookmarkCollectionLinksTableTableManager(
    _$AppDatabase db,
    $BookmarkCollectionLinksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarkCollectionLinksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BookmarkCollectionLinksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BookmarkCollectionLinksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bookmarkId = const Value.absent(),
                Value<String> folderId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarkCollectionLinksCompanion(
                id: id,
                bookmarkId: bookmarkId,
                folderId: folderId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bookmarkId,
                required String folderId,
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarkCollectionLinksCompanion.insert(
                id: id,
                bookmarkId: bookmarkId,
                folderId: folderId,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BookmarkCollectionLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bookmarkId = false, folderId = false}) {
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
                    if (bookmarkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.bookmarkId,
                                referencedTable:
                                    $$BookmarkCollectionLinksTableReferences
                                        ._bookmarkIdTable(db),
                                referencedColumn:
                                    $$BookmarkCollectionLinksTableReferences
                                        ._bookmarkIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (folderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.folderId,
                                referencedTable:
                                    $$BookmarkCollectionLinksTableReferences
                                        ._folderIdTable(db),
                                referencedColumn:
                                    $$BookmarkCollectionLinksTableReferences
                                        ._folderIdTable(db)
                                        .id,
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

typedef $$BookmarkCollectionLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarkCollectionLinksTable,
      BookmarkCollectionLink,
      $$BookmarkCollectionLinksTableFilterComposer,
      $$BookmarkCollectionLinksTableOrderingComposer,
      $$BookmarkCollectionLinksTableAnnotationComposer,
      $$BookmarkCollectionLinksTableCreateCompanionBuilder,
      $$BookmarkCollectionLinksTableUpdateCompanionBuilder,
      (BookmarkCollectionLink, $$BookmarkCollectionLinksTableReferences),
      BookmarkCollectionLink,
      PrefetchHooks Function({bool bookmarkId, bool folderId})
    >;
typedef $$BrowserHistoryEntriesTableCreateCompanionBuilder =
    BrowserHistoryEntriesCompanion Function({
      required String id,
      required String url,
      Value<String?> canonicalUrl,
      Value<String?> title,
      Value<String?> description,
      required DateTime visitedAt,
      Value<int> rowid,
    });
typedef $$BrowserHistoryEntriesTableUpdateCompanionBuilder =
    BrowserHistoryEntriesCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String?> canonicalUrl,
      Value<String?> title,
      Value<String?> description,
      Value<DateTime> visitedAt,
      Value<int> rowid,
    });

class $$BrowserHistoryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrowserHistoryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get visitedAt => $composableBuilder(
    column: $table.visitedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrowserHistoryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BrowserHistoryEntriesTable> {
  $$BrowserHistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get canonicalUrl => $composableBuilder(
    column: $table.canonicalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get visitedAt =>
      $composableBuilder(column: $table.visitedAt, builder: (column) => column);
}

class $$BrowserHistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BrowserHistoryEntriesTable,
          BrowserHistoryEntry,
          $$BrowserHistoryEntriesTableFilterComposer,
          $$BrowserHistoryEntriesTableOrderingComposer,
          $$BrowserHistoryEntriesTableAnnotationComposer,
          $$BrowserHistoryEntriesTableCreateCompanionBuilder,
          $$BrowserHistoryEntriesTableUpdateCompanionBuilder,
          (
            BrowserHistoryEntry,
            BaseReferences<
              _$AppDatabase,
              $BrowserHistoryEntriesTable,
              BrowserHistoryEntry
            >,
          ),
          BrowserHistoryEntry,
          PrefetchHooks Function()
        > {
  $$BrowserHistoryEntriesTableTableManager(
    _$AppDatabase db,
    $BrowserHistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrowserHistoryEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BrowserHistoryEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BrowserHistoryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> canonicalUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> visitedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrowserHistoryEntriesCompanion(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                description: description,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                Value<String?> canonicalUrl = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required DateTime visitedAt,
                Value<int> rowid = const Value.absent(),
              }) => BrowserHistoryEntriesCompanion.insert(
                id: id,
                url: url,
                canonicalUrl: canonicalUrl,
                title: title,
                description: description,
                visitedAt: visitedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrowserHistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BrowserHistoryEntriesTable,
      BrowserHistoryEntry,
      $$BrowserHistoryEntriesTableFilterComposer,
      $$BrowserHistoryEntriesTableOrderingComposer,
      $$BrowserHistoryEntriesTableAnnotationComposer,
      $$BrowserHistoryEntriesTableCreateCompanionBuilder,
      $$BrowserHistoryEntriesTableUpdateCompanionBuilder,
      (
        BrowserHistoryEntry,
        BaseReferences<
          _$AppDatabase,
          $BrowserHistoryEntriesTable,
          BrowserHistoryEntry
        >,
      ),
      BrowserHistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$AtprotoAccountsTableCreateCompanionBuilder =
    AtprotoAccountsCompanion Function({
      required String did,
      Value<String?> handle,
      Value<String?> pdsEndpoint,
      required String authMethod,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AtprotoAccountsTableUpdateCompanionBuilder =
    AtprotoAccountsCompanion Function({
      Value<String> did,
      Value<String?> handle,
      Value<String?> pdsEndpoint,
      Value<String> authMethod,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AtprotoAccountsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AtprotoAccountsTable, AtprotoAccount> {
  $$AtprotoAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $AtprotoRecordMirrorsTable,
    List<AtprotoRecordMirror>
  >
  _atprotoRecordMirrorsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.atprotoRecordMirrors,
        aliasName: $_aliasNameGenerator(
          db.atprotoAccounts.did,
          db.atprotoRecordMirrors.accountDid,
        ),
      );

  $$AtprotoRecordMirrorsTableProcessedTableManager
  get atprotoRecordMirrorsRefs {
    final manager = $$AtprotoRecordMirrorsTableTableManager(
      $_db,
      $_db.atprotoRecordMirrors,
    ).filter((f) => f.accountDid.did.sqlEquals($_itemColumn<String>('did')!));

    final cache = $_typedResult.readTableOrNull(
      _atprotoRecordMirrorsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AtprotoSyncStateTable, List<AtprotoSyncStateData>>
  _atprotoSyncStateRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.atprotoSyncState,
    aliasName: $_aliasNameGenerator(
      db.atprotoAccounts.did,
      db.atprotoSyncState.accountDid,
    ),
  );

  $$AtprotoSyncStateTableProcessedTableManager get atprotoSyncStateRefs {
    final manager = $$AtprotoSyncStateTableTableManager(
      $_db,
      $_db.atprotoSyncState,
    ).filter((f) => f.accountDid.did.sqlEquals($_itemColumn<String>('did')!));

    final cache = $_typedResult.readTableOrNull(
      _atprotoSyncStateRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AtprotoSyncOutboxTable,
    List<AtprotoSyncOutboxData>
  >
  _atprotoSyncOutboxRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.atprotoSyncOutbox,
        aliasName: $_aliasNameGenerator(
          db.atprotoAccounts.did,
          db.atprotoSyncOutbox.accountDid,
        ),
      );

  $$AtprotoSyncOutboxTableProcessedTableManager get atprotoSyncOutboxRefs {
    final manager = $$AtprotoSyncOutboxTableTableManager(
      $_db,
      $_db.atprotoSyncOutbox,
    ).filter((f) => f.accountDid.did.sqlEquals($_itemColumn<String>('did')!));

    final cache = $_typedResult.readTableOrNull(
      _atprotoSyncOutboxRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AtprotoAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AtprotoAccountsTable> {
  $$AtprotoAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get did => $composableBuilder(
    column: $table.did,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdsEndpoint => $composableBuilder(
    column: $table.pdsEndpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authMethod => $composableBuilder(
    column: $table.authMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> atprotoRecordMirrorsRefs(
    Expression<bool> Function($$AtprotoRecordMirrorsTableFilterComposer f) f,
  ) {
    final $$AtprotoRecordMirrorsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.did,
      referencedTable: $db.atprotoRecordMirrors,
      getReferencedColumn: (t) => t.accountDid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoRecordMirrorsTableFilterComposer(
            $db: $db,
            $table: $db.atprotoRecordMirrors,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> atprotoSyncStateRefs(
    Expression<bool> Function($$AtprotoSyncStateTableFilterComposer f) f,
  ) {
    final $$AtprotoSyncStateTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.did,
      referencedTable: $db.atprotoSyncState,
      getReferencedColumn: (t) => t.accountDid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoSyncStateTableFilterComposer(
            $db: $db,
            $table: $db.atprotoSyncState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> atprotoSyncOutboxRefs(
    Expression<bool> Function($$AtprotoSyncOutboxTableFilterComposer f) f,
  ) {
    final $$AtprotoSyncOutboxTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.did,
      referencedTable: $db.atprotoSyncOutbox,
      getReferencedColumn: (t) => t.accountDid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoSyncOutboxTableFilterComposer(
            $db: $db,
            $table: $db.atprotoSyncOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AtprotoAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AtprotoAccountsTable> {
  $$AtprotoAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get did => $composableBuilder(
    column: $table.did,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get handle => $composableBuilder(
    column: $table.handle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdsEndpoint => $composableBuilder(
    column: $table.pdsEndpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authMethod => $composableBuilder(
    column: $table.authMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AtprotoAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtprotoAccountsTable> {
  $$AtprotoAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get did =>
      $composableBuilder(column: $table.did, builder: (column) => column);

  GeneratedColumn<String> get handle =>
      $composableBuilder(column: $table.handle, builder: (column) => column);

  GeneratedColumn<String> get pdsEndpoint => $composableBuilder(
    column: $table.pdsEndpoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authMethod => $composableBuilder(
    column: $table.authMethod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> atprotoRecordMirrorsRefs<T extends Object>(
    Expression<T> Function($$AtprotoRecordMirrorsTableAnnotationComposer a) f,
  ) {
    final $$AtprotoRecordMirrorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.did,
          referencedTable: $db.atprotoRecordMirrors,
          getReferencedColumn: (t) => t.accountDid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AtprotoRecordMirrorsTableAnnotationComposer(
                $db: $db,
                $table: $db.atprotoRecordMirrors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> atprotoSyncStateRefs<T extends Object>(
    Expression<T> Function($$AtprotoSyncStateTableAnnotationComposer a) f,
  ) {
    final $$AtprotoSyncStateTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.did,
      referencedTable: $db.atprotoSyncState,
      getReferencedColumn: (t) => t.accountDid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoSyncStateTableAnnotationComposer(
            $db: $db,
            $table: $db.atprotoSyncState,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> atprotoSyncOutboxRefs<T extends Object>(
    Expression<T> Function($$AtprotoSyncOutboxTableAnnotationComposer a) f,
  ) {
    final $$AtprotoSyncOutboxTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.did,
          referencedTable: $db.atprotoSyncOutbox,
          getReferencedColumn: (t) => t.accountDid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AtprotoSyncOutboxTableAnnotationComposer(
                $db: $db,
                $table: $db.atprotoSyncOutbox,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AtprotoAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtprotoAccountsTable,
          AtprotoAccount,
          $$AtprotoAccountsTableFilterComposer,
          $$AtprotoAccountsTableOrderingComposer,
          $$AtprotoAccountsTableAnnotationComposer,
          $$AtprotoAccountsTableCreateCompanionBuilder,
          $$AtprotoAccountsTableUpdateCompanionBuilder,
          (AtprotoAccount, $$AtprotoAccountsTableReferences),
          AtprotoAccount,
          PrefetchHooks Function({
            bool atprotoRecordMirrorsRefs,
            bool atprotoSyncStateRefs,
            bool atprotoSyncOutboxRefs,
          })
        > {
  $$AtprotoAccountsTableTableManager(
    _$AppDatabase db,
    $AtprotoAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtprotoAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtprotoAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtprotoAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> did = const Value.absent(),
                Value<String?> handle = const Value.absent(),
                Value<String?> pdsEndpoint = const Value.absent(),
                Value<String> authMethod = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoAccountsCompanion(
                did: did,
                handle: handle,
                pdsEndpoint: pdsEndpoint,
                authMethod: authMethod,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String did,
                Value<String?> handle = const Value.absent(),
                Value<String?> pdsEndpoint = const Value.absent(),
                required String authMethod,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AtprotoAccountsCompanion.insert(
                did: did,
                handle: handle,
                pdsEndpoint: pdsEndpoint,
                authMethod: authMethod,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AtprotoAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                atprotoRecordMirrorsRefs = false,
                atprotoSyncStateRefs = false,
                atprotoSyncOutboxRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (atprotoRecordMirrorsRefs) db.atprotoRecordMirrors,
                    if (atprotoSyncStateRefs) db.atprotoSyncState,
                    if (atprotoSyncOutboxRefs) db.atprotoSyncOutbox,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (atprotoRecordMirrorsRefs)
                        await $_getPrefetchedData<
                          AtprotoAccount,
                          $AtprotoAccountsTable,
                          AtprotoRecordMirror
                        >(
                          currentTable: table,
                          referencedTable: $$AtprotoAccountsTableReferences
                              ._atprotoRecordMirrorsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AtprotoAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).atprotoRecordMirrorsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountDid == item.did,
                              ),
                          typedResults: items,
                        ),
                      if (atprotoSyncStateRefs)
                        await $_getPrefetchedData<
                          AtprotoAccount,
                          $AtprotoAccountsTable,
                          AtprotoSyncStateData
                        >(
                          currentTable: table,
                          referencedTable: $$AtprotoAccountsTableReferences
                              ._atprotoSyncStateRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AtprotoAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).atprotoSyncStateRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountDid == item.did,
                              ),
                          typedResults: items,
                        ),
                      if (atprotoSyncOutboxRefs)
                        await $_getPrefetchedData<
                          AtprotoAccount,
                          $AtprotoAccountsTable,
                          AtprotoSyncOutboxData
                        >(
                          currentTable: table,
                          referencedTable: $$AtprotoAccountsTableReferences
                              ._atprotoSyncOutboxRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AtprotoAccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).atprotoSyncOutboxRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountDid == item.did,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AtprotoAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtprotoAccountsTable,
      AtprotoAccount,
      $$AtprotoAccountsTableFilterComposer,
      $$AtprotoAccountsTableOrderingComposer,
      $$AtprotoAccountsTableAnnotationComposer,
      $$AtprotoAccountsTableCreateCompanionBuilder,
      $$AtprotoAccountsTableUpdateCompanionBuilder,
      (AtprotoAccount, $$AtprotoAccountsTableReferences),
      AtprotoAccount,
      PrefetchHooks Function({
        bool atprotoRecordMirrorsRefs,
        bool atprotoSyncStateRefs,
        bool atprotoSyncOutboxRefs,
      })
    >;
typedef $$AtprotoRecordMirrorsTableCreateCompanionBuilder =
    AtprotoRecordMirrorsCompanion Function({
      required String id,
      required String accountDid,
      required String localTable,
      required String localId,
      required String collection,
      required String rkey,
      required String uri,
      Value<String?> cid,
      Value<String?> lastSyncedRecordJson,
      Value<String?> lastSyncedHash,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> dirtyAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$AtprotoRecordMirrorsTableUpdateCompanionBuilder =
    AtprotoRecordMirrorsCompanion Function({
      Value<String> id,
      Value<String> accountDid,
      Value<String> localTable,
      Value<String> localId,
      Value<String> collection,
      Value<String> rkey,
      Value<String> uri,
      Value<String?> cid,
      Value<String?> lastSyncedRecordJson,
      Value<String?> lastSyncedHash,
      Value<DateTime?> lastSyncedAt,
      Value<DateTime?> dirtyAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$AtprotoRecordMirrorsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AtprotoRecordMirrorsTable,
          AtprotoRecordMirror
        > {
  $$AtprotoRecordMirrorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AtprotoAccountsTable _accountDidTable(_$AppDatabase db) =>
      db.atprotoAccounts.createAlias(
        $_aliasNameGenerator(
          db.atprotoRecordMirrors.accountDid,
          db.atprotoAccounts.did,
        ),
      );

  $$AtprotoAccountsTableProcessedTableManager get accountDid {
    final $_column = $_itemColumn<String>('account_did')!;

    final manager = $$AtprotoAccountsTableTableManager(
      $_db,
      $_db.atprotoAccounts,
    ).filter((f) => f.did.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountDidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AtprotoRecordMirrorsTableFilterComposer
    extends Composer<_$AppDatabase, $AtprotoRecordMirrorsTable> {
  $$AtprotoRecordMirrorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rkey => $composableBuilder(
    column: $table.rkey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncedRecordJson => $composableBuilder(
    column: $table.lastSyncedRecordJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dirtyAt => $composableBuilder(
    column: $table.dirtyAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AtprotoAccountsTableFilterComposer get accountDid {
    final $$AtprotoAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableFilterComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoRecordMirrorsTableOrderingComposer
    extends Composer<_$AppDatabase, $AtprotoRecordMirrorsTable> {
  $$AtprotoRecordMirrorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rkey => $composableBuilder(
    column: $table.rkey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uri => $composableBuilder(
    column: $table.uri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cid => $composableBuilder(
    column: $table.cid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncedRecordJson => $composableBuilder(
    column: $table.lastSyncedRecordJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dirtyAt => $composableBuilder(
    column: $table.dirtyAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AtprotoAccountsTableOrderingComposer get accountDid {
    final $$AtprotoAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoRecordMirrorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtprotoRecordMirrorsTable> {
  $$AtprotoRecordMirrorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rkey =>
      $composableBuilder(column: $table.rkey, builder: (column) => column);

  GeneratedColumn<String> get uri =>
      $composableBuilder(column: $table.uri, builder: (column) => column);

  GeneratedColumn<String> get cid =>
      $composableBuilder(column: $table.cid, builder: (column) => column);

  GeneratedColumn<String> get lastSyncedRecordJson => $composableBuilder(
    column: $table.lastSyncedRecordJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncedHash => $composableBuilder(
    column: $table.lastSyncedHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dirtyAt =>
      $composableBuilder(column: $table.dirtyAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$AtprotoAccountsTableAnnotationComposer get accountDid {
    final $$AtprotoAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoRecordMirrorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtprotoRecordMirrorsTable,
          AtprotoRecordMirror,
          $$AtprotoRecordMirrorsTableFilterComposer,
          $$AtprotoRecordMirrorsTableOrderingComposer,
          $$AtprotoRecordMirrorsTableAnnotationComposer,
          $$AtprotoRecordMirrorsTableCreateCompanionBuilder,
          $$AtprotoRecordMirrorsTableUpdateCompanionBuilder,
          (AtprotoRecordMirror, $$AtprotoRecordMirrorsTableReferences),
          AtprotoRecordMirror,
          PrefetchHooks Function({bool accountDid})
        > {
  $$AtprotoRecordMirrorsTableTableManager(
    _$AppDatabase db,
    $AtprotoRecordMirrorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtprotoRecordMirrorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtprotoRecordMirrorsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AtprotoRecordMirrorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountDid = const Value.absent(),
                Value<String> localTable = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String> rkey = const Value.absent(),
                Value<String> uri = const Value.absent(),
                Value<String?> cid = const Value.absent(),
                Value<String?> lastSyncedRecordJson = const Value.absent(),
                Value<String?> lastSyncedHash = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> dirtyAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoRecordMirrorsCompanion(
                id: id,
                accountDid: accountDid,
                localTable: localTable,
                localId: localId,
                collection: collection,
                rkey: rkey,
                uri: uri,
                cid: cid,
                lastSyncedRecordJson: lastSyncedRecordJson,
                lastSyncedHash: lastSyncedHash,
                lastSyncedAt: lastSyncedAt,
                dirtyAt: dirtyAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountDid,
                required String localTable,
                required String localId,
                required String collection,
                required String rkey,
                required String uri,
                Value<String?> cid = const Value.absent(),
                Value<String?> lastSyncedRecordJson = const Value.absent(),
                Value<String?> lastSyncedHash = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<DateTime?> dirtyAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoRecordMirrorsCompanion.insert(
                id: id,
                accountDid: accountDid,
                localTable: localTable,
                localId: localId,
                collection: collection,
                rkey: rkey,
                uri: uri,
                cid: cid,
                lastSyncedRecordJson: lastSyncedRecordJson,
                lastSyncedHash: lastSyncedHash,
                lastSyncedAt: lastSyncedAt,
                dirtyAt: dirtyAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AtprotoRecordMirrorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountDid = false}) {
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
                    if (accountDid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountDid,
                                referencedTable:
                                    $$AtprotoRecordMirrorsTableReferences
                                        ._accountDidTable(db),
                                referencedColumn:
                                    $$AtprotoRecordMirrorsTableReferences
                                        ._accountDidTable(db)
                                        .did,
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

typedef $$AtprotoRecordMirrorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtprotoRecordMirrorsTable,
      AtprotoRecordMirror,
      $$AtprotoRecordMirrorsTableFilterComposer,
      $$AtprotoRecordMirrorsTableOrderingComposer,
      $$AtprotoRecordMirrorsTableAnnotationComposer,
      $$AtprotoRecordMirrorsTableCreateCompanionBuilder,
      $$AtprotoRecordMirrorsTableUpdateCompanionBuilder,
      (AtprotoRecordMirror, $$AtprotoRecordMirrorsTableReferences),
      AtprotoRecordMirror,
      PrefetchHooks Function({bool accountDid})
    >;
typedef $$AtprotoSyncStateTableCreateCompanionBuilder =
    AtprotoSyncStateCompanion Function({
      required String id,
      required String accountDid,
      required String collection,
      Value<String?> cursor,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$AtprotoSyncStateTableUpdateCompanionBuilder =
    AtprotoSyncStateCompanion Function({
      Value<String> id,
      Value<String> accountDid,
      Value<String> collection,
      Value<String?> cursor,
      Value<DateTime?> lastSuccessfulSyncAt,
      Value<String?> lastError,
      Value<int> rowid,
    });

final class $$AtprotoSyncStateTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AtprotoSyncStateTable,
          AtprotoSyncStateData
        > {
  $$AtprotoSyncStateTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AtprotoAccountsTable _accountDidTable(_$AppDatabase db) =>
      db.atprotoAccounts.createAlias(
        $_aliasNameGenerator(
          db.atprotoSyncState.accountDid,
          db.atprotoAccounts.did,
        ),
      );

  $$AtprotoAccountsTableProcessedTableManager get accountDid {
    final $_column = $_itemColumn<String>('account_did')!;

    final manager = $$AtprotoAccountsTableTableManager(
      $_db,
      $_db.atprotoAccounts,
    ).filter((f) => f.did.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountDidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AtprotoSyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $AtprotoSyncStateTable> {
  $$AtprotoSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$AtprotoAccountsTableFilterComposer get accountDid {
    final $$AtprotoAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableFilterComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $AtprotoSyncStateTable> {
  $$AtprotoSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$AtprotoAccountsTableOrderingComposer get accountDid {
    final $$AtprotoAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtprotoSyncStateTable> {
  $$AtprotoSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSuccessfulSyncAt => $composableBuilder(
    column: $table.lastSuccessfulSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$AtprotoAccountsTableAnnotationComposer get accountDid {
    final $$AtprotoAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtprotoSyncStateTable,
          AtprotoSyncStateData,
          $$AtprotoSyncStateTableFilterComposer,
          $$AtprotoSyncStateTableOrderingComposer,
          $$AtprotoSyncStateTableAnnotationComposer,
          $$AtprotoSyncStateTableCreateCompanionBuilder,
          $$AtprotoSyncStateTableUpdateCompanionBuilder,
          (AtprotoSyncStateData, $$AtprotoSyncStateTableReferences),
          AtprotoSyncStateData,
          PrefetchHooks Function({bool accountDid})
        > {
  $$AtprotoSyncStateTableTableManager(
    _$AppDatabase db,
    $AtprotoSyncStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtprotoSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtprotoSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtprotoSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountDid = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoSyncStateCompanion(
                id: id,
                accountDid: accountDid,
                collection: collection,
                cursor: cursor,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountDid,
                required String collection,
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastSuccessfulSyncAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoSyncStateCompanion.insert(
                id: id,
                accountDid: accountDid,
                collection: collection,
                cursor: cursor,
                lastSuccessfulSyncAt: lastSuccessfulSyncAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AtprotoSyncStateTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountDid = false}) {
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
                    if (accountDid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountDid,
                                referencedTable:
                                    $$AtprotoSyncStateTableReferences
                                        ._accountDidTable(db),
                                referencedColumn:
                                    $$AtprotoSyncStateTableReferences
                                        ._accountDidTable(db)
                                        .did,
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

typedef $$AtprotoSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtprotoSyncStateTable,
      AtprotoSyncStateData,
      $$AtprotoSyncStateTableFilterComposer,
      $$AtprotoSyncStateTableOrderingComposer,
      $$AtprotoSyncStateTableAnnotationComposer,
      $$AtprotoSyncStateTableCreateCompanionBuilder,
      $$AtprotoSyncStateTableUpdateCompanionBuilder,
      (AtprotoSyncStateData, $$AtprotoSyncStateTableReferences),
      AtprotoSyncStateData,
      PrefetchHooks Function({bool accountDid})
    >;
typedef $$AtprotoSyncOutboxTableCreateCompanionBuilder =
    AtprotoSyncOutboxCompanion Function({
      required String id,
      required String accountDid,
      required String operation,
      required String localTable,
      required String localId,
      required String collection,
      Value<String?> payloadJson,
      Value<int> attemptCount,
      Value<String?> lastError,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AtprotoSyncOutboxTableUpdateCompanionBuilder =
    AtprotoSyncOutboxCompanion Function({
      Value<String> id,
      Value<String> accountDid,
      Value<String> operation,
      Value<String> localTable,
      Value<String> localId,
      Value<String> collection,
      Value<String?> payloadJson,
      Value<int> attemptCount,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AtprotoSyncOutboxTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $AtprotoSyncOutboxTable,
          AtprotoSyncOutboxData
        > {
  $$AtprotoSyncOutboxTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AtprotoAccountsTable _accountDidTable(_$AppDatabase db) =>
      db.atprotoAccounts.createAlias(
        $_aliasNameGenerator(
          db.atprotoSyncOutbox.accountDid,
          db.atprotoAccounts.did,
        ),
      );

  $$AtprotoAccountsTableProcessedTableManager get accountDid {
    final $_column = $_itemColumn<String>('account_did')!;

    final manager = $$AtprotoAccountsTableTableManager(
      $_db,
      $_db.atprotoAccounts,
    ).filter((f) => f.did.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountDidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AtprotoSyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $AtprotoSyncOutboxTable> {
  $$AtprotoSyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AtprotoAccountsTableFilterComposer get accountDid {
    final $$AtprotoAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableFilterComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $AtprotoSyncOutboxTable> {
  $$AtprotoSyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AtprotoAccountsTableOrderingComposer get accountDid {
    final $$AtprotoAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $AtprotoSyncOutboxTable> {
  $$AtprotoSyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get localTable => $composableBuilder(
    column: $table.localTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get collection => $composableBuilder(
    column: $table.collection,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AtprotoAccountsTableAnnotationComposer get accountDid {
    final $$AtprotoAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountDid,
      referencedTable: $db.atprotoAccounts,
      getReferencedColumn: (t) => t.did,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AtprotoAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.atprotoAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AtprotoSyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AtprotoSyncOutboxTable,
          AtprotoSyncOutboxData,
          $$AtprotoSyncOutboxTableFilterComposer,
          $$AtprotoSyncOutboxTableOrderingComposer,
          $$AtprotoSyncOutboxTableAnnotationComposer,
          $$AtprotoSyncOutboxTableCreateCompanionBuilder,
          $$AtprotoSyncOutboxTableUpdateCompanionBuilder,
          (AtprotoSyncOutboxData, $$AtprotoSyncOutboxTableReferences),
          AtprotoSyncOutboxData,
          PrefetchHooks Function({bool accountDid})
        > {
  $$AtprotoSyncOutboxTableTableManager(
    _$AppDatabase db,
    $AtprotoSyncOutboxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AtprotoSyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AtprotoSyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AtprotoSyncOutboxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountDid = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> localTable = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> collection = const Value.absent(),
                Value<String?> payloadJson = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AtprotoSyncOutboxCompanion(
                id: id,
                accountDid: accountDid,
                operation: operation,
                localTable: localTable,
                localId: localId,
                collection: collection,
                payloadJson: payloadJson,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountDid,
                required String operation,
                required String localTable,
                required String localId,
                required String collection,
                Value<String?> payloadJson = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AtprotoSyncOutboxCompanion.insert(
                id: id,
                accountDid: accountDid,
                operation: operation,
                localTable: localTable,
                localId: localId,
                collection: collection,
                payloadJson: payloadJson,
                attemptCount: attemptCount,
                lastError: lastError,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AtprotoSyncOutboxTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountDid = false}) {
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
                    if (accountDid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountDid,
                                referencedTable:
                                    $$AtprotoSyncOutboxTableReferences
                                        ._accountDidTable(db),
                                referencedColumn:
                                    $$AtprotoSyncOutboxTableReferences
                                        ._accountDidTable(db)
                                        .did,
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

typedef $$AtprotoSyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AtprotoSyncOutboxTable,
      AtprotoSyncOutboxData,
      $$AtprotoSyncOutboxTableFilterComposer,
      $$AtprotoSyncOutboxTableOrderingComposer,
      $$AtprotoSyncOutboxTableAnnotationComposer,
      $$AtprotoSyncOutboxTableCreateCompanionBuilder,
      $$AtprotoSyncOutboxTableUpdateCompanionBuilder,
      (AtprotoSyncOutboxData, $$AtprotoSyncOutboxTableReferences),
      AtprotoSyncOutboxData,
      PrefetchHooks Function({bool accountDid})
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$AnnotationsTableTableManager get annotations =>
      $$AnnotationsTableTableManager(_db, _db.annotations);
  $$AnnotationTargetsTableTableManager get annotationTargets =>
      $$AnnotationTargetsTableTableManager(_db, _db.annotationTargets);
  $$AnnotationBodiesTableTableManager get annotationBodies =>
      $$AnnotationBodiesTableTableManager(_db, _db.annotationBodies);
  $$BookmarkFoldersTableTableManager get bookmarkFolders =>
      $$BookmarkFoldersTableTableManager(_db, _db.bookmarkFolders);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$BookmarkCollectionLinksTableTableManager get bookmarkCollectionLinks =>
      $$BookmarkCollectionLinksTableTableManager(
        _db,
        _db.bookmarkCollectionLinks,
      );
  $$BrowserHistoryEntriesTableTableManager get browserHistoryEntries =>
      $$BrowserHistoryEntriesTableTableManager(_db, _db.browserHistoryEntries);
  $$AtprotoAccountsTableTableManager get atprotoAccounts =>
      $$AtprotoAccountsTableTableManager(_db, _db.atprotoAccounts);
  $$AtprotoRecordMirrorsTableTableManager get atprotoRecordMirrors =>
      $$AtprotoRecordMirrorsTableTableManager(_db, _db.atprotoRecordMirrors);
  $$AtprotoSyncStateTableTableManager get atprotoSyncState =>
      $$AtprotoSyncStateTableTableManager(_db, _db.atprotoSyncState);
  $$AtprotoSyncOutboxTableTableManager get atprotoSyncOutbox =>
      $$AtprotoSyncOutboxTableTableManager(_db, _db.atprotoSyncOutbox);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
