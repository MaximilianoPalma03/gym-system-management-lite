import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase({String? testPath}) : _testPath = testPath;
  final String? _testPath;
  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    final base = _testPath ?? p.join(await getDatabasesPath(), 'gym_lite.db');
    _db = await openDatabase(
      base, version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            duration_days INTEGER NOT NULL CHECK(duration_days BETWEEN 1 AND 3650),
            price_cents INTEGER NOT NULL CHECK(price_cents >= 0),
            active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1))
          )''');
        await db.execute('''
          CREATE TABLE clients (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)),
            plan_id INTEGER REFERENCES plans(id) ON DELETE RESTRICT,
            due_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id INTEGER NOT NULL REFERENCES clients(id) ON DELETE RESTRICT,
            plan_id INTEGER NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
            plan_name TEXT NOT NULL,
            amount_cents INTEGER NOT NULL CHECK(amount_cents > 0),
            method TEXT NOT NULL CHECK(method IN ('Efectivo','Transferencia','Tarjeta','Otro')),
            paid_at TEXT NOT NULL,
            period_start TEXT NOT NULL,
            period_end TEXT NOT NULL,
            notes TEXT NOT NULL DEFAULT '',
            voided INTEGER NOT NULL DEFAULT 0 CHECK(voided IN (0,1)),
            created_at TEXT NOT NULL
          )''');
        await db.execute('CREATE INDEX idx_clients_due ON clients(active, due_date)');
        await db.execute('CREATE INDEX idx_payments_date ON payments(paid_at, voided)');
        await db.execute('CREATE INDEX idx_payments_client ON payments(client_id, voided)');
        await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        await db.insert('plans', {'name': 'Mensual (30 días)', 'duration_days': 30, 'price_cents': 0});
        await db.insert('plans', {'name': 'Semanal (7 días)', 'duration_days': 7, 'price_cents': 0});
        await db.insert('settings', {'key': 'studio_name', 'value': 'Mi estudio'});
        await db.insert('settings', {'key': 'color_index', 'value': '0'});
      },
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
