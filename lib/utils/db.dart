import 'dart:io';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:locations/parser/parser.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite/sqlite_api.dart';

class Coord {
  double lat;
  double lon;
  int quality;
  bool hasImage;
}

class LocationsDB {
  static String dbName;
  static String tableBase;
  static String baseName;
  static List<String> createStmts;
  static List<String> updateStmts;
  static Database db;
  static bool hasZusatz;
  static int bcVers;

  static double lat, lon;
  static int stellen;
  static String latRound, lonRound;
  static Map<String, String> qmarks = {};
  static Map<String, String> colNames = {};
  static List<Statement> statements;

  static DateFormat dateFormatterDB = DateFormat('yyyy.MM.dd HH:mm:ss');

  static Future<void> setBaseDB(BaseConfig baseConfig) async {
    if (dbName == baseConfig.getDbName()) return;
    baseName = baseConfig.getName();
    dbName = baseConfig.getDbName();
    if (db != null) await db.close();
    db = null;
    createStmts = [];
    updateStmts = [];
    bcVers = baseConfig.getVersion();
    int dbVers = await dbVersion();
    if (bcVers > dbVers) {
      final diffs = baseConfig.getDiff(dbVers, bcVers);
      final addedDaten = diffs.item1;
      final removedDaten = diffs.item2;
      final addedZusatz = diffs.item3;
      final removedZusatz = diffs.item4;
      print("ne $addedDaten $removedDaten $addedZusatz, $removedZusatz");
      updateStmts.addAll(updateAddStatementsFor(addedDaten, "daten"));
      updateStmts.addAll(updateAddStatementsFor(addedZusatz, "zusatz"));
      // cannot remove columns from DB, see https://www.sqlitetutorial.net/sqlite-alter-table/
    }

    tableBase = baseConfig.getDbTableBaseName();
    var felder = baseConfig.getDbDatenFelder();
    qmarks["daten"] = List.generate(felder.length, (_) => "?").join(",");
    colNames["daten"] = felder.map((feld) => feld["name"]).join(",");
    createStmts.addAll(createStmtsFor(felder, "daten"));
    felder = baseConfig.getDbZusatzFelder();
    qmarks["zusatz"] = List.generate(felder.length, (_) => "?").join(",");
    colNames["zusatz"] = felder.map((feld) => feld["name"]).join(",");
    hasZusatz = felder.length > 0;
    if (hasZusatz) createStmts.addAll(createStmtsFor(felder, "zusatz"));
    felder = baseConfig.getDbImagesFelder();
    qmarks["images"] = List.generate(felder.length, (_) => "?").join(",");
    colNames["images"] = felder.map((feld) => feld["name"]).join(",");
    createStmts.addAll(createStmtsFor(felder, "images"));
    db = await database();
    lat = lon = null;
    statements = parseProgram(baseConfig.getProgram());
  }

  static const dbType = {
    "string": "TEXT",
    "float": "REAL",
    "bool": "INTEGER",
    "int": "INTEGER",
    "prozent": "INTEGER",
  };

  static List<String> createStmtsFor(List felder, String table) {
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

  // sorry no DROP COLUMN in Sqflite
  static List<String> updateAddStatementsFor(List felder, String table) {
    List<String> stmts = felder.map((feld) {
      return 'ALTER TABLE $table ADD COLUMN ${feld["name"]} ${dbType[feld["type"]]}';
    }).toList();
    return stmts;
  }

  static Future<Database> database() async {
    final extPath = getExtPath();

    // while we are at the extstor:
    final imgDirPath = path.join(extPath, tableBase, "images");
    final imageDir = Directory(imgDirPath);
    imageDir.create(recursive: true);

    final dbPath = path.join(extPath, "db", dbName);
    final db = await sql.openDatabase(
      dbPath,
      onCreate: (Database db, int version) async {
        await Future.forEach(createStmts, (stmt) async {
          try {
            await db.execute(stmt);
          } catch (e) {
            print("db exception $e");
          }
        });
      },
      onUpgrade: (Database db, int oldv, int newv) async {
        print("upgrade from $oldv to $newv");
        await Future.forEach(updateStmts, (stmt) async {
          try {
            await db.execute(stmt);
          } catch (e) {
            print("db exception $e");
          }
        });
      },
      onDowngrade: (Database db, int oldv, int newv) {
        print("downgrade from $oldv to $newv");
      },
      version: bcVers,
    );
    return db;
  }

  static Future<int> dbVersion() async {
    try {
      final extPath = getExtPath();
      final dbPath = path.join(extPath, "db", dbName);
      final db = await sql.openDatabase(dbPath, readOnly: true);

      final res = await db.getVersion();
      await db.close();
      return res;
    } catch (e) {
      print("db exc $e");
    }
    return 0;
  }

  static Future<void> deleteDBNotUsed() async {
    final extPath = getExtPath();
    final dbPath = path.join(extPath, "db", dbName);
    await sql.deleteDatabase(dbPath);
    db = await database();
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

  static Map<String, dynamic> makeWritableMap(Map m) {
    var r = Map<String, dynamic>();
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
    r.sort((a, b) => a["created"].compareTo(b["created"]));
    return r;
  }

  static Future<Map> dataFor(double alat, double alon, int astellen) async {
    // print("DB dataFor");
    lat = alat;
    lon = alon;
    stellen = astellen;
    latRound = roundDS(alat, stellen);
    lonRound = roundDS(alon, stellen);

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

  static Future<Map> getNewData() async {
    String where = "new_or_modified is not null";
    final resD = await db.query(
      "daten",
      where: where,
    );
    final resZ = hasZusatz
        ? await db.query(
            "zusatz",
            where: where,
          )
        : [];
    final resI = await db.query(
      "images",
      where: where,
    );
    return {
      // res is readOnly
      "daten": makeWritableList(resD),
      "zusatz": makeWritableList(resZ),
      "images": makeWritableList(resI),
    };
  }

  static Future<Map> updateRowDB(
      String table, String region, String name, Object val, String userName,
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
    final now = dateFormatterDB.format(DateTime.now());
    if (table != "zusatz" || nr != null) {
      int res = await db.update(
        table,
        {
          "creator": userName,
          "region": region,
          name: val,
          if (table != "images") "modified": now,
          "new_or_modified": 1,
        },
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
      "region": region,
      "lat": lat,
      "lon": lon,
      "lat_round": latRound,
      "lon_round": lonRound,
      "creator": userName,
      "created": now,
      "modified": now,
      "new_or_modified": 1,
      name: val,
    });
    // res = the created rowid
    return {"nr": res, "created": now};
  }

  static Future<void> updateImagesDB(
      String imagePath, String name, Object val) async {
    String where = "image_path=?";
    List whereArgs = [imagePath];
    await db.update(
      "images",
      {
        name: val,
      },
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static int qualityOfLoc(Map daten, List zusatz) {
    int r = evalProgram(statements, daten, zusatz);
    if (r == null || r < 0 || r > 2) r = 0;
    return r;
  }

  static Future<List<Coord>> readCoords() async {
    Map<String, Map<String, dynamic>> daten = {};
    Map<String, List> zusatz = {};
    Map<String, Coord> map = {};
    final resD = await db.query("daten");
    for (final res in resD) {
      final coord = Coord();
      coord.lat = res["lat"];
      coord.lon = res["lon"];
      coord.hasImage = false;
      final key = '${res["lat_round"]}:${res["lon_round"]}';
      map[key] = coord;
      daten[key] = res;
    }
    if (hasZusatz) {
      final resZ = await db.query("zusatz");
      for (final res in resZ) {
        final key = '${res["lat_round"]}:${res["lon_round"]}';
        List l = zusatz[key];
        if (l == null) {
          l = [];
          zusatz[key] = l;
        }
        l.add(res);
        var coord = map[key];
        if (coord == null) {
          coord = Coord();
          coord.lat = res["lat"];
          coord.lon = res["lon"];
          coord.hasImage = false;
          map[key] = coord;
        }
      }
    }
    final resI = await db.query("images");
    for (final res in resI) {
      final key = '${res["lat_round"]}:${res["lon_round"]}';
      var coord = map[key];
      if (coord == null) {
        coord = Coord();
        coord.lat = res["lat"];
        coord.lon = res["lon"];
        map[key] = coord;
      }
      coord.hasImage = true;
    }

    map.forEach((key, coord) {
      final m = daten[key] != null ? makeWritableMap(daten[key]) : {};
      final z = zusatz[key];
      List l;
      if (z != null) {
        l = makeWritableList(z);
      } else {
        l = [];
      }
      coord.quality = qualityOfLoc(m, l);
    });
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

  static Future<void> deleteOldData() async {
    String where = "new_or_modified is null";
    await db.delete("daten", where: where);
    await db.delete("images", where: where);
    if (hasZusatz) {
      await db.delete("zusatz", where: where);
    }
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
    Map newData = await getNewData(); // save new data
    for (String table in values.keys) {
      bool isZusatz = table == "zusatz";

      List rows = values[table];
      if (rows == null) continue;
      // sort for modification date: newer records overwrite older ones
      // because of sqlite's onConflict:replace, and primary key not on
      // creator like on server DBs.
      switch (table) {
        case "daten":
          rows.sort((r1, r2) => (r1[2] as String).compareTo(r2[2] as String));
          break;
        case "zusatz":
          rows.sort((r1, r2) => (r1[3] as String).compareTo(r2[3] as String));
          break;
      }

      int rl = rows.length;
      int start = 0;
      while (start < rl) {
        int end = min(start + 100, rl);
        final batch = db.batch();
        List sub = rows.sublist(start, end);
        start = end;
        for (List row in sub) {
          row.add(null); // for new_or_modified
          if (isZusatz) row[0] = null; // nr field
          try {
            batch.rawInsert(
                "INSERT INTO $table(${colNames[table]}) VALUES(${qmarks[table]})",
                row);
          } catch (e) {
            print("db exception $e");
          }
        }
        await batch.commit(noResult: true);
      }
      // restore new data
      rows = newData[table];
      for (final map in rows) {
        if (isZusatz) map['nr'] = null;
        await (db.insert(table, map));
      }
    }
  }

  static Future<Set> getNewImagePaths() async {
    String where = "new_or_modified is not null";
    final set = Set();
    final resI =
        await db.query("images", columns: ["image_path"], where: where);
    for (final res in resI) {
      set.add(res["image_path"]);
    }
    return set;
  }

  static Future<void> clearNewOrModified() async {
    String where = "new_or_modified is not null";
    for (final table in ["daten", if (hasZusatz) "zusatz", "images"]) {
      await db.update(table, {"new_or_modified": null}, where: where);
    }
  }
}
