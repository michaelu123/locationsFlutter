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
import 'package:locations/utils/utils.dart';
import 'package:provider/provider.dart';

class IndexModel extends ChangeNotifier {
  int curIndex = 0;

  void set(int x) {
    curIndex = x;
    print("set curIndex = $curIndex");
    notifyListeners();
  }

  int get() {
    print("curIndex == $curIndex");
    return curIndex;
  }
}

class ImagesScreen extends StatefulWidget {
  static String routeName = "/images";
  @override
  _ImagesScreenState createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen>
    with Felder, SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    final idx = Provider.of<IndexModel>(context, listen: false);
    idx.curIndex = 0;
  }

  Future<void> deleteImage(LocData locData, BaseConfig baseConfig) async {
    String imgPath = locData.deleteImage();
    await LocationsDB.deleteImage(imgPath);
    String tableBase = baseConfig.getDbTableBaseName();
    await deleteImageFile(tableBase, imgPath);
    print("done");
    // perhaps delete on Server?
    // or not delete if not newer lastStored?
  }

  Future<File> getImageFile(BaseConfig baseConfig, LocationsClient locClnt,
      String imgPath, String imgUrl) async {
    final settingsNL = Provider.of<Settings>(context, listen: false);
    String tableBase = baseConfig.getDbTableBaseName();
    int dim = settingsNL.getConfigValueI("thumbnaildim");
    File f = await locClnt.getImage(tableBase, imgPath, dim, true);
    return f;
  }

  Future<File> getImageFileIndexed(
    BaseConfig baseConfig,
    LocationsClient locClnt,
    LocData locData,
    int index,
  ) {
    String imgPath = locData.getImgPath(index);
    String imgUrl = locData.getImgUrl(index);
    return getImageFile(baseConfig, locClnt, imgPath, imgUrl);
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final locData = Provider.of<LocData>(context);
    final locClnt = Provider.of<LocationsClient>(context);
    final pageController = PageController();

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Bilder"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: locData.isEmptyImages()
                ? null
                : () => deleteImage(locData, baseConfig),
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
              Consumer<IndexModel>(
                builder: (ctx, idx, _) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(Icons.arrow_back),
                    onPressed: idx.get() > 0
                        ? () {
                            int prev = idx.get() - 1;
                            locData.setImagesIndex(prev);
                            pageController.animateToPage(
                              prev,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.linear,
                            );
                          }
                        : null,
                  );
                },
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
              Consumer<IndexModel>(
                builder: (ctx, idx, _) {
                  return IconButton(
                    iconSize: 40,
                    icon: Icon(Icons.arrow_forward),
                    onPressed: idx.get() < locData.getImagesCount() - 1
                        ? () {
                            int next = idx.get() + 1;
                            locData.setImagesIndex(next);
                            pageController.animateToPage(
                              next,
                              duration: Duration(milliseconds: 500),
                              curve: Curves.ease,
                            );
                          }
                        : null,
                  );
                },
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
                  final idx = Provider.of<IndexModel>(context, listen: false);
                  if (details.primaryVelocity < 0) {
                    if (idx.get() <= locData.getImagesCount() - 1) {
                      pageController.animateToPage(
                        idx.get() + 1,
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.ease,
                      );
                    }
                  } else {
                    if (idx.get() > 0) {
                      pageController.animateToPage(
                        idx.get() - 1,
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.ease,
                      );
                    }
                  }
                },
                child: PageView.builder(
                  onPageChanged: (int x) {
                    final idx = Provider.of<IndexModel>(context, listen: false);
                    print("set curindex=$x");
                    //setState(() => curIndex = x);
                    idx.set(x);
                    locData.setImagesIndex(x);
                  },
                  controller: pageController,
                  itemCount: locData.getImagesCount(),
                  itemBuilder: (ctx, index) {
                    return FutureBuilder(
                      future: getImageFileIndexed(
                          baseConfig, locClnt, locData, index),
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
