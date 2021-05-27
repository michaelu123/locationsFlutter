import 'dart:io';
import 'package:flutter/material.dart';
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
  } else if (Platform.isIOS) {
    _extPath = (await getApplicationDocumentsDirectory()).path;
  } else {
    _extPath = "./extPath";
    //but Windows or other platforms fail elsewhere,
    // e.g. Windows because of sqflite, or Chrome Web because of dart:io
  }
}

String getExtPath() {
  return _extPath;
}

Future<bool> areYouSure(BuildContext context, String msg) {
  return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: const Text('Sicher?'),
          content: Text(msg),
          actions: <Widget>[
            TextButton(
              child: const Text("Nein"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text("Ja"),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> screenMessage(BuildContext context, String msg) {
  return showDialog(
    context: context,
    builder: (context) => new AlertDialog(
      title: const Text('Achtung'),
      content: Text(msg),
      actions: <Widget>[
        TextButton(
          child: const Text("OK"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    ),
  );
}

// https://stackoverflow.com/questions/56280736/alertdialog-without-context-in-flutter
final navigatorKey = GlobalKey<NavigatorState>(); // see main.dart

Future<void> screenMessageNoContext(String msg) {
  return screenMessage(navigatorKey.currentContext, msg);
}
