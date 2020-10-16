import 'dart:io';

import 'package:locations/providers/base_config.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqlite_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:locations/utils/utils.dart';

class Coord {
  double lat;
  double lon;
  int quality;
  bool hasImage;
}

class LocationsDB {
  static String dbName;
  static List<String> createStmts;
  static Database db;
  static bool hasZusatz;

  static double lat, lon;
  static int stellen;
  static String latRound, lonRound;
  static Map<String, String> qmarks = {};

  static DateFormat dateFormatter = DateFormat('yyyy.MM.dd HH:mm:ss');

  static Future<void> setBase(BaseConfig baseConfig) async {
    if (db != null) await db.close();
    db = null;
    createStmts = [];
    dbName = baseConfig.getDbName();
    var felder = baseConfig.getDbDatenFelder();
    qmarks["daten"] = List.generate(felder.length, (_) => "?").join(",");
    createStmts.addAll(stmtsFor(felder, "daten"));
    felder = baseConfig.getDbZusatzFelder();
    qmarks["zusatz"] = List.generate(felder.length, (_) => "?").join(",");
    hasZusatz = felder.length > 0;
    if (hasZusatz) createStmts.addAll(stmtsFor(felder, "zusatz"));
    felder = baseConfig.getDbImagesFelder();
    qmarks["images"] = List.generate(felder.length, (_) => "?").join(",");
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
          "PRIMARY KEY(nr), UNIQUE(creator, created, modified, lat_round, lon_round)";
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
// only dir visible in Astro: getExternalStorageDirectory

    final extPath = await getExternalStorageDirectory();

    // while we are at the extstor:
    final imgDirPath = path.join(extPath.path, "images");
    final imageDir = Directory(imgDirPath);
    imageDir.create(recursive: true);

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
    return await db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, Object>>> getData(String table) async {
    return await db.query(table);
  }

  static Future<Map> dataForSameLoc() async {
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
    print("DB dataFor");
    lat = alat;
    lon = alon;
    stellen = astellen;

    String latRound = roundDS(alat, stellen);
    String lonRound = roundDS(alon, stellen);
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
      // res is readOnly
      "daten": makeWritableList(resD),
      "zusatz": makeWritableList(resZ),
      "images": makeWritableList(resI),
    };
  }

  static Future<Map> updateDB(
      String table, String name, Object val, String nickName,
      {int nr}) async {
    String where;
    List whereArgs;
    if (table == "zusatz") {
      where = "nr=? and lat_round=? and lon_round=?";
      whereArgs = [nr, latRound, lonRound];
    } else {
      where = "lat_round=? and lon_round=?";
      whereArgs = [latRound, lonRound];
    }
    final now = dateFormatter.format(DateTime.now());
    if (table != "zusatz" || nr != null) {
      int res = await db.update(
        table,
        {name: val, "modified": now},
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: sql.ConflictAlgorithm.replace,
      );
      // res = number of updated rows
      if (res != 0) {
        return {"modified": now};
      }
    }
    int res = await db.insert(table, {
      // nr is autoincremented
      "lat": lat,
      "lon": lon,
      "lat_round": latRound,
      "lon_round": lonRound,
      "creator": nickName,
      "created": now,
      "modified": now,
      name: val,
    });
    // res = the created rowid
    return {"nr": res, "created": now};
  }

  // works only for Abstellanlagen...
  static int qualityOf(Map row) {
    var good = 0;
    for (final f in [
      "abschließbar",
      "anlehnbar",
      "abstand",
      "ausparken",
      "geschützt",
    ]) {
      if (row[f] == 1) good += 1;
    }
    if (good == 5 && row["zustand"] == "hoch") return 2;
    if (good >= 2 && row["zustand"] != null && row["zustand"] != "niedrig")
      return 1;
    return 0;
  }

  static Future<List<Coord>> readCoords() async {
    print("readCoords");
    String key;
    Map<String, Coord> map = {};
    final resD = await db.query("daten");
    for (final res in resD) {
      final coord = Coord();
      coord.lat = res["lat"];
      coord.lon = res["lon"];
      coord.quality = qualityOf(res);
      coord.hasImage = false;
      key = '${res["lat_round"]}:${res["lon_round"]}';
      map[key] = coord;
    }
    if (hasZusatz) {
      final resZ = await db.query("zusatz");
      for (final res in resZ) {
        key = '${res["lat_round"]}:${res["lon_round"]}';
        var coord = map[key];
        if (coord == null) {
          final coord = Coord();
          coord.lat = res["lat"];
          coord.lon = res["lon"];
          coord.quality = 0;
          coord.hasImage = false;
          map[key] = coord;
        }
      }
    }
    final resI = await db.query("images");
    for (final res in resI) {
      key = '${res["lat_round"]}:${res["lon_round"]}';
      var coord = map[key];
      if (coord == null) {
        final coord = Coord();
        coord.lat = res["lat"];
        coord.lon = res["lon"];
        coord.quality = 0;
        map[key] = coord;
      }
      coord.hasImage = true;
    }
    return map.values.toList();
  }

  static Future<void> deleteAllLoc(double lat, double lon) async {
    String where = "lat_round=? and lon_round=?";
    List whereArgs = [
      roundDS(lat, stellen),
      roundDS(lon, stellen),
    ];
    await db.delete("daten", where: where, whereArgs: whereArgs);
    await db.delete("images", where: where, whereArgs: whereArgs);
    await db.delete("zusatz", where: where, whereArgs: whereArgs);
  }

  static Future<void> deleteAll() async {
    await db.delete("daten");
    await db.delete("images");
    await db.delete("zusatz");
  }

  static Future<void> deleteZusatz(int nr) async {
    String where = "nr=? and lat_round=? and lon_round=?";
    List whereArgs = [nr, latRound, lonRound];
    await db.delete("zusatz", where: where, whereArgs: whereArgs);
  }

  static Future<void> deleteImage(String imgPath) async {
    String where = "image_path=?";
    List whereArgs = [imgPath];
    await db.delete("images", where: where, whereArgs: whereArgs);
  }

  static Future<void> fillWithDBValues(Map values) async {
    print("1fill");
    for (String table in values.keys) {
      List rows = values[table];
      for (List row in rows) {
        await db.rawInsert("INSERT INTO $table VALUES(${qmarks[table]})", row);
      }
    }
    print("2fill");
  }
}
