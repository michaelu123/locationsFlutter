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

// needed extra IndexModel for left and right arrow. If moving from
// one page to other triggers locData notification, the image flickers at
// half the transition, because build is called in between. Looks bad.
class IndexModel extends ChangeNotifier {
  int curIndex = 0;

  void set(int x) {
    curIndex = x;
    notifyListeners();
  }

  int get() {
    return curIndex;
  }
}

int imageAdded = 0;

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

  Future<void> deleteImage(
    LocData locData,
    BaseConfig baseConfig,
    Markers markers,
    IndexModel indexModel,
  ) async {
    String imgPath = locData.deleteImage(markers);
    indexModel.set(locData.imagesIndex);
    await LocationsDB.deleteImage(imgPath);
    String tableBase = baseConfig.getDbTableBaseName();
    await deleteImageFile(tableBase, imgPath);
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
    final markersNL = Provider.of<Markers>(context, listen: false);
    final photosNL = Provider.of<Photos>(context, listen: false);
    final settingsNL = Provider.of<Settings>(context, listen: false);
    final indexModelNL = Provider.of<IndexModel>(context, listen: false);

    final pageController = PageController();

    // Big problem to move to new image, AND have the right
    // arrow button greyed out. One problem was that after
    // pagecontroller.goto(x) Pageview.onPageChanged was called with x-1.
    // Is the page number 1-based??
    // Hence this hack with global imageAdded...
    if (imageAdded > 0) {
      int x = imageAdded;
      imageAdded = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        pageController.jumpToPage(x + 1); // must be one higher!?!?
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(baseConfig.getName() + "/Bilder"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: locData.isEmptyImages()
                ? null
                : () => deleteImage(
                      locData,
                      baseConfig,
                      markersNL,
                      indexModelNL,
                    ),
          ),
        ],
      ),
      body: FutureBuilder(
        future: photosNL.retrieveLostData(
          locData,
          settingsNL.getConfigValueS("nickname"),
          baseConfig.getDbTableBaseName(),
        ),
        builder: (ctx, snap) {
          print(
              "rld ${snap.connectionState} data ${snap.hasData} data ${snap.hasError}");
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          KartenScreen.routeName, (_) => false);
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
                    onPressed: () async {
                      int x = await photosNL.takePicture(
                        locData,
                        settingsNL.getConfigValueI("maxdim"),
                        settingsNL.getConfigValueS("nickname"),
                        baseConfig.getDbTableBaseName(),
                      );
                      if (x != null) {
                        locData.setImagesIndex(x);
                        imageAdded = x;
                      }
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
                                  curve: Curves.linear,
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
                    child: PageView.builder(
                      onPageChanged: (int x) {
                        indexModelNL.set(x);
                        locData.setImagesIndex(x);
                      },
                      controller: pageController,
                      itemCount: locData.getImagesCount(),
                      itemBuilder: (ctx, index) {
                        return FutureBuilder(
                          future: getImageFileIndexed(
                              baseConfig, locClnt, locData, index),
                          builder: (ctx, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
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
                                : Stack(
                                    children: [
                                      Image.file(
                                        snap.data,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                      ),
                                      Positioned(
                                        child: Text(
                                          locData.getImgCreated(index),
                                          style: TextStyle(
                                            backgroundColor: Colors.white,
                                            color: Colors.black,
                                          ),
                                        ),
                                        bottom: 20,
                                        right: 20,
                                      ),
                                    ],
                                  );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
