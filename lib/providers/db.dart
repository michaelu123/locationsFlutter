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
  static bool hasZusatz;

  static double lat, lon;
  static int stellen;
  static String latRound, lonRound;

  static Future<void> setBase(BaseConfig baseConfig) async {
    if (db != null) await db.close();
    db = null;
    createStmts = [];
    dbName = baseConfig.getDbName();
    var felder = baseConfig.getDbDatenFelder();
    createStmts.addAll(stmtsFor(felder, "daten"));
    felder = baseConfig.getDbZusatzFelder();
    hasZusatz = felder.length > 0;
    if (hasZusatz) createStmts.addAll(stmtsFor(felder, "zusatz"));
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
    final dbPath = path.join(extPath.path, "db", dbName);
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
    return db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, Object>>> getData(String table) async {
    return db.query(table);
  }

  static Future<Map> dataFor2() async {
    return dataFor(lat, lon, stellen);
  }

  static Map makeWritableMap(Map m) {
    var r = {};
    m.keys.forEach((k) {
      r[k] = m[k];
    });
    return r;
  }

  static List makeWritableList(List l) {
    var r = [];
    l.forEach((m) {
      r.add(makeWritableMap(m));
    });
    return r;
  }

  static Future<Map> dataFor(double alat, double alon, int astellen) async {
    lat = alat;
    lon = alon;
    stellen = astellen;
    latRound = alat.toStringAsFixed(stellen);
    lonRound = alon.toStringAsFixed(stellen);

    final resD = await db.query(
      "daten",
      where: "lat_round=? and lon_round=?",
      whereArgs: [latRound, lonRound],
    );
    final resZ = hasZusatz
        ? await db.query(
            "zusatz",
            where: "lat_round=? and lon_round=?",
            whereArgs: [latRound, lonRound],
          )
        : [];
    final resI = await db.query(
      "images",
      where: "lat_round=? and lon_round=?",
      whereArgs: [latRound, lonRound],
    );
    return {
      "daten": makeWritableList(resD),
      "zusatz": makeWritableList(resZ),
      "images": makeWritableList(resI),
    };
  }

  static Future<void> set(String table, String name, Object val) async {
    int res = await db.update(
      table,
      {name: val},
      where: "lat_round=? and lon_round=?",
      whereArgs: [latRound, lonRound],
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
    print("res1 $res");
    if (res == 0) {
      res = await db.insert(table, {
        "lat": lat,
        "lon": lon,
        "lat_round": latRound,
        "lon_round": lonRound,
        "created": "xxx",
        "modified": "xxx",
        name: val,
      });
      print("res2 $res");
    }
  }
}
