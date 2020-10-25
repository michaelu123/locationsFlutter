import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

String roundDS(double d, int stellen) {
  // trim trailing zeroes
  // we try to achieve what str(round(d, stellen)) does in Python
  String s = d.toStringAsFixed(stellen);
  while (s[s.length - 1] == '0') {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

Future<void> deleteImageFile(String tableBase, String imgPath) async {
  final extPath = getExtPath();
  String imgFilePath = path.join(extPath, tableBase, "images", imgPath);
  try {
    await File(imgFilePath).delete();
  } catch (e) {}
  imgFilePath = path.join(extPath, tableBase, "images", "tn_" + imgPath);
  try {
    await File(imgFilePath).delete();
  } catch (e) {}
}

String _extPath;

Future<void> initExtPath() async {
  if (Platform.isAndroid) {
    _extPath = (await getExternalStorageDirectory()).path;
  } else {
    _extPath = "./extPath";
    //but Windows or other platforms fail elsewhere,
    // e.g. Windows because of sqflite, or Chrome Web because of dart:io
  }
}

String getExtPath() {
  return _extPath;
}
