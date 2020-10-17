import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
import 'package:locations/screens/photo.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:locations/utils/felder.dart';
import 'package:locations/providers/locations_client.dart';
import 'package:provider/provider.dart';

class ImagesScreen extends StatefulWidget {
  static String routeName = "/images";
  @override
  _ImagesScreenState createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen>
    with Felder, SingleTickerProviderStateMixin {
  void deleteImage(LocData locData) {
    String imgPath = locData.deleteImage();
    LocationsDB.deleteImage(imgPath);
  }

  Future<File> getImageFile(BaseConfig baseConfig, LocationsClient locClnt,
      String imgName, String imgUrl) async {
    final settingsNL = Provider.of<Settings>(context, listen: false);
    String tableBase = baseConfig.getDbTableBaseName();
    int dim = settingsNL.getConfigValueI("thumbnaildim");
    File f = await locClnt.getImage(tableBase, imgName, dim, true);
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final locData = Provider.of<LocData>(context);
    final locClnt = Provider.of<LocationsClient>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Bilder"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed:
                locData.isEmptyImages() ? null : () => deleteImage(locData),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(KartenScreen.routeName);
                },
                child: Text(
                  'Karte',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () async {
                  final map = await LocationsDB.dataForSameLoc();
                  locData.dataFor("daten", map);
                  Navigator.of(context).pushNamed(DatenScreen.routeName);
                },
                child: Text(
                  'Daten',
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(ZusatzScreen.routeName);
                },
                child: Text(
                  'Zusatz',
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.arrow_back),
                onPressed:
                    locData.canDecImages() ? locData.decIndexImages : null,
              ),
              IconButton(
                icon: Icon(Icons.add_a_photo),
                onPressed: () {
                  final photosNL = Provider.of<Photos>(context, listen: false);
                  final settingsNL =
                      Provider.of<Settings>(context, listen: false);
                  final markersNL =
                      Provider.of<Markers>(context, listen: false);
                  photosNL.takePicture(
                    markersNL,
                    locData,
                    settingsNL.getConfigValueI("maxdim"),
                    settingsNL.getConfigValueS("nickname"),
                    baseConfig.getDbTableBaseName(),
                  );
                },
              ),
              IconButton(
                iconSize: 40,
                icon: Icon(Icons.arrow_forward),
                onPressed:
                    locData.canIncImages() ? locData.incIndexImages : null,
              ),
            ],
          ),
          if (locData.isEmptyImages())
            Expanded(
              child: Center(
                child: Text(
                  "Noch keine Bilder aufgenommen",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          if (!locData.isEmptyImages())
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context)
                      .pushNamed(PhotoScreen.routeName, arguments: {
                    "imgPath": locData.getImagePath(),
                    "imgUrl": locData.getImageUrl(),
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity < 0) {
                    locData.incIndexImages();
                  } else {
                    locData.decIndexImages();
                  }
                },
                child: FutureBuilder(
                  future: getImageFile(baseConfig, locClnt,
                      locData.getImagePath(), locData.getImageUrl()),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: Text(
                        "Loading Image",
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ));
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Text(
                          "error ${snap.error}",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      );
                    }
                    return snap.data == null
                        ? Center(
                            child: Text(
                            "Bild nicht gefunden",
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ))
                        : Image.file(
                            snap.data,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
