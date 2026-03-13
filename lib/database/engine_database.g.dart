// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'engine_database.dart';

// ignore_for_file: type=lint
class Workspaces extends Table with TableInfo<Workspaces, Workspace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Workspaces(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _projectPathMeta = const VerificationMeta(
    'projectPath',
  );
  late final GeneratedColumn<String> projectPath = GeneratedColumn<String>(
    'project_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    projectPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workspace> instance, {
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
    if (data.containsKey('project_path')) {
      context.handle(
        _projectPathMeta,
        projectPath.isAcceptableOrUnknown(
          data['project_path']!,
          _projectPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectPathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workspace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workspace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      projectPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Workspaces createAlias(String alias) {
    return Workspaces(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Workspace extends DataClass implements Insertable<Workspace> {
  final String id;
  final String name;
  final String projectPath;
  final String createdAt;
  final String updatedAt;
  const Workspace({
    required this.id,
    required this.name,
    required this.projectPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['project_path'] = Variable<String>(projectPath);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      projectPath: Value(projectPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Workspace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workspace(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      projectPath: serializer.fromJson<String>(json['project_path']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'project_path': serializer.toJson<String>(projectPath),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  Workspace copyWith({
    String? id,
    String? name,
    String? projectPath,
    String? createdAt,
    String? updatedAt,
  }) => Workspace(
    id: id ?? this.id,
    name: name ?? this.name,
    projectPath: projectPath ?? this.projectPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Workspace copyWithCompanion(WorkspacesCompanion data) {
    return Workspace(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      projectPath: data.projectPath.present
          ? data.projectPath.value
          : this.projectPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workspace(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectPath: $projectPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, projectPath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workspace &&
          other.id == this.id &&
          other.name == this.name &&
          other.projectPath == this.projectPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkspacesCompanion extends UpdateCompanion<Workspace> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> projectPath;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.projectPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    required String projectPath,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       projectPath = Value(projectPath);
  static Insertable<Workspace> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? projectPath,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (projectPath != null) 'project_path': projectPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? projectPath,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (projectPath.present) {
      map['project_path'] = Variable<String>(projectPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('projectPath: $projectPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceRuns extends Table with TableInfo<WorkspaceRuns, WorkspaceRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceRuns(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspaces(id)',
  );
  static const VerificationMeta _runNumberMeta = const VerificationMeta(
    'runNumber',
  );
  late final GeneratedColumn<int> runNumber = GeneratedColumn<int>(
    'run_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'starting\'',
    defaultValue: const CustomExpression('\'starting\''),
  );
  static const VerificationMeta _containerIdMeta = const VerificationMeta(
    'containerId',
  );
  late final GeneratedColumn<String> containerId = GeneratedColumn<String>(
    'container_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serverPortMeta = const VerificationMeta(
    'serverPort',
  );
  late final GeneratedColumn<int> serverPort = GeneratedColumn<int>(
    'server_port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _apiKeyMeta = const VerificationMeta('apiKey');
  late final GeneratedColumn<String> apiKey = GeneratedColumn<String>(
    'api_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<String> startedAt = GeneratedColumn<String>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _stoppedAtMeta = const VerificationMeta(
    'stoppedAt',
  );
  late final GeneratedColumn<String> stoppedAt = GeneratedColumn<String>(
    'stopped_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    runNumber,
    status,
    containerId,
    serverPort,
    apiKey,
    startedAt,
    stoppedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('run_number')) {
      context.handle(
        _runNumberMeta,
        runNumber.isAcceptableOrUnknown(data['run_number']!, _runNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_runNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('container_id')) {
      context.handle(
        _containerIdMeta,
        containerId.isAcceptableOrUnknown(
          data['container_id']!,
          _containerIdMeta,
        ),
      );
    }
    if (data.containsKey('server_port')) {
      context.handle(
        _serverPortMeta,
        serverPort.isAcceptableOrUnknown(data['server_port']!, _serverPortMeta),
      );
    }
    if (data.containsKey('api_key')) {
      context.handle(
        _apiKeyMeta,
        apiKey.isAcceptableOrUnknown(data['api_key']!, _apiKeyMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('stopped_at')) {
      context.handle(
        _stoppedAtMeta,
        stoppedAt.isAcceptableOrUnknown(data['stopped_at']!, _stoppedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRun(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      runNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}run_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      containerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_id'],
      ),
      serverPort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_port'],
      ),
      apiKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_key'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}started_at'],
      )!,
      stoppedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stopped_at'],
      ),
    );
  }

  @override
  WorkspaceRuns createAlias(String alias) {
    return WorkspaceRuns(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceRun extends DataClass implements Insertable<WorkspaceRun> {
  final String id;
  final String workspaceId;
  final int runNumber;
  final String status;
  final String? containerId;
  final int? serverPort;
  final String? apiKey;
  final String startedAt;
  final String? stoppedAt;
  const WorkspaceRun({
    required this.id,
    required this.workspaceId,
    required this.runNumber,
    required this.status,
    this.containerId,
    this.serverPort,
    this.apiKey,
    required this.startedAt,
    this.stoppedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['run_number'] = Variable<int>(runNumber);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || containerId != null) {
      map['container_id'] = Variable<String>(containerId);
    }
    if (!nullToAbsent || serverPort != null) {
      map['server_port'] = Variable<int>(serverPort);
    }
    if (!nullToAbsent || apiKey != null) {
      map['api_key'] = Variable<String>(apiKey);
    }
    map['started_at'] = Variable<String>(startedAt);
    if (!nullToAbsent || stoppedAt != null) {
      map['stopped_at'] = Variable<String>(stoppedAt);
    }
    return map;
  }

  WorkspaceRunsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceRunsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      runNumber: Value(runNumber),
      status: Value(status),
      containerId: containerId == null && nullToAbsent
          ? const Value.absent()
          : Value(containerId),
      serverPort: serverPort == null && nullToAbsent
          ? const Value.absent()
          : Value(serverPort),
      apiKey: apiKey == null && nullToAbsent
          ? const Value.absent()
          : Value(apiKey),
      startedAt: Value(startedAt),
      stoppedAt: stoppedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(stoppedAt),
    );
  }

  factory WorkspaceRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRun(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspace_id']),
      runNumber: serializer.fromJson<int>(json['run_number']),
      status: serializer.fromJson<String>(json['status']),
      containerId: serializer.fromJson<String?>(json['container_id']),
      serverPort: serializer.fromJson<int?>(json['server_port']),
      apiKey: serializer.fromJson<String?>(json['api_key']),
      startedAt: serializer.fromJson<String>(json['started_at']),
      stoppedAt: serializer.fromJson<String?>(json['stopped_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspace_id': serializer.toJson<String>(workspaceId),
      'run_number': serializer.toJson<int>(runNumber),
      'status': serializer.toJson<String>(status),
      'container_id': serializer.toJson<String?>(containerId),
      'server_port': serializer.toJson<int?>(serverPort),
      'api_key': serializer.toJson<String?>(apiKey),
      'started_at': serializer.toJson<String>(startedAt),
      'stopped_at': serializer.toJson<String?>(stoppedAt),
    };
  }

  WorkspaceRun copyWith({
    String? id,
    String? workspaceId,
    int? runNumber,
    String? status,
    Value<String?> containerId = const Value.absent(),
    Value<int?> serverPort = const Value.absent(),
    Value<String?> apiKey = const Value.absent(),
    String? startedAt,
    Value<String?> stoppedAt = const Value.absent(),
  }) => WorkspaceRun(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    runNumber: runNumber ?? this.runNumber,
    status: status ?? this.status,
    containerId: containerId.present ? containerId.value : this.containerId,
    serverPort: serverPort.present ? serverPort.value : this.serverPort,
    apiKey: apiKey.present ? apiKey.value : this.apiKey,
    startedAt: startedAt ?? this.startedAt,
    stoppedAt: stoppedAt.present ? stoppedAt.value : this.stoppedAt,
  );
  WorkspaceRun copyWithCompanion(WorkspaceRunsCompanion data) {
    return WorkspaceRun(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      runNumber: data.runNumber.present ? data.runNumber.value : this.runNumber,
      status: data.status.present ? data.status.value : this.status,
      containerId: data.containerId.present
          ? data.containerId.value
          : this.containerId,
      serverPort: data.serverPort.present
          ? data.serverPort.value
          : this.serverPort,
      apiKey: data.apiKey.present ? data.apiKey.value : this.apiKey,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      stoppedAt: data.stoppedAt.present ? data.stoppedAt.value : this.stoppedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRun(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('runNumber: $runNumber, ')
          ..write('status: $status, ')
          ..write('containerId: $containerId, ')
          ..write('serverPort: $serverPort, ')
          ..write('apiKey: $apiKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('stoppedAt: $stoppedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    runNumber,
    status,
    containerId,
    serverPort,
    apiKey,
    startedAt,
    stoppedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRun &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.runNumber == this.runNumber &&
          other.status == this.status &&
          other.containerId == this.containerId &&
          other.serverPort == this.serverPort &&
          other.apiKey == this.apiKey &&
          other.startedAt == this.startedAt &&
          other.stoppedAt == this.stoppedAt);
}

class WorkspaceRunsCompanion extends UpdateCompanion<WorkspaceRun> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<int> runNumber;
  final Value<String> status;
  final Value<String?> containerId;
  final Value<int?> serverPort;
  final Value<String?> apiKey;
  final Value<String> startedAt;
  final Value<String?> stoppedAt;
  final Value<int> rowid;
  const WorkspaceRunsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.runNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.containerId = const Value.absent(),
    this.serverPort = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceRunsCompanion.insert({
    required String id,
    required String workspaceId,
    required int runNumber,
    this.status = const Value.absent(),
    this.containerId = const Value.absent(),
    this.serverPort = const Value.absent(),
    this.apiKey = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.stoppedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       runNumber = Value(runNumber);
  static Insertable<WorkspaceRun> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<int>? runNumber,
    Expression<String>? status,
    Expression<String>? containerId,
    Expression<int>? serverPort,
    Expression<String>? apiKey,
    Expression<String>? startedAt,
    Expression<String>? stoppedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (runNumber != null) 'run_number': runNumber,
      if (status != null) 'status': status,
      if (containerId != null) 'container_id': containerId,
      if (serverPort != null) 'server_port': serverPort,
      if (apiKey != null) 'api_key': apiKey,
      if (startedAt != null) 'started_at': startedAt,
      if (stoppedAt != null) 'stopped_at': stoppedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceRunsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<int>? runNumber,
    Value<String>? status,
    Value<String?>? containerId,
    Value<int?>? serverPort,
    Value<String?>? apiKey,
    Value<String>? startedAt,
    Value<String?>? stoppedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceRunsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      runNumber: runNumber ?? this.runNumber,
      status: status ?? this.status,
      containerId: containerId ?? this.containerId,
      serverPort: serverPort ?? this.serverPort,
      apiKey: apiKey ?? this.apiKey,
      startedAt: startedAt ?? this.startedAt,
      stoppedAt: stoppedAt ?? this.stoppedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (runNumber.present) {
      map['run_number'] = Variable<int>(runNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (containerId.present) {
      map['container_id'] = Variable<String>(containerId.value);
    }
    if (serverPort.present) {
      map['server_port'] = Variable<int>(serverPort.value);
    }
    if (apiKey.present) {
      map['api_key'] = Variable<String>(apiKey.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<String>(startedAt.value);
    }
    if (stoppedAt.present) {
      map['stopped_at'] = Variable<String>(stoppedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRunsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('runNumber: $runNumber, ')
          ..write('status: $status, ')
          ..write('containerId: $containerId, ')
          ..write('serverPort: $serverPort, ')
          ..write('apiKey: $apiKey, ')
          ..write('startedAt: $startedAt, ')
          ..write('stoppedAt: $stoppedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceAgents extends Table
    with TableInfo<WorkspaceAgents, WorkspaceAgent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceAgents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _chainJsonMeta = const VerificationMeta(
    'chainJson',
  );
  late final GeneratedColumn<String> chainJson = GeneratedColumn<String>(
    'chain_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'disconnected\'',
    defaultValue: const CustomExpression('\'disconnected\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    displayName,
    chainJson,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_agents';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceAgent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('chain_json')) {
      context.handle(
        _chainJsonMeta,
        chainJson.isAcceptableOrUnknown(data['chain_json']!, _chainJsonMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceAgent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceAgent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      chainJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  WorkspaceAgents createAlias(String alias) {
    return WorkspaceAgents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceAgent extends DataClass implements Insertable<WorkspaceAgent> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String displayName;
  final String chainJson;
  final String status;
  final String createdAt;
  final String updatedAt;
  const WorkspaceAgent({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    required this.displayName,
    required this.chainJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    map['display_name'] = Variable<String>(displayName);
    map['chain_json'] = Variable<String>(chainJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WorkspaceAgentsCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceAgentsCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      displayName: Value(displayName),
      chainJson: Value(chainJson),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkspaceAgent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceAgent(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      chainJson: serializer.fromJson<String>(json['chain_json']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'display_name': serializer.toJson<String>(displayName),
      'chain_json': serializer.toJson<String>(chainJson),
      'status': serializer.toJson<String>(status),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  WorkspaceAgent copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    String? displayName,
    String? chainJson,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) => WorkspaceAgent(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    displayName: displayName ?? this.displayName,
    chainJson: chainJson ?? this.chainJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkspaceAgent copyWithCompanion(WorkspaceAgentsCompanion data) {
    return WorkspaceAgent(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      chainJson: data.chainJson.present ? data.chainJson.value : this.chainJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceAgent(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('displayName: $displayName, ')
          ..write('chainJson: $chainJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    displayName,
    chainJson,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceAgent &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.displayName == this.displayName &&
          other.chainJson == this.chainJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkspaceAgentsCompanion extends UpdateCompanion<WorkspaceAgent> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String> displayName;
  final Value<String> chainJson;
  final Value<String> status;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WorkspaceAgentsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.chainJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceAgentsCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    required String displayName,
    this.chainJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       displayName = Value(displayName);
  static Insertable<WorkspaceAgent> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? displayName,
    Expression<String>? chainJson,
    Expression<String>? status,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (displayName != null) 'display_name': displayName,
      if (chainJson != null) 'chain_json': chainJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceAgentsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String>? displayName,
    Value<String>? chainJson,
    Value<String>? status,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceAgentsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      displayName: displayName ?? this.displayName,
      chainJson: chainJson ?? this.chainJson,
      status: status ?? this.status,
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
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (chainJson.present) {
      map['chain_json'] = Variable<String>(chainJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceAgentsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('displayName: $displayName, ')
          ..write('chainJson: $chainJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentMessages extends Table with TableInfo<AgentMessages, AgentMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentMessages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _senderNameMeta = const VerificationMeta(
    'senderName',
  );
  late final GeneratedColumn<String> senderName = GeneratedColumn<String>(
    'sender_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    role,
    content,
    model,
    inputTokens,
    outputTokens,
    instanceId,
    turnId,
    senderName,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('sender_name')) {
      context.handle(
        _senderNameMeta,
        senderName.isAcceptableOrUnknown(data['sender_name']!, _senderNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      ),
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      ),
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      senderName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  AgentMessages createAlias(String alias) {
    return AgentMessages(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentMessage extends DataClass implements Insertable<AgentMessage> {
  final String id;
  final String runId;
  final String role;
  final String content;
  final String? model;
  final int? inputTokens;
  final int? outputTokens;
  final String instanceId;
  final String? turnId;
  final String? senderName;
  final String createdAt;
  const AgentMessage({
    required this.id,
    required this.runId,
    required this.role,
    required this.content,
    this.model,
    this.inputTokens,
    this.outputTokens,
    required this.instanceId,
    this.turnId,
    this.senderName,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['role'] = Variable<String>(role);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || inputTokens != null) {
      map['input_tokens'] = Variable<int>(inputTokens);
    }
    if (!nullToAbsent || outputTokens != null) {
      map['output_tokens'] = Variable<int>(outputTokens);
    }
    map['instance_id'] = Variable<String>(instanceId);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    if (!nullToAbsent || senderName != null) {
      map['sender_name'] = Variable<String>(senderName);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  AgentMessagesCompanion toCompanion(bool nullToAbsent) {
    return AgentMessagesCompanion(
      id: Value(id),
      runId: Value(runId),
      role: Value(role),
      content: Value(content),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      inputTokens: inputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(inputTokens),
      outputTokens: outputTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(outputTokens),
      instanceId: Value(instanceId),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      senderName: senderName == null && nullToAbsent
          ? const Value.absent()
          : Value(senderName),
      createdAt: Value(createdAt),
    );
  }

  factory AgentMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentMessage(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      role: serializer.fromJson<String>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      model: serializer.fromJson<String?>(json['model']),
      inputTokens: serializer.fromJson<int?>(json['input_tokens']),
      outputTokens: serializer.fromJson<int?>(json['output_tokens']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String?>(json['turn_id']),
      senderName: serializer.fromJson<String?>(json['sender_name']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'role': serializer.toJson<String>(role),
      'content': serializer.toJson<String>(content),
      'model': serializer.toJson<String?>(model),
      'input_tokens': serializer.toJson<int?>(inputTokens),
      'output_tokens': serializer.toJson<int?>(outputTokens),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String?>(turnId),
      'sender_name': serializer.toJson<String?>(senderName),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  AgentMessage copyWith({
    String? id,
    String? runId,
    String? role,
    String? content,
    Value<String?> model = const Value.absent(),
    Value<int?> inputTokens = const Value.absent(),
    Value<int?> outputTokens = const Value.absent(),
    String? instanceId,
    Value<String?> turnId = const Value.absent(),
    Value<String?> senderName = const Value.absent(),
    String? createdAt,
  }) => AgentMessage(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    role: role ?? this.role,
    content: content ?? this.content,
    model: model.present ? model.value : this.model,
    inputTokens: inputTokens.present ? inputTokens.value : this.inputTokens,
    outputTokens: outputTokens.present ? outputTokens.value : this.outputTokens,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId.present ? turnId.value : this.turnId,
    senderName: senderName.present ? senderName.value : this.senderName,
    createdAt: createdAt ?? this.createdAt,
  );
  AgentMessage copyWithCompanion(AgentMessagesCompanion data) {
    return AgentMessage(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      model: data.model.present ? data.model.value : this.model,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      senderName: data.senderName.present
          ? data.senderName.value
          : this.senderName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentMessage(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('senderName: $senderName, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    role,
    content,
    model,
    inputTokens,
    outputTokens,
    instanceId,
    turnId,
    senderName,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentMessage &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.role == this.role &&
          other.content == this.content &&
          other.model == this.model &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.senderName == this.senderName &&
          other.createdAt == this.createdAt);
}

class AgentMessagesCompanion extends UpdateCompanion<AgentMessage> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> role;
  final Value<String> content;
  final Value<String?> model;
  final Value<int?> inputTokens;
  final Value<int?> outputTokens;
  final Value<String> instanceId;
  final Value<String?> turnId;
  final Value<String?> senderName;
  final Value<String> createdAt;
  final Value<int> rowid;
  const AgentMessagesCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.model = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentMessagesCompanion.insert({
    required String id,
    required String runId,
    required String role,
    required String content,
    this.model = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    required String instanceId,
    this.turnId = const Value.absent(),
    this.senderName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       role = Value(role),
       content = Value(content),
       instanceId = Value(instanceId);
  static Insertable<AgentMessage> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? role,
    Expression<String>? content,
    Expression<String>? model,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? senderName,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (model != null) 'model': model,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (senderName != null) 'sender_name': senderName,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? role,
    Value<String>? content,
    Value<String?>? model,
    Value<int?>? inputTokens,
    Value<int?>? outputTokens,
    Value<String>? instanceId,
    Value<String?>? turnId,
    Value<String?>? senderName,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return AgentMessagesCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      role: role ?? this.role,
      content: content ?? this.content,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      senderName: senderName ?? this.senderName,
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
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (senderName.present) {
      map['sender_name'] = Variable<String>(senderName.value);
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
    return (StringBuffer('AgentMessagesCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('senderName: $senderName, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentLogs extends Table with TableInfo<AgentLogs, AgentLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentLogs(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    level,
    message,
    source,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  AgentLogs createAlias(String alias) {
    return AgentLogs(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentLog extends DataClass implements Insertable<AgentLog> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String? turnId;
  final String level;
  final String message;
  final String source;
  final String timestamp;
  const AgentLog({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    this.turnId,
    required this.level,
    required this.message,
    required this.source,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    map['level'] = Variable<String>(level);
    map['message'] = Variable<String>(message);
    map['source'] = Variable<String>(source);
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  AgentLogsCompanion toCompanion(bool nullToAbsent) {
    return AgentLogsCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      level: Value(level),
      message: Value(message),
      source: Value(source),
      timestamp: Value(timestamp),
    );
  }

  factory AgentLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentLog(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String?>(json['turn_id']),
      level: serializer.fromJson<String>(json['level']),
      message: serializer.fromJson<String>(json['message']),
      source: serializer.fromJson<String>(json['source']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String?>(turnId),
      'level': serializer.toJson<String>(level),
      'message': serializer.toJson<String>(message),
      'source': serializer.toJson<String>(source),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  AgentLog copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    Value<String?> turnId = const Value.absent(),
    String? level,
    String? message,
    String? source,
    String? timestamp,
  }) => AgentLog(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId.present ? turnId.value : this.turnId,
    level: level ?? this.level,
    message: message ?? this.message,
    source: source ?? this.source,
    timestamp: timestamp ?? this.timestamp,
  );
  AgentLog copyWithCompanion(AgentLogsCompanion data) {
    return AgentLog(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      level: data.level.present ? data.level.value : this.level,
      message: data.message.present ? data.message.value : this.message,
      source: data.source.present ? data.source.value : this.source,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentLog(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('source: $source, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    level,
    message,
    source,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentLog &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.level == this.level &&
          other.message == this.message &&
          other.source == this.source &&
          other.timestamp == this.timestamp);
}

class AgentLogsCompanion extends UpdateCompanion<AgentLog> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String?> turnId;
  final Value<String> level;
  final Value<String> message;
  final Value<String> source;
  final Value<String> timestamp;
  final Value<int> rowid;
  const AgentLogsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.level = const Value.absent(),
    this.message = const Value.absent(),
    this.source = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentLogsCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    this.turnId = const Value.absent(),
    required String level,
    required String message,
    required String source,
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       level = Value(level),
       message = Value(message),
       source = Value(source);
  static Insertable<AgentLog> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? level,
    Expression<String>? message,
    Expression<String>? source,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (level != null) 'level': level,
      if (message != null) 'message': message,
      if (source != null) 'source': source,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String?>? turnId,
    Value<String>? level,
    Value<String>? message,
    Value<String>? source,
    Value<String>? timestamp,
    Value<int>? rowid,
  }) {
    return AgentLogsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      level: level ?? this.level,
      message: message ?? this.message,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentLogsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('level: $level, ')
          ..write('message: $message, ')
          ..write('source: $source, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentActivityEvents extends Table
    with TableInfo<AgentActivityEvents, AgentActivityEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentActivityEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    eventType,
    dataJson,
    content,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_activity_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentActivityEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentActivityEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentActivityEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  AgentActivityEvents createAlias(String alias) {
    return AgentActivityEvents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentActivityEvent extends DataClass
    implements Insertable<AgentActivityEvent> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String? turnId;
  final String eventType;
  final String? dataJson;
  final String? content;
  final String timestamp;
  const AgentActivityEvent({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    this.turnId,
    required this.eventType,
    this.dataJson,
    this.content,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || dataJson != null) {
      map['data_json'] = Variable<String>(dataJson);
    }
    if (!nullToAbsent || content != null) {
      map['content'] = Variable<String>(content);
    }
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  AgentActivityEventsCompanion toCompanion(bool nullToAbsent) {
    return AgentActivityEventsCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      eventType: Value(eventType),
      dataJson: dataJson == null && nullToAbsent
          ? const Value.absent()
          : Value(dataJson),
      content: content == null && nullToAbsent
          ? const Value.absent()
          : Value(content),
      timestamp: Value(timestamp),
    );
  }

  factory AgentActivityEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentActivityEvent(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String?>(json['turn_id']),
      eventType: serializer.fromJson<String>(json['event_type']),
      dataJson: serializer.fromJson<String?>(json['data_json']),
      content: serializer.fromJson<String?>(json['content']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String?>(turnId),
      'event_type': serializer.toJson<String>(eventType),
      'data_json': serializer.toJson<String?>(dataJson),
      'content': serializer.toJson<String?>(content),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  AgentActivityEvent copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    Value<String?> turnId = const Value.absent(),
    String? eventType,
    Value<String?> dataJson = const Value.absent(),
    Value<String?> content = const Value.absent(),
    String? timestamp,
  }) => AgentActivityEvent(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId.present ? turnId.value : this.turnId,
    eventType: eventType ?? this.eventType,
    dataJson: dataJson.present ? dataJson.value : this.dataJson,
    content: content.present ? content.value : this.content,
    timestamp: timestamp ?? this.timestamp,
  );
  AgentActivityEvent copyWithCompanion(AgentActivityEventsCompanion data) {
    return AgentActivityEvent(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentActivityEvent(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('eventType: $eventType, ')
          ..write('dataJson: $dataJson, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    eventType,
    dataJson,
    content,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentActivityEvent &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.eventType == this.eventType &&
          other.dataJson == this.dataJson &&
          other.content == this.content &&
          other.timestamp == this.timestamp);
}

class AgentActivityEventsCompanion extends UpdateCompanion<AgentActivityEvent> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String?> turnId;
  final Value<String> eventType;
  final Value<String?> dataJson;
  final Value<String?> content;
  final Value<String> timestamp;
  final Value<int> rowid;
  const AgentActivityEventsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentActivityEventsCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    this.turnId = const Value.absent(),
    required String eventType,
    this.dataJson = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       eventType = Value(eventType);
  static Insertable<AgentActivityEvent> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? eventType,
    Expression<String>? dataJson,
    Expression<String>? content,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (eventType != null) 'event_type': eventType,
      if (dataJson != null) 'data_json': dataJson,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentActivityEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String?>? turnId,
    Value<String>? eventType,
    Value<String?>? dataJson,
    Value<String?>? content,
    Value<String>? timestamp,
    Value<int>? rowid,
  }) {
    return AgentActivityEventsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      eventType: eventType ?? this.eventType,
      dataJson: dataJson ?? this.dataJson,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentActivityEventsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('eventType: $eventType, ')
          ..write('dataJson: $dataJson, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentUsageRecords extends Table
    with TableInfo<AgentUsageRecords, AgentUsageRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentUsageRecords(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _inputTokensMeta = const VerificationMeta(
    'inputTokens',
  );
  late final GeneratedColumn<int> inputTokens = GeneratedColumn<int>(
    'input_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _outputTokensMeta = const VerificationMeta(
    'outputTokens',
  );
  late final GeneratedColumn<int> outputTokens = GeneratedColumn<int>(
    'output_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cacheReadTokensMeta = const VerificationMeta(
    'cacheReadTokens',
  );
  late final GeneratedColumn<int> cacheReadTokens = GeneratedColumn<int>(
    'cache_read_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _cacheWriteTokensMeta = const VerificationMeta(
    'cacheWriteTokens',
  );
  late final GeneratedColumn<int> cacheWriteTokens = GeneratedColumn<int>(
    'cache_write_tokens',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _costUsdMeta = const VerificationMeta(
    'costUsd',
  );
  late final GeneratedColumn<double> costUsd = GeneratedColumn<double>(
    'cost_usd',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    model,
    inputTokens,
    outputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    costUsd,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_usage_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentUsageRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('input_tokens')) {
      context.handle(
        _inputTokensMeta,
        inputTokens.isAcceptableOrUnknown(
          data['input_tokens']!,
          _inputTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputTokensMeta);
    }
    if (data.containsKey('output_tokens')) {
      context.handle(
        _outputTokensMeta,
        outputTokens.isAcceptableOrUnknown(
          data['output_tokens']!,
          _outputTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_outputTokensMeta);
    }
    if (data.containsKey('cache_read_tokens')) {
      context.handle(
        _cacheReadTokensMeta,
        cacheReadTokens.isAcceptableOrUnknown(
          data['cache_read_tokens']!,
          _cacheReadTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheReadTokensMeta);
    }
    if (data.containsKey('cache_write_tokens')) {
      context.handle(
        _cacheWriteTokensMeta,
        cacheWriteTokens.isAcceptableOrUnknown(
          data['cache_write_tokens']!,
          _cacheWriteTokensMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cacheWriteTokensMeta);
    }
    if (data.containsKey('cost_usd')) {
      context.handle(
        _costUsdMeta,
        costUsd.isAcceptableOrUnknown(data['cost_usd']!, _costUsdMeta),
      );
    } else if (isInserting) {
      context.missing(_costUsdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentUsageRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentUsageRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      inputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}input_tokens'],
      )!,
      outputTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}output_tokens'],
      )!,
      cacheReadTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_read_tokens'],
      )!,
      cacheWriteTokens: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cache_write_tokens'],
      )!,
      costUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cost_usd'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  AgentUsageRecords createAlias(String alias) {
    return AgentUsageRecords(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentUsageRecord extends DataClass
    implements Insertable<AgentUsageRecord> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String? turnId;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final int cacheReadTokens;
  final int cacheWriteTokens;
  final double costUsd;
  final String timestamp;
  const AgentUsageRecord({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    this.turnId,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    required this.cacheReadTokens,
    required this.cacheWriteTokens,
    required this.costUsd,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    map['model'] = Variable<String>(model);
    map['input_tokens'] = Variable<int>(inputTokens);
    map['output_tokens'] = Variable<int>(outputTokens);
    map['cache_read_tokens'] = Variable<int>(cacheReadTokens);
    map['cache_write_tokens'] = Variable<int>(cacheWriteTokens);
    map['cost_usd'] = Variable<double>(costUsd);
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  AgentUsageRecordsCompanion toCompanion(bool nullToAbsent) {
    return AgentUsageRecordsCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      model: Value(model),
      inputTokens: Value(inputTokens),
      outputTokens: Value(outputTokens),
      cacheReadTokens: Value(cacheReadTokens),
      cacheWriteTokens: Value(cacheWriteTokens),
      costUsd: Value(costUsd),
      timestamp: Value(timestamp),
    );
  }

  factory AgentUsageRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentUsageRecord(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String?>(json['turn_id']),
      model: serializer.fromJson<String>(json['model']),
      inputTokens: serializer.fromJson<int>(json['input_tokens']),
      outputTokens: serializer.fromJson<int>(json['output_tokens']),
      cacheReadTokens: serializer.fromJson<int>(json['cache_read_tokens']),
      cacheWriteTokens: serializer.fromJson<int>(json['cache_write_tokens']),
      costUsd: serializer.fromJson<double>(json['cost_usd']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String?>(turnId),
      'model': serializer.toJson<String>(model),
      'input_tokens': serializer.toJson<int>(inputTokens),
      'output_tokens': serializer.toJson<int>(outputTokens),
      'cache_read_tokens': serializer.toJson<int>(cacheReadTokens),
      'cache_write_tokens': serializer.toJson<int>(cacheWriteTokens),
      'cost_usd': serializer.toJson<double>(costUsd),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  AgentUsageRecord copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    Value<String?> turnId = const Value.absent(),
    String? model,
    int? inputTokens,
    int? outputTokens,
    int? cacheReadTokens,
    int? cacheWriteTokens,
    double? costUsd,
    String? timestamp,
  }) => AgentUsageRecord(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId.present ? turnId.value : this.turnId,
    model: model ?? this.model,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
    cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
    costUsd: costUsd ?? this.costUsd,
    timestamp: timestamp ?? this.timestamp,
  );
  AgentUsageRecord copyWithCompanion(AgentUsageRecordsCompanion data) {
    return AgentUsageRecord(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      model: data.model.present ? data.model.value : this.model,
      inputTokens: data.inputTokens.present
          ? data.inputTokens.value
          : this.inputTokens,
      outputTokens: data.outputTokens.present
          ? data.outputTokens.value
          : this.outputTokens,
      cacheReadTokens: data.cacheReadTokens.present
          ? data.cacheReadTokens.value
          : this.cacheReadTokens,
      cacheWriteTokens: data.cacheWriteTokens.present
          ? data.cacheWriteTokens.value
          : this.cacheWriteTokens,
      costUsd: data.costUsd.present ? data.costUsd.value : this.costUsd,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentUsageRecord(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('costUsd: $costUsd, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    model,
    inputTokens,
    outputTokens,
    cacheReadTokens,
    cacheWriteTokens,
    costUsd,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentUsageRecord &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.model == this.model &&
          other.inputTokens == this.inputTokens &&
          other.outputTokens == this.outputTokens &&
          other.cacheReadTokens == this.cacheReadTokens &&
          other.cacheWriteTokens == this.cacheWriteTokens &&
          other.costUsd == this.costUsd &&
          other.timestamp == this.timestamp);
}

class AgentUsageRecordsCompanion extends UpdateCompanion<AgentUsageRecord> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String?> turnId;
  final Value<String> model;
  final Value<int> inputTokens;
  final Value<int> outputTokens;
  final Value<int> cacheReadTokens;
  final Value<int> cacheWriteTokens;
  final Value<double> costUsd;
  final Value<String> timestamp;
  final Value<int> rowid;
  const AgentUsageRecordsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.model = const Value.absent(),
    this.inputTokens = const Value.absent(),
    this.outputTokens = const Value.absent(),
    this.cacheReadTokens = const Value.absent(),
    this.cacheWriteTokens = const Value.absent(),
    this.costUsd = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentUsageRecordsCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    this.turnId = const Value.absent(),
    required String model,
    required int inputTokens,
    required int outputTokens,
    required int cacheReadTokens,
    required int cacheWriteTokens,
    required double costUsd,
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       model = Value(model),
       inputTokens = Value(inputTokens),
       outputTokens = Value(outputTokens),
       cacheReadTokens = Value(cacheReadTokens),
       cacheWriteTokens = Value(cacheWriteTokens),
       costUsd = Value(costUsd);
  static Insertable<AgentUsageRecord> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? model,
    Expression<int>? inputTokens,
    Expression<int>? outputTokens,
    Expression<int>? cacheReadTokens,
    Expression<int>? cacheWriteTokens,
    Expression<double>? costUsd,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (model != null) 'model': model,
      if (inputTokens != null) 'input_tokens': inputTokens,
      if (outputTokens != null) 'output_tokens': outputTokens,
      if (cacheReadTokens != null) 'cache_read_tokens': cacheReadTokens,
      if (cacheWriteTokens != null) 'cache_write_tokens': cacheWriteTokens,
      if (costUsd != null) 'cost_usd': costUsd,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentUsageRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String?>? turnId,
    Value<String>? model,
    Value<int>? inputTokens,
    Value<int>? outputTokens,
    Value<int>? cacheReadTokens,
    Value<int>? cacheWriteTokens,
    Value<double>? costUsd,
    Value<String>? timestamp,
    Value<int>? rowid,
  }) {
    return AgentUsageRecordsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      model: model ?? this.model,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cacheReadTokens: cacheReadTokens ?? this.cacheReadTokens,
      cacheWriteTokens: cacheWriteTokens ?? this.cacheWriteTokens,
      costUsd: costUsd ?? this.costUsd,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (inputTokens.present) {
      map['input_tokens'] = Variable<int>(inputTokens.value);
    }
    if (outputTokens.present) {
      map['output_tokens'] = Variable<int>(outputTokens.value);
    }
    if (cacheReadTokens.present) {
      map['cache_read_tokens'] = Variable<int>(cacheReadTokens.value);
    }
    if (cacheWriteTokens.present) {
      map['cache_write_tokens'] = Variable<int>(cacheWriteTokens.value);
    }
    if (costUsd.present) {
      map['cost_usd'] = Variable<double>(costUsd.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentUsageRecordsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('model: $model, ')
          ..write('inputTokens: $inputTokens, ')
          ..write('outputTokens: $outputTokens, ')
          ..write('cacheReadTokens: $cacheReadTokens, ')
          ..write('cacheWriteTokens: $cacheWriteTokens, ')
          ..write('costUsd: $costUsd, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentFiles extends Table with TableInfo<AgentFiles, AgentFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentFiles(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    filePath,
    operation,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      ),
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  AgentFiles createAlias(String alias) {
    return AgentFiles(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentFile extends DataClass implements Insertable<AgentFile> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String? turnId;
  final String filePath;
  final String operation;
  final String timestamp;
  const AgentFile({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    this.turnId,
    required this.filePath,
    required this.operation,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    if (!nullToAbsent || turnId != null) {
      map['turn_id'] = Variable<String>(turnId);
    }
    map['file_path'] = Variable<String>(filePath);
    map['operation'] = Variable<String>(operation);
    map['timestamp'] = Variable<String>(timestamp);
    return map;
  }

  AgentFilesCompanion toCompanion(bool nullToAbsent) {
    return AgentFilesCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      turnId: turnId == null && nullToAbsent
          ? const Value.absent()
          : Value(turnId),
      filePath: Value(filePath),
      operation: Value(operation),
      timestamp: Value(timestamp),
    );
  }

  factory AgentFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentFile(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String?>(json['turn_id']),
      filePath: serializer.fromJson<String>(json['file_path']),
      operation: serializer.fromJson<String>(json['operation']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String?>(turnId),
      'file_path': serializer.toJson<String>(filePath),
      'operation': serializer.toJson<String>(operation),
      'timestamp': serializer.toJson<String>(timestamp),
    };
  }

  AgentFile copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    Value<String?> turnId = const Value.absent(),
    String? filePath,
    String? operation,
    String? timestamp,
  }) => AgentFile(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId.present ? turnId.value : this.turnId,
    filePath: filePath ?? this.filePath,
    operation: operation ?? this.operation,
    timestamp: timestamp ?? this.timestamp,
  );
  AgentFile copyWithCompanion(AgentFilesCompanion data) {
    return AgentFile(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      operation: data.operation.present ? data.operation.value : this.operation,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentFile(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('filePath: $filePath, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    filePath,
    operation,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentFile &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.filePath == this.filePath &&
          other.operation == this.operation &&
          other.timestamp == this.timestamp);
}

class AgentFilesCompanion extends UpdateCompanion<AgentFile> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String?> turnId;
  final Value<String> filePath;
  final Value<String> operation;
  final Value<String> timestamp;
  final Value<int> rowid;
  const AgentFilesCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.operation = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentFilesCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    this.turnId = const Value.absent(),
    required String filePath,
    required String operation,
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       filePath = Value(filePath),
       operation = Value(operation);
  static Insertable<AgentFile> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? filePath,
    Expression<String>? operation,
    Expression<String>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (filePath != null) 'file_path': filePath,
      if (operation != null) 'operation': operation,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String?>? turnId,
    Value<String>? filePath,
    Value<String>? operation,
    Value<String>? timestamp,
    Value<int>? rowid,
  }) {
    return AgentFilesCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      filePath: filePath ?? this.filePath,
      operation: operation ?? this.operation,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentFilesCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('filePath: $filePath, ')
          ..write('operation: $operation, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceInquiries extends Table
    with TableInfo<WorkspaceInquiries, WorkspaceInquiry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceInquiries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _contentMarkdownMeta = const VerificationMeta(
    'contentMarkdown',
  );
  late final GeneratedColumn<String> contentMarkdown = GeneratedColumn<String>(
    'content_markdown',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _attachmentsJsonMeta = const VerificationMeta(
    'attachmentsJson',
  );
  late final GeneratedColumn<String> attachmentsJson = GeneratedColumn<String>(
    'attachments_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _suggestionsJsonMeta = const VerificationMeta(
    'suggestionsJson',
  );
  late final GeneratedColumn<String> suggestionsJson = GeneratedColumn<String>(
    'suggestions_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _responseTextMeta = const VerificationMeta(
    'responseText',
  );
  late final GeneratedColumn<String> responseText = GeneratedColumn<String>(
    'response_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _responseSuggestionIndexMeta =
      const VerificationMeta('responseSuggestionIndex');
  late final GeneratedColumn<int> responseSuggestionIndex =
      GeneratedColumn<int>(
        'response_suggestion_index',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _respondedByAgentKeyMeta =
      const VerificationMeta('respondedByAgentKey');
  late final GeneratedColumn<String> respondedByAgentKey =
      GeneratedColumn<String>(
        'responded_by_agent_key',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _forwardingChainJsonMeta =
      const VerificationMeta('forwardingChainJson');
  late final GeneratedColumn<String> forwardingChainJson =
      GeneratedColumn<String>(
        'forwarding_chain_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _respondedAtMeta = const VerificationMeta(
    'respondedAt',
  );
  late final GeneratedColumn<String> respondedAt = GeneratedColumn<String>(
    'responded_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    status,
    priority,
    contentMarkdown,
    attachmentsJson,
    suggestionsJson,
    responseText,
    responseSuggestionIndex,
    respondedByAgentKey,
    forwardingChainJson,
    createdAt,
    respondedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_inquiries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceInquiry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('content_markdown')) {
      context.handle(
        _contentMarkdownMeta,
        contentMarkdown.isAcceptableOrUnknown(
          data['content_markdown']!,
          _contentMarkdownMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentMarkdownMeta);
    }
    if (data.containsKey('attachments_json')) {
      context.handle(
        _attachmentsJsonMeta,
        attachmentsJson.isAcceptableOrUnknown(
          data['attachments_json']!,
          _attachmentsJsonMeta,
        ),
      );
    }
    if (data.containsKey('suggestions_json')) {
      context.handle(
        _suggestionsJsonMeta,
        suggestionsJson.isAcceptableOrUnknown(
          data['suggestions_json']!,
          _suggestionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('response_text')) {
      context.handle(
        _responseTextMeta,
        responseText.isAcceptableOrUnknown(
          data['response_text']!,
          _responseTextMeta,
        ),
      );
    }
    if (data.containsKey('response_suggestion_index')) {
      context.handle(
        _responseSuggestionIndexMeta,
        responseSuggestionIndex.isAcceptableOrUnknown(
          data['response_suggestion_index']!,
          _responseSuggestionIndexMeta,
        ),
      );
    }
    if (data.containsKey('responded_by_agent_key')) {
      context.handle(
        _respondedByAgentKeyMeta,
        respondedByAgentKey.isAcceptableOrUnknown(
          data['responded_by_agent_key']!,
          _respondedByAgentKeyMeta,
        ),
      );
    }
    if (data.containsKey('forwarding_chain_json')) {
      context.handle(
        _forwardingChainJsonMeta,
        forwardingChainJson.isAcceptableOrUnknown(
          data['forwarding_chain_json']!,
          _forwardingChainJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('responded_at')) {
      context.handle(
        _respondedAtMeta,
        respondedAt.isAcceptableOrUnknown(
          data['responded_at']!,
          _respondedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceInquiry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceInquiry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      contentMarkdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_markdown'],
      )!,
      attachmentsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachments_json'],
      ),
      suggestionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggestions_json'],
      ),
      responseText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_text'],
      ),
      responseSuggestionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}response_suggestion_index'],
      ),
      respondedByAgentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responded_by_agent_key'],
      ),
      forwardingChainJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forwarding_chain_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      respondedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}responded_at'],
      ),
    );
  }

  @override
  WorkspaceInquiries createAlias(String alias) {
    return WorkspaceInquiries(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceInquiry extends DataClass
    implements Insertable<WorkspaceInquiry> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String status;
  final String priority;
  final String contentMarkdown;
  final String? attachmentsJson;
  final String? suggestionsJson;
  final String? responseText;
  final int? responseSuggestionIndex;
  final String? respondedByAgentKey;
  final String? forwardingChainJson;
  final String createdAt;
  final String? respondedAt;
  const WorkspaceInquiry({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    required this.status,
    required this.priority,
    required this.contentMarkdown,
    this.attachmentsJson,
    this.suggestionsJson,
    this.responseText,
    this.responseSuggestionIndex,
    this.respondedByAgentKey,
    this.forwardingChainJson,
    required this.createdAt,
    this.respondedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    map['content_markdown'] = Variable<String>(contentMarkdown);
    if (!nullToAbsent || attachmentsJson != null) {
      map['attachments_json'] = Variable<String>(attachmentsJson);
    }
    if (!nullToAbsent || suggestionsJson != null) {
      map['suggestions_json'] = Variable<String>(suggestionsJson);
    }
    if (!nullToAbsent || responseText != null) {
      map['response_text'] = Variable<String>(responseText);
    }
    if (!nullToAbsent || responseSuggestionIndex != null) {
      map['response_suggestion_index'] = Variable<int>(responseSuggestionIndex);
    }
    if (!nullToAbsent || respondedByAgentKey != null) {
      map['responded_by_agent_key'] = Variable<String>(respondedByAgentKey);
    }
    if (!nullToAbsent || forwardingChainJson != null) {
      map['forwarding_chain_json'] = Variable<String>(forwardingChainJson);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || respondedAt != null) {
      map['responded_at'] = Variable<String>(respondedAt);
    }
    return map;
  }

  WorkspaceInquiriesCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceInquiriesCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      status: Value(status),
      priority: Value(priority),
      contentMarkdown: Value(contentMarkdown),
      attachmentsJson: attachmentsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentsJson),
      suggestionsJson: suggestionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestionsJson),
      responseText: responseText == null && nullToAbsent
          ? const Value.absent()
          : Value(responseText),
      responseSuggestionIndex: responseSuggestionIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(responseSuggestionIndex),
      respondedByAgentKey: respondedByAgentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedByAgentKey),
      forwardingChainJson: forwardingChainJson == null && nullToAbsent
          ? const Value.absent()
          : Value(forwardingChainJson),
      createdAt: Value(createdAt),
      respondedAt: respondedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(respondedAt),
    );
  }

  factory WorkspaceInquiry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceInquiry(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      contentMarkdown: serializer.fromJson<String>(json['content_markdown']),
      attachmentsJson: serializer.fromJson<String?>(json['attachments_json']),
      suggestionsJson: serializer.fromJson<String?>(json['suggestions_json']),
      responseText: serializer.fromJson<String?>(json['response_text']),
      responseSuggestionIndex: serializer.fromJson<int?>(
        json['response_suggestion_index'],
      ),
      respondedByAgentKey: serializer.fromJson<String?>(
        json['responded_by_agent_key'],
      ),
      forwardingChainJson: serializer.fromJson<String?>(
        json['forwarding_chain_json'],
      ),
      createdAt: serializer.fromJson<String>(json['created_at']),
      respondedAt: serializer.fromJson<String?>(json['responded_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'content_markdown': serializer.toJson<String>(contentMarkdown),
      'attachments_json': serializer.toJson<String?>(attachmentsJson),
      'suggestions_json': serializer.toJson<String?>(suggestionsJson),
      'response_text': serializer.toJson<String?>(responseText),
      'response_suggestion_index': serializer.toJson<int?>(
        responseSuggestionIndex,
      ),
      'responded_by_agent_key': serializer.toJson<String?>(respondedByAgentKey),
      'forwarding_chain_json': serializer.toJson<String?>(forwardingChainJson),
      'created_at': serializer.toJson<String>(createdAt),
      'responded_at': serializer.toJson<String?>(respondedAt),
    };
  }

  WorkspaceInquiry copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    String? status,
    String? priority,
    String? contentMarkdown,
    Value<String?> attachmentsJson = const Value.absent(),
    Value<String?> suggestionsJson = const Value.absent(),
    Value<String?> responseText = const Value.absent(),
    Value<int?> responseSuggestionIndex = const Value.absent(),
    Value<String?> respondedByAgentKey = const Value.absent(),
    Value<String?> forwardingChainJson = const Value.absent(),
    String? createdAt,
    Value<String?> respondedAt = const Value.absent(),
  }) => WorkspaceInquiry(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    contentMarkdown: contentMarkdown ?? this.contentMarkdown,
    attachmentsJson: attachmentsJson.present
        ? attachmentsJson.value
        : this.attachmentsJson,
    suggestionsJson: suggestionsJson.present
        ? suggestionsJson.value
        : this.suggestionsJson,
    responseText: responseText.present ? responseText.value : this.responseText,
    responseSuggestionIndex: responseSuggestionIndex.present
        ? responseSuggestionIndex.value
        : this.responseSuggestionIndex,
    respondedByAgentKey: respondedByAgentKey.present
        ? respondedByAgentKey.value
        : this.respondedByAgentKey,
    forwardingChainJson: forwardingChainJson.present
        ? forwardingChainJson.value
        : this.forwardingChainJson,
    createdAt: createdAt ?? this.createdAt,
    respondedAt: respondedAt.present ? respondedAt.value : this.respondedAt,
  );
  WorkspaceInquiry copyWithCompanion(WorkspaceInquiriesCompanion data) {
    return WorkspaceInquiry(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      contentMarkdown: data.contentMarkdown.present
          ? data.contentMarkdown.value
          : this.contentMarkdown,
      attachmentsJson: data.attachmentsJson.present
          ? data.attachmentsJson.value
          : this.attachmentsJson,
      suggestionsJson: data.suggestionsJson.present
          ? data.suggestionsJson.value
          : this.suggestionsJson,
      responseText: data.responseText.present
          ? data.responseText.value
          : this.responseText,
      responseSuggestionIndex: data.responseSuggestionIndex.present
          ? data.responseSuggestionIndex.value
          : this.responseSuggestionIndex,
      respondedByAgentKey: data.respondedByAgentKey.present
          ? data.respondedByAgentKey.value
          : this.respondedByAgentKey,
      forwardingChainJson: data.forwardingChainJson.present
          ? data.forwardingChainJson.value
          : this.forwardingChainJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      respondedAt: data.respondedAt.present
          ? data.respondedAt.value
          : this.respondedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceInquiry(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('suggestionsJson: $suggestionsJson, ')
          ..write('responseText: $responseText, ')
          ..write('responseSuggestionIndex: $responseSuggestionIndex, ')
          ..write('respondedByAgentKey: $respondedByAgentKey, ')
          ..write('forwardingChainJson: $forwardingChainJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('respondedAt: $respondedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    status,
    priority,
    contentMarkdown,
    attachmentsJson,
    suggestionsJson,
    responseText,
    responseSuggestionIndex,
    respondedByAgentKey,
    forwardingChainJson,
    createdAt,
    respondedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceInquiry &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.contentMarkdown == this.contentMarkdown &&
          other.attachmentsJson == this.attachmentsJson &&
          other.suggestionsJson == this.suggestionsJson &&
          other.responseText == this.responseText &&
          other.responseSuggestionIndex == this.responseSuggestionIndex &&
          other.respondedByAgentKey == this.respondedByAgentKey &&
          other.forwardingChainJson == this.forwardingChainJson &&
          other.createdAt == this.createdAt &&
          other.respondedAt == this.respondedAt);
}

class WorkspaceInquiriesCompanion extends UpdateCompanion<WorkspaceInquiry> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String> status;
  final Value<String> priority;
  final Value<String> contentMarkdown;
  final Value<String?> attachmentsJson;
  final Value<String?> suggestionsJson;
  final Value<String?> responseText;
  final Value<int?> responseSuggestionIndex;
  final Value<String?> respondedByAgentKey;
  final Value<String?> forwardingChainJson;
  final Value<String> createdAt;
  final Value<String?> respondedAt;
  final Value<int> rowid;
  const WorkspaceInquiriesCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.contentMarkdown = const Value.absent(),
    this.attachmentsJson = const Value.absent(),
    this.suggestionsJson = const Value.absent(),
    this.responseText = const Value.absent(),
    this.responseSuggestionIndex = const Value.absent(),
    this.respondedByAgentKey = const Value.absent(),
    this.forwardingChainJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceInquiriesCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    required String status,
    required String priority,
    required String contentMarkdown,
    this.attachmentsJson = const Value.absent(),
    this.suggestionsJson = const Value.absent(),
    this.responseText = const Value.absent(),
    this.responseSuggestionIndex = const Value.absent(),
    this.respondedByAgentKey = const Value.absent(),
    this.forwardingChainJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.respondedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       status = Value(status),
       priority = Value(priority),
       contentMarkdown = Value(contentMarkdown);
  static Insertable<WorkspaceInquiry> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? contentMarkdown,
    Expression<String>? attachmentsJson,
    Expression<String>? suggestionsJson,
    Expression<String>? responseText,
    Expression<int>? responseSuggestionIndex,
    Expression<String>? respondedByAgentKey,
    Expression<String>? forwardingChainJson,
    Expression<String>? createdAt,
    Expression<String>? respondedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (contentMarkdown != null) 'content_markdown': contentMarkdown,
      if (attachmentsJson != null) 'attachments_json': attachmentsJson,
      if (suggestionsJson != null) 'suggestions_json': suggestionsJson,
      if (responseText != null) 'response_text': responseText,
      if (responseSuggestionIndex != null)
        'response_suggestion_index': responseSuggestionIndex,
      if (respondedByAgentKey != null)
        'responded_by_agent_key': respondedByAgentKey,
      if (forwardingChainJson != null)
        'forwarding_chain_json': forwardingChainJson,
      if (createdAt != null) 'created_at': createdAt,
      if (respondedAt != null) 'responded_at': respondedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceInquiriesCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String>? status,
    Value<String>? priority,
    Value<String>? contentMarkdown,
    Value<String?>? attachmentsJson,
    Value<String?>? suggestionsJson,
    Value<String?>? responseText,
    Value<int?>? responseSuggestionIndex,
    Value<String?>? respondedByAgentKey,
    Value<String?>? forwardingChainJson,
    Value<String>? createdAt,
    Value<String?>? respondedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceInquiriesCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      attachmentsJson: attachmentsJson ?? this.attachmentsJson,
      suggestionsJson: suggestionsJson ?? this.suggestionsJson,
      responseText: responseText ?? this.responseText,
      responseSuggestionIndex:
          responseSuggestionIndex ?? this.responseSuggestionIndex,
      respondedByAgentKey: respondedByAgentKey ?? this.respondedByAgentKey,
      forwardingChainJson: forwardingChainJson ?? this.forwardingChainJson,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (contentMarkdown.present) {
      map['content_markdown'] = Variable<String>(contentMarkdown.value);
    }
    if (attachmentsJson.present) {
      map['attachments_json'] = Variable<String>(attachmentsJson.value);
    }
    if (suggestionsJson.present) {
      map['suggestions_json'] = Variable<String>(suggestionsJson.value);
    }
    if (responseText.present) {
      map['response_text'] = Variable<String>(responseText.value);
    }
    if (responseSuggestionIndex.present) {
      map['response_suggestion_index'] = Variable<int>(
        responseSuggestionIndex.value,
      );
    }
    if (respondedByAgentKey.present) {
      map['responded_by_agent_key'] = Variable<String>(
        respondedByAgentKey.value,
      );
    }
    if (forwardingChainJson.present) {
      map['forwarding_chain_json'] = Variable<String>(
        forwardingChainJson.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (respondedAt.present) {
      map['responded_at'] = Variable<String>(respondedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceInquiriesCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('contentMarkdown: $contentMarkdown, ')
          ..write('attachmentsJson: $attachmentsJson, ')
          ..write('suggestionsJson: $suggestionsJson, ')
          ..write('responseText: $responseText, ')
          ..write('responseSuggestionIndex: $responseSuggestionIndex, ')
          ..write('respondedByAgentKey: $respondedByAgentKey, ')
          ..write('forwardingChainJson: $forwardingChainJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('respondedAt: $respondedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentProviders extends Table
    with TableInfo<AgentProviders, AgentProvider> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentProviders(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _gitUrlMeta = const VerificationMeta('gitUrl');
  late final GeneratedColumn<String> gitUrl = GeneratedColumn<String>(
    'git_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _gitBranchMeta = const VerificationMeta(
    'gitBranch',
  );
  late final GeneratedColumn<String> gitBranch = GeneratedColumn<String>(
    'git_branch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _entryPointMeta = const VerificationMeta(
    'entryPoint',
  );
  late final GeneratedColumn<String> entryPoint = GeneratedColumn<String>(
    'entry_point',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _readmeMeta = const VerificationMeta('readme');
  late final GeneratedColumn<String> readme = GeneratedColumn<String>(
    'readme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _requiredEnvJsonMeta = const VerificationMeta(
    'requiredEnvJson',
  );
  late final GeneratedColumn<String> requiredEnvJson = GeneratedColumn<String>(
    'required_env_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _requiredMountsJsonMeta =
      const VerificationMeta('requiredMountsJson');
  late final GeneratedColumn<String> requiredMountsJson =
      GeneratedColumn<String>(
        'required_mounts_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT \'[]\'',
        defaultValue: const CustomExpression('\'[]\''),
      );
  static const VerificationMeta _fieldsJsonMeta = const VerificationMeta(
    'fieldsJson',
  );
  late final GeneratedColumn<String> fieldsJson = GeneratedColumn<String>(
    'fields_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'{}\'',
    defaultValue: const CustomExpression('\'{}\''),
  );
  static const VerificationMeta _hubSlugMeta = const VerificationMeta(
    'hubSlug',
  );
  late final GeneratedColumn<String> hubSlug = GeneratedColumn<String>(
    'hub_slug',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubAuthorMeta = const VerificationMeta(
    'hubAuthor',
  );
  late final GeneratedColumn<String> hubAuthor = GeneratedColumn<String>(
    'hub_author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubCategoryMeta = const VerificationMeta(
    'hubCategory',
  );
  late final GeneratedColumn<String> hubCategory = GeneratedColumn<String>(
    'hub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubTagsJsonMeta = const VerificationMeta(
    'hubTagsJson',
  );
  late final GeneratedColumn<String> hubTagsJson = GeneratedColumn<String>(
    'hub_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _hubVersionMeta = const VerificationMeta(
    'hubVersion',
  );
  late final GeneratedColumn<int> hubVersion = GeneratedColumn<int>(
    'hub_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubRepoUrlMeta = const VerificationMeta(
    'hubRepoUrl',
  );
  late final GeneratedColumn<String> hubRepoUrl = GeneratedColumn<String>(
    'hub_repo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubCommitHashMeta = const VerificationMeta(
    'hubCommitHash',
  );
  late final GeneratedColumn<String> hubCommitHash = GeneratedColumn<String>(
    'hub_commit_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceType,
    sourcePath,
    gitUrl,
    gitBranch,
    entryPoint,
    description,
    readme,
    requiredEnvJson,
    requiredMountsJson,
    fieldsJson,
    hubSlug,
    hubAuthor,
    hubCategory,
    hubTagsJson,
    hubVersion,
    hubRepoUrl,
    hubCommitHash,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentProvider> instance, {
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
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    }
    if (data.containsKey('git_url')) {
      context.handle(
        _gitUrlMeta,
        gitUrl.isAcceptableOrUnknown(data['git_url']!, _gitUrlMeta),
      );
    }
    if (data.containsKey('git_branch')) {
      context.handle(
        _gitBranchMeta,
        gitBranch.isAcceptableOrUnknown(data['git_branch']!, _gitBranchMeta),
      );
    }
    if (data.containsKey('entry_point')) {
      context.handle(
        _entryPointMeta,
        entryPoint.isAcceptableOrUnknown(data['entry_point']!, _entryPointMeta),
      );
    } else if (isInserting) {
      context.missing(_entryPointMeta);
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
    if (data.containsKey('readme')) {
      context.handle(
        _readmeMeta,
        readme.isAcceptableOrUnknown(data['readme']!, _readmeMeta),
      );
    }
    if (data.containsKey('required_env_json')) {
      context.handle(
        _requiredEnvJsonMeta,
        requiredEnvJson.isAcceptableOrUnknown(
          data['required_env_json']!,
          _requiredEnvJsonMeta,
        ),
      );
    }
    if (data.containsKey('required_mounts_json')) {
      context.handle(
        _requiredMountsJsonMeta,
        requiredMountsJson.isAcceptableOrUnknown(
          data['required_mounts_json']!,
          _requiredMountsJsonMeta,
        ),
      );
    }
    if (data.containsKey('fields_json')) {
      context.handle(
        _fieldsJsonMeta,
        fieldsJson.isAcceptableOrUnknown(data['fields_json']!, _fieldsJsonMeta),
      );
    }
    if (data.containsKey('hub_slug')) {
      context.handle(
        _hubSlugMeta,
        hubSlug.isAcceptableOrUnknown(data['hub_slug']!, _hubSlugMeta),
      );
    }
    if (data.containsKey('hub_author')) {
      context.handle(
        _hubAuthorMeta,
        hubAuthor.isAcceptableOrUnknown(data['hub_author']!, _hubAuthorMeta),
      );
    }
    if (data.containsKey('hub_category')) {
      context.handle(
        _hubCategoryMeta,
        hubCategory.isAcceptableOrUnknown(
          data['hub_category']!,
          _hubCategoryMeta,
        ),
      );
    }
    if (data.containsKey('hub_tags_json')) {
      context.handle(
        _hubTagsJsonMeta,
        hubTagsJson.isAcceptableOrUnknown(
          data['hub_tags_json']!,
          _hubTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('hub_version')) {
      context.handle(
        _hubVersionMeta,
        hubVersion.isAcceptableOrUnknown(data['hub_version']!, _hubVersionMeta),
      );
    }
    if (data.containsKey('hub_repo_url')) {
      context.handle(
        _hubRepoUrlMeta,
        hubRepoUrl.isAcceptableOrUnknown(
          data['hub_repo_url']!,
          _hubRepoUrlMeta,
        ),
      );
    }
    if (data.containsKey('hub_commit_hash')) {
      context.handle(
        _hubCommitHashMeta,
        hubCommitHash.isAcceptableOrUnknown(
          data['hub_commit_hash']!,
          _hubCommitHashMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentProvider map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentProvider(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      ),
      gitUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_url'],
      ),
      gitBranch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}git_branch'],
      ),
      entryPoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entry_point'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      readme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}readme'],
      ),
      requiredEnvJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_env_json'],
      )!,
      requiredMountsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}required_mounts_json'],
      )!,
      fieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fields_json'],
      )!,
      hubSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_slug'],
      ),
      hubAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_author'],
      ),
      hubCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_category'],
      ),
      hubTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_tags_json'],
      )!,
      hubVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hub_version'],
      ),
      hubRepoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_repo_url'],
      ),
      hubCommitHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_commit_hash'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AgentProviders createAlias(String alias) {
    return AgentProviders(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentProvider extends DataClass implements Insertable<AgentProvider> {
  final String id;
  final String name;
  final String sourceType;
  final String? sourcePath;
  final String? gitUrl;
  final String? gitBranch;
  final String entryPoint;
  final String? description;
  final String? readme;
  final String requiredEnvJson;
  final String requiredMountsJson;
  final String fieldsJson;
  final String? hubSlug;
  final String? hubAuthor;
  final String? hubCategory;
  final String hubTagsJson;
  final int? hubVersion;
  final String? hubRepoUrl;
  final String? hubCommitHash;
  final String createdAt;
  final String updatedAt;
  const AgentProvider({
    required this.id,
    required this.name,
    required this.sourceType,
    this.sourcePath,
    this.gitUrl,
    this.gitBranch,
    required this.entryPoint,
    this.description,
    this.readme,
    required this.requiredEnvJson,
    required this.requiredMountsJson,
    required this.fieldsJson,
    this.hubSlug,
    this.hubAuthor,
    this.hubCategory,
    required this.hubTagsJson,
    this.hubVersion,
    this.hubRepoUrl,
    this.hubCommitHash,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourcePath != null) {
      map['source_path'] = Variable<String>(sourcePath);
    }
    if (!nullToAbsent || gitUrl != null) {
      map['git_url'] = Variable<String>(gitUrl);
    }
    if (!nullToAbsent || gitBranch != null) {
      map['git_branch'] = Variable<String>(gitBranch);
    }
    map['entry_point'] = Variable<String>(entryPoint);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || readme != null) {
      map['readme'] = Variable<String>(readme);
    }
    map['required_env_json'] = Variable<String>(requiredEnvJson);
    map['required_mounts_json'] = Variable<String>(requiredMountsJson);
    map['fields_json'] = Variable<String>(fieldsJson);
    if (!nullToAbsent || hubSlug != null) {
      map['hub_slug'] = Variable<String>(hubSlug);
    }
    if (!nullToAbsent || hubAuthor != null) {
      map['hub_author'] = Variable<String>(hubAuthor);
    }
    if (!nullToAbsent || hubCategory != null) {
      map['hub_category'] = Variable<String>(hubCategory);
    }
    map['hub_tags_json'] = Variable<String>(hubTagsJson);
    if (!nullToAbsent || hubVersion != null) {
      map['hub_version'] = Variable<int>(hubVersion);
    }
    if (!nullToAbsent || hubRepoUrl != null) {
      map['hub_repo_url'] = Variable<String>(hubRepoUrl);
    }
    if (!nullToAbsent || hubCommitHash != null) {
      map['hub_commit_hash'] = Variable<String>(hubCommitHash);
    }
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AgentProvidersCompanion toCompanion(bool nullToAbsent) {
    return AgentProvidersCompanion(
      id: Value(id),
      name: Value(name),
      sourceType: Value(sourceType),
      sourcePath: sourcePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePath),
      gitUrl: gitUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(gitUrl),
      gitBranch: gitBranch == null && nullToAbsent
          ? const Value.absent()
          : Value(gitBranch),
      entryPoint: Value(entryPoint),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      readme: readme == null && nullToAbsent
          ? const Value.absent()
          : Value(readme),
      requiredEnvJson: Value(requiredEnvJson),
      requiredMountsJson: Value(requiredMountsJson),
      fieldsJson: Value(fieldsJson),
      hubSlug: hubSlug == null && nullToAbsent
          ? const Value.absent()
          : Value(hubSlug),
      hubAuthor: hubAuthor == null && nullToAbsent
          ? const Value.absent()
          : Value(hubAuthor),
      hubCategory: hubCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(hubCategory),
      hubTagsJson: Value(hubTagsJson),
      hubVersion: hubVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(hubVersion),
      hubRepoUrl: hubRepoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(hubRepoUrl),
      hubCommitHash: hubCommitHash == null && nullToAbsent
          ? const Value.absent()
          : Value(hubCommitHash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentProvider.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentProvider(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceType: serializer.fromJson<String>(json['source_type']),
      sourcePath: serializer.fromJson<String?>(json['source_path']),
      gitUrl: serializer.fromJson<String?>(json['git_url']),
      gitBranch: serializer.fromJson<String?>(json['git_branch']),
      entryPoint: serializer.fromJson<String>(json['entry_point']),
      description: serializer.fromJson<String?>(json['description']),
      readme: serializer.fromJson<String?>(json['readme']),
      requiredEnvJson: serializer.fromJson<String>(json['required_env_json']),
      requiredMountsJson: serializer.fromJson<String>(
        json['required_mounts_json'],
      ),
      fieldsJson: serializer.fromJson<String>(json['fields_json']),
      hubSlug: serializer.fromJson<String?>(json['hub_slug']),
      hubAuthor: serializer.fromJson<String?>(json['hub_author']),
      hubCategory: serializer.fromJson<String?>(json['hub_category']),
      hubTagsJson: serializer.fromJson<String>(json['hub_tags_json']),
      hubVersion: serializer.fromJson<int?>(json['hub_version']),
      hubRepoUrl: serializer.fromJson<String?>(json['hub_repo_url']),
      hubCommitHash: serializer.fromJson<String?>(json['hub_commit_hash']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'source_type': serializer.toJson<String>(sourceType),
      'source_path': serializer.toJson<String?>(sourcePath),
      'git_url': serializer.toJson<String?>(gitUrl),
      'git_branch': serializer.toJson<String?>(gitBranch),
      'entry_point': serializer.toJson<String>(entryPoint),
      'description': serializer.toJson<String?>(description),
      'readme': serializer.toJson<String?>(readme),
      'required_env_json': serializer.toJson<String>(requiredEnvJson),
      'required_mounts_json': serializer.toJson<String>(requiredMountsJson),
      'fields_json': serializer.toJson<String>(fieldsJson),
      'hub_slug': serializer.toJson<String?>(hubSlug),
      'hub_author': serializer.toJson<String?>(hubAuthor),
      'hub_category': serializer.toJson<String?>(hubCategory),
      'hub_tags_json': serializer.toJson<String>(hubTagsJson),
      'hub_version': serializer.toJson<int?>(hubVersion),
      'hub_repo_url': serializer.toJson<String?>(hubRepoUrl),
      'hub_commit_hash': serializer.toJson<String?>(hubCommitHash),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AgentProvider copyWith({
    String? id,
    String? name,
    String? sourceType,
    Value<String?> sourcePath = const Value.absent(),
    Value<String?> gitUrl = const Value.absent(),
    Value<String?> gitBranch = const Value.absent(),
    String? entryPoint,
    Value<String?> description = const Value.absent(),
    Value<String?> readme = const Value.absent(),
    String? requiredEnvJson,
    String? requiredMountsJson,
    String? fieldsJson,
    Value<String?> hubSlug = const Value.absent(),
    Value<String?> hubAuthor = const Value.absent(),
    Value<String?> hubCategory = const Value.absent(),
    String? hubTagsJson,
    Value<int?> hubVersion = const Value.absent(),
    Value<String?> hubRepoUrl = const Value.absent(),
    Value<String?> hubCommitHash = const Value.absent(),
    String? createdAt,
    String? updatedAt,
  }) => AgentProvider(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceType: sourceType ?? this.sourceType,
    sourcePath: sourcePath.present ? sourcePath.value : this.sourcePath,
    gitUrl: gitUrl.present ? gitUrl.value : this.gitUrl,
    gitBranch: gitBranch.present ? gitBranch.value : this.gitBranch,
    entryPoint: entryPoint ?? this.entryPoint,
    description: description.present ? description.value : this.description,
    readme: readme.present ? readme.value : this.readme,
    requiredEnvJson: requiredEnvJson ?? this.requiredEnvJson,
    requiredMountsJson: requiredMountsJson ?? this.requiredMountsJson,
    fieldsJson: fieldsJson ?? this.fieldsJson,
    hubSlug: hubSlug.present ? hubSlug.value : this.hubSlug,
    hubAuthor: hubAuthor.present ? hubAuthor.value : this.hubAuthor,
    hubCategory: hubCategory.present ? hubCategory.value : this.hubCategory,
    hubTagsJson: hubTagsJson ?? this.hubTagsJson,
    hubVersion: hubVersion.present ? hubVersion.value : this.hubVersion,
    hubRepoUrl: hubRepoUrl.present ? hubRepoUrl.value : this.hubRepoUrl,
    hubCommitHash: hubCommitHash.present
        ? hubCommitHash.value
        : this.hubCommitHash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AgentProvider copyWithCompanion(AgentProvidersCompanion data) {
    return AgentProvider(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      gitUrl: data.gitUrl.present ? data.gitUrl.value : this.gitUrl,
      gitBranch: data.gitBranch.present ? data.gitBranch.value : this.gitBranch,
      entryPoint: data.entryPoint.present
          ? data.entryPoint.value
          : this.entryPoint,
      description: data.description.present
          ? data.description.value
          : this.description,
      readme: data.readme.present ? data.readme.value : this.readme,
      requiredEnvJson: data.requiredEnvJson.present
          ? data.requiredEnvJson.value
          : this.requiredEnvJson,
      requiredMountsJson: data.requiredMountsJson.present
          ? data.requiredMountsJson.value
          : this.requiredMountsJson,
      fieldsJson: data.fieldsJson.present
          ? data.fieldsJson.value
          : this.fieldsJson,
      hubSlug: data.hubSlug.present ? data.hubSlug.value : this.hubSlug,
      hubAuthor: data.hubAuthor.present ? data.hubAuthor.value : this.hubAuthor,
      hubCategory: data.hubCategory.present
          ? data.hubCategory.value
          : this.hubCategory,
      hubTagsJson: data.hubTagsJson.present
          ? data.hubTagsJson.value
          : this.hubTagsJson,
      hubVersion: data.hubVersion.present
          ? data.hubVersion.value
          : this.hubVersion,
      hubRepoUrl: data.hubRepoUrl.present
          ? data.hubRepoUrl.value
          : this.hubRepoUrl,
      hubCommitHash: data.hubCommitHash.present
          ? data.hubCommitHash.value
          : this.hubCommitHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentProvider(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('gitUrl: $gitUrl, ')
          ..write('gitBranch: $gitBranch, ')
          ..write('entryPoint: $entryPoint, ')
          ..write('description: $description, ')
          ..write('readme: $readme, ')
          ..write('requiredEnvJson: $requiredEnvJson, ')
          ..write('requiredMountsJson: $requiredMountsJson, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('hubSlug: $hubSlug, ')
          ..write('hubAuthor: $hubAuthor, ')
          ..write('hubCategory: $hubCategory, ')
          ..write('hubTagsJson: $hubTagsJson, ')
          ..write('hubVersion: $hubVersion, ')
          ..write('hubRepoUrl: $hubRepoUrl, ')
          ..write('hubCommitHash: $hubCommitHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    sourceType,
    sourcePath,
    gitUrl,
    gitBranch,
    entryPoint,
    description,
    readme,
    requiredEnvJson,
    requiredMountsJson,
    fieldsJson,
    hubSlug,
    hubAuthor,
    hubCategory,
    hubTagsJson,
    hubVersion,
    hubRepoUrl,
    hubCommitHash,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentProvider &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceType == this.sourceType &&
          other.sourcePath == this.sourcePath &&
          other.gitUrl == this.gitUrl &&
          other.gitBranch == this.gitBranch &&
          other.entryPoint == this.entryPoint &&
          other.description == this.description &&
          other.readme == this.readme &&
          other.requiredEnvJson == this.requiredEnvJson &&
          other.requiredMountsJson == this.requiredMountsJson &&
          other.fieldsJson == this.fieldsJson &&
          other.hubSlug == this.hubSlug &&
          other.hubAuthor == this.hubAuthor &&
          other.hubCategory == this.hubCategory &&
          other.hubTagsJson == this.hubTagsJson &&
          other.hubVersion == this.hubVersion &&
          other.hubRepoUrl == this.hubRepoUrl &&
          other.hubCommitHash == this.hubCommitHash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentProvidersCompanion extends UpdateCompanion<AgentProvider> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> sourceType;
  final Value<String?> sourcePath;
  final Value<String?> gitUrl;
  final Value<String?> gitBranch;
  final Value<String> entryPoint;
  final Value<String?> description;
  final Value<String?> readme;
  final Value<String> requiredEnvJson;
  final Value<String> requiredMountsJson;
  final Value<String> fieldsJson;
  final Value<String?> hubSlug;
  final Value<String?> hubAuthor;
  final Value<String?> hubCategory;
  final Value<String> hubTagsJson;
  final Value<int?> hubVersion;
  final Value<String?> hubRepoUrl;
  final Value<String?> hubCommitHash;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AgentProvidersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.gitUrl = const Value.absent(),
    this.gitBranch = const Value.absent(),
    this.entryPoint = const Value.absent(),
    this.description = const Value.absent(),
    this.readme = const Value.absent(),
    this.requiredEnvJson = const Value.absent(),
    this.requiredMountsJson = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.hubSlug = const Value.absent(),
    this.hubAuthor = const Value.absent(),
    this.hubCategory = const Value.absent(),
    this.hubTagsJson = const Value.absent(),
    this.hubVersion = const Value.absent(),
    this.hubRepoUrl = const Value.absent(),
    this.hubCommitHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentProvidersCompanion.insert({
    required String id,
    required String name,
    required String sourceType,
    this.sourcePath = const Value.absent(),
    this.gitUrl = const Value.absent(),
    this.gitBranch = const Value.absent(),
    required String entryPoint,
    this.description = const Value.absent(),
    this.readme = const Value.absent(),
    this.requiredEnvJson = const Value.absent(),
    this.requiredMountsJson = const Value.absent(),
    this.fieldsJson = const Value.absent(),
    this.hubSlug = const Value.absent(),
    this.hubAuthor = const Value.absent(),
    this.hubCategory = const Value.absent(),
    this.hubTagsJson = const Value.absent(),
    this.hubVersion = const Value.absent(),
    this.hubRepoUrl = const Value.absent(),
    this.hubCommitHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sourceType = Value(sourceType),
       entryPoint = Value(entryPoint);
  static Insertable<AgentProvider> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceType,
    Expression<String>? sourcePath,
    Expression<String>? gitUrl,
    Expression<String>? gitBranch,
    Expression<String>? entryPoint,
    Expression<String>? description,
    Expression<String>? readme,
    Expression<String>? requiredEnvJson,
    Expression<String>? requiredMountsJson,
    Expression<String>? fieldsJson,
    Expression<String>? hubSlug,
    Expression<String>? hubAuthor,
    Expression<String>? hubCategory,
    Expression<String>? hubTagsJson,
    Expression<int>? hubVersion,
    Expression<String>? hubRepoUrl,
    Expression<String>? hubCommitHash,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceType != null) 'source_type': sourceType,
      if (sourcePath != null) 'source_path': sourcePath,
      if (gitUrl != null) 'git_url': gitUrl,
      if (gitBranch != null) 'git_branch': gitBranch,
      if (entryPoint != null) 'entry_point': entryPoint,
      if (description != null) 'description': description,
      if (readme != null) 'readme': readme,
      if (requiredEnvJson != null) 'required_env_json': requiredEnvJson,
      if (requiredMountsJson != null)
        'required_mounts_json': requiredMountsJson,
      if (fieldsJson != null) 'fields_json': fieldsJson,
      if (hubSlug != null) 'hub_slug': hubSlug,
      if (hubAuthor != null) 'hub_author': hubAuthor,
      if (hubCategory != null) 'hub_category': hubCategory,
      if (hubTagsJson != null) 'hub_tags_json': hubTagsJson,
      if (hubVersion != null) 'hub_version': hubVersion,
      if (hubRepoUrl != null) 'hub_repo_url': hubRepoUrl,
      if (hubCommitHash != null) 'hub_commit_hash': hubCommitHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? sourceType,
    Value<String?>? sourcePath,
    Value<String?>? gitUrl,
    Value<String?>? gitBranch,
    Value<String>? entryPoint,
    Value<String?>? description,
    Value<String?>? readme,
    Value<String>? requiredEnvJson,
    Value<String>? requiredMountsJson,
    Value<String>? fieldsJson,
    Value<String?>? hubSlug,
    Value<String?>? hubAuthor,
    Value<String?>? hubCategory,
    Value<String>? hubTagsJson,
    Value<int?>? hubVersion,
    Value<String?>? hubRepoUrl,
    Value<String?>? hubCommitHash,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AgentProvidersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceType: sourceType ?? this.sourceType,
      sourcePath: sourcePath ?? this.sourcePath,
      gitUrl: gitUrl ?? this.gitUrl,
      gitBranch: gitBranch ?? this.gitBranch,
      entryPoint: entryPoint ?? this.entryPoint,
      description: description ?? this.description,
      readme: readme ?? this.readme,
      requiredEnvJson: requiredEnvJson ?? this.requiredEnvJson,
      requiredMountsJson: requiredMountsJson ?? this.requiredMountsJson,
      fieldsJson: fieldsJson ?? this.fieldsJson,
      hubSlug: hubSlug ?? this.hubSlug,
      hubAuthor: hubAuthor ?? this.hubAuthor,
      hubCategory: hubCategory ?? this.hubCategory,
      hubTagsJson: hubTagsJson ?? this.hubTagsJson,
      hubVersion: hubVersion ?? this.hubVersion,
      hubRepoUrl: hubRepoUrl ?? this.hubRepoUrl,
      hubCommitHash: hubCommitHash ?? this.hubCommitHash,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (gitUrl.present) {
      map['git_url'] = Variable<String>(gitUrl.value);
    }
    if (gitBranch.present) {
      map['git_branch'] = Variable<String>(gitBranch.value);
    }
    if (entryPoint.present) {
      map['entry_point'] = Variable<String>(entryPoint.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (readme.present) {
      map['readme'] = Variable<String>(readme.value);
    }
    if (requiredEnvJson.present) {
      map['required_env_json'] = Variable<String>(requiredEnvJson.value);
    }
    if (requiredMountsJson.present) {
      map['required_mounts_json'] = Variable<String>(requiredMountsJson.value);
    }
    if (fieldsJson.present) {
      map['fields_json'] = Variable<String>(fieldsJson.value);
    }
    if (hubSlug.present) {
      map['hub_slug'] = Variable<String>(hubSlug.value);
    }
    if (hubAuthor.present) {
      map['hub_author'] = Variable<String>(hubAuthor.value);
    }
    if (hubCategory.present) {
      map['hub_category'] = Variable<String>(hubCategory.value);
    }
    if (hubTagsJson.present) {
      map['hub_tags_json'] = Variable<String>(hubTagsJson.value);
    }
    if (hubVersion.present) {
      map['hub_version'] = Variable<int>(hubVersion.value);
    }
    if (hubRepoUrl.present) {
      map['hub_repo_url'] = Variable<String>(hubRepoUrl.value);
    }
    if (hubCommitHash.present) {
      map['hub_commit_hash'] = Variable<String>(hubCommitHash.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentProvidersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('gitUrl: $gitUrl, ')
          ..write('gitBranch: $gitBranch, ')
          ..write('entryPoint: $entryPoint, ')
          ..write('description: $description, ')
          ..write('readme: $readme, ')
          ..write('requiredEnvJson: $requiredEnvJson, ')
          ..write('requiredMountsJson: $requiredMountsJson, ')
          ..write('fieldsJson: $fieldsJson, ')
          ..write('hubSlug: $hubSlug, ')
          ..write('hubAuthor: $hubAuthor, ')
          ..write('hubCategory: $hubCategory, ')
          ..write('hubTagsJson: $hubTagsJson, ')
          ..write('hubVersion: $hubVersion, ')
          ..write('hubRepoUrl: $hubRepoUrl, ')
          ..write('hubCommitHash: $hubCommitHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentTemplates extends Table
    with TableInfo<AgentTemplates, AgentTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentTemplates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _sourceUriMeta = const VerificationMeta(
    'sourceUri',
  );
  late final GeneratedColumn<String> sourceUri = GeneratedColumn<String>(
    'source_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%S.000Z\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%S.000Z\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%S.000Z\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%S.000Z\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    sourceUri,
    filePath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentTemplate> instance, {
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
    if (data.containsKey('source_uri')) {
      context.handle(
        _sourceUriMeta,
        sourceUri.isAcceptableOrUnknown(data['source_uri']!, _sourceUriMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceUriMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AgentTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_uri'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AgentTemplates createAlias(String alias) {
    return AgentTemplates(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentTemplate extends DataClass implements Insertable<AgentTemplate> {
  final String id;
  final String name;
  final String sourceUri;
  final String filePath;
  final String createdAt;
  final String updatedAt;
  const AgentTemplate({
    required this.id,
    required this.name,
    required this.sourceUri,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['source_uri'] = Variable<String>(sourceUri);
    map['file_path'] = Variable<String>(filePath);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AgentTemplatesCompanion toCompanion(bool nullToAbsent) {
    return AgentTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      sourceUri: Value(sourceUri),
      filePath: Value(filePath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sourceUri: serializer.fromJson<String>(json['source_uri']),
      filePath: serializer.fromJson<String>(json['file_path']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'source_uri': serializer.toJson<String>(sourceUri),
      'file_path': serializer.toJson<String>(filePath),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AgentTemplate copyWith({
    String? id,
    String? name,
    String? sourceUri,
    String? filePath,
    String? createdAt,
    String? updatedAt,
  }) => AgentTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    sourceUri: sourceUri ?? this.sourceUri,
    filePath: filePath ?? this.filePath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AgentTemplate copyWithCompanion(AgentTemplatesCompanion data) {
    return AgentTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sourceUri: data.sourceUri.present ? data.sourceUri.value : this.sourceUri,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, sourceUri, filePath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.sourceUri == this.sourceUri &&
          other.filePath == this.filePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AgentTemplatesCompanion extends UpdateCompanion<AgentTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> sourceUri;
  final Value<String> filePath;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AgentTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceUri = const Value.absent(),
    this.filePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentTemplatesCompanion.insert({
    required String id,
    required String name,
    required String sourceUri,
    required String filePath,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sourceUri = Value(sourceUri),
       filePath = Value(filePath);
  static Insertable<AgentTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? sourceUri,
    Expression<String>? filePath,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sourceUri != null) 'source_uri': sourceUri,
      if (filePath != null) 'file_path': filePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? sourceUri,
    Value<String>? filePath,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AgentTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sourceUri: sourceUri ?? this.sourceUri,
      filePath: filePath ?? this.filePath,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceUri.present) {
      map['source_uri'] = Variable<String>(sourceUri.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sourceUri: $sourceUri, ')
          ..write('filePath: $filePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ApiKeys extends Table with TableInfo<ApiKeys, ApiKey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ApiKeys(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _providerLabelMeta = const VerificationMeta(
    'providerLabel',
  );
  late final GeneratedColumn<String> providerLabel = GeneratedColumn<String>(
    'provider_label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _encryptedKeyMeta = const VerificationMeta(
    'encryptedKey',
  );
  late final GeneratedColumn<Uint8List> encryptedKey =
      GeneratedColumn<Uint8List>(
        'encrypted_key',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      );
  static const VerificationMeta _displayHintMeta = const VerificationMeta(
    'displayHint',
  );
  late final GeneratedColumn<String> displayHint = GeneratedColumn<String>(
    'display_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    providerLabel,
    encryptedKey,
    displayHint,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_keys';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiKey> instance, {
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
    if (data.containsKey('provider_label')) {
      context.handle(
        _providerLabelMeta,
        providerLabel.isAcceptableOrUnknown(
          data['provider_label']!,
          _providerLabelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerLabelMeta);
    }
    if (data.containsKey('encrypted_key')) {
      context.handle(
        _encryptedKeyMeta,
        encryptedKey.isAcceptableOrUnknown(
          data['encrypted_key']!,
          _encryptedKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedKeyMeta);
    }
    if (data.containsKey('display_hint')) {
      context.handle(
        _displayHintMeta,
        displayHint.isAcceptableOrUnknown(
          data['display_hint']!,
          _displayHintMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiKey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiKey(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      providerLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_label'],
      )!,
      encryptedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}encrypted_key'],
      )!,
      displayHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_hint'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  ApiKeys createAlias(String alias) {
    return ApiKeys(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ApiKey extends DataClass implements Insertable<ApiKey> {
  final String id;
  final String name;
  final String providerLabel;
  final Uint8List encryptedKey;
  final String? displayHint;
  final String createdAt;
  const ApiKey({
    required this.id,
    required this.name,
    required this.providerLabel,
    required this.encryptedKey,
    this.displayHint,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['provider_label'] = Variable<String>(providerLabel);
    map['encrypted_key'] = Variable<Uint8List>(encryptedKey);
    if (!nullToAbsent || displayHint != null) {
      map['display_hint'] = Variable<String>(displayHint);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  ApiKeysCompanion toCompanion(bool nullToAbsent) {
    return ApiKeysCompanion(
      id: Value(id),
      name: Value(name),
      providerLabel: Value(providerLabel),
      encryptedKey: Value(encryptedKey),
      displayHint: displayHint == null && nullToAbsent
          ? const Value.absent()
          : Value(displayHint),
      createdAt: Value(createdAt),
    );
  }

  factory ApiKey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiKey(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      providerLabel: serializer.fromJson<String>(json['provider_label']),
      encryptedKey: serializer.fromJson<Uint8List>(json['encrypted_key']),
      displayHint: serializer.fromJson<String?>(json['display_hint']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'provider_label': serializer.toJson<String>(providerLabel),
      'encrypted_key': serializer.toJson<Uint8List>(encryptedKey),
      'display_hint': serializer.toJson<String?>(displayHint),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  ApiKey copyWith({
    String? id,
    String? name,
    String? providerLabel,
    Uint8List? encryptedKey,
    Value<String?> displayHint = const Value.absent(),
    String? createdAt,
  }) => ApiKey(
    id: id ?? this.id,
    name: name ?? this.name,
    providerLabel: providerLabel ?? this.providerLabel,
    encryptedKey: encryptedKey ?? this.encryptedKey,
    displayHint: displayHint.present ? displayHint.value : this.displayHint,
    createdAt: createdAt ?? this.createdAt,
  );
  ApiKey copyWithCompanion(ApiKeysCompanion data) {
    return ApiKey(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      providerLabel: data.providerLabel.present
          ? data.providerLabel.value
          : this.providerLabel,
      encryptedKey: data.encryptedKey.present
          ? data.encryptedKey.value
          : this.encryptedKey,
      displayHint: data.displayHint.present
          ? data.displayHint.value
          : this.displayHint,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiKey(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerLabel: $providerLabel, ')
          ..write('encryptedKey: $encryptedKey, ')
          ..write('displayHint: $displayHint, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    providerLabel,
    $driftBlobEquality.hash(encryptedKey),
    displayHint,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiKey &&
          other.id == this.id &&
          other.name == this.name &&
          other.providerLabel == this.providerLabel &&
          $driftBlobEquality.equals(other.encryptedKey, this.encryptedKey) &&
          other.displayHint == this.displayHint &&
          other.createdAt == this.createdAt);
}

class ApiKeysCompanion extends UpdateCompanion<ApiKey> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> providerLabel;
  final Value<Uint8List> encryptedKey;
  final Value<String?> displayHint;
  final Value<String> createdAt;
  final Value<int> rowid;
  const ApiKeysCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.providerLabel = const Value.absent(),
    this.encryptedKey = const Value.absent(),
    this.displayHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiKeysCompanion.insert({
    required String id,
    required String name,
    required String providerLabel,
    required Uint8List encryptedKey,
    this.displayHint = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       providerLabel = Value(providerLabel),
       encryptedKey = Value(encryptedKey);
  static Insertable<ApiKey> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? providerLabel,
    Expression<Uint8List>? encryptedKey,
    Expression<String>? displayHint,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (providerLabel != null) 'provider_label': providerLabel,
      if (encryptedKey != null) 'encrypted_key': encryptedKey,
      if (displayHint != null) 'display_hint': displayHint,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiKeysCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? providerLabel,
    Value<Uint8List>? encryptedKey,
    Value<String?>? displayHint,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return ApiKeysCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      providerLabel: providerLabel ?? this.providerLabel,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      displayHint: displayHint ?? this.displayHint,
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
    if (providerLabel.present) {
      map['provider_label'] = Variable<String>(providerLabel.value);
    }
    if (encryptedKey.present) {
      map['encrypted_key'] = Variable<Uint8List>(encryptedKey.value);
    }
    if (displayHint.present) {
      map['display_hint'] = Variable<String>(displayHint.value);
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
    return (StringBuffer('ApiKeysCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerLabel: $providerLabel, ')
          ..write('encryptedKey: $encryptedKey, ')
          ..write('displayHint: $displayHint, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Preferences extends Table with TableInfo<Preferences, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Preferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
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
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  Preferences createAlias(String alias) {
    return Preferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
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

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
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
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
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

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
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
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceTemplates extends Table
    with TableInfo<WorkspaceTemplates, WorkspaceTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceTemplates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubSlugMeta = const VerificationMeta(
    'hubSlug',
  );
  late final GeneratedColumn<String> hubSlug = GeneratedColumn<String>(
    'hub_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hubAuthorMeta = const VerificationMeta(
    'hubAuthor',
  );
  late final GeneratedColumn<String> hubAuthor = GeneratedColumn<String>(
    'hub_author',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _hubCategoryMeta = const VerificationMeta(
    'hubCategory',
  );
  late final GeneratedColumn<String> hubCategory = GeneratedColumn<String>(
    'hub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hubTagsJsonMeta = const VerificationMeta(
    'hubTagsJson',
  );
  late final GeneratedColumn<String> hubTagsJson = GeneratedColumn<String>(
    'hub_tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _hubVersionMeta = const VerificationMeta(
    'hubVersion',
  );
  late final GeneratedColumn<int> hubVersion = GeneratedColumn<int>(
    'hub_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _agentRefsJsonMeta = const VerificationMeta(
    'agentRefsJson',
  );
  late final GeneratedColumn<String> agentRefsJson = GeneratedColumn<String>(
    'agent_refs_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\'',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    hubSlug,
    hubAuthor,
    hubCategory,
    hubTagsJson,
    hubVersion,
    configJson,
    agentRefsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceTemplate> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('hub_slug')) {
      context.handle(
        _hubSlugMeta,
        hubSlug.isAcceptableOrUnknown(data['hub_slug']!, _hubSlugMeta),
      );
    } else if (isInserting) {
      context.missing(_hubSlugMeta);
    }
    if (data.containsKey('hub_author')) {
      context.handle(
        _hubAuthorMeta,
        hubAuthor.isAcceptableOrUnknown(data['hub_author']!, _hubAuthorMeta),
      );
    } else if (isInserting) {
      context.missing(_hubAuthorMeta);
    }
    if (data.containsKey('hub_category')) {
      context.handle(
        _hubCategoryMeta,
        hubCategory.isAcceptableOrUnknown(
          data['hub_category']!,
          _hubCategoryMeta,
        ),
      );
    }
    if (data.containsKey('hub_tags_json')) {
      context.handle(
        _hubTagsJsonMeta,
        hubTagsJson.isAcceptableOrUnknown(
          data['hub_tags_json']!,
          _hubTagsJsonMeta,
        ),
      );
    }
    if (data.containsKey('hub_version')) {
      context.handle(
        _hubVersionMeta,
        hubVersion.isAcceptableOrUnknown(data['hub_version']!, _hubVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_hubVersionMeta);
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_configJsonMeta);
    }
    if (data.containsKey('agent_refs_json')) {
      context.handle(
        _agentRefsJsonMeta,
        agentRefsJson.isAcceptableOrUnknown(
          data['agent_refs_json']!,
          _agentRefsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      hubSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_slug'],
      )!,
      hubAuthor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_author'],
      )!,
      hubCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_category'],
      ),
      hubTagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hub_tags_json'],
      )!,
      hubVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hub_version'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      )!,
      agentRefsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_refs_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  WorkspaceTemplates createAlias(String alias) {
    return WorkspaceTemplates(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceTemplate extends DataClass
    implements Insertable<WorkspaceTemplate> {
  final String id;
  final String name;
  final String? description;
  final String hubSlug;
  final String hubAuthor;
  final String? hubCategory;
  final String hubTagsJson;
  final int hubVersion;
  final String configJson;
  final String agentRefsJson;
  final String createdAt;
  final String updatedAt;
  const WorkspaceTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.hubSlug,
    required this.hubAuthor,
    this.hubCategory,
    required this.hubTagsJson,
    required this.hubVersion,
    required this.configJson,
    required this.agentRefsJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['hub_slug'] = Variable<String>(hubSlug);
    map['hub_author'] = Variable<String>(hubAuthor);
    if (!nullToAbsent || hubCategory != null) {
      map['hub_category'] = Variable<String>(hubCategory);
    }
    map['hub_tags_json'] = Variable<String>(hubTagsJson);
    map['hub_version'] = Variable<int>(hubVersion);
    map['config_json'] = Variable<String>(configJson);
    map['agent_refs_json'] = Variable<String>(agentRefsJson);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WorkspaceTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      hubSlug: Value(hubSlug),
      hubAuthor: Value(hubAuthor),
      hubCategory: hubCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(hubCategory),
      hubTagsJson: Value(hubTagsJson),
      hubVersion: Value(hubVersion),
      configJson: Value(configJson),
      agentRefsJson: Value(agentRefsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkspaceTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      hubSlug: serializer.fromJson<String>(json['hub_slug']),
      hubAuthor: serializer.fromJson<String>(json['hub_author']),
      hubCategory: serializer.fromJson<String?>(json['hub_category']),
      hubTagsJson: serializer.fromJson<String>(json['hub_tags_json']),
      hubVersion: serializer.fromJson<int>(json['hub_version']),
      configJson: serializer.fromJson<String>(json['config_json']),
      agentRefsJson: serializer.fromJson<String>(json['agent_refs_json']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'hub_slug': serializer.toJson<String>(hubSlug),
      'hub_author': serializer.toJson<String>(hubAuthor),
      'hub_category': serializer.toJson<String?>(hubCategory),
      'hub_tags_json': serializer.toJson<String>(hubTagsJson),
      'hub_version': serializer.toJson<int>(hubVersion),
      'config_json': serializer.toJson<String>(configJson),
      'agent_refs_json': serializer.toJson<String>(agentRefsJson),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  WorkspaceTemplate copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    String? hubSlug,
    String? hubAuthor,
    Value<String?> hubCategory = const Value.absent(),
    String? hubTagsJson,
    int? hubVersion,
    String? configJson,
    String? agentRefsJson,
    String? createdAt,
    String? updatedAt,
  }) => WorkspaceTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    hubSlug: hubSlug ?? this.hubSlug,
    hubAuthor: hubAuthor ?? this.hubAuthor,
    hubCategory: hubCategory.present ? hubCategory.value : this.hubCategory,
    hubTagsJson: hubTagsJson ?? this.hubTagsJson,
    hubVersion: hubVersion ?? this.hubVersion,
    configJson: configJson ?? this.configJson,
    agentRefsJson: agentRefsJson ?? this.agentRefsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkspaceTemplate copyWithCompanion(WorkspaceTemplatesCompanion data) {
    return WorkspaceTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      hubSlug: data.hubSlug.present ? data.hubSlug.value : this.hubSlug,
      hubAuthor: data.hubAuthor.present ? data.hubAuthor.value : this.hubAuthor,
      hubCategory: data.hubCategory.present
          ? data.hubCategory.value
          : this.hubCategory,
      hubTagsJson: data.hubTagsJson.present
          ? data.hubTagsJson.value
          : this.hubTagsJson,
      hubVersion: data.hubVersion.present
          ? data.hubVersion.value
          : this.hubVersion,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      agentRefsJson: data.agentRefsJson.present
          ? data.agentRefsJson.value
          : this.agentRefsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('hubSlug: $hubSlug, ')
          ..write('hubAuthor: $hubAuthor, ')
          ..write('hubCategory: $hubCategory, ')
          ..write('hubTagsJson: $hubTagsJson, ')
          ..write('hubVersion: $hubVersion, ')
          ..write('configJson: $configJson, ')
          ..write('agentRefsJson: $agentRefsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    hubSlug,
    hubAuthor,
    hubCategory,
    hubTagsJson,
    hubVersion,
    configJson,
    agentRefsJson,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.hubSlug == this.hubSlug &&
          other.hubAuthor == this.hubAuthor &&
          other.hubCategory == this.hubCategory &&
          other.hubTagsJson == this.hubTagsJson &&
          other.hubVersion == this.hubVersion &&
          other.configJson == this.configJson &&
          other.agentRefsJson == this.agentRefsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorkspaceTemplatesCompanion extends UpdateCompanion<WorkspaceTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> hubSlug;
  final Value<String> hubAuthor;
  final Value<String?> hubCategory;
  final Value<String> hubTagsJson;
  final Value<int> hubVersion;
  final Value<String> configJson;
  final Value<String> agentRefsJson;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WorkspaceTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.hubSlug = const Value.absent(),
    this.hubAuthor = const Value.absent(),
    this.hubCategory = const Value.absent(),
    this.hubTagsJson = const Value.absent(),
    this.hubVersion = const Value.absent(),
    this.configJson = const Value.absent(),
    this.agentRefsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceTemplatesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required String hubSlug,
    required String hubAuthor,
    this.hubCategory = const Value.absent(),
    this.hubTagsJson = const Value.absent(),
    required int hubVersion,
    required String configJson,
    this.agentRefsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       hubSlug = Value(hubSlug),
       hubAuthor = Value(hubAuthor),
       hubVersion = Value(hubVersion),
       configJson = Value(configJson);
  static Insertable<WorkspaceTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? hubSlug,
    Expression<String>? hubAuthor,
    Expression<String>? hubCategory,
    Expression<String>? hubTagsJson,
    Expression<int>? hubVersion,
    Expression<String>? configJson,
    Expression<String>? agentRefsJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (hubSlug != null) 'hub_slug': hubSlug,
      if (hubAuthor != null) 'hub_author': hubAuthor,
      if (hubCategory != null) 'hub_category': hubCategory,
      if (hubTagsJson != null) 'hub_tags_json': hubTagsJson,
      if (hubVersion != null) 'hub_version': hubVersion,
      if (configJson != null) 'config_json': configJson,
      if (agentRefsJson != null) 'agent_refs_json': agentRefsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? hubSlug,
    Value<String>? hubAuthor,
    Value<String?>? hubCategory,
    Value<String>? hubTagsJson,
    Value<int>? hubVersion,
    Value<String>? configJson,
    Value<String>? agentRefsJson,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hubSlug: hubSlug ?? this.hubSlug,
      hubAuthor: hubAuthor ?? this.hubAuthor,
      hubCategory: hubCategory ?? this.hubCategory,
      hubTagsJson: hubTagsJson ?? this.hubTagsJson,
      hubVersion: hubVersion ?? this.hubVersion,
      configJson: configJson ?? this.configJson,
      agentRefsJson: agentRefsJson ?? this.agentRefsJson,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (hubSlug.present) {
      map['hub_slug'] = Variable<String>(hubSlug.value);
    }
    if (hubAuthor.present) {
      map['hub_author'] = Variable<String>(hubAuthor.value);
    }
    if (hubCategory.present) {
      map['hub_category'] = Variable<String>(hubCategory.value);
    }
    if (hubTagsJson.present) {
      map['hub_tags_json'] = Variable<String>(hubTagsJson.value);
    }
    if (hubVersion.present) {
      map['hub_version'] = Variable<int>(hubVersion.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (agentRefsJson.present) {
      map['agent_refs_json'] = Variable<String>(agentRefsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('hubSlug: $hubSlug, ')
          ..write('hubAuthor: $hubAuthor, ')
          ..write('hubCategory: $hubCategory, ')
          ..write('hubTagsJson: $hubTagsJson, ')
          ..write('hubVersion: $hubVersion, ')
          ..write('configJson: $configJson, ')
          ..write('agentRefsJson: $agentRefsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class InstanceResults extends Table
    with TableInfo<InstanceResults, InstanceResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  InstanceResults(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _turnIdMeta = const VerificationMeta('turnId');
  late final GeneratedColumn<String> turnId = GeneratedColumn<String>(
    'turn_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _requestIdMeta = const VerificationMeta(
    'requestId',
  );
  late final GeneratedColumn<String> requestId = GeneratedColumn<String>(
    'request_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    requestId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'instance_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstanceResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('turn_id')) {
      context.handle(
        _turnIdMeta,
        turnId.isAcceptableOrUnknown(data['turn_id']!, _turnIdMeta),
      );
    } else if (isInserting) {
      context.missing(_turnIdMeta);
    }
    if (data.containsKey('request_id')) {
      context.handle(
        _requestIdMeta,
        requestId.isAcceptableOrUnknown(data['request_id']!, _requestIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstanceResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstanceResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      turnId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}turn_id'],
      )!,
      requestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  InstanceResults createAlias(String alias) {
    return InstanceResults(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class InstanceResult extends DataClass implements Insertable<InstanceResult> {
  final String id;
  final String runId;
  final String agentKey;
  final String instanceId;
  final String turnId;
  final String? requestId;
  final String createdAt;
  const InstanceResult({
    required this.id,
    required this.runId,
    required this.agentKey,
    required this.instanceId,
    required this.turnId,
    this.requestId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['instance_id'] = Variable<String>(instanceId);
    map['turn_id'] = Variable<String>(turnId);
    if (!nullToAbsent || requestId != null) {
      map['request_id'] = Variable<String>(requestId);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  InstanceResultsCompanion toCompanion(bool nullToAbsent) {
    return InstanceResultsCompanion(
      id: Value(id),
      runId: Value(runId),
      agentKey: Value(agentKey),
      instanceId: Value(instanceId),
      turnId: Value(turnId),
      requestId: requestId == null && nullToAbsent
          ? const Value.absent()
          : Value(requestId),
      createdAt: Value(createdAt),
    );
  }

  factory InstanceResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstanceResult(
      id: serializer.fromJson<String>(json['id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      instanceId: serializer.fromJson<String>(json['instance_id']),
      turnId: serializer.fromJson<String>(json['turn_id']),
      requestId: serializer.fromJson<String?>(json['request_id']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'instance_id': serializer.toJson<String>(instanceId),
      'turn_id': serializer.toJson<String>(turnId),
      'request_id': serializer.toJson<String?>(requestId),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  InstanceResult copyWith({
    String? id,
    String? runId,
    String? agentKey,
    String? instanceId,
    String? turnId,
    Value<String?> requestId = const Value.absent(),
    String? createdAt,
  }) => InstanceResult(
    id: id ?? this.id,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    instanceId: instanceId ?? this.instanceId,
    turnId: turnId ?? this.turnId,
    requestId: requestId.present ? requestId.value : this.requestId,
    createdAt: createdAt ?? this.createdAt,
  );
  InstanceResult copyWithCompanion(InstanceResultsCompanion data) {
    return InstanceResult(
      id: data.id.present ? data.id.value : this.id,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      turnId: data.turnId.present ? data.turnId.value : this.turnId,
      requestId: data.requestId.present ? data.requestId.value : this.requestId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstanceResult(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('requestId: $requestId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    runId,
    agentKey,
    instanceId,
    turnId,
    requestId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstanceResult &&
          other.id == this.id &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.instanceId == this.instanceId &&
          other.turnId == this.turnId &&
          other.requestId == this.requestId &&
          other.createdAt == this.createdAt);
}

class InstanceResultsCompanion extends UpdateCompanion<InstanceResult> {
  final Value<String> id;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> instanceId;
  final Value<String> turnId;
  final Value<String?> requestId;
  final Value<String> createdAt;
  final Value<int> rowid;
  const InstanceResultsCompanion({
    this.id = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.instanceId = const Value.absent(),
    this.turnId = const Value.absent(),
    this.requestId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstanceResultsCompanion.insert({
    required String id,
    required String runId,
    required String agentKey,
    required String instanceId,
    required String turnId,
    this.requestId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       runId = Value(runId),
       agentKey = Value(agentKey),
       instanceId = Value(instanceId),
       turnId = Value(turnId);
  static Insertable<InstanceResult> custom({
    Expression<String>? id,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? instanceId,
    Expression<String>? turnId,
    Expression<String>? requestId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (instanceId != null) 'instance_id': instanceId,
      if (turnId != null) 'turn_id': turnId,
      if (requestId != null) 'request_id': requestId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstanceResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? instanceId,
    Value<String>? turnId,
    Value<String?>? requestId,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return InstanceResultsCompanion(
      id: id ?? this.id,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      instanceId: instanceId ?? this.instanceId,
      turnId: turnId ?? this.turnId,
      requestId: requestId ?? this.requestId,
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
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (turnId.present) {
      map['turn_id'] = Variable<String>(turnId.value);
    }
    if (requestId.present) {
      map['request_id'] = Variable<String>(requestId.value);
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
    return (StringBuffer('InstanceResultsCompanion(')
          ..write('id: $id, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('instanceId: $instanceId, ')
          ..write('turnId: $turnId, ')
          ..write('requestId: $requestId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentInstanceStates extends Table
    with TableInfo<AgentInstanceStates, AgentInstanceState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentInstanceStates(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _instanceIdMeta = const VerificationMeta(
    'instanceId',
  );
  late final GeneratedColumn<String> instanceId = GeneratedColumn<String>(
    'instance_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'idle\'',
    defaultValue: const CustomExpression('\'idle\''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    instanceId,
    runId,
    agentKey,
    state,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_instance_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentInstanceState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('instance_id')) {
      context.handle(
        _instanceIdMeta,
        instanceId.isAcceptableOrUnknown(data['instance_id']!, _instanceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_instanceIdMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {instanceId};
  @override
  AgentInstanceState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentInstanceState(
      instanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instance_id'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AgentInstanceStates createAlias(String alias) {
    return AgentInstanceStates(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AgentInstanceState extends DataClass
    implements Insertable<AgentInstanceState> {
  final String instanceId;
  final String runId;
  final String agentKey;
  final String state;
  final String updatedAt;
  const AgentInstanceState({
    required this.instanceId,
    required this.runId,
    required this.agentKey,
    required this.state,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['instance_id'] = Variable<String>(instanceId);
    map['run_id'] = Variable<String>(runId);
    map['agent_key'] = Variable<String>(agentKey);
    map['state'] = Variable<String>(state);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AgentInstanceStatesCompanion toCompanion(bool nullToAbsent) {
    return AgentInstanceStatesCompanion(
      instanceId: Value(instanceId),
      runId: Value(runId),
      agentKey: Value(agentKey),
      state: Value(state),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentInstanceState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentInstanceState(
      instanceId: serializer.fromJson<String>(json['instance_id']),
      runId: serializer.fromJson<String>(json['run_id']),
      agentKey: serializer.fromJson<String>(json['agent_key']),
      state: serializer.fromJson<String>(json['state']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'instance_id': serializer.toJson<String>(instanceId),
      'run_id': serializer.toJson<String>(runId),
      'agent_key': serializer.toJson<String>(agentKey),
      'state': serializer.toJson<String>(state),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AgentInstanceState copyWith({
    String? instanceId,
    String? runId,
    String? agentKey,
    String? state,
    String? updatedAt,
  }) => AgentInstanceState(
    instanceId: instanceId ?? this.instanceId,
    runId: runId ?? this.runId,
    agentKey: agentKey ?? this.agentKey,
    state: state ?? this.state,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AgentInstanceState copyWithCompanion(AgentInstanceStatesCompanion data) {
    return AgentInstanceState(
      instanceId: data.instanceId.present
          ? data.instanceId.value
          : this.instanceId,
      runId: data.runId.present ? data.runId.value : this.runId,
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      state: data.state.present ? data.state.value : this.state,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentInstanceState(')
          ..write('instanceId: $instanceId, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(instanceId, runId, agentKey, state, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentInstanceState &&
          other.instanceId == this.instanceId &&
          other.runId == this.runId &&
          other.agentKey == this.agentKey &&
          other.state == this.state &&
          other.updatedAt == this.updatedAt);
}

class AgentInstanceStatesCompanion extends UpdateCompanion<AgentInstanceState> {
  final Value<String> instanceId;
  final Value<String> runId;
  final Value<String> agentKey;
  final Value<String> state;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AgentInstanceStatesCompanion({
    this.instanceId = const Value.absent(),
    this.runId = const Value.absent(),
    this.agentKey = const Value.absent(),
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentInstanceStatesCompanion.insert({
    required String instanceId,
    required String runId,
    required String agentKey,
    this.state = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : instanceId = Value(instanceId),
       runId = Value(runId),
       agentKey = Value(agentKey);
  static Insertable<AgentInstanceState> custom({
    Expression<String>? instanceId,
    Expression<String>? runId,
    Expression<String>? agentKey,
    Expression<String>? state,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (instanceId != null) 'instance_id': instanceId,
      if (runId != null) 'run_id': runId,
      if (agentKey != null) 'agent_key': agentKey,
      if (state != null) 'state': state,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentInstanceStatesCompanion copyWith({
    Value<String>? instanceId,
    Value<String>? runId,
    Value<String>? agentKey,
    Value<String>? state,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AgentInstanceStatesCompanion(
      instanceId: instanceId ?? this.instanceId,
      runId: runId ?? this.runId,
      agentKey: agentKey ?? this.agentKey,
      state: state ?? this.state,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (instanceId.present) {
      map['instance_id'] = Variable<String>(instanceId.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentInstanceStatesCompanion(')
          ..write('instanceId: $instanceId, ')
          ..write('runId: $runId, ')
          ..write('agentKey: $agentKey, ')
          ..write('state: $state, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class AgentConnectionStatus extends Table
    with TableInfo<AgentConnectionStatus, AgentConnectionStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AgentConnectionStatus(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _agentKeyMeta = const VerificationMeta(
    'agentKey',
  );
  late final GeneratedColumn<String> agentKey = GeneratedColumn<String>(
    'agent_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _connectedMeta = const VerificationMeta(
    'connected',
  );
  late final GeneratedColumn<int> connected = GeneratedColumn<int>(
    'connected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [agentKey, runId, connected, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'agent_connection_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<AgentConnectionStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('agent_key')) {
      context.handle(
        _agentKeyMeta,
        agentKey.isAcceptableOrUnknown(data['agent_key']!, _agentKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_agentKeyMeta);
    }
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('connected')) {
      context.handle(
        _connectedMeta,
        connected.isAcceptableOrUnknown(data['connected']!, _connectedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {agentKey, runId};
  @override
  AgentConnectionStatusData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AgentConnectionStatusData(
      agentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}agent_key'],
      )!,
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      connected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}connected'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  AgentConnectionStatus createAlias(String alias) {
    return AgentConnectionStatus(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(agent_key, run_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class AgentConnectionStatusData extends DataClass
    implements Insertable<AgentConnectionStatusData> {
  final String agentKey;
  final String runId;
  final int connected;
  final String updatedAt;
  const AgentConnectionStatusData({
    required this.agentKey,
    required this.runId,
    required this.connected,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['agent_key'] = Variable<String>(agentKey);
    map['run_id'] = Variable<String>(runId);
    map['connected'] = Variable<int>(connected);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  AgentConnectionStatusCompanion toCompanion(bool nullToAbsent) {
    return AgentConnectionStatusCompanion(
      agentKey: Value(agentKey),
      runId: Value(runId),
      connected: Value(connected),
      updatedAt: Value(updatedAt),
    );
  }

  factory AgentConnectionStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AgentConnectionStatusData(
      agentKey: serializer.fromJson<String>(json['agent_key']),
      runId: serializer.fromJson<String>(json['run_id']),
      connected: serializer.fromJson<int>(json['connected']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'agent_key': serializer.toJson<String>(agentKey),
      'run_id': serializer.toJson<String>(runId),
      'connected': serializer.toJson<int>(connected),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  AgentConnectionStatusData copyWith({
    String? agentKey,
    String? runId,
    int? connected,
    String? updatedAt,
  }) => AgentConnectionStatusData(
    agentKey: agentKey ?? this.agentKey,
    runId: runId ?? this.runId,
    connected: connected ?? this.connected,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AgentConnectionStatusData copyWithCompanion(
    AgentConnectionStatusCompanion data,
  ) {
    return AgentConnectionStatusData(
      agentKey: data.agentKey.present ? data.agentKey.value : this.agentKey,
      runId: data.runId.present ? data.runId.value : this.runId,
      connected: data.connected.present ? data.connected.value : this.connected,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AgentConnectionStatusData(')
          ..write('agentKey: $agentKey, ')
          ..write('runId: $runId, ')
          ..write('connected: $connected, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(agentKey, runId, connected, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgentConnectionStatusData &&
          other.agentKey == this.agentKey &&
          other.runId == this.runId &&
          other.connected == this.connected &&
          other.updatedAt == this.updatedAt);
}

class AgentConnectionStatusCompanion
    extends UpdateCompanion<AgentConnectionStatusData> {
  final Value<String> agentKey;
  final Value<String> runId;
  final Value<int> connected;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const AgentConnectionStatusCompanion({
    this.agentKey = const Value.absent(),
    this.runId = const Value.absent(),
    this.connected = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AgentConnectionStatusCompanion.insert({
    required String agentKey,
    required String runId,
    this.connected = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : agentKey = Value(agentKey),
       runId = Value(runId);
  static Insertable<AgentConnectionStatusData> custom({
    Expression<String>? agentKey,
    Expression<String>? runId,
    Expression<int>? connected,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (agentKey != null) 'agent_key': agentKey,
      if (runId != null) 'run_id': runId,
      if (connected != null) 'connected': connected,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AgentConnectionStatusCompanion copyWith({
    Value<String>? agentKey,
    Value<String>? runId,
    Value<int>? connected,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return AgentConnectionStatusCompanion(
      agentKey: agentKey ?? this.agentKey,
      runId: runId ?? this.runId,
      connected: connected ?? this.connected,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (agentKey.present) {
      map['agent_key'] = Variable<String>(agentKey.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (connected.present) {
      map['connected'] = Variable<int>(connected.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AgentConnectionStatusCompanion(')
          ..write('agentKey: $agentKey, ')
          ..write('runId: $runId, ')
          ..write('connected: $connected, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ContainerHealth extends Table
    with TableInfo<ContainerHealth, ContainerHealthData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ContainerHealth(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'unknown\'',
    defaultValue: const CustomExpression('\'unknown\''),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    runId,
    status,
    errorMessage,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'container_health';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContainerHealthData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId};
  @override
  ContainerHealthData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContainerHealthData(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  ContainerHealth createAlias(String alias) {
    return ContainerHealth(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ContainerHealthData extends DataClass
    implements Insertable<ContainerHealthData> {
  final String runId;
  final String status;
  final String? errorMessage;
  final String updatedAt;
  const ContainerHealthData({
    required this.runId,
    required this.status,
    this.errorMessage,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ContainerHealthCompanion toCompanion(bool nullToAbsent) {
    return ContainerHealthCompanion(
      runId: Value(runId),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContainerHealthData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContainerHealthData(
      runId: serializer.fromJson<String>(json['run_id']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['error_message']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'run_id': serializer.toJson<String>(runId),
      'status': serializer.toJson<String>(status),
      'error_message': serializer.toJson<String?>(errorMessage),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  ContainerHealthData copyWith({
    String? runId,
    String? status,
    Value<String?> errorMessage = const Value.absent(),
    String? updatedAt,
  }) => ContainerHealthData(
    runId: runId ?? this.runId,
    status: status ?? this.status,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContainerHealthData copyWithCompanion(ContainerHealthCompanion data) {
    return ContainerHealthData(
      runId: data.runId.present ? data.runId.value : this.runId,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContainerHealthData(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, status, errorMessage, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContainerHealthData &&
          other.runId == this.runId &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.updatedAt == this.updatedAt);
}

class ContainerHealthCompanion extends UpdateCompanion<ContainerHealthData> {
  final Value<String> runId;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ContainerHealthCompanion({
    this.runId = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContainerHealthCompanion.insert({
    required String runId,
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId);
  static Insertable<ContainerHealthData> custom({
    Expression<String>? runId,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContainerHealthCompanion copyWith({
    Value<String>? runId,
    Value<String>? status,
    Value<String?>? errorMessage,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContainerHealthCompanion(
      runId: runId ?? this.runId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContainerHealthCompanion(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class WorkspaceRunStatus extends Table
    with TableInfo<WorkspaceRunStatus, WorkspaceRunStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  WorkspaceRunStatus(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY REFERENCES workspace_runs(id)',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'starting\'',
    defaultValue: const CustomExpression('\'starting\''),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [runId, status, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspace_run_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceRunStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('run_id')) {
      context.handle(
        _runIdMeta,
        runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta),
      );
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {runId};
  @override
  WorkspaceRunStatusData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceRunStatusData(
      runId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}run_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  WorkspaceRunStatus createAlias(String alias) {
    return WorkspaceRunStatus(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class WorkspaceRunStatusData extends DataClass
    implements Insertable<WorkspaceRunStatusData> {
  final String runId;
  final String status;
  final String updatedAt;
  const WorkspaceRunStatusData({
    required this.runId,
    required this.status,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['run_id'] = Variable<String>(runId);
    map['status'] = Variable<String>(status);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  WorkspaceRunStatusCompanion toCompanion(bool nullToAbsent) {
    return WorkspaceRunStatusCompanion(
      runId: Value(runId),
      status: Value(status),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorkspaceRunStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceRunStatusData(
      runId: serializer.fromJson<String>(json['run_id']),
      status: serializer.fromJson<String>(json['status']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'run_id': serializer.toJson<String>(runId),
      'status': serializer.toJson<String>(status),
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  WorkspaceRunStatusData copyWith({
    String? runId,
    String? status,
    String? updatedAt,
  }) => WorkspaceRunStatusData(
    runId: runId ?? this.runId,
    status: status ?? this.status,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorkspaceRunStatusData copyWithCompanion(WorkspaceRunStatusCompanion data) {
    return WorkspaceRunStatusData(
      runId: data.runId.present ? data.runId.value : this.runId,
      status: data.status.present ? data.status.value : this.status,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRunStatusData(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(runId, status, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceRunStatusData &&
          other.runId == this.runId &&
          other.status == this.status &&
          other.updatedAt == this.updatedAt);
}

class WorkspaceRunStatusCompanion
    extends UpdateCompanion<WorkspaceRunStatusData> {
  final Value<String> runId;
  final Value<String> status;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const WorkspaceRunStatusCompanion({
    this.runId = const Value.absent(),
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspaceRunStatusCompanion.insert({
    required String runId,
    this.status = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId);
  static Insertable<WorkspaceRunStatusData> custom({
    Expression<String>? runId,
    Expression<String>? status,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (runId != null) 'run_id': runId,
      if (status != null) 'status': status,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspaceRunStatusCompanion copyWith({
    Value<String>? runId,
    Value<String>? status,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorkspaceRunStatusCompanion(
      runId: runId ?? this.runId,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceRunStatusCompanion(')
          ..write('runId: $runId, ')
          ..write('status: $status, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecentProjects extends Table
    with TableInfo<RecentProjects, RecentProject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecentProjects(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isGitRepoMeta = const VerificationMeta(
    'isGitRepo',
  );
  late final GeneratedColumn<int> isGitRepo = GeneratedColumn<int>(
    'is_git_repo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastUsedAtMeta = const VerificationMeta(
    'lastUsedAt',
  );
  late final GeneratedColumn<String> lastUsedAt = GeneratedColumn<String>(
    'last_used_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, name, isGitRepo, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentProject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_git_repo')) {
      context.handle(
        _isGitRepoMeta,
        isGitRepo.isAcceptableOrUnknown(data['is_git_repo']!, _isGitRepoMeta),
      );
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
        _lastUsedAtMeta,
        lastUsedAt.isAcceptableOrUnknown(
          data['last_used_at']!,
          _lastUsedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecentProject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentProject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isGitRepo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_git_repo'],
      )!,
      lastUsedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_used_at'],
      )!,
    );
  }

  @override
  RecentProjects createAlias(String alias) {
    return RecentProjects(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class RecentProject extends DataClass implements Insertable<RecentProject> {
  final String id;
  final String path;
  final String name;
  final int isGitRepo;
  final String lastUsedAt;
  const RecentProject({
    required this.id,
    required this.path,
    required this.name,
    required this.isGitRepo,
    required this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    map['name'] = Variable<String>(name);
    map['is_git_repo'] = Variable<int>(isGitRepo);
    map['last_used_at'] = Variable<String>(lastUsedAt);
    return map;
  }

  RecentProjectsCompanion toCompanion(bool nullToAbsent) {
    return RecentProjectsCompanion(
      id: Value(id),
      path: Value(path),
      name: Value(name),
      isGitRepo: Value(isGitRepo),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory RecentProject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentProject(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      name: serializer.fromJson<String>(json['name']),
      isGitRepo: serializer.fromJson<int>(json['is_git_repo']),
      lastUsedAt: serializer.fromJson<String>(json['last_used_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'name': serializer.toJson<String>(name),
      'is_git_repo': serializer.toJson<int>(isGitRepo),
      'last_used_at': serializer.toJson<String>(lastUsedAt),
    };
  }

  RecentProject copyWith({
    String? id,
    String? path,
    String? name,
    int? isGitRepo,
    String? lastUsedAt,
  }) => RecentProject(
    id: id ?? this.id,
    path: path ?? this.path,
    name: name ?? this.name,
    isGitRepo: isGitRepo ?? this.isGitRepo,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
  RecentProject copyWithCompanion(RecentProjectsCompanion data) {
    return RecentProject(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      name: data.name.present ? data.name.value : this.name,
      isGitRepo: data.isGitRepo.present ? data.isGitRepo.value : this.isGitRepo,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentProject(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('isGitRepo: $isGitRepo, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, name, isGitRepo, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentProject &&
          other.id == this.id &&
          other.path == this.path &&
          other.name == this.name &&
          other.isGitRepo == this.isGitRepo &&
          other.lastUsedAt == this.lastUsedAt);
}

class RecentProjectsCompanion extends UpdateCompanion<RecentProject> {
  final Value<String> id;
  final Value<String> path;
  final Value<String> name;
  final Value<int> isGitRepo;
  final Value<String> lastUsedAt;
  final Value<int> rowid;
  const RecentProjectsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.name = const Value.absent(),
    this.isGitRepo = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentProjectsCompanion.insert({
    required String id,
    required String path,
    required String name,
    this.isGitRepo = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path),
       name = Value(name);
  static Insertable<RecentProject> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? name,
    Expression<int>? isGitRepo,
    Expression<String>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (name != null) 'name': name,
      if (isGitRepo != null) 'is_git_repo': isGitRepo,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<String>? name,
    Value<int>? isGitRepo,
    Value<String>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return RecentProjectsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      isGitRepo: isGitRepo ?? this.isGitRepo,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isGitRepo.present) {
      map['is_git_repo'] = Variable<int>(isGitRepo.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<String>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentProjectsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('name: $name, ')
          ..write('isGitRepo: $isGitRepo, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EngineDatabase extends GeneratedDatabase {
  _$EngineDatabase(QueryExecutor e) : super(e);
  $EngineDatabaseManager get managers => $EngineDatabaseManager(this);
  late final Workspaces workspaces = Workspaces(this);
  late final WorkspaceRuns workspaceRuns = WorkspaceRuns(this);
  late final WorkspaceAgents workspaceAgents = WorkspaceAgents(this);
  late final AgentMessages agentMessages = AgentMessages(this);
  late final AgentLogs agentLogs = AgentLogs(this);
  late final AgentActivityEvents agentActivityEvents = AgentActivityEvents(
    this,
  );
  late final AgentUsageRecords agentUsageRecords = AgentUsageRecords(this);
  late final AgentFiles agentFiles = AgentFiles(this);
  late final WorkspaceInquiries workspaceInquiries = WorkspaceInquiries(this);
  late final AgentProviders agentProviders = AgentProviders(this);
  late final AgentTemplates agentTemplates = AgentTemplates(this);
  late final ApiKeys apiKeys = ApiKeys(this);
  late final Preferences preferences = Preferences(this);
  late final WorkspaceTemplates workspaceTemplates = WorkspaceTemplates(this);
  late final InstanceResults instanceResults = InstanceResults(this);
  late final AgentInstanceStates agentInstanceStates = AgentInstanceStates(
    this,
  );
  late final AgentConnectionStatus agentConnectionStatus =
      AgentConnectionStatus(this);
  late final ContainerHealth containerHealth = ContainerHealth(this);
  late final WorkspaceRunStatus workspaceRunStatus = WorkspaceRunStatus(this);
  late final RecentProjects recentProjects = RecentProjects(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    workspaceRuns,
    workspaceAgents,
    agentMessages,
    agentLogs,
    agentActivityEvents,
    agentUsageRecords,
    agentFiles,
    workspaceInquiries,
    agentProviders,
    agentTemplates,
    apiKeys,
    preferences,
    workspaceTemplates,
    instanceResults,
    agentInstanceStates,
    agentConnectionStatus,
    containerHealth,
    workspaceRunStatus,
    recentProjects,
  ];
}

typedef $WorkspacesCreateCompanionBuilder =
    WorkspacesCompanion Function({
      required String id,
      required String name,
      required String projectPath,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $WorkspacesUpdateCompanionBuilder =
    WorkspacesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> projectPath,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $WorkspacesReferences
    extends BaseReferences<_$EngineDatabase, Workspaces, Workspace> {
  $WorkspacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<WorkspaceRuns, List<WorkspaceRun>>
  _workspaceRunsRefsTable(_$EngineDatabase db) => MultiTypedResultKey.fromTable(
    db.workspaceRuns,
    aliasName: $_aliasNameGenerator(
      db.workspaces.id,
      db.workspaceRuns.workspaceId,
    ),
  );

  $WorkspaceRunsProcessedTableManager get workspaceRunsRefs {
    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workspaceRunsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $WorkspacesFilterComposer extends Composer<_$EngineDatabase, Workspaces> {
  $WorkspacesFilterComposer({
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

  ColumnFilters<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workspaceRunsRefs(
    Expression<bool> Function($WorkspaceRunsFilterComposer f) f,
  ) {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspacesOrderingComposer
    extends Composer<_$EngineDatabase, Workspaces> {
  $WorkspacesOrderingComposer({
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

  ColumnOrderings<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $WorkspacesAnnotationComposer
    extends Composer<_$EngineDatabase, Workspaces> {
  $WorkspacesAnnotationComposer({
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

  GeneratedColumn<String> get projectPath => $composableBuilder(
    column: $table.projectPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> workspaceRunsRefs<T extends Object>(
    Expression<T> Function($WorkspaceRunsAnnotationComposer a) f,
  ) {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspacesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          Workspaces,
          Workspace,
          $WorkspacesFilterComposer,
          $WorkspacesOrderingComposer,
          $WorkspacesAnnotationComposer,
          $WorkspacesCreateCompanionBuilder,
          $WorkspacesUpdateCompanionBuilder,
          (Workspace, $WorkspacesReferences),
          Workspace,
          PrefetchHooks Function({bool workspaceRunsRefs})
        > {
  $WorkspacesTableManager(_$EngineDatabase db, Workspaces table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspacesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspacesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspacesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> projectPath = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                projectPath: projectPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String projectPath,
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                projectPath: projectPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $WorkspacesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceRunsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workspaceRunsRefs) db.workspaceRuns,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workspaceRunsRefs)
                    await $_getPrefetchedData<
                      Workspace,
                      Workspaces,
                      WorkspaceRun
                    >(
                      currentTable: table,
                      referencedTable: $WorkspacesReferences
                          ._workspaceRunsRefsTable(db),
                      managerFromTypedResult: (p0) => $WorkspacesReferences(
                        db,
                        table,
                        p0,
                      ).workspaceRunsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.workspaceId == item.id,
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

typedef $WorkspacesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      Workspaces,
      Workspace,
      $WorkspacesFilterComposer,
      $WorkspacesOrderingComposer,
      $WorkspacesAnnotationComposer,
      $WorkspacesCreateCompanionBuilder,
      $WorkspacesUpdateCompanionBuilder,
      (Workspace, $WorkspacesReferences),
      Workspace,
      PrefetchHooks Function({bool workspaceRunsRefs})
    >;
typedef $WorkspaceRunsCreateCompanionBuilder =
    WorkspaceRunsCompanion Function({
      required String id,
      required String workspaceId,
      required int runNumber,
      Value<String> status,
      Value<String?> containerId,
      Value<int?> serverPort,
      Value<String?> apiKey,
      Value<String> startedAt,
      Value<String?> stoppedAt,
      Value<int> rowid,
    });
typedef $WorkspaceRunsUpdateCompanionBuilder =
    WorkspaceRunsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<int> runNumber,
      Value<String> status,
      Value<String?> containerId,
      Value<int?> serverPort,
      Value<String?> apiKey,
      Value<String> startedAt,
      Value<String?> stoppedAt,
      Value<int> rowid,
    });

final class $WorkspaceRunsReferences
    extends BaseReferences<_$EngineDatabase, WorkspaceRuns, WorkspaceRun> {
  $WorkspaceRunsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Workspaces _workspaceIdTable(_$EngineDatabase db) =>
      db.workspaces.createAlias(
        $_aliasNameGenerator(db.workspaceRuns.workspaceId, db.workspaces.id),
      );

  $WorkspacesProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $WorkspacesTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<WorkspaceAgents, List<WorkspaceAgent>>
  _workspaceAgentsRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceAgents,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.workspaceAgents.runId,
        ),
      );

  $WorkspaceAgentsProcessedTableManager get workspaceAgentsRefs {
    final manager = $WorkspaceAgentsTableManager(
      $_db,
      $_db.workspaceAgents,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceAgentsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentMessages, List<AgentMessage>>
  _agentMessagesRefsTable(_$EngineDatabase db) => MultiTypedResultKey.fromTable(
    db.agentMessages,
    aliasName: $_aliasNameGenerator(
      db.workspaceRuns.id,
      db.agentMessages.runId,
    ),
  );

  $AgentMessagesProcessedTableManager get agentMessagesRefs {
    final manager = $AgentMessagesTableManager(
      $_db,
      $_db.agentMessages,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_agentMessagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentLogs, List<AgentLog>> _agentLogsRefsTable(
    _$EngineDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.agentLogs,
    aliasName: $_aliasNameGenerator(db.workspaceRuns.id, db.agentLogs.runId),
  );

  $AgentLogsProcessedTableManager get agentLogsRefs {
    final manager = $AgentLogsTableManager(
      $_db,
      $_db.agentLogs,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_agentLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentActivityEvents, List<AgentActivityEvent>>
  _agentActivityEventsRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.agentActivityEvents,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.agentActivityEvents.runId,
        ),
      );

  $AgentActivityEventsProcessedTableManager get agentActivityEventsRefs {
    final manager = $AgentActivityEventsTableManager(
      $_db,
      $_db.agentActivityEvents,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentActivityEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentUsageRecords, List<AgentUsageRecord>>
  _agentUsageRecordsRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.agentUsageRecords,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.agentUsageRecords.runId,
        ),
      );

  $AgentUsageRecordsProcessedTableManager get agentUsageRecordsRefs {
    final manager = $AgentUsageRecordsTableManager(
      $_db,
      $_db.agentUsageRecords,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentUsageRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentFiles, List<AgentFile>> _agentFilesRefsTable(
    _$EngineDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.agentFiles,
    aliasName: $_aliasNameGenerator(db.workspaceRuns.id, db.agentFiles.runId),
  );

  $AgentFilesProcessedTableManager get agentFilesRefs {
    final manager = $AgentFilesTableManager(
      $_db,
      $_db.agentFiles,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_agentFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<WorkspaceInquiries, List<WorkspaceInquiry>>
  _workspaceInquiriesRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceInquiries,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.workspaceInquiries.runId,
        ),
      );

  $WorkspaceInquiriesProcessedTableManager get workspaceInquiriesRefs {
    final manager = $WorkspaceInquiriesTableManager(
      $_db,
      $_db.workspaceInquiries,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceInquiriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<InstanceResults, List<InstanceResult>>
  _instanceResultsRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.instanceResults,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.instanceResults.runId,
        ),
      );

  $InstanceResultsProcessedTableManager get instanceResultsRefs {
    final manager = $InstanceResultsTableManager(
      $_db,
      $_db.instanceResults,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _instanceResultsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<AgentInstanceStates, List<AgentInstanceState>>
  _agentInstanceStatesRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.agentInstanceStates,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.agentInstanceStates.runId,
        ),
      );

  $AgentInstanceStatesProcessedTableManager get agentInstanceStatesRefs {
    final manager = $AgentInstanceStatesTableManager(
      $_db,
      $_db.agentInstanceStates,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentInstanceStatesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    AgentConnectionStatus,
    List<AgentConnectionStatusData>
  >
  _agentConnectionStatusRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.agentConnectionStatus,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.agentConnectionStatus.runId,
        ),
      );

  $AgentConnectionStatusProcessedTableManager get agentConnectionStatusRefs {
    final manager = $AgentConnectionStatusTableManager(
      $_db,
      $_db.agentConnectionStatus,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _agentConnectionStatusRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ContainerHealth, List<ContainerHealthData>>
  _containerHealthRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.containerHealth,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.containerHealth.runId,
        ),
      );

  $ContainerHealthProcessedTableManager get containerHealthRefs {
    final manager = $ContainerHealthTableManager(
      $_db,
      $_db.containerHealth,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _containerHealthRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<WorkspaceRunStatus, List<WorkspaceRunStatusData>>
  _workspaceRunStatusRefsTable(_$EngineDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workspaceRunStatus,
        aliasName: $_aliasNameGenerator(
          db.workspaceRuns.id,
          db.workspaceRunStatus.runId,
        ),
      );

  $WorkspaceRunStatusProcessedTableManager get workspaceRunStatusRefs {
    final manager = $WorkspaceRunStatusTableManager(
      $_db,
      $_db.workspaceRunStatus,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _workspaceRunStatusRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $WorkspaceRunsFilterComposer
    extends Composer<_$EngineDatabase, WorkspaceRuns> {
  $WorkspaceRunsFilterComposer({
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

  ColumnFilters<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverPort => $composableBuilder(
    column: $table.serverPort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspacesFilterComposer get workspaceId {
    final $WorkspacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workspaceAgentsRefs(
    Expression<bool> Function($WorkspaceAgentsFilterComposer f) f,
  ) {
    final $WorkspaceAgentsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceAgents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceAgentsFilterComposer(
            $db: $db,
            $table: $db.workspaceAgents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentMessagesRefs(
    Expression<bool> Function($AgentMessagesFilterComposer f) f,
  ) {
    final $AgentMessagesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentMessages,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentMessagesFilterComposer(
            $db: $db,
            $table: $db.agentMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentLogsRefs(
    Expression<bool> Function($AgentLogsFilterComposer f) f,
  ) {
    final $AgentLogsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentLogs,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentLogsFilterComposer(
            $db: $db,
            $table: $db.agentLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentActivityEventsRefs(
    Expression<bool> Function($AgentActivityEventsFilterComposer f) f,
  ) {
    final $AgentActivityEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentActivityEvents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentActivityEventsFilterComposer(
            $db: $db,
            $table: $db.agentActivityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentUsageRecordsRefs(
    Expression<bool> Function($AgentUsageRecordsFilterComposer f) f,
  ) {
    final $AgentUsageRecordsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentUsageRecords,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentUsageRecordsFilterComposer(
            $db: $db,
            $table: $db.agentUsageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentFilesRefs(
    Expression<bool> Function($AgentFilesFilterComposer f) f,
  ) {
    final $AgentFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentFiles,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentFilesFilterComposer(
            $db: $db,
            $table: $db.agentFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workspaceInquiriesRefs(
    Expression<bool> Function($WorkspaceInquiriesFilterComposer f) f,
  ) {
    final $WorkspaceInquiriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceInquiries,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceInquiriesFilterComposer(
            $db: $db,
            $table: $db.workspaceInquiries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> instanceResultsRefs(
    Expression<bool> Function($InstanceResultsFilterComposer f) f,
  ) {
    final $InstanceResultsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instanceResults,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $InstanceResultsFilterComposer(
            $db: $db,
            $table: $db.instanceResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentInstanceStatesRefs(
    Expression<bool> Function($AgentInstanceStatesFilterComposer f) f,
  ) {
    final $AgentInstanceStatesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentInstanceStates,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentInstanceStatesFilterComposer(
            $db: $db,
            $table: $db.agentInstanceStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> agentConnectionStatusRefs(
    Expression<bool> Function($AgentConnectionStatusFilterComposer f) f,
  ) {
    final $AgentConnectionStatusFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentConnectionStatus,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentConnectionStatusFilterComposer(
            $db: $db,
            $table: $db.agentConnectionStatus,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> containerHealthRefs(
    Expression<bool> Function($ContainerHealthFilterComposer f) f,
  ) {
    final $ContainerHealthFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.containerHealth,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContainerHealthFilterComposer(
            $db: $db,
            $table: $db.containerHealth,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workspaceRunStatusRefs(
    Expression<bool> Function($WorkspaceRunStatusFilterComposer f) f,
  ) {
    final $WorkspaceRunStatusFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceRunStatus,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunStatusFilterComposer(
            $db: $db,
            $table: $db.workspaceRunStatus,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspaceRunsOrderingComposer
    extends Composer<_$EngineDatabase, WorkspaceRuns> {
  $WorkspaceRunsOrderingComposer({
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

  ColumnOrderings<int> get runNumber => $composableBuilder(
    column: $table.runNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverPort => $composableBuilder(
    column: $table.serverPort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiKey => $composableBuilder(
    column: $table.apiKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stoppedAt => $composableBuilder(
    column: $table.stoppedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspacesOrderingComposer get workspaceId {
    final $WorkspacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceRunsAnnotationComposer
    extends Composer<_$EngineDatabase, WorkspaceRuns> {
  $WorkspaceRunsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get runNumber =>
      $composableBuilder(column: $table.runNumber, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get containerId => $composableBuilder(
    column: $table.containerId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverPort => $composableBuilder(
    column: $table.serverPort,
    builder: (column) => column,
  );

  GeneratedColumn<String> get apiKey =>
      $composableBuilder(column: $table.apiKey, builder: (column) => column);

  GeneratedColumn<String> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<String> get stoppedAt =>
      $composableBuilder(column: $table.stoppedAt, builder: (column) => column);

  $WorkspacesAnnotationComposer get workspaceId {
    final $WorkspacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspacesAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workspaceAgentsRefs<T extends Object>(
    Expression<T> Function($WorkspaceAgentsAnnotationComposer a) f,
  ) {
    final $WorkspaceAgentsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceAgents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceAgentsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceAgents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentMessagesRefs<T extends Object>(
    Expression<T> Function($AgentMessagesAnnotationComposer a) f,
  ) {
    final $AgentMessagesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentMessages,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentMessagesAnnotationComposer(
            $db: $db,
            $table: $db.agentMessages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentLogsRefs<T extends Object>(
    Expression<T> Function($AgentLogsAnnotationComposer a) f,
  ) {
    final $AgentLogsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentLogs,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentLogsAnnotationComposer(
            $db: $db,
            $table: $db.agentLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentActivityEventsRefs<T extends Object>(
    Expression<T> Function($AgentActivityEventsAnnotationComposer a) f,
  ) {
    final $AgentActivityEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentActivityEvents,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentActivityEventsAnnotationComposer(
            $db: $db,
            $table: $db.agentActivityEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentUsageRecordsRefs<T extends Object>(
    Expression<T> Function($AgentUsageRecordsAnnotationComposer a) f,
  ) {
    final $AgentUsageRecordsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentUsageRecords,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentUsageRecordsAnnotationComposer(
            $db: $db,
            $table: $db.agentUsageRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentFilesRefs<T extends Object>(
    Expression<T> Function($AgentFilesAnnotationComposer a) f,
  ) {
    final $AgentFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentFiles,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentFilesAnnotationComposer(
            $db: $db,
            $table: $db.agentFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workspaceInquiriesRefs<T extends Object>(
    Expression<T> Function($WorkspaceInquiriesAnnotationComposer a) f,
  ) {
    final $WorkspaceInquiriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceInquiries,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceInquiriesAnnotationComposer(
            $db: $db,
            $table: $db.workspaceInquiries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> instanceResultsRefs<T extends Object>(
    Expression<T> Function($InstanceResultsAnnotationComposer a) f,
  ) {
    final $InstanceResultsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.instanceResults,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $InstanceResultsAnnotationComposer(
            $db: $db,
            $table: $db.instanceResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentInstanceStatesRefs<T extends Object>(
    Expression<T> Function($AgentInstanceStatesAnnotationComposer a) f,
  ) {
    final $AgentInstanceStatesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentInstanceStates,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentInstanceStatesAnnotationComposer(
            $db: $db,
            $table: $db.agentInstanceStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> agentConnectionStatusRefs<T extends Object>(
    Expression<T> Function($AgentConnectionStatusAnnotationComposer a) f,
  ) {
    final $AgentConnectionStatusAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.agentConnectionStatus,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $AgentConnectionStatusAnnotationComposer(
            $db: $db,
            $table: $db.agentConnectionStatus,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> containerHealthRefs<T extends Object>(
    Expression<T> Function($ContainerHealthAnnotationComposer a) f,
  ) {
    final $ContainerHealthAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.containerHealth,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ContainerHealthAnnotationComposer(
            $db: $db,
            $table: $db.containerHealth,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workspaceRunStatusRefs<T extends Object>(
    Expression<T> Function($WorkspaceRunStatusAnnotationComposer a) f,
  ) {
    final $WorkspaceRunStatusAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workspaceRunStatus,
      getReferencedColumn: (t) => t.runId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunStatusAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRunStatus,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $WorkspaceRunsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          WorkspaceRuns,
          WorkspaceRun,
          $WorkspaceRunsFilterComposer,
          $WorkspaceRunsOrderingComposer,
          $WorkspaceRunsAnnotationComposer,
          $WorkspaceRunsCreateCompanionBuilder,
          $WorkspaceRunsUpdateCompanionBuilder,
          (WorkspaceRun, $WorkspaceRunsReferences),
          WorkspaceRun,
          PrefetchHooks Function({
            bool workspaceId,
            bool workspaceAgentsRefs,
            bool agentMessagesRefs,
            bool agentLogsRefs,
            bool agentActivityEventsRefs,
            bool agentUsageRecordsRefs,
            bool agentFilesRefs,
            bool workspaceInquiriesRefs,
            bool instanceResultsRefs,
            bool agentInstanceStatesRefs,
            bool agentConnectionStatusRefs,
            bool containerHealthRefs,
            bool workspaceRunStatusRefs,
          })
        > {
  $WorkspaceRunsTableManager(_$EngineDatabase db, WorkspaceRuns table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceRunsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceRunsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceRunsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<int> runNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> containerId = const Value.absent(),
                Value<int?> serverPort = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> stoppedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRunsCompanion(
                id: id,
                workspaceId: workspaceId,
                runNumber: runNumber,
                status: status,
                containerId: containerId,
                serverPort: serverPort,
                apiKey: apiKey,
                startedAt: startedAt,
                stoppedAt: stoppedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required int runNumber,
                Value<String> status = const Value.absent(),
                Value<String?> containerId = const Value.absent(),
                Value<int?> serverPort = const Value.absent(),
                Value<String?> apiKey = const Value.absent(),
                Value<String> startedAt = const Value.absent(),
                Value<String?> stoppedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRunsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                runNumber: runNumber,
                status: status,
                containerId: containerId,
                serverPort: serverPort,
                apiKey: apiKey,
                startedAt: startedAt,
                stoppedAt: stoppedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $WorkspaceRunsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                workspaceAgentsRefs = false,
                agentMessagesRefs = false,
                agentLogsRefs = false,
                agentActivityEventsRefs = false,
                agentUsageRecordsRefs = false,
                agentFilesRefs = false,
                workspaceInquiriesRefs = false,
                instanceResultsRefs = false,
                agentInstanceStatesRefs = false,
                agentConnectionStatusRefs = false,
                containerHealthRefs = false,
                workspaceRunStatusRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workspaceAgentsRefs) db.workspaceAgents,
                    if (agentMessagesRefs) db.agentMessages,
                    if (agentLogsRefs) db.agentLogs,
                    if (agentActivityEventsRefs) db.agentActivityEvents,
                    if (agentUsageRecordsRefs) db.agentUsageRecords,
                    if (agentFilesRefs) db.agentFiles,
                    if (workspaceInquiriesRefs) db.workspaceInquiries,
                    if (instanceResultsRefs) db.instanceResults,
                    if (agentInstanceStatesRefs) db.agentInstanceStates,
                    if (agentConnectionStatusRefs) db.agentConnectionStatus,
                    if (containerHealthRefs) db.containerHealth,
                    if (workspaceRunStatusRefs) db.workspaceRunStatus,
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
                        if (workspaceId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.workspaceId,
                                    referencedTable: $WorkspaceRunsReferences
                                        ._workspaceIdTable(db),
                                    referencedColumn: $WorkspaceRunsReferences
                                        ._workspaceIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workspaceAgentsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          WorkspaceAgent
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._workspaceAgentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).workspaceAgentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentMessagesRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentMessage
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentMessagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentMessagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentLogsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentLog
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentActivityEventsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentActivityEvent
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentActivityEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentActivityEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentUsageRecordsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentUsageRecord
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentUsageRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentUsageRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentFilesRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentFile
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentFilesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentFilesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workspaceInquiriesRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          WorkspaceInquiry
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._workspaceInquiriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).workspaceInquiriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (instanceResultsRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          InstanceResult
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._instanceResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).instanceResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentInstanceStatesRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentInstanceState
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentInstanceStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentInstanceStatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (agentConnectionStatusRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          AgentConnectionStatusData
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._agentConnectionStatusRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).agentConnectionStatusRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (containerHealthRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          ContainerHealthData
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._containerHealthRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).containerHealthRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (workspaceRunStatusRefs)
                        await $_getPrefetchedData<
                          WorkspaceRun,
                          WorkspaceRuns,
                          WorkspaceRunStatusData
                        >(
                          currentTable: table,
                          referencedTable: $WorkspaceRunsReferences
                              ._workspaceRunStatusRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $WorkspaceRunsReferences(
                                db,
                                table,
                                p0,
                              ).workspaceRunStatusRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.runId == item.id,
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

typedef $WorkspaceRunsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      WorkspaceRuns,
      WorkspaceRun,
      $WorkspaceRunsFilterComposer,
      $WorkspaceRunsOrderingComposer,
      $WorkspaceRunsAnnotationComposer,
      $WorkspaceRunsCreateCompanionBuilder,
      $WorkspaceRunsUpdateCompanionBuilder,
      (WorkspaceRun, $WorkspaceRunsReferences),
      WorkspaceRun,
      PrefetchHooks Function({
        bool workspaceId,
        bool workspaceAgentsRefs,
        bool agentMessagesRefs,
        bool agentLogsRefs,
        bool agentActivityEventsRefs,
        bool agentUsageRecordsRefs,
        bool agentFilesRefs,
        bool workspaceInquiriesRefs,
        bool instanceResultsRefs,
        bool agentInstanceStatesRefs,
        bool agentConnectionStatusRefs,
        bool containerHealthRefs,
        bool workspaceRunStatusRefs,
      })
    >;
typedef $WorkspaceAgentsCreateCompanionBuilder =
    WorkspaceAgentsCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      required String displayName,
      Value<String> chainJson,
      Value<String> status,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $WorkspaceAgentsUpdateCompanionBuilder =
    WorkspaceAgentsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String> displayName,
      Value<String> chainJson,
      Value<String> status,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $WorkspaceAgentsReferences
    extends BaseReferences<_$EngineDatabase, WorkspaceAgents, WorkspaceAgent> {
  $WorkspaceAgentsReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.workspaceAgents.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $WorkspaceAgentsFilterComposer
    extends Composer<_$EngineDatabase, WorkspaceAgents> {
  $WorkspaceAgentsFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chainJson => $composableBuilder(
    column: $table.chainJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceAgentsOrderingComposer
    extends Composer<_$EngineDatabase, WorkspaceAgents> {
  $WorkspaceAgentsOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chainJson => $composableBuilder(
    column: $table.chainJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceAgentsAnnotationComposer
    extends Composer<_$EngineDatabase, WorkspaceAgents> {
  $WorkspaceAgentsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chainJson =>
      $composableBuilder(column: $table.chainJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceAgentsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          WorkspaceAgents,
          WorkspaceAgent,
          $WorkspaceAgentsFilterComposer,
          $WorkspaceAgentsOrderingComposer,
          $WorkspaceAgentsAnnotationComposer,
          $WorkspaceAgentsCreateCompanionBuilder,
          $WorkspaceAgentsUpdateCompanionBuilder,
          (WorkspaceAgent, $WorkspaceAgentsReferences),
          WorkspaceAgent,
          PrefetchHooks Function({bool runId})
        > {
  $WorkspaceAgentsTableManager(_$EngineDatabase db, WorkspaceAgents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceAgentsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceAgentsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceAgentsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> chainJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceAgentsCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                displayName: displayName,
                chainJson: chainJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                required String displayName,
                Value<String> chainJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceAgentsCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                displayName: displayName,
                chainJson: chainJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $WorkspaceAgentsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $WorkspaceAgentsReferences
                                    ._runIdTable(db),
                                referencedColumn: $WorkspaceAgentsReferences
                                    ._runIdTable(db)
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

typedef $WorkspaceAgentsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      WorkspaceAgents,
      WorkspaceAgent,
      $WorkspaceAgentsFilterComposer,
      $WorkspaceAgentsOrderingComposer,
      $WorkspaceAgentsAnnotationComposer,
      $WorkspaceAgentsCreateCompanionBuilder,
      $WorkspaceAgentsUpdateCompanionBuilder,
      (WorkspaceAgent, $WorkspaceAgentsReferences),
      WorkspaceAgent,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentMessagesCreateCompanionBuilder =
    AgentMessagesCompanion Function({
      required String id,
      required String runId,
      required String role,
      required String content,
      Value<String?> model,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      required String instanceId,
      Value<String?> turnId,
      Value<String?> senderName,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $AgentMessagesUpdateCompanionBuilder =
    AgentMessagesCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> role,
      Value<String> content,
      Value<String?> model,
      Value<int?> inputTokens,
      Value<int?> outputTokens,
      Value<String> instanceId,
      Value<String?> turnId,
      Value<String?> senderName,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $AgentMessagesReferences
    extends BaseReferences<_$EngineDatabase, AgentMessages, AgentMessage> {
  $AgentMessagesReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentMessages.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentMessagesFilterComposer
    extends Composer<_$EngineDatabase, AgentMessages> {
  $AgentMessagesFilterComposer({
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

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentMessagesOrderingComposer
    extends Composer<_$EngineDatabase, AgentMessages> {
  $AgentMessagesOrderingComposer({
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

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentMessagesAnnotationComposer
    extends Composer<_$EngineDatabase, AgentMessages> {
  $AgentMessagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get senderName => $composableBuilder(
    column: $table.senderName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentMessagesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentMessages,
          AgentMessage,
          $AgentMessagesFilterComposer,
          $AgentMessagesOrderingComposer,
          $AgentMessagesAnnotationComposer,
          $AgentMessagesCreateCompanionBuilder,
          $AgentMessagesUpdateCompanionBuilder,
          (AgentMessage, $AgentMessagesReferences),
          AgentMessage,
          PrefetchHooks Function({bool runId})
        > {
  $AgentMessagesTableManager(_$EngineDatabase db, AgentMessages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentMessagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentMessagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentMessagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentMessagesCompanion(
                id: id,
                runId: runId,
                role: role,
                content: content,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                instanceId: instanceId,
                turnId: turnId,
                senderName: senderName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String role,
                required String content,
                Value<String?> model = const Value.absent(),
                Value<int?> inputTokens = const Value.absent(),
                Value<int?> outputTokens = const Value.absent(),
                required String instanceId,
                Value<String?> turnId = const Value.absent(),
                Value<String?> senderName = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentMessagesCompanion.insert(
                id: id,
                runId: runId,
                role: role,
                content: content,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                instanceId: instanceId,
                turnId: turnId,
                senderName: senderName,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $AgentMessagesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentMessagesReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentMessagesReferences
                                    ._runIdTable(db)
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

typedef $AgentMessagesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentMessages,
      AgentMessage,
      $AgentMessagesFilterComposer,
      $AgentMessagesOrderingComposer,
      $AgentMessagesAnnotationComposer,
      $AgentMessagesCreateCompanionBuilder,
      $AgentMessagesUpdateCompanionBuilder,
      (AgentMessage, $AgentMessagesReferences),
      AgentMessage,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentLogsCreateCompanionBuilder =
    AgentLogsCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      Value<String?> turnId,
      required String level,
      required String message,
      required String source,
      Value<String> timestamp,
      Value<int> rowid,
    });
typedef $AgentLogsUpdateCompanionBuilder =
    AgentLogsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String?> turnId,
      Value<String> level,
      Value<String> message,
      Value<String> source,
      Value<String> timestamp,
      Value<int> rowid,
    });

final class $AgentLogsReferences
    extends BaseReferences<_$EngineDatabase, AgentLogs, AgentLog> {
  $AgentLogsReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentLogs.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentLogsFilterComposer extends Composer<_$EngineDatabase, AgentLogs> {
  $AgentLogsFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentLogsOrderingComposer extends Composer<_$EngineDatabase, AgentLogs> {
  $AgentLogsOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentLogsAnnotationComposer
    extends Composer<_$EngineDatabase, AgentLogs> {
  $AgentLogsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentLogsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentLogs,
          AgentLog,
          $AgentLogsFilterComposer,
          $AgentLogsOrderingComposer,
          $AgentLogsAnnotationComposer,
          $AgentLogsCreateCompanionBuilder,
          $AgentLogsUpdateCompanionBuilder,
          (AgentLog, $AgentLogsReferences),
          AgentLog,
          PrefetchHooks Function({bool runId})
        > {
  $AgentLogsTableManager(_$EngineDatabase db, AgentLogs table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentLogsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentLogsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentLogsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentLogsCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                level: level,
                message: message,
                source: source,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                Value<String?> turnId = const Value.absent(),
                required String level,
                required String message,
                required String source,
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentLogsCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                level: level,
                message: message,
                source: source,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $AgentLogsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentLogsReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentLogsReferences
                                    ._runIdTable(db)
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

typedef $AgentLogsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentLogs,
      AgentLog,
      $AgentLogsFilterComposer,
      $AgentLogsOrderingComposer,
      $AgentLogsAnnotationComposer,
      $AgentLogsCreateCompanionBuilder,
      $AgentLogsUpdateCompanionBuilder,
      (AgentLog, $AgentLogsReferences),
      AgentLog,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentActivityEventsCreateCompanionBuilder =
    AgentActivityEventsCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      Value<String?> turnId,
      required String eventType,
      Value<String?> dataJson,
      Value<String?> content,
      Value<String> timestamp,
      Value<int> rowid,
    });
typedef $AgentActivityEventsUpdateCompanionBuilder =
    AgentActivityEventsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String?> turnId,
      Value<String> eventType,
      Value<String?> dataJson,
      Value<String?> content,
      Value<String> timestamp,
      Value<int> rowid,
    });

final class $AgentActivityEventsReferences
    extends
        BaseReferences<
          _$EngineDatabase,
          AgentActivityEvents,
          AgentActivityEvent
        > {
  $AgentActivityEventsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentActivityEvents.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentActivityEventsFilterComposer
    extends Composer<_$EngineDatabase, AgentActivityEvents> {
  $AgentActivityEventsFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentActivityEventsOrderingComposer
    extends Composer<_$EngineDatabase, AgentActivityEvents> {
  $AgentActivityEventsOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentActivityEventsAnnotationComposer
    extends Composer<_$EngineDatabase, AgentActivityEvents> {
  $AgentActivityEventsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentActivityEventsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentActivityEvents,
          AgentActivityEvent,
          $AgentActivityEventsFilterComposer,
          $AgentActivityEventsOrderingComposer,
          $AgentActivityEventsAnnotationComposer,
          $AgentActivityEventsCreateCompanionBuilder,
          $AgentActivityEventsUpdateCompanionBuilder,
          (AgentActivityEvent, $AgentActivityEventsReferences),
          AgentActivityEvent,
          PrefetchHooks Function({bool runId})
        > {
  $AgentActivityEventsTableManager(
    _$EngineDatabase db,
    AgentActivityEvents table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentActivityEventsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentActivityEventsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentActivityEventsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> dataJson = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentActivityEventsCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                eventType: eventType,
                dataJson: dataJson,
                content: content,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                Value<String?> turnId = const Value.absent(),
                required String eventType,
                Value<String?> dataJson = const Value.absent(),
                Value<String?> content = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentActivityEventsCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                eventType: eventType,
                dataJson: dataJson,
                content: content,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $AgentActivityEventsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentActivityEventsReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentActivityEventsReferences
                                    ._runIdTable(db)
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

typedef $AgentActivityEventsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentActivityEvents,
      AgentActivityEvent,
      $AgentActivityEventsFilterComposer,
      $AgentActivityEventsOrderingComposer,
      $AgentActivityEventsAnnotationComposer,
      $AgentActivityEventsCreateCompanionBuilder,
      $AgentActivityEventsUpdateCompanionBuilder,
      (AgentActivityEvent, $AgentActivityEventsReferences),
      AgentActivityEvent,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentUsageRecordsCreateCompanionBuilder =
    AgentUsageRecordsCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      Value<String?> turnId,
      required String model,
      required int inputTokens,
      required int outputTokens,
      required int cacheReadTokens,
      required int cacheWriteTokens,
      required double costUsd,
      Value<String> timestamp,
      Value<int> rowid,
    });
typedef $AgentUsageRecordsUpdateCompanionBuilder =
    AgentUsageRecordsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String?> turnId,
      Value<String> model,
      Value<int> inputTokens,
      Value<int> outputTokens,
      Value<int> cacheReadTokens,
      Value<int> cacheWriteTokens,
      Value<double> costUsd,
      Value<String> timestamp,
      Value<int> rowid,
    });

final class $AgentUsageRecordsReferences
    extends
        BaseReferences<_$EngineDatabase, AgentUsageRecords, AgentUsageRecord> {
  $AgentUsageRecordsReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentUsageRecords.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentUsageRecordsFilterComposer
    extends Composer<_$EngineDatabase, AgentUsageRecords> {
  $AgentUsageRecordsFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentUsageRecordsOrderingComposer
    extends Composer<_$EngineDatabase, AgentUsageRecords> {
  $AgentUsageRecordsOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get costUsd => $composableBuilder(
    column: $table.costUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentUsageRecordsAnnotationComposer
    extends Composer<_$EngineDatabase, AgentUsageRecords> {
  $AgentUsageRecordsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<int> get inputTokens => $composableBuilder(
    column: $table.inputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outputTokens => $composableBuilder(
    column: $table.outputTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheReadTokens => $composableBuilder(
    column: $table.cacheReadTokens,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cacheWriteTokens => $composableBuilder(
    column: $table.cacheWriteTokens,
    builder: (column) => column,
  );

  GeneratedColumn<double> get costUsd =>
      $composableBuilder(column: $table.costUsd, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentUsageRecordsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentUsageRecords,
          AgentUsageRecord,
          $AgentUsageRecordsFilterComposer,
          $AgentUsageRecordsOrderingComposer,
          $AgentUsageRecordsAnnotationComposer,
          $AgentUsageRecordsCreateCompanionBuilder,
          $AgentUsageRecordsUpdateCompanionBuilder,
          (AgentUsageRecord, $AgentUsageRecordsReferences),
          AgentUsageRecord,
          PrefetchHooks Function({bool runId})
        > {
  $AgentUsageRecordsTableManager(_$EngineDatabase db, AgentUsageRecords table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentUsageRecordsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentUsageRecordsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentUsageRecordsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<int> inputTokens = const Value.absent(),
                Value<int> outputTokens = const Value.absent(),
                Value<int> cacheReadTokens = const Value.absent(),
                Value<int> cacheWriteTokens = const Value.absent(),
                Value<double> costUsd = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentUsageRecordsCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                costUsd: costUsd,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                Value<String?> turnId = const Value.absent(),
                required String model,
                required int inputTokens,
                required int outputTokens,
                required int cacheReadTokens,
                required int cacheWriteTokens,
                required double costUsd,
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentUsageRecordsCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                model: model,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                cacheReadTokens: cacheReadTokens,
                cacheWriteTokens: cacheWriteTokens,
                costUsd: costUsd,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $AgentUsageRecordsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentUsageRecordsReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentUsageRecordsReferences
                                    ._runIdTable(db)
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

typedef $AgentUsageRecordsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentUsageRecords,
      AgentUsageRecord,
      $AgentUsageRecordsFilterComposer,
      $AgentUsageRecordsOrderingComposer,
      $AgentUsageRecordsAnnotationComposer,
      $AgentUsageRecordsCreateCompanionBuilder,
      $AgentUsageRecordsUpdateCompanionBuilder,
      (AgentUsageRecord, $AgentUsageRecordsReferences),
      AgentUsageRecord,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentFilesCreateCompanionBuilder =
    AgentFilesCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      Value<String?> turnId,
      required String filePath,
      required String operation,
      Value<String> timestamp,
      Value<int> rowid,
    });
typedef $AgentFilesUpdateCompanionBuilder =
    AgentFilesCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String?> turnId,
      Value<String> filePath,
      Value<String> operation,
      Value<String> timestamp,
      Value<int> rowid,
    });

final class $AgentFilesReferences
    extends BaseReferences<_$EngineDatabase, AgentFiles, AgentFile> {
  $AgentFilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentFiles.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentFilesFilterComposer extends Composer<_$EngineDatabase, AgentFiles> {
  $AgentFilesFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentFilesOrderingComposer
    extends Composer<_$EngineDatabase, AgentFiles> {
  $AgentFilesOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentFilesAnnotationComposer
    extends Composer<_$EngineDatabase, AgentFiles> {
  $AgentFilesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentFilesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentFiles,
          AgentFile,
          $AgentFilesFilterComposer,
          $AgentFilesOrderingComposer,
          $AgentFilesAnnotationComposer,
          $AgentFilesCreateCompanionBuilder,
          $AgentFilesUpdateCompanionBuilder,
          (AgentFile, $AgentFilesReferences),
          AgentFile,
          PrefetchHooks Function({bool runId})
        > {
  $AgentFilesTableManager(_$EngineDatabase db, AgentFiles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentFilesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentFilesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentFilesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String?> turnId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentFilesCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                filePath: filePath,
                operation: operation,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                Value<String?> turnId = const Value.absent(),
                required String filePath,
                required String operation,
                Value<String> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentFilesCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                filePath: filePath,
                operation: operation,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $AgentFilesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentFilesReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentFilesReferences
                                    ._runIdTable(db)
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

typedef $AgentFilesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentFiles,
      AgentFile,
      $AgentFilesFilterComposer,
      $AgentFilesOrderingComposer,
      $AgentFilesAnnotationComposer,
      $AgentFilesCreateCompanionBuilder,
      $AgentFilesUpdateCompanionBuilder,
      (AgentFile, $AgentFilesReferences),
      AgentFile,
      PrefetchHooks Function({bool runId})
    >;
typedef $WorkspaceInquiriesCreateCompanionBuilder =
    WorkspaceInquiriesCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      required String status,
      required String priority,
      required String contentMarkdown,
      Value<String?> attachmentsJson,
      Value<String?> suggestionsJson,
      Value<String?> responseText,
      Value<int?> responseSuggestionIndex,
      Value<String?> respondedByAgentKey,
      Value<String?> forwardingChainJson,
      Value<String> createdAt,
      Value<String?> respondedAt,
      Value<int> rowid,
    });
typedef $WorkspaceInquiriesUpdateCompanionBuilder =
    WorkspaceInquiriesCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String> status,
      Value<String> priority,
      Value<String> contentMarkdown,
      Value<String?> attachmentsJson,
      Value<String?> suggestionsJson,
      Value<String?> responseText,
      Value<int?> responseSuggestionIndex,
      Value<String?> respondedByAgentKey,
      Value<String?> forwardingChainJson,
      Value<String> createdAt,
      Value<String?> respondedAt,
      Value<int> rowid,
    });

final class $WorkspaceInquiriesReferences
    extends
        BaseReferences<_$EngineDatabase, WorkspaceInquiries, WorkspaceInquiry> {
  $WorkspaceInquiriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.workspaceInquiries.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $WorkspaceInquiriesFilterComposer
    extends Composer<_$EngineDatabase, WorkspaceInquiries> {
  $WorkspaceInquiriesFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestionsJson => $composableBuilder(
    column: $table.suggestionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get responseSuggestionIndex => $composableBuilder(
    column: $table.responseSuggestionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get respondedByAgentKey => $composableBuilder(
    column: $table.respondedByAgentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forwardingChainJson => $composableBuilder(
    column: $table.forwardingChainJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceInquiriesOrderingComposer
    extends Composer<_$EngineDatabase, WorkspaceInquiries> {
  $WorkspaceInquiriesOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestionsJson => $composableBuilder(
    column: $table.suggestionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get responseSuggestionIndex => $composableBuilder(
    column: $table.responseSuggestionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get respondedByAgentKey => $composableBuilder(
    column: $table.respondedByAgentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forwardingChainJson => $composableBuilder(
    column: $table.forwardingChainJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceInquiriesAnnotationComposer
    extends Composer<_$EngineDatabase, WorkspaceInquiries> {
  $WorkspaceInquiriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get contentMarkdown => $composableBuilder(
    column: $table.contentMarkdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attachmentsJson => $composableBuilder(
    column: $table.attachmentsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestionsJson => $composableBuilder(
    column: $table.suggestionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseText => $composableBuilder(
    column: $table.responseText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get responseSuggestionIndex => $composableBuilder(
    column: $table.responseSuggestionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get respondedByAgentKey => $composableBuilder(
    column: $table.respondedByAgentKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forwardingChainJson => $composableBuilder(
    column: $table.forwardingChainJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get respondedAt => $composableBuilder(
    column: $table.respondedAt,
    builder: (column) => column,
  );

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceInquiriesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          WorkspaceInquiries,
          WorkspaceInquiry,
          $WorkspaceInquiriesFilterComposer,
          $WorkspaceInquiriesOrderingComposer,
          $WorkspaceInquiriesAnnotationComposer,
          $WorkspaceInquiriesCreateCompanionBuilder,
          $WorkspaceInquiriesUpdateCompanionBuilder,
          (WorkspaceInquiry, $WorkspaceInquiriesReferences),
          WorkspaceInquiry,
          PrefetchHooks Function({bool runId})
        > {
  $WorkspaceInquiriesTableManager(_$EngineDatabase db, WorkspaceInquiries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceInquiriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceInquiriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceInquiriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> contentMarkdown = const Value.absent(),
                Value<String?> attachmentsJson = const Value.absent(),
                Value<String?> suggestionsJson = const Value.absent(),
                Value<String?> responseText = const Value.absent(),
                Value<int?> responseSuggestionIndex = const Value.absent(),
                Value<String?> respondedByAgentKey = const Value.absent(),
                Value<String?> forwardingChainJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> respondedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceInquiriesCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                status: status,
                priority: priority,
                contentMarkdown: contentMarkdown,
                attachmentsJson: attachmentsJson,
                suggestionsJson: suggestionsJson,
                responseText: responseText,
                responseSuggestionIndex: responseSuggestionIndex,
                respondedByAgentKey: respondedByAgentKey,
                forwardingChainJson: forwardingChainJson,
                createdAt: createdAt,
                respondedAt: respondedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                required String status,
                required String priority,
                required String contentMarkdown,
                Value<String?> attachmentsJson = const Value.absent(),
                Value<String?> suggestionsJson = const Value.absent(),
                Value<String?> responseText = const Value.absent(),
                Value<int?> responseSuggestionIndex = const Value.absent(),
                Value<String?> respondedByAgentKey = const Value.absent(),
                Value<String?> forwardingChainJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> respondedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceInquiriesCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                status: status,
                priority: priority,
                contentMarkdown: contentMarkdown,
                attachmentsJson: attachmentsJson,
                suggestionsJson: suggestionsJson,
                responseText: responseText,
                responseSuggestionIndex: responseSuggestionIndex,
                respondedByAgentKey: respondedByAgentKey,
                forwardingChainJson: forwardingChainJson,
                createdAt: createdAt,
                respondedAt: respondedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $WorkspaceInquiriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $WorkspaceInquiriesReferences
                                    ._runIdTable(db),
                                referencedColumn: $WorkspaceInquiriesReferences
                                    ._runIdTable(db)
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

typedef $WorkspaceInquiriesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      WorkspaceInquiries,
      WorkspaceInquiry,
      $WorkspaceInquiriesFilterComposer,
      $WorkspaceInquiriesOrderingComposer,
      $WorkspaceInquiriesAnnotationComposer,
      $WorkspaceInquiriesCreateCompanionBuilder,
      $WorkspaceInquiriesUpdateCompanionBuilder,
      (WorkspaceInquiry, $WorkspaceInquiriesReferences),
      WorkspaceInquiry,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentProvidersCreateCompanionBuilder =
    AgentProvidersCompanion Function({
      required String id,
      required String name,
      required String sourceType,
      Value<String?> sourcePath,
      Value<String?> gitUrl,
      Value<String?> gitBranch,
      required String entryPoint,
      Value<String?> description,
      Value<String?> readme,
      Value<String> requiredEnvJson,
      Value<String> requiredMountsJson,
      Value<String> fieldsJson,
      Value<String?> hubSlug,
      Value<String?> hubAuthor,
      Value<String?> hubCategory,
      Value<String> hubTagsJson,
      Value<int?> hubVersion,
      Value<String?> hubRepoUrl,
      Value<String?> hubCommitHash,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $AgentProvidersUpdateCompanionBuilder =
    AgentProvidersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> sourceType,
      Value<String?> sourcePath,
      Value<String?> gitUrl,
      Value<String?> gitBranch,
      Value<String> entryPoint,
      Value<String?> description,
      Value<String?> readme,
      Value<String> requiredEnvJson,
      Value<String> requiredMountsJson,
      Value<String> fieldsJson,
      Value<String?> hubSlug,
      Value<String?> hubAuthor,
      Value<String?> hubCategory,
      Value<String> hubTagsJson,
      Value<int?> hubVersion,
      Value<String?> hubRepoUrl,
      Value<String?> hubCommitHash,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $AgentProvidersFilterComposer
    extends Composer<_$EngineDatabase, AgentProviders> {
  $AgentProvidersFilterComposer({
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

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitUrl => $composableBuilder(
    column: $table.gitUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gitBranch => $composableBuilder(
    column: $table.gitBranch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get readme => $composableBuilder(
    column: $table.readme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredEnvJson => $composableBuilder(
    column: $table.requiredEnvJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requiredMountsJson => $composableBuilder(
    column: $table.requiredMountsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubSlug => $composableBuilder(
    column: $table.hubSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubAuthor => $composableBuilder(
    column: $table.hubAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubRepoUrl => $composableBuilder(
    column: $table.hubRepoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubCommitHash => $composableBuilder(
    column: $table.hubCommitHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $AgentProvidersOrderingComposer
    extends Composer<_$EngineDatabase, AgentProviders> {
  $AgentProvidersOrderingComposer({
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

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitUrl => $composableBuilder(
    column: $table.gitUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gitBranch => $composableBuilder(
    column: $table.gitBranch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get readme => $composableBuilder(
    column: $table.readme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredEnvJson => $composableBuilder(
    column: $table.requiredEnvJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requiredMountsJson => $composableBuilder(
    column: $table.requiredMountsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubSlug => $composableBuilder(
    column: $table.hubSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubAuthor => $composableBuilder(
    column: $table.hubAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubRepoUrl => $composableBuilder(
    column: $table.hubRepoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubCommitHash => $composableBuilder(
    column: $table.hubCommitHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AgentProvidersAnnotationComposer
    extends Composer<_$EngineDatabase, AgentProviders> {
  $AgentProvidersAnnotationComposer({
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

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gitUrl =>
      $composableBuilder(column: $table.gitUrl, builder: (column) => column);

  GeneratedColumn<String> get gitBranch =>
      $composableBuilder(column: $table.gitBranch, builder: (column) => column);

  GeneratedColumn<String> get entryPoint => $composableBuilder(
    column: $table.entryPoint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get readme =>
      $composableBuilder(column: $table.readme, builder: (column) => column);

  GeneratedColumn<String> get requiredEnvJson => $composableBuilder(
    column: $table.requiredEnvJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requiredMountsJson => $composableBuilder(
    column: $table.requiredMountsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fieldsJson => $composableBuilder(
    column: $table.fieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubSlug =>
      $composableBuilder(column: $table.hubSlug, builder: (column) => column);

  GeneratedColumn<String> get hubAuthor =>
      $composableBuilder(column: $table.hubAuthor, builder: (column) => column);

  GeneratedColumn<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubRepoUrl => $composableBuilder(
    column: $table.hubRepoUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubCommitHash => $composableBuilder(
    column: $table.hubCommitHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $AgentProvidersTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentProviders,
          AgentProvider,
          $AgentProvidersFilterComposer,
          $AgentProvidersOrderingComposer,
          $AgentProvidersAnnotationComposer,
          $AgentProvidersCreateCompanionBuilder,
          $AgentProvidersUpdateCompanionBuilder,
          (
            AgentProvider,
            BaseReferences<_$EngineDatabase, AgentProviders, AgentProvider>,
          ),
          AgentProvider,
          PrefetchHooks Function()
        > {
  $AgentProvidersTableManager(_$EngineDatabase db, AgentProviders table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentProvidersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentProvidersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentProvidersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> gitUrl = const Value.absent(),
                Value<String?> gitBranch = const Value.absent(),
                Value<String> entryPoint = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> readme = const Value.absent(),
                Value<String> requiredEnvJson = const Value.absent(),
                Value<String> requiredMountsJson = const Value.absent(),
                Value<String> fieldsJson = const Value.absent(),
                Value<String?> hubSlug = const Value.absent(),
                Value<String?> hubAuthor = const Value.absent(),
                Value<String?> hubCategory = const Value.absent(),
                Value<String> hubTagsJson = const Value.absent(),
                Value<int?> hubVersion = const Value.absent(),
                Value<String?> hubRepoUrl = const Value.absent(),
                Value<String?> hubCommitHash = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentProvidersCompanion(
                id: id,
                name: name,
                sourceType: sourceType,
                sourcePath: sourcePath,
                gitUrl: gitUrl,
                gitBranch: gitBranch,
                entryPoint: entryPoint,
                description: description,
                readme: readme,
                requiredEnvJson: requiredEnvJson,
                requiredMountsJson: requiredMountsJson,
                fieldsJson: fieldsJson,
                hubSlug: hubSlug,
                hubAuthor: hubAuthor,
                hubCategory: hubCategory,
                hubTagsJson: hubTagsJson,
                hubVersion: hubVersion,
                hubRepoUrl: hubRepoUrl,
                hubCommitHash: hubCommitHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String sourceType,
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> gitUrl = const Value.absent(),
                Value<String?> gitBranch = const Value.absent(),
                required String entryPoint,
                Value<String?> description = const Value.absent(),
                Value<String?> readme = const Value.absent(),
                Value<String> requiredEnvJson = const Value.absent(),
                Value<String> requiredMountsJson = const Value.absent(),
                Value<String> fieldsJson = const Value.absent(),
                Value<String?> hubSlug = const Value.absent(),
                Value<String?> hubAuthor = const Value.absent(),
                Value<String?> hubCategory = const Value.absent(),
                Value<String> hubTagsJson = const Value.absent(),
                Value<int?> hubVersion = const Value.absent(),
                Value<String?> hubRepoUrl = const Value.absent(),
                Value<String?> hubCommitHash = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentProvidersCompanion.insert(
                id: id,
                name: name,
                sourceType: sourceType,
                sourcePath: sourcePath,
                gitUrl: gitUrl,
                gitBranch: gitBranch,
                entryPoint: entryPoint,
                description: description,
                readme: readme,
                requiredEnvJson: requiredEnvJson,
                requiredMountsJson: requiredMountsJson,
                fieldsJson: fieldsJson,
                hubSlug: hubSlug,
                hubAuthor: hubAuthor,
                hubCategory: hubCategory,
                hubTagsJson: hubTagsJson,
                hubVersion: hubVersion,
                hubRepoUrl: hubRepoUrl,
                hubCommitHash: hubCommitHash,
                createdAt: createdAt,
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

typedef $AgentProvidersProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentProviders,
      AgentProvider,
      $AgentProvidersFilterComposer,
      $AgentProvidersOrderingComposer,
      $AgentProvidersAnnotationComposer,
      $AgentProvidersCreateCompanionBuilder,
      $AgentProvidersUpdateCompanionBuilder,
      (
        AgentProvider,
        BaseReferences<_$EngineDatabase, AgentProviders, AgentProvider>,
      ),
      AgentProvider,
      PrefetchHooks Function()
    >;
typedef $AgentTemplatesCreateCompanionBuilder =
    AgentTemplatesCompanion Function({
      required String id,
      required String name,
      required String sourceUri,
      required String filePath,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $AgentTemplatesUpdateCompanionBuilder =
    AgentTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> sourceUri,
      Value<String> filePath,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $AgentTemplatesFilterComposer
    extends Composer<_$EngineDatabase, AgentTemplates> {
  $AgentTemplatesFilterComposer({
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

  ColumnFilters<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $AgentTemplatesOrderingComposer
    extends Composer<_$EngineDatabase, AgentTemplates> {
  $AgentTemplatesOrderingComposer({
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

  ColumnOrderings<String> get sourceUri => $composableBuilder(
    column: $table.sourceUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $AgentTemplatesAnnotationComposer
    extends Composer<_$EngineDatabase, AgentTemplates> {
  $AgentTemplatesAnnotationComposer({
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

  GeneratedColumn<String> get sourceUri =>
      $composableBuilder(column: $table.sourceUri, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $AgentTemplatesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentTemplates,
          AgentTemplate,
          $AgentTemplatesFilterComposer,
          $AgentTemplatesOrderingComposer,
          $AgentTemplatesAnnotationComposer,
          $AgentTemplatesCreateCompanionBuilder,
          $AgentTemplatesUpdateCompanionBuilder,
          (
            AgentTemplate,
            BaseReferences<_$EngineDatabase, AgentTemplates, AgentTemplate>,
          ),
          AgentTemplate,
          PrefetchHooks Function()
        > {
  $AgentTemplatesTableManager(_$EngineDatabase db, AgentTemplates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentTemplatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentTemplatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentTemplatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> sourceUri = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentTemplatesCompanion(
                id: id,
                name: name,
                sourceUri: sourceUri,
                filePath: filePath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String sourceUri,
                required String filePath,
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentTemplatesCompanion.insert(
                id: id,
                name: name,
                sourceUri: sourceUri,
                filePath: filePath,
                createdAt: createdAt,
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

typedef $AgentTemplatesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentTemplates,
      AgentTemplate,
      $AgentTemplatesFilterComposer,
      $AgentTemplatesOrderingComposer,
      $AgentTemplatesAnnotationComposer,
      $AgentTemplatesCreateCompanionBuilder,
      $AgentTemplatesUpdateCompanionBuilder,
      (
        AgentTemplate,
        BaseReferences<_$EngineDatabase, AgentTemplates, AgentTemplate>,
      ),
      AgentTemplate,
      PrefetchHooks Function()
    >;
typedef $ApiKeysCreateCompanionBuilder =
    ApiKeysCompanion Function({
      required String id,
      required String name,
      required String providerLabel,
      required Uint8List encryptedKey,
      Value<String?> displayHint,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $ApiKeysUpdateCompanionBuilder =
    ApiKeysCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> providerLabel,
      Value<Uint8List> encryptedKey,
      Value<String?> displayHint,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $ApiKeysFilterComposer extends Composer<_$EngineDatabase, ApiKeys> {
  $ApiKeysFilterComposer({
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

  ColumnFilters<String> get providerLabel => $composableBuilder(
    column: $table.providerLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get encryptedKey => $composableBuilder(
    column: $table.encryptedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayHint => $composableBuilder(
    column: $table.displayHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $ApiKeysOrderingComposer extends Composer<_$EngineDatabase, ApiKeys> {
  $ApiKeysOrderingComposer({
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

  ColumnOrderings<String> get providerLabel => $composableBuilder(
    column: $table.providerLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get encryptedKey => $composableBuilder(
    column: $table.encryptedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayHint => $composableBuilder(
    column: $table.displayHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ApiKeysAnnotationComposer extends Composer<_$EngineDatabase, ApiKeys> {
  $ApiKeysAnnotationComposer({
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

  GeneratedColumn<String> get providerLabel => $composableBuilder(
    column: $table.providerLabel,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get encryptedKey => $composableBuilder(
    column: $table.encryptedKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayHint => $composableBuilder(
    column: $table.displayHint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $ApiKeysTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          ApiKeys,
          ApiKey,
          $ApiKeysFilterComposer,
          $ApiKeysOrderingComposer,
          $ApiKeysAnnotationComposer,
          $ApiKeysCreateCompanionBuilder,
          $ApiKeysUpdateCompanionBuilder,
          (ApiKey, BaseReferences<_$EngineDatabase, ApiKeys, ApiKey>),
          ApiKey,
          PrefetchHooks Function()
        > {
  $ApiKeysTableManager(_$EngineDatabase db, ApiKeys table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ApiKeysFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ApiKeysOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ApiKeysAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> providerLabel = const Value.absent(),
                Value<Uint8List> encryptedKey = const Value.absent(),
                Value<String?> displayHint = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiKeysCompanion(
                id: id,
                name: name,
                providerLabel: providerLabel,
                encryptedKey: encryptedKey,
                displayHint: displayHint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String providerLabel,
                required Uint8List encryptedKey,
                Value<String?> displayHint = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiKeysCompanion.insert(
                id: id,
                name: name,
                providerLabel: providerLabel,
                encryptedKey: encryptedKey,
                displayHint: displayHint,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ApiKeysProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      ApiKeys,
      ApiKey,
      $ApiKeysFilterComposer,
      $ApiKeysOrderingComposer,
      $ApiKeysAnnotationComposer,
      $ApiKeysCreateCompanionBuilder,
      $ApiKeysUpdateCompanionBuilder,
      (ApiKey, BaseReferences<_$EngineDatabase, ApiKeys, ApiKey>),
      ApiKey,
      PrefetchHooks Function()
    >;
typedef $PreferencesCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $PreferencesUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $PreferencesFilterComposer
    extends Composer<_$EngineDatabase, Preferences> {
  $PreferencesFilterComposer({
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

class $PreferencesOrderingComposer
    extends Composer<_$EngineDatabase, Preferences> {
  $PreferencesOrderingComposer({
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

class $PreferencesAnnotationComposer
    extends Composer<_$EngineDatabase, Preferences> {
  $PreferencesAnnotationComposer({
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

class $PreferencesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          Preferences,
          Preference,
          $PreferencesFilterComposer,
          $PreferencesOrderingComposer,
          $PreferencesAnnotationComposer,
          $PreferencesCreateCompanionBuilder,
          $PreferencesUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$EngineDatabase, Preferences, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $PreferencesTableManager(_$EngineDatabase db, Preferences table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PreferencesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PreferencesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PreferencesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PreferencesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      Preferences,
      Preference,
      $PreferencesFilterComposer,
      $PreferencesOrderingComposer,
      $PreferencesAnnotationComposer,
      $PreferencesCreateCompanionBuilder,
      $PreferencesUpdateCompanionBuilder,
      (Preference, BaseReferences<_$EngineDatabase, Preferences, Preference>),
      Preference,
      PrefetchHooks Function()
    >;
typedef $WorkspaceTemplatesCreateCompanionBuilder =
    WorkspaceTemplatesCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required String hubSlug,
      required String hubAuthor,
      Value<String?> hubCategory,
      Value<String> hubTagsJson,
      required int hubVersion,
      required String configJson,
      Value<String> agentRefsJson,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $WorkspaceTemplatesUpdateCompanionBuilder =
    WorkspaceTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String> hubSlug,
      Value<String> hubAuthor,
      Value<String?> hubCategory,
      Value<String> hubTagsJson,
      Value<int> hubVersion,
      Value<String> configJson,
      Value<String> agentRefsJson,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $WorkspaceTemplatesFilterComposer
    extends Composer<_$EngineDatabase, WorkspaceTemplates> {
  $WorkspaceTemplatesFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubSlug => $composableBuilder(
    column: $table.hubSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubAuthor => $composableBuilder(
    column: $table.hubAuthor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentRefsJson => $composableBuilder(
    column: $table.agentRefsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $WorkspaceTemplatesOrderingComposer
    extends Composer<_$EngineDatabase, WorkspaceTemplates> {
  $WorkspaceTemplatesOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubSlug => $composableBuilder(
    column: $table.hubSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubAuthor => $composableBuilder(
    column: $table.hubAuthor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentRefsJson => $composableBuilder(
    column: $table.agentRefsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $WorkspaceTemplatesAnnotationComposer
    extends Composer<_$EngineDatabase, WorkspaceTemplates> {
  $WorkspaceTemplatesAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubSlug =>
      $composableBuilder(column: $table.hubSlug, builder: (column) => column);

  GeneratedColumn<String> get hubAuthor =>
      $composableBuilder(column: $table.hubAuthor, builder: (column) => column);

  GeneratedColumn<String> get hubCategory => $composableBuilder(
    column: $table.hubCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hubTagsJson => $composableBuilder(
    column: $table.hubTagsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get hubVersion => $composableBuilder(
    column: $table.hubVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentRefsJson => $composableBuilder(
    column: $table.agentRefsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $WorkspaceTemplatesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          WorkspaceTemplates,
          WorkspaceTemplate,
          $WorkspaceTemplatesFilterComposer,
          $WorkspaceTemplatesOrderingComposer,
          $WorkspaceTemplatesAnnotationComposer,
          $WorkspaceTemplatesCreateCompanionBuilder,
          $WorkspaceTemplatesUpdateCompanionBuilder,
          (
            WorkspaceTemplate,
            BaseReferences<
              _$EngineDatabase,
              WorkspaceTemplates,
              WorkspaceTemplate
            >,
          ),
          WorkspaceTemplate,
          PrefetchHooks Function()
        > {
  $WorkspaceTemplatesTableManager(_$EngineDatabase db, WorkspaceTemplates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceTemplatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceTemplatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceTemplatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> hubSlug = const Value.absent(),
                Value<String> hubAuthor = const Value.absent(),
                Value<String?> hubCategory = const Value.absent(),
                Value<String> hubTagsJson = const Value.absent(),
                Value<int> hubVersion = const Value.absent(),
                Value<String> configJson = const Value.absent(),
                Value<String> agentRefsJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceTemplatesCompanion(
                id: id,
                name: name,
                description: description,
                hubSlug: hubSlug,
                hubAuthor: hubAuthor,
                hubCategory: hubCategory,
                hubTagsJson: hubTagsJson,
                hubVersion: hubVersion,
                configJson: configJson,
                agentRefsJson: agentRefsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required String hubSlug,
                required String hubAuthor,
                Value<String?> hubCategory = const Value.absent(),
                Value<String> hubTagsJson = const Value.absent(),
                required int hubVersion,
                required String configJson,
                Value<String> agentRefsJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceTemplatesCompanion.insert(
                id: id,
                name: name,
                description: description,
                hubSlug: hubSlug,
                hubAuthor: hubAuthor,
                hubCategory: hubCategory,
                hubTagsJson: hubTagsJson,
                hubVersion: hubVersion,
                configJson: configJson,
                agentRefsJson: agentRefsJson,
                createdAt: createdAt,
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

typedef $WorkspaceTemplatesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      WorkspaceTemplates,
      WorkspaceTemplate,
      $WorkspaceTemplatesFilterComposer,
      $WorkspaceTemplatesOrderingComposer,
      $WorkspaceTemplatesAnnotationComposer,
      $WorkspaceTemplatesCreateCompanionBuilder,
      $WorkspaceTemplatesUpdateCompanionBuilder,
      (
        WorkspaceTemplate,
        BaseReferences<_$EngineDatabase, WorkspaceTemplates, WorkspaceTemplate>,
      ),
      WorkspaceTemplate,
      PrefetchHooks Function()
    >;
typedef $InstanceResultsCreateCompanionBuilder =
    InstanceResultsCompanion Function({
      required String id,
      required String runId,
      required String agentKey,
      required String instanceId,
      required String turnId,
      Value<String?> requestId,
      Value<String> createdAt,
      Value<int> rowid,
    });
typedef $InstanceResultsUpdateCompanionBuilder =
    InstanceResultsCompanion Function({
      Value<String> id,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> instanceId,
      Value<String> turnId,
      Value<String?> requestId,
      Value<String> createdAt,
      Value<int> rowid,
    });

final class $InstanceResultsReferences
    extends BaseReferences<_$EngineDatabase, InstanceResults, InstanceResult> {
  $InstanceResultsReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.instanceResults.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $InstanceResultsFilterComposer
    extends Composer<_$EngineDatabase, InstanceResults> {
  $InstanceResultsFilterComposer({
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

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $InstanceResultsOrderingComposer
    extends Composer<_$EngineDatabase, InstanceResults> {
  $InstanceResultsOrderingComposer({
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

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get turnId => $composableBuilder(
    column: $table.turnId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestId => $composableBuilder(
    column: $table.requestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $InstanceResultsAnnotationComposer
    extends Composer<_$EngineDatabase, InstanceResults> {
  $InstanceResultsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get turnId =>
      $composableBuilder(column: $table.turnId, builder: (column) => column);

  GeneratedColumn<String> get requestId =>
      $composableBuilder(column: $table.requestId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $InstanceResultsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          InstanceResults,
          InstanceResult,
          $InstanceResultsFilterComposer,
          $InstanceResultsOrderingComposer,
          $InstanceResultsAnnotationComposer,
          $InstanceResultsCreateCompanionBuilder,
          $InstanceResultsUpdateCompanionBuilder,
          (InstanceResult, $InstanceResultsReferences),
          InstanceResult,
          PrefetchHooks Function({bool runId})
        > {
  $InstanceResultsTableManager(_$EngineDatabase db, InstanceResults table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $InstanceResultsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $InstanceResultsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $InstanceResultsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> instanceId = const Value.absent(),
                Value<String> turnId = const Value.absent(),
                Value<String?> requestId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstanceResultsCompanion(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                requestId: requestId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String runId,
                required String agentKey,
                required String instanceId,
                required String turnId,
                Value<String?> requestId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstanceResultsCompanion.insert(
                id: id,
                runId: runId,
                agentKey: agentKey,
                instanceId: instanceId,
                turnId: turnId,
                requestId: requestId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $InstanceResultsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $InstanceResultsReferences
                                    ._runIdTable(db),
                                referencedColumn: $InstanceResultsReferences
                                    ._runIdTable(db)
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

typedef $InstanceResultsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      InstanceResults,
      InstanceResult,
      $InstanceResultsFilterComposer,
      $InstanceResultsOrderingComposer,
      $InstanceResultsAnnotationComposer,
      $InstanceResultsCreateCompanionBuilder,
      $InstanceResultsUpdateCompanionBuilder,
      (InstanceResult, $InstanceResultsReferences),
      InstanceResult,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentInstanceStatesCreateCompanionBuilder =
    AgentInstanceStatesCompanion Function({
      required String instanceId,
      required String runId,
      required String agentKey,
      Value<String> state,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $AgentInstanceStatesUpdateCompanionBuilder =
    AgentInstanceStatesCompanion Function({
      Value<String> instanceId,
      Value<String> runId,
      Value<String> agentKey,
      Value<String> state,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $AgentInstanceStatesReferences
    extends
        BaseReferences<
          _$EngineDatabase,
          AgentInstanceStates,
          AgentInstanceState
        > {
  $AgentInstanceStatesReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.agentInstanceStates.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentInstanceStatesFilterComposer
    extends Composer<_$EngineDatabase, AgentInstanceStates> {
  $AgentInstanceStatesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentInstanceStatesOrderingComposer
    extends Composer<_$EngineDatabase, AgentInstanceStates> {
  $AgentInstanceStatesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentInstanceStatesAnnotationComposer
    extends Composer<_$EngineDatabase, AgentInstanceStates> {
  $AgentInstanceStatesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get instanceId => $composableBuilder(
    column: $table.instanceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentInstanceStatesTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentInstanceStates,
          AgentInstanceState,
          $AgentInstanceStatesFilterComposer,
          $AgentInstanceStatesOrderingComposer,
          $AgentInstanceStatesAnnotationComposer,
          $AgentInstanceStatesCreateCompanionBuilder,
          $AgentInstanceStatesUpdateCompanionBuilder,
          (AgentInstanceState, $AgentInstanceStatesReferences),
          AgentInstanceState,
          PrefetchHooks Function({bool runId})
        > {
  $AgentInstanceStatesTableManager(
    _$EngineDatabase db,
    AgentInstanceStates table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentInstanceStatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentInstanceStatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentInstanceStatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> instanceId = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<String> agentKey = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentInstanceStatesCompanion(
                instanceId: instanceId,
                runId: runId,
                agentKey: agentKey,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String instanceId,
                required String runId,
                required String agentKey,
                Value<String> state = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentInstanceStatesCompanion.insert(
                instanceId: instanceId,
                runId: runId,
                agentKey: agentKey,
                state: state,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $AgentInstanceStatesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $AgentInstanceStatesReferences
                                    ._runIdTable(db),
                                referencedColumn: $AgentInstanceStatesReferences
                                    ._runIdTable(db)
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

typedef $AgentInstanceStatesProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentInstanceStates,
      AgentInstanceState,
      $AgentInstanceStatesFilterComposer,
      $AgentInstanceStatesOrderingComposer,
      $AgentInstanceStatesAnnotationComposer,
      $AgentInstanceStatesCreateCompanionBuilder,
      $AgentInstanceStatesUpdateCompanionBuilder,
      (AgentInstanceState, $AgentInstanceStatesReferences),
      AgentInstanceState,
      PrefetchHooks Function({bool runId})
    >;
typedef $AgentConnectionStatusCreateCompanionBuilder =
    AgentConnectionStatusCompanion Function({
      required String agentKey,
      required String runId,
      Value<int> connected,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $AgentConnectionStatusUpdateCompanionBuilder =
    AgentConnectionStatusCompanion Function({
      Value<String> agentKey,
      Value<String> runId,
      Value<int> connected,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $AgentConnectionStatusReferences
    extends
        BaseReferences<
          _$EngineDatabase,
          AgentConnectionStatus,
          AgentConnectionStatusData
        > {
  $AgentConnectionStatusReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(
          db.agentConnectionStatus.runId,
          db.workspaceRuns.id,
        ),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $AgentConnectionStatusFilterComposer
    extends Composer<_$EngineDatabase, AgentConnectionStatus> {
  $AgentConnectionStatusFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get connected => $composableBuilder(
    column: $table.connected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentConnectionStatusOrderingComposer
    extends Composer<_$EngineDatabase, AgentConnectionStatus> {
  $AgentConnectionStatusOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get agentKey => $composableBuilder(
    column: $table.agentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get connected => $composableBuilder(
    column: $table.connected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentConnectionStatusAnnotationComposer
    extends Composer<_$EngineDatabase, AgentConnectionStatus> {
  $AgentConnectionStatusAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get agentKey =>
      $composableBuilder(column: $table.agentKey, builder: (column) => column);

  GeneratedColumn<int> get connected =>
      $composableBuilder(column: $table.connected, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $AgentConnectionStatusTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          AgentConnectionStatus,
          AgentConnectionStatusData,
          $AgentConnectionStatusFilterComposer,
          $AgentConnectionStatusOrderingComposer,
          $AgentConnectionStatusAnnotationComposer,
          $AgentConnectionStatusCreateCompanionBuilder,
          $AgentConnectionStatusUpdateCompanionBuilder,
          (AgentConnectionStatusData, $AgentConnectionStatusReferences),
          AgentConnectionStatusData,
          PrefetchHooks Function({bool runId})
        > {
  $AgentConnectionStatusTableManager(
    _$EngineDatabase db,
    AgentConnectionStatus table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $AgentConnectionStatusFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $AgentConnectionStatusOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $AgentConnectionStatusAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> agentKey = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<int> connected = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentConnectionStatusCompanion(
                agentKey: agentKey,
                runId: runId,
                connected: connected,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String agentKey,
                required String runId,
                Value<int> connected = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AgentConnectionStatusCompanion.insert(
                agentKey: agentKey,
                runId: runId,
                connected: connected,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $AgentConnectionStatusReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable:
                                    $AgentConnectionStatusReferences
                                        ._runIdTable(db),
                                referencedColumn:
                                    $AgentConnectionStatusReferences
                                        ._runIdTable(db)
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

typedef $AgentConnectionStatusProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      AgentConnectionStatus,
      AgentConnectionStatusData,
      $AgentConnectionStatusFilterComposer,
      $AgentConnectionStatusOrderingComposer,
      $AgentConnectionStatusAnnotationComposer,
      $AgentConnectionStatusCreateCompanionBuilder,
      $AgentConnectionStatusUpdateCompanionBuilder,
      (AgentConnectionStatusData, $AgentConnectionStatusReferences),
      AgentConnectionStatusData,
      PrefetchHooks Function({bool runId})
    >;
typedef $ContainerHealthCreateCompanionBuilder =
    ContainerHealthCompanion Function({
      required String runId,
      Value<String> status,
      Value<String?> errorMessage,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $ContainerHealthUpdateCompanionBuilder =
    ContainerHealthCompanion Function({
      Value<String> runId,
      Value<String> status,
      Value<String?> errorMessage,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $ContainerHealthReferences
    extends
        BaseReferences<_$EngineDatabase, ContainerHealth, ContainerHealthData> {
  $ContainerHealthReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.containerHealth.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ContainerHealthFilterComposer
    extends Composer<_$EngineDatabase, ContainerHealth> {
  $ContainerHealthFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerHealthOrderingComposer
    extends Composer<_$EngineDatabase, ContainerHealth> {
  $ContainerHealthOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerHealthAnnotationComposer
    extends Composer<_$EngineDatabase, ContainerHealth> {
  $ContainerHealthAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ContainerHealthTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          ContainerHealth,
          ContainerHealthData,
          $ContainerHealthFilterComposer,
          $ContainerHealthOrderingComposer,
          $ContainerHealthAnnotationComposer,
          $ContainerHealthCreateCompanionBuilder,
          $ContainerHealthUpdateCompanionBuilder,
          (ContainerHealthData, $ContainerHealthReferences),
          ContainerHealthData,
          PrefetchHooks Function({bool runId})
        > {
  $ContainerHealthTableManager(_$EngineDatabase db, ContainerHealth table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ContainerHealthFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ContainerHealthOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ContainerHealthAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainerHealthCompanion(
                runId: runId,
                status: status,
                errorMessage: errorMessage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                Value<String> status = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContainerHealthCompanion.insert(
                runId: runId,
                status: status,
                errorMessage: errorMessage,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $ContainerHealthReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $ContainerHealthReferences
                                    ._runIdTable(db),
                                referencedColumn: $ContainerHealthReferences
                                    ._runIdTable(db)
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

typedef $ContainerHealthProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      ContainerHealth,
      ContainerHealthData,
      $ContainerHealthFilterComposer,
      $ContainerHealthOrderingComposer,
      $ContainerHealthAnnotationComposer,
      $ContainerHealthCreateCompanionBuilder,
      $ContainerHealthUpdateCompanionBuilder,
      (ContainerHealthData, $ContainerHealthReferences),
      ContainerHealthData,
      PrefetchHooks Function({bool runId})
    >;
typedef $WorkspaceRunStatusCreateCompanionBuilder =
    WorkspaceRunStatusCompanion Function({
      required String runId,
      Value<String> status,
      Value<String> updatedAt,
      Value<int> rowid,
    });
typedef $WorkspaceRunStatusUpdateCompanionBuilder =
    WorkspaceRunStatusCompanion Function({
      Value<String> runId,
      Value<String> status,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $WorkspaceRunStatusReferences
    extends
        BaseReferences<
          _$EngineDatabase,
          WorkspaceRunStatus,
          WorkspaceRunStatusData
        > {
  $WorkspaceRunStatusReferences(super.$_db, super.$_table, super.$_typedResult);

  static WorkspaceRuns _runIdTable(_$EngineDatabase db) =>
      db.workspaceRuns.createAlias(
        $_aliasNameGenerator(db.workspaceRunStatus.runId, db.workspaceRuns.id),
      );

  $WorkspaceRunsProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $WorkspaceRunsTableManager(
      $_db,
      $_db.workspaceRuns,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $WorkspaceRunStatusFilterComposer
    extends Composer<_$EngineDatabase, WorkspaceRunStatus> {
  $WorkspaceRunStatusFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $WorkspaceRunsFilterComposer get runId {
    final $WorkspaceRunsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsFilterComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceRunStatusOrderingComposer
    extends Composer<_$EngineDatabase, WorkspaceRunStatus> {
  $WorkspaceRunStatusOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $WorkspaceRunsOrderingComposer get runId {
    final $WorkspaceRunsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsOrderingComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceRunStatusAnnotationComposer
    extends Composer<_$EngineDatabase, WorkspaceRunStatus> {
  $WorkspaceRunStatusAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $WorkspaceRunsAnnotationComposer get runId {
    final $WorkspaceRunsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.workspaceRuns,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $WorkspaceRunsAnnotationComposer(
            $db: $db,
            $table: $db.workspaceRuns,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $WorkspaceRunStatusTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          WorkspaceRunStatus,
          WorkspaceRunStatusData,
          $WorkspaceRunStatusFilterComposer,
          $WorkspaceRunStatusOrderingComposer,
          $WorkspaceRunStatusAnnotationComposer,
          $WorkspaceRunStatusCreateCompanionBuilder,
          $WorkspaceRunStatusUpdateCompanionBuilder,
          (WorkspaceRunStatusData, $WorkspaceRunStatusReferences),
          WorkspaceRunStatusData,
          PrefetchHooks Function({bool runId})
        > {
  $WorkspaceRunStatusTableManager(_$EngineDatabase db, WorkspaceRunStatus table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $WorkspaceRunStatusFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $WorkspaceRunStatusOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $WorkspaceRunStatusAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> runId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRunStatusCompanion(
                runId: runId,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String runId,
                Value<String> status = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspaceRunStatusCompanion.insert(
                runId: runId,
                status: status,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $WorkspaceRunStatusReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
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
                    if (runId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.runId,
                                referencedTable: $WorkspaceRunStatusReferences
                                    ._runIdTable(db),
                                referencedColumn: $WorkspaceRunStatusReferences
                                    ._runIdTable(db)
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

typedef $WorkspaceRunStatusProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      WorkspaceRunStatus,
      WorkspaceRunStatusData,
      $WorkspaceRunStatusFilterComposer,
      $WorkspaceRunStatusOrderingComposer,
      $WorkspaceRunStatusAnnotationComposer,
      $WorkspaceRunStatusCreateCompanionBuilder,
      $WorkspaceRunStatusUpdateCompanionBuilder,
      (WorkspaceRunStatusData, $WorkspaceRunStatusReferences),
      WorkspaceRunStatusData,
      PrefetchHooks Function({bool runId})
    >;
typedef $RecentProjectsCreateCompanionBuilder =
    RecentProjectsCompanion Function({
      required String id,
      required String path,
      required String name,
      Value<int> isGitRepo,
      Value<String> lastUsedAt,
      Value<int> rowid,
    });
typedef $RecentProjectsUpdateCompanionBuilder =
    RecentProjectsCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<String> name,
      Value<int> isGitRepo,
      Value<String> lastUsedAt,
      Value<int> rowid,
    });

class $RecentProjectsFilterComposer
    extends Composer<_$EngineDatabase, RecentProjects> {
  $RecentProjectsFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isGitRepo => $composableBuilder(
    column: $table.isGitRepo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $RecentProjectsOrderingComposer
    extends Composer<_$EngineDatabase, RecentProjects> {
  $RecentProjectsOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isGitRepo => $composableBuilder(
    column: $table.isGitRepo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RecentProjectsAnnotationComposer
    extends Composer<_$EngineDatabase, RecentProjects> {
  $RecentProjectsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get isGitRepo =>
      $composableBuilder(column: $table.isGitRepo, builder: (column) => column);

  GeneratedColumn<String> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => column,
  );
}

class $RecentProjectsTableManager
    extends
        RootTableManager<
          _$EngineDatabase,
          RecentProjects,
          RecentProject,
          $RecentProjectsFilterComposer,
          $RecentProjectsOrderingComposer,
          $RecentProjectsAnnotationComposer,
          $RecentProjectsCreateCompanionBuilder,
          $RecentProjectsUpdateCompanionBuilder,
          (
            RecentProject,
            BaseReferences<_$EngineDatabase, RecentProjects, RecentProject>,
          ),
          RecentProject,
          PrefetchHooks Function()
        > {
  $RecentProjectsTableManager(_$EngineDatabase db, RecentProjects table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecentProjectsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecentProjectsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecentProjectsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> isGitRepo = const Value.absent(),
                Value<String> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentProjectsCompanion(
                id: id,
                path: path,
                name: name,
                isGitRepo: isGitRepo,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                required String name,
                Value<int> isGitRepo = const Value.absent(),
                Value<String> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentProjectsCompanion.insert(
                id: id,
                path: path,
                name: name,
                isGitRepo: isGitRepo,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $RecentProjectsProcessedTableManager =
    ProcessedTableManager<
      _$EngineDatabase,
      RecentProjects,
      RecentProject,
      $RecentProjectsFilterComposer,
      $RecentProjectsOrderingComposer,
      $RecentProjectsAnnotationComposer,
      $RecentProjectsCreateCompanionBuilder,
      $RecentProjectsUpdateCompanionBuilder,
      (
        RecentProject,
        BaseReferences<_$EngineDatabase, RecentProjects, RecentProject>,
      ),
      RecentProject,
      PrefetchHooks Function()
    >;

class $EngineDatabaseManager {
  final _$EngineDatabase _db;
  $EngineDatabaseManager(this._db);
  $WorkspacesTableManager get workspaces =>
      $WorkspacesTableManager(_db, _db.workspaces);
  $WorkspaceRunsTableManager get workspaceRuns =>
      $WorkspaceRunsTableManager(_db, _db.workspaceRuns);
  $WorkspaceAgentsTableManager get workspaceAgents =>
      $WorkspaceAgentsTableManager(_db, _db.workspaceAgents);
  $AgentMessagesTableManager get agentMessages =>
      $AgentMessagesTableManager(_db, _db.agentMessages);
  $AgentLogsTableManager get agentLogs =>
      $AgentLogsTableManager(_db, _db.agentLogs);
  $AgentActivityEventsTableManager get agentActivityEvents =>
      $AgentActivityEventsTableManager(_db, _db.agentActivityEvents);
  $AgentUsageRecordsTableManager get agentUsageRecords =>
      $AgentUsageRecordsTableManager(_db, _db.agentUsageRecords);
  $AgentFilesTableManager get agentFiles =>
      $AgentFilesTableManager(_db, _db.agentFiles);
  $WorkspaceInquiriesTableManager get workspaceInquiries =>
      $WorkspaceInquiriesTableManager(_db, _db.workspaceInquiries);
  $AgentProvidersTableManager get agentProviders =>
      $AgentProvidersTableManager(_db, _db.agentProviders);
  $AgentTemplatesTableManager get agentTemplates =>
      $AgentTemplatesTableManager(_db, _db.agentTemplates);
  $ApiKeysTableManager get apiKeys => $ApiKeysTableManager(_db, _db.apiKeys);
  $PreferencesTableManager get preferences =>
      $PreferencesTableManager(_db, _db.preferences);
  $WorkspaceTemplatesTableManager get workspaceTemplates =>
      $WorkspaceTemplatesTableManager(_db, _db.workspaceTemplates);
  $InstanceResultsTableManager get instanceResults =>
      $InstanceResultsTableManager(_db, _db.instanceResults);
  $AgentInstanceStatesTableManager get agentInstanceStates =>
      $AgentInstanceStatesTableManager(_db, _db.agentInstanceStates);
  $AgentConnectionStatusTableManager get agentConnectionStatus =>
      $AgentConnectionStatusTableManager(_db, _db.agentConnectionStatus);
  $ContainerHealthTableManager get containerHealth =>
      $ContainerHealthTableManager(_db, _db.containerHealth);
  $WorkspaceRunStatusTableManager get workspaceRunStatus =>
      $WorkspaceRunStatusTableManager(_db, _db.workspaceRunStatus);
  $RecentProjectsTableManager get recentProjects =>
      $RecentProjectsTableManager(_db, _db.recentProjects);
}
