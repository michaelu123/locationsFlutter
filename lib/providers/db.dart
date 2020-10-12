import 'package:locations/providers/base_config.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';
import 'package:path_provider/path_provider.dart';

// only dir visible in astro: getExternalStorageDirectory

class LocationsDB {
  static String dbName;
  static List<String> createStmts;
  static Database db;

  static Future<void> setBase(BaseConfig baseConfig) async {
    if (db != null) await db.close();
    db = null;
    createStmts = [];
    dbName = baseConfig.getDbName();
    var felder = baseConfig.getDbDatenFelder();
    createStmts.addAll(stmtsFor(felder, "daten"));
    felder = baseConfig.getDbZusatzFelder();
    createStmts.addAll(stmtsFor(felder, "zusatz"));
    felder = baseConfig.getDbImagesFelder();
    createStmts.addAll(stmtsFor(felder, "images"));
    db = await database();
  }

  static const dbType = {
    "string": "TEXT",
    "float": "REAL",
    "bool": "INTEGER",
    "int": "INTEGER",
    "prozent": "INTEGER",
  };

  static List<String> stmtsFor(List felder, String table) {
    List<String> stmts = [];
    List<String> dbfelder = felder.map((feld) {
      return '${feld["name"]} ${dbType[feld["type"]]}';
    }).toList();
    String stmt = "CREATE TABLE IF NOT EXISTS $table (${dbfelder.join(", ")}, ";
    if (table == "daten") {
      stmt += " PRIMARY KEY (lat_round, lon_round)";
    } else if (table == "zusatz") {
      stmt +=
          "PRIMARY KEY (nr), UNIQUE(creator, created, modified, lat_round, lon_round)";
    } else {
      stmt += "PRIMARY KEY (image_path)";
    }
    stmt += " ON CONFLICT REPLACE)";
    stmts.add(stmt);
    if (table == "zusatz") {
      stmts.add(
          "CREATE INDEX IF NOT EXISTS latlonrnd_zusatz ON zusatz (lat_round, lon_round)");
    } else if (table == "images") {
      stmts.add(
          "CREATE INDEX IF NOT EXISTS latlonrnd_images ON images (lat_round, lon_round)");
    }
    return stmts;
  }

  static Future<Database> database() async {
    final extPath = await getExternalStorageDirectory();
    final dbPath = path.join(extPath.path, dbName);
    // await sql.deleteDatabase(dbPath);
    final db = await sql.openDatabase(
      dbPath,
      onCreate: (Database db, int version) async {
        await Future.forEach(createStmts, (stmt) async {
          print("$stmt");
          try {
            await db.execute(stmt);
          } catch (e) {
            print(e);
            print("!!");
          }
        });
      },
      version: 1,
    );
    return db;
  }

  static Future<int> insert(String table, Map<String, Object> data) async {
    final db = await database();
    return db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, Object>>> getData(String table) async {
    final db = await database();
    return db.query(table);
  }
}
