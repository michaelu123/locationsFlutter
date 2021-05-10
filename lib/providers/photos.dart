import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/utils/utils.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import 'package:locations/utils/db.dart';
import 'package:locations/providers/loc_data.dart';

class Photos extends ChangeNotifier {
  static DateFormat dateFormatterName = DateFormat('yyyyMMdd_HHmmss');
  static DateFormat dateFormatterDB = DateFormat('yyyy.MM.dd HH:mm:ss');
  final ImagePicker ip = ImagePicker();

  Future<int> takePicture(
    LocData locData,
    int maxDim,
    String userName,
    String region,
    String tableBase,
    Markers markers,
  ) async {
    final PickedFile pf = await ip.getImage(
      source: ImageSource.camera,
      maxHeight: maxDim * 1.0,
      maxWidth: maxDim * 1.0,
    );
    if (pf == null || pf.path == null) {
      return null;
    }

    return await saveImage(
        File(pf.path), tableBase, userName, region, locData, markers);
    // notifyListeners();
  }

  Future<void> retrieveLostData(LocData locData, String userName, String region,
      String tableBase, Markers markers) async {
    final LostData response = await ip.getLostData();
    if (response.isEmpty || response.file == null) {
      print("no lost data");
      return null;
    }
    print("recovered lost data");
    await saveImage(File(response.file.path), tableBase, userName, region,
        locData, markers);
  }

  Future<int> saveImage(File imf, String tableBase, String userName,
      String region, LocData locData, Markers markers) async {
    final lat = LocationsDB.lat;
    final lon = LocationsDB.lon;
    final latRound = LocationsDB.latRound;
    final lonRound = LocationsDB.lonRound;

    final extPath = getExtPath();
    final now = DateTime.now();
    final dbNow = dateFormatterDB.format(now);
    final nameNow = dateFormatterName.format(now);
    final imgName = "${latRound}_${lonRound}_$nameNow.jpg";
    final imgDirPath = path.join(extPath, tableBase, "images");
    Directory(imgDirPath).create(recursive: true);
    final imgPath = path.join(imgDirPath, imgName);
    await imf.copy(imgPath);
    await imf.delete();

    final map = {
      "creator": userName,
      "created": dbNow,
      "region": region,
      "lat": lat,
      "lon": lon,
      "lat_round": latRound,
      "lon_round": lonRound,
      "image_path": imgName,
      "image_url": null,
      "bemerkung": null,
      "new_or_modified": 1,
    };
    await LocationsDB.insert("images", map);
    int x = locData.addImage(map, markers);
    return x;
  }

  Future<void> deleteAllImagesExcept(String tableBase, Set newImages) async {
    final extPath = getExtPath();
    String imgDirPath = path.join(extPath, tableBase, "images");
    Stream<FileSystemEntity> images = Directory(imgDirPath).list();
    images.forEach((image) async {
      String imagePath = path.basename(image.path);
      if (!newImages.contains(imagePath)) await image.delete();
    });
    // pictures taken by Camera
    imgDirPath = path.join(extPath, "Pictures");
    final imagesDir = Directory(imgDirPath);
    if (await imagesDir.exists()) {
      images = imagesDir.list();
      images.forEach((image) async {
        await image.delete();
      });
    }
  }
}
