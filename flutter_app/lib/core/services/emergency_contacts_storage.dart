import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/emergency_reporting/data/models/emergency_contact.dart';

/// SQLite storage for emergency contacts
class EmergencyContactsStorage {
  static final EmergencyContactsStorage _instance = EmergencyContactsStorage._internal();
  factory EmergencyContactsStorage() => _instance;
  EmergencyContactsStorage._internal();

  Database? _db;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'emergency_data.db');

    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE emergency_contacts (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            label TEXT NOT NULL,
            email TEXT,
            verified INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_contacts_name ON emergency_contacts(name)');
        await db.execute('CREATE INDEX idx_contacts_phone ON emergency_contacts(phone)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE emergency_contacts ADD COLUMN verified INTEGER NOT NULL DEFAULT 0');
        }
      },
    );

    _initialized = true;
  }

  Future<List<EmergencyContact>> getAllContacts() async {
    if (!_initialized) await initialize();
    final rows = await _db!.query('emergency_contacts', orderBy: 'name COLLATE NOCASE ASC');
    return rows
        .map((r) => EmergencyContact(
              id: r['id'] as String,
              name: r['name'] as String,
              phoneNumber: r['phone'] as String,
              label: r['label'] as String,
              email: r['email'] as String?,
              verified: ((r['verified'] as int?) ?? 0) == 1,
            ))
        .toList();
  }

  Future<void> upsertContact(EmergencyContact c) async {
    if (!_initialized) await initialize();
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.insert(
      'emergency_contacts',
      {
        'id': c.id,
        'name': c.name,
        'phone': c.phoneNumber,
        'label': c.label,
        'email': c.email,
        'verified': c.verified ? 1 : 0,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteContact(String id) async {
    if (!_initialized) await initialize();
    await _db!.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    if (!_initialized) await initialize();
    await _db!.delete('emergency_contacts');
  }
}
