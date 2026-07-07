// lib/database/database_helper.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ─── Modelo ──────────────────────────────────────────────────────────────────

class Registro {
  final int?         id;
  final String       titulo;
  final String       descricao;
  final String       local;
  final String       dataHora;  // ISO-8601
  final int          humor;     // índice 0-4
  final String       tags;      // CSV: "Viagem,Natureza"
  final String       album;
  final List<String> fotos;     // caminhos absolutos no dispositivo

  const Registro({
    this.id,
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
    'titulo':    titulo,
    'descricao': descricao,
    'local':     local,
    'data_hora': dataHora,
    'humor':     humor,
    'tags':      tags,
    'album':     album,
  };

  factory Registro.fromMap(Map<String, dynamic> m, List<String> fotos) =>
      Registro(
        id:        m['id']        as int?,
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
      tags.isEmpty ? [] : tags.split(',').map((t) => t.trim()).toList();
}

// ─── DatabaseHelper (singleton) ──────────────────────────────────────────────

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  // Chame este método UMA VEZ no main(), antes de runApp()
  static void initFfiIfNeeded() {
    // sqflite_common_ffi é necessário em Desktop (Windows, Linux, macOS)
    // e no Flutter Web. No Android/iOS o sqflite nativo já funciona sozinho.
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'chronicle.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE registros (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo    TEXT    NOT NULL,
        descricao TEXT    NOT NULL DEFAULT '',
        local     TEXT    NOT NULL DEFAULT '',
        data_hora TEXT    NOT NULL,
        humor     INTEGER NOT NULL DEFAULT 0,
        tags      TEXT    NOT NULL DEFAULT '',
        album     TEXT    NOT NULL DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE fotos (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        registro_id  INTEGER NOT NULL,
        caminho      TEXT    NOT NULL,
        FOREIGN KEY (registro_id) REFERENCES registros(id) ON DELETE CASCADE
      )
    ''');
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<int> inserirRegistro(Registro r) async {
    final db = await database;
    int newId = 0;
    await db.transaction((txn) async {
      newId = await txn.insert('registros', r.toMap());
      for (final caminho in r.fotos) {
        await txn.insert('fotos', {'registro_id': newId, 'caminho': caminho});
      }
    });
    return newId;
  }

  Future<List<Registro>> listarRegistros() async {
    final db   = await database;
    final rows = await db.query('registros', orderBy: 'data_hora DESC');
    final List<Registro> result = [];
    for (final row in rows) {
      final id    = row['id'] as int;
      final fotos = await _fotosDe(db, id);
      result.add(Registro.fromMap(row, fotos));
    }
    return result;
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
      for (final caminho in r.fotos) {
        await txn.insert('fotos', {'registro_id': r.id, 'caminho': caminho});
      }
    });
  }

  Future<void> deletarRegistro(int id) async {
    final db = await database;
    await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> totalRegistros() async {
    final db  = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM registros');
    return (res.first['c'] as int?) ?? 0;
  }

  Future<List<String>> _fotosDe(Database db, int registroId) async {
    final rows = await db.query(
      'fotos', where: 'registro_id = ?', whereArgs: [registroId],
    );
    return rows.map((r) => r['caminho'] as String).toList();
  }

  Future<Object?> listarAlbuns() async {}
}