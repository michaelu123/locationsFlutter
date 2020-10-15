import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class PhotoScreen extends StatelessWidget {
  static String routeName = "/photo";
  @override
  Widget build(BuildContext context) {
    final String imgPath = ModalRoute.of(context).settings.arguments as String;

    return Scaffold(
      appBar: AppBar(),
      body: PhotoView(
        imageProvider: FileImage(File(imgPath)),
      ),
    );
  }
}
