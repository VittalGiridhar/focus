// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
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
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}key'],
          )!,
      value:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}value'],
          )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  const SettingsEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(key: Value(key), value: Value(value));
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingsEntry copyWith({String? key, String? value}) =>
      SettingsEntry(key: key ?? this.key, value: value ?? this.value);
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingsEntry> custom({
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

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
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
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModesTable extends Modes with TableInfo<$ModesTable, ModeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 40,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [id, name, durationMinutes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'modes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ModeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModeRow(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      name:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}name'],
          )!,
      durationMinutes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}duration_minutes'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $ModesTable createAlias(String alias) {
    return $ModesTable(attachedDatabase, alias);
  }
}

class ModeRow extends DataClass implements Insertable<ModeRow> {
  final String id;
  final String name;
  final int durationMinutes;
  final DateTime createdAt;
  const ModeRow({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ModesCompanion toCompanion(bool nullToAbsent) {
    return ModesCompanion(
      id: Value(id),
      name: Value(name),
      durationMinutes: Value(durationMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory ModeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ModeRow copyWith({
    String? id,
    String? name,
    int? durationMinutes,
    DateTime? createdAt,
  }) => ModeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  ModeRow copyWithCompanion(ModesCompanion data) {
    return ModeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      durationMinutes:
          data.durationMinutes.present
              ? data.durationMinutes.value
              : this.durationMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, durationMinutes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.durationMinutes == this.durationMinutes &&
          other.createdAt == this.createdAt);
}

class ModesCompanion extends UpdateCompanion<ModeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> durationMinutes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ModesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModesCompanion.insert({
    required String id,
    required String name,
    required int durationMinutes,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       durationMinutes = Value(durationMinutes),
       createdAt = Value(createdAt);
  static Insertable<ModeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? durationMinutes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? durationMinutes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ModesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMinutes: durationMinutes ?? this.durationMinutes,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
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
    return (StringBuffer('ModesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LimitRulesTable extends LimitRules
    with TableInfo<$LimitRulesTable, LimitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LimitRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyLimitMinutesMeta = const VerificationMeta(
    'dailyLimitMinutes',
  );
  @override
  late final GeneratedColumn<int> dailyLimitMinutes = GeneratedColumn<int>(
    'daily_limit_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    appId,
    label,
    dailyLimitMinutes,
    enabled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'limit_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<LimitRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('app_id')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta),
      );
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('daily_limit_minutes')) {
      context.handle(
        _dailyLimitMinutesMeta,
        dailyLimitMinutes.isAcceptableOrUnknown(
          data['daily_limit_minutes']!,
          _dailyLimitMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyLimitMinutesMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {appId};
  @override
  LimitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LimitRow(
      appId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}app_id'],
          )!,
      label:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}label'],
          )!,
      dailyLimitMinutes:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}daily_limit_minutes'],
          )!,
      enabled:
          attachedDatabase.typeMapping.read(
            DriftSqlType.bool,
            data['${effectivePrefix}enabled'],
          )!,
    );
  }

  @override
  $LimitRulesTable createAlias(String alias) {
    return $LimitRulesTable(attachedDatabase, alias);
  }
}

class LimitRow extends DataClass implements Insertable<LimitRow> {
  final String appId;
  final String label;
  final int dailyLimitMinutes;
  final bool enabled;
  const LimitRow({
    required this.appId,
    required this.label,
    required this.dailyLimitMinutes,
    required this.enabled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['app_id'] = Variable<String>(appId);
    map['label'] = Variable<String>(label);
    map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes);
    map['enabled'] = Variable<bool>(enabled);
    return map;
  }

  LimitRulesCompanion toCompanion(bool nullToAbsent) {
    return LimitRulesCompanion(
      appId: Value(appId),
      label: Value(label),
      dailyLimitMinutes: Value(dailyLimitMinutes),
      enabled: Value(enabled),
    );
  }

  factory LimitRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LimitRow(
      appId: serializer.fromJson<String>(json['appId']),
      label: serializer.fromJson<String>(json['label']),
      dailyLimitMinutes: serializer.fromJson<int>(json['dailyLimitMinutes']),
      enabled: serializer.fromJson<bool>(json['enabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'appId': serializer.toJson<String>(appId),
      'label': serializer.toJson<String>(label),
      'dailyLimitMinutes': serializer.toJson<int>(dailyLimitMinutes),
      'enabled': serializer.toJson<bool>(enabled),
    };
  }

  LimitRow copyWith({
    String? appId,
    String? label,
    int? dailyLimitMinutes,
    bool? enabled,
  }) => LimitRow(
    appId: appId ?? this.appId,
    label: label ?? this.label,
    dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
    enabled: enabled ?? this.enabled,
  );
  LimitRow copyWithCompanion(LimitRulesCompanion data) {
    return LimitRow(
      appId: data.appId.present ? data.appId.value : this.appId,
      label: data.label.present ? data.label.value : this.label,
      dailyLimitMinutes:
          data.dailyLimitMinutes.present
              ? data.dailyLimitMinutes.value
              : this.dailyLimitMinutes,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LimitRow(')
          ..write('appId: $appId, ')
          ..write('label: $label, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('enabled: $enabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(appId, label, dailyLimitMinutes, enabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LimitRow &&
          other.appId == this.appId &&
          other.label == this.label &&
          other.dailyLimitMinutes == this.dailyLimitMinutes &&
          other.enabled == this.enabled);
}

class LimitRulesCompanion extends UpdateCompanion<LimitRow> {
  final Value<String> appId;
  final Value<String> label;
  final Value<int> dailyLimitMinutes;
  final Value<bool> enabled;
  final Value<int> rowid;
  const LimitRulesCompanion({
    this.appId = const Value.absent(),
    this.label = const Value.absent(),
    this.dailyLimitMinutes = const Value.absent(),
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LimitRulesCompanion.insert({
    required String appId,
    required String label,
    required int dailyLimitMinutes,
    this.enabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : appId = Value(appId),
       label = Value(label),
       dailyLimitMinutes = Value(dailyLimitMinutes);
  static Insertable<LimitRow> custom({
    Expression<String>? appId,
    Expression<String>? label,
    Expression<int>? dailyLimitMinutes,
    Expression<bool>? enabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (appId != null) 'app_id': appId,
      if (label != null) 'label': label,
      if (dailyLimitMinutes != null) 'daily_limit_minutes': dailyLimitMinutes,
      if (enabled != null) 'enabled': enabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LimitRulesCompanion copyWith({
    Value<String>? appId,
    Value<String>? label,
    Value<int>? dailyLimitMinutes,
    Value<bool>? enabled,
    Value<int>? rowid,
  }) {
    return LimitRulesCompanion(
      appId: appId ?? this.appId,
      label: label ?? this.label,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      enabled: enabled ?? this.enabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (dailyLimitMinutes.present) {
      map['daily_limit_minutes'] = Variable<int>(dailyLimitMinutes.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LimitRulesCompanion(')
          ..write('appId: $appId, ')
          ..write('label: $label, ')
          ..write('dailyLimitMinutes: $dailyLimitMinutes, ')
          ..write('enabled: $enabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ModeAppsTable extends ModeApps
    with TableInfo<$ModeAppsTable, ModeAppRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ModeAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _modeIdMeta = const VerificationMeta('modeId');
  @override
  late final GeneratedColumn<String> modeId = GeneratedColumn<String>(
    'mode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [modeId, appId, label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mode_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ModeAppRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mode_id')) {
      context.handle(
        _modeIdMeta,
        modeId.isAcceptableOrUnknown(data['mode_id']!, _modeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_modeIdMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta),
      );
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {modeId, appId};
  @override
  ModeAppRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ModeAppRow(
      modeId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}mode_id'],
          )!,
      appId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}app_id'],
          )!,
      label:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}label'],
          )!,
    );
  }

  @override
  $ModeAppsTable createAlias(String alias) {
    return $ModeAppsTable(attachedDatabase, alias);
  }
}

class ModeAppRow extends DataClass implements Insertable<ModeAppRow> {
  final String modeId;
  final String appId;
  final String label;
  const ModeAppRow({
    required this.modeId,
    required this.appId,
    required this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mode_id'] = Variable<String>(modeId);
    map['app_id'] = Variable<String>(appId);
    map['label'] = Variable<String>(label);
    return map;
  }

  ModeAppsCompanion toCompanion(bool nullToAbsent) {
    return ModeAppsCompanion(
      modeId: Value(modeId),
      appId: Value(appId),
      label: Value(label),
    );
  }

  factory ModeAppRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ModeAppRow(
      modeId: serializer.fromJson<String>(json['modeId']),
      appId: serializer.fromJson<String>(json['appId']),
      label: serializer.fromJson<String>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modeId': serializer.toJson<String>(modeId),
      'appId': serializer.toJson<String>(appId),
      'label': serializer.toJson<String>(label),
    };
  }

  ModeAppRow copyWith({String? modeId, String? appId, String? label}) =>
      ModeAppRow(
        modeId: modeId ?? this.modeId,
        appId: appId ?? this.appId,
        label: label ?? this.label,
      );
  ModeAppRow copyWithCompanion(ModeAppsCompanion data) {
    return ModeAppRow(
      modeId: data.modeId.present ? data.modeId.value : this.modeId,
      appId: data.appId.present ? data.appId.value : this.appId,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ModeAppRow(')
          ..write('modeId: $modeId, ')
          ..write('appId: $appId, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(modeId, appId, label);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ModeAppRow &&
          other.modeId == this.modeId &&
          other.appId == this.appId &&
          other.label == this.label);
}

class ModeAppsCompanion extends UpdateCompanion<ModeAppRow> {
  final Value<String> modeId;
  final Value<String> appId;
  final Value<String> label;
  final Value<int> rowid;
  const ModeAppsCompanion({
    this.modeId = const Value.absent(),
    this.appId = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ModeAppsCompanion.insert({
    required String modeId,
    required String appId,
    required String label,
    this.rowid = const Value.absent(),
  }) : modeId = Value(modeId),
       appId = Value(appId),
       label = Value(label);
  static Insertable<ModeAppRow> custom({
    Expression<String>? modeId,
    Expression<String>? appId,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modeId != null) 'mode_id': modeId,
      if (appId != null) 'app_id': appId,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ModeAppsCompanion copyWith({
    Value<String>? modeId,
    Value<String>? appId,
    Value<String>? label,
    Value<int>? rowid,
  }) {
    return ModeAppsCompanion(
      modeId: modeId ?? this.modeId,
      appId: appId ?? this.appId,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modeId.present) {
      map['mode_id'] = Variable<String>(modeId.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ModeAppsCompanion(')
          ..write('modeId: $modeId, ')
          ..write('appId: $appId, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $ModesTable modes = $ModesTable(this);
  late final $LimitRulesTable limitRules = $LimitRulesTable(this);
  late final $ModeAppsTable modeApps = $ModeAppsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settingsEntries,
    modes,
    limitRules,
    modeApps,
  ];
}

typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
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
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
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
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
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
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SettingsEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SettingsEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;
typedef $$ModesTableCreateCompanionBuilder =
    ModesCompanion Function({
      required String id,
      required String name,
      required int durationMinutes,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ModesTableUpdateCompanionBuilder =
    ModesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> durationMinutes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ModesTableFilterComposer extends Composer<_$AppDatabase, $ModesTable> {
  $$ModesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModesTableOrderingComposer
    extends Composer<_$AppDatabase, $ModesTable> {
  $$ModesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModesTable> {
  $$ModesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ModesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModesTable,
          ModeRow,
          $$ModesTableFilterComposer,
          $$ModesTableOrderingComposer,
          $$ModesTableAnnotationComposer,
          $$ModesTableCreateCompanionBuilder,
          $$ModesTableUpdateCompanionBuilder,
          (ModeRow, BaseReferences<_$AppDatabase, $ModesTable, ModeRow>),
          ModeRow,
          PrefetchHooks Function()
        > {
  $$ModesTableTableManager(_$AppDatabase db, $ModesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ModesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ModesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ModesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModesCompanion(
                id: id,
                name: name,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int durationMinutes,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ModesCompanion.insert(
                id: id,
                name: name,
                durationMinutes: durationMinutes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModesTable,
      ModeRow,
      $$ModesTableFilterComposer,
      $$ModesTableOrderingComposer,
      $$ModesTableAnnotationComposer,
      $$ModesTableCreateCompanionBuilder,
      $$ModesTableUpdateCompanionBuilder,
      (ModeRow, BaseReferences<_$AppDatabase, $ModesTable, ModeRow>),
      ModeRow,
      PrefetchHooks Function()
    >;
typedef $$LimitRulesTableCreateCompanionBuilder =
    LimitRulesCompanion Function({
      required String appId,
      required String label,
      required int dailyLimitMinutes,
      Value<bool> enabled,
      Value<int> rowid,
    });
typedef $$LimitRulesTableUpdateCompanionBuilder =
    LimitRulesCompanion Function({
      Value<String> appId,
      Value<String> label,
      Value<int> dailyLimitMinutes,
      Value<bool> enabled,
      Value<int> rowid,
    });

class $$LimitRulesTableFilterComposer
    extends Composer<_$AppDatabase, $LimitRulesTable> {
  $$LimitRulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LimitRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $LimitRulesTable> {
  $$LimitRulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LimitRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LimitRulesTable> {
  $$LimitRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get dailyLimitMinutes => $composableBuilder(
    column: $table.dailyLimitMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);
}

class $$LimitRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LimitRulesTable,
          LimitRow,
          $$LimitRulesTableFilterComposer,
          $$LimitRulesTableOrderingComposer,
          $$LimitRulesTableAnnotationComposer,
          $$LimitRulesTableCreateCompanionBuilder,
          $$LimitRulesTableUpdateCompanionBuilder,
          (LimitRow, BaseReferences<_$AppDatabase, $LimitRulesTable, LimitRow>),
          LimitRow,
          PrefetchHooks Function()
        > {
  $$LimitRulesTableTableManager(_$AppDatabase db, $LimitRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$LimitRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$LimitRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$LimitRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> appId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> dailyLimitMinutes = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LimitRulesCompanion(
                appId: appId,
                label: label,
                dailyLimitMinutes: dailyLimitMinutes,
                enabled: enabled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String appId,
                required String label,
                required int dailyLimitMinutes,
                Value<bool> enabled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LimitRulesCompanion.insert(
                appId: appId,
                label: label,
                dailyLimitMinutes: dailyLimitMinutes,
                enabled: enabled,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LimitRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LimitRulesTable,
      LimitRow,
      $$LimitRulesTableFilterComposer,
      $$LimitRulesTableOrderingComposer,
      $$LimitRulesTableAnnotationComposer,
      $$LimitRulesTableCreateCompanionBuilder,
      $$LimitRulesTableUpdateCompanionBuilder,
      (LimitRow, BaseReferences<_$AppDatabase, $LimitRulesTable, LimitRow>),
      LimitRow,
      PrefetchHooks Function()
    >;
typedef $$ModeAppsTableCreateCompanionBuilder =
    ModeAppsCompanion Function({
      required String modeId,
      required String appId,
      required String label,
      Value<int> rowid,
    });
typedef $$ModeAppsTableUpdateCompanionBuilder =
    ModeAppsCompanion Function({
      Value<String> modeId,
      Value<String> appId,
      Value<String> label,
      Value<int> rowid,
    });

class $$ModeAppsTableFilterComposer
    extends Composer<_$AppDatabase, $ModeAppsTable> {
  $$ModeAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ModeAppsTableOrderingComposer
    extends Composer<_$AppDatabase, $ModeAppsTable> {
  $$ModeAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get modeId => $composableBuilder(
    column: $table.modeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ModeAppsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ModeAppsTable> {
  $$ModeAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get modeId =>
      $composableBuilder(column: $table.modeId, builder: (column) => column);

  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$ModeAppsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ModeAppsTable,
          ModeAppRow,
          $$ModeAppsTableFilterComposer,
          $$ModeAppsTableOrderingComposer,
          $$ModeAppsTableAnnotationComposer,
          $$ModeAppsTableCreateCompanionBuilder,
          $$ModeAppsTableUpdateCompanionBuilder,
          (
            ModeAppRow,
            BaseReferences<_$AppDatabase, $ModeAppsTable, ModeAppRow>,
          ),
          ModeAppRow,
          PrefetchHooks Function()
        > {
  $$ModeAppsTableTableManager(_$AppDatabase db, $ModeAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ModeAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ModeAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ModeAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> modeId = const Value.absent(),
                Value<String> appId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ModeAppsCompanion(
                modeId: modeId,
                appId: appId,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String modeId,
                required String appId,
                required String label,
                Value<int> rowid = const Value.absent(),
              }) => ModeAppsCompanion.insert(
                modeId: modeId,
                appId: appId,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ModeAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ModeAppsTable,
      ModeAppRow,
      $$ModeAppsTableFilterComposer,
      $$ModeAppsTableOrderingComposer,
      $$ModeAppsTableAnnotationComposer,
      $$ModeAppsTableCreateCompanionBuilder,
      $$ModeAppsTableUpdateCompanionBuilder,
      (ModeAppRow, BaseReferences<_$AppDatabase, $ModeAppsTable, ModeAppRow>),
      ModeAppRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$ModesTableTableManager get modes =>
      $$ModesTableTableManager(_db, _db.modes);
  $$LimitRulesTableTableManager get limitRules =>
      $$LimitRulesTableTableManager(_db, _db.limitRules);
  $$ModeAppsTableTableManager get modeApps =>
      $$ModeAppsTableTableManager(_db, _db.modeApps);
}
