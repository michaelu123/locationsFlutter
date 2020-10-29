import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/providers/storage.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';

class PhotoScreen extends StatelessWidget {
  static String routeName = "/photo";

  Future<File> getImageFile(
      BuildContext context, String imgName, String imgUrl) async {
    final baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    final settingsNL = Provider.of<Settings>(context, listen: false);
    final strgClntNL = Provider.of<Storage>(context, listen: false);
    String tableBase = baseConfigNL.getDbTableBaseName();
    int dim = settingsNL.getConfigValueI("maxdim");
    File f = await strgClntNL.getImage(tableBase, imgName, dim, false);
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final Map args = ModalRoute.of(context).settings.arguments as Map;
    final String imgPath = args["imgPath"];
    final String imgUrl = args["imgUrl"];

    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
        future: getImageFile(context, imgPath, imgUrl),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              child: const Center(
                  child: Text(
                "Loading Image",
                style: TextStyle(
                  backgroundColor: Colors.white,
                  color: Colors.black,
                  fontSize: 20,
                ),
              )),
            );
          }
          if (snap.hasError) {
            return Container(
              child: Center(
                child: Text(
                  "error ${snap.error}",
                  style: const TextStyle(
                    backgroundColor: Colors.white,
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          }
          return snap.data == null
              ? Container(
                  child: Center(
                    child: const Text(
                      "Image not found",
                      style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ),
                )
              : PhotoView(
                  enableRotation: true,
                  imageProvider: FileImage(snap.data),
                );
        },
      ),
    );
  }
}
