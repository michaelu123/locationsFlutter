import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

import 'package:locations/utils/db.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/providers/markers.dart';

class Photos extends ChangeNotifier {
  static DateFormat dateFormatter = DateFormat('yyyy.MM.dd_HH:mm:ss');

  Future<void> takePicture(
    Markers markers,
    LocData locData,
    int maxDim,
    String nickName,
    String tableBase,
  ) async {
    final ImagePicker ip = ImagePicker();
    final PickedFile pf = await ip.getImage(
      source: ImageSource.camera,
      maxHeight: maxDim * 1.0,
      maxWidth: maxDim * 1.0,
    );
    if (pf == null || pf.path == null) {
      return;
    }

    final lat = LocationsDB.lat;
    final lon = LocationsDB.lat;
    final latRound = LocationsDB.latRound;
    final lonRound = LocationsDB.lonRound;

    File _storedImage = File(pf.path);
    final extPath = (await getExternalStorageDirectory()).path;
    final now = dateFormatter.format(DateTime.now());
    final imgName = "${latRound}_${lonRound}_$now.jpg";
    final imgDirPath = path.join(extPath, tableBase, "images");
    Directory(imgDirPath).create(recursive: true);
    final imgPath = path.join(imgDirPath, imgName);
    await _storedImage.copy(imgPath);

    final map = {
      "creator": nickName,
      "created": now,
      "lat": lat,
      "lon": lon,
      "lat_round": latRound,
      "lon_round": lonRound,
      "image_path": imgName,
      "image_url": null,
    };
    await LocationsDB.insert("images", map);
    locData.addImage(map);
    // notifyListeners();
  }

  Future<void> deleteAllImages(String tableBase) async {
    final extPath = (await getExternalStorageDirectory()).path;
    String imgDirPath = path.join(extPath, tableBase, "images");
    Stream<FileSystemEntity> images = Directory(imgDirPath).list();
    images.forEach((image) async {
      await image.delete();
    });
    // pictures taken by Camera
    imgDirPath = path.join(extPath, "Pictures");
    images = Directory(imgDirPath).list();
    images.forEach((image) async {
      await image.delete();
    });
  }
}
