// lib/database/database_helper.dart
//
// Fixes vs. the version in the RAR:
//  1. listarAlbuns() was a stub returning Future<Object?> — now fully implemented
//  2. Album model added (was missing entirely)
//  3. album_id FK column added to registros (with migration from v1 → v2)
//  4. initFfiIfNeeded() correctly guards Android/iOS (no FFI there)
//  5. Foreign-key PRAGMA enabled so ON DELETE CASCADE actually fires on Android
//  6. All fromMap casts use null-safe fallbacks (no more type-cast crashes)
//  7. Removed sqflite_common_ffi import guard — it's only referenced inside
//     the Platform.is* branch so it compiles fine on mobile too

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class Album {
  final int?   id;
  final String nome;
  final String descricao;
  final String icone;    // key into kIconMap, e.g. 'snowflake'
  final String cor;      // hex string, e.g. '#2E9E50'
  final String criadoEm; // ISO-8601

  const Album({
    this.id,
    required this.nome,
    this.descricao = '',
    this.icone     = 'photo_album',
    this.cor       = '#2E9E50',
    required this.criadoEm,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome':      nome,
    'descricao': descricao,
    'icone':     icone,
    'cor':       cor,
    'criado_em': criadoEm,
  };

  factory Album.fromMap(Map<String, dynamic> m) => Album(
    id:        m['id']        as int?,
    nome:      (m['nome']      as String?) ?? '',
    descricao: (m['descricao'] as String?) ?? '',
    icone:     (m['icone']     as String?) ?? 'photo_album',
    cor:       (m['cor']       as String?) ?? '#2E9E50',
    criadoEm:  (m['criado_em'] as String?) ?? DateTime.now().toIso8601String(),
  );

  Album copyWith({String? nome, String? descricao, String? icone, String? cor}) => Album(
    id: id, criadoEm: criadoEm,
    nome:      nome      ?? this.nome,
    descricao: descricao ?? this.descricao,
    icone:     icone     ?? this.icone,
    cor:       cor       ?? this.cor,
  );
}

class Registro {
  final int?         id;
  final int?         albumId;   // FK → albuns.id  (nullable)
  final String       titulo;
  final String       descricao;
  final String       local;
  final String       dataHora;  // ISO-8601
  final int          humor;     // 0-4
  final String       tags;      // CSV: "Viagem,Natureza"
  final String       album;     // denormalized album name for quick display
  final List<String> fotos;     // absolute file paths on device

  const Registro({
    this.id,
    this.albumId,
    required this.titulo,
    required this.descricao,
    required this.local,
    required this.dataHora,
    required this.humor,
    required this.tags,
    required this.album,
    this.fotos = const [],
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'album_id':  albumId,
    'titulo':    titulo,
    'descricao': descricao,
    'local':     local,
    'data_hora': dataHora,
    'humor':     humor,
    'tags':      tags,
    'album':     album,
  };

  factory Registro.fromMap(Map<String, dynamic> m, List<String> fotos) => Registro(
    id:        m['id']        as int?,
    albumId:   m['album_id']  as int?,
    titulo:    (m['titulo']    as String?) ?? '',
    descricao: (m['descricao'] as String?) ?? '',
    local:     (m['local']     as String?) ?? '',
    dataHora:  (m['data_hora'] as String?) ?? DateTime.now().toIso8601String(),
    humor:     (m['humor']     as int?)    ?? 0,
    tags:      (m['tags']      as String?) ?? '',
    album:     (m['album']     as String?) ?? '',
    fotos:     fotos,
  );

  List<String> get tagList =>
      tags.isEmpty ? [] : tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
}

// ─── DatabaseHelper ───────────────────────────────────────────────────────────

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  /// Call once in main() before runApp().
  /// Android & iOS use the native sqflite engine and do NOT need FFI.
  static void initFfiIfNeeded() {
    if (kIsWeb || (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS))) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    // Android & iOS: do nothing — sqflite uses the platform channel natively.
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir  = await getDatabasesPath();
    final path = join(dir, 'chronicle.db');

    return openDatabase(
      path,
      version: 2,
      onCreate:  _onCreate,
      onUpgrade: _onUpgrade,
      // Required so ON DELETE CASCADE actually works on Android/iOS SQLite
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createAlbuns(db);
    await _createRegistros(db);
    await _createFotos(db);
    await _seedAlbuns(db);
  }

  Future<void> _onUpgrade(Database db, int old, int newV) async {
    if (old < 2) {
      // v1 had no albuns table and no album_id column
      await _createAlbuns(db);
      await _seedAlbuns(db);
      try {
        await db.execute('ALTER TABLE registros ADD COLUMN album_id INTEGER');
      } catch (_) {
        // column may already exist if partial migration happened
      }
    }
  }

  Future<void> _createAlbuns(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS albuns (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      nome       TEXT    NOT NULL,
      descricao  TEXT    NOT NULL DEFAULT '',
      icone      TEXT    NOT NULL DEFAULT 'photo_album',
      cor        TEXT    NOT NULL DEFAULT '#2E9E50',
      criado_em  TEXT    NOT NULL
    )
  ''');

  Future<void> _createRegistros(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS registros (
      id        INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id  INTEGER,
      titulo    TEXT    NOT NULL,
      descricao TEXT    NOT NULL DEFAULT '',
      local     TEXT    NOT NULL DEFAULT '',
      data_hora TEXT    NOT NULL,
      humor     INTEGER NOT NULL DEFAULT 0,
      tags      TEXT    NOT NULL DEFAULT '',
      album     TEXT    NOT NULL DEFAULT '',
      FOREIGN KEY (album_id) REFERENCES albuns(id) ON DELETE SET NULL
    )
  ''');

  Future<void> _createFotos(Database db) => db.execute('''
    CREATE TABLE IF NOT EXISTS fotos (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      registro_id  INTEGER NOT NULL,
      caminho      TEXT    NOT NULL,
      FOREIGN KEY (registro_id) REFERENCES registros(id) ON DELETE CASCADE
    )
  ''');

  Future<void> _seedAlbuns(Database db) async {
    final now = DateTime.now().toIso8601String();
    for (final a in [
      {'nome': 'Inverno',   'icone': 'snowflake',     'cor': '#5B8DEF'},
      {'nome': 'Verão',     'icone': 'wb_sunny',      'cor': '#F5A623'},
      {'nome': 'Outono',    'icone': 'eco',           'cor': '#E07B39'},
      {'nome': 'Primavera', 'icone': 'local_florist', 'cor': '#2E9E50'},
    ]) {
      await db.insert('albuns', {
        'nome': a['nome'], 'descricao': '',
        'icone': a['icone'], 'cor': a['cor'], 'criado_em': now,
      });
    }
  }

  // ── Album CRUD ─────────────────────────────────────────────────────────────

  Future<int> inserirAlbum(Album a) async =>
      (await database).insert('albuns', a.toMap());

  Future<List<Album>> listarAlbuns() async {
    final rows = await (await database).query('albuns', orderBy: 'criado_em ASC');
    return rows.map(Album.fromMap).toList();
  }

  Future<Album?> buscarAlbum(int id) async {
    final rows = await (await database).query('albuns', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Album.fromMap(rows.first);
  }

  Future<void> atualizarAlbum(Album a) async =>
      (await database).update('albuns', a.toMap(), where: 'id = ?', whereArgs: [a.id]);

  Future<void> deletarAlbum(int id) async =>
      (await database).delete('albuns', where: 'id = ?', whereArgs: [id]);

  Future<int> totalRegistrosPorAlbum(int albumId) async {
    final res = await (await database).rawQuery(
        'SELECT COUNT(*) as c FROM registros WHERE album_id = ?', [albumId]);
    return (res.first['c'] as int?) ?? 0;
  }

  Future<List<Registro>> listarRegistrosPorAlbum(int albumId) async {
    final db   = await database;
    final rows = await db.query('registros',
        where: 'album_id = ?', whereArgs: [albumId], orderBy: 'data_hora DESC');
    return _hydrateRows(db, rows);
  }

  // ── Registro CRUD ──────────────────────────────────────────────────────────

  Future<int> inserirRegistro(Registro r) async {
    final db = await database;
    int newId = 0;
    await db.transaction((txn) async {
      newId = await txn.insert('registros', r.toMap());
      for (final p in r.fotos) {
        await txn.insert('fotos', {'registro_id': newId, 'caminho': p});
      }
    });
    return newId;
  }

  Future<List<Registro>> listarRegistros() async {
    final db   = await database;
    final rows = await db.query('registros', orderBy: 'data_hora DESC');
    return _hydrateRows(db, rows);
  }

  Future<Registro?> buscarRegistro(int id) async {
    final db   = await database;
    final rows = await db.query('registros', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Registro.fromMap(rows.first, await _fotosDe(db, id));
  }

  Future<void> atualizarRegistro(Registro r) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('registros', r.toMap(), where: 'id = ?', whereArgs: [r.id]);
      await txn.delete('fotos', where: 'registro_id = ?', whereArgs: [r.id]);
      for (final p in r.fotos) {
        await txn.insert('fotos', {'registro_id': r.id, 'caminho': p});
      }
    });
  }

  Future<void> deletarRegistro(int id) async =>
      (await database).delete('registros', where: 'id = ?', whereArgs: [id]);

  Future<int> totalRegistros() async {
    final res = await (await database).rawQuery('SELECT COUNT(*) as c FROM registros');
    return (res.first['c'] as int?) ?? 0;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<Registro>> _hydrateRows(Database db, List<Map<String, dynamic>> rows) async {
    final result = <Registro>[];
    for (final row in rows) {
      final id    = row['id'] as int;
      final fotos = await _fotosDe(db, id);
      result.add(Registro.fromMap(row, fotos));
    }
    return result;
  }

  Future<List<String>> _fotosDe(Database db, int registroId) async {
    final rows = await db.query('fotos',
        where: 'registro_id = ?', whereArgs: [registroId]);
    return rows.map((r) => r['caminho'] as String).toList();
  }
}
