import 'dart:io';

import 'package:flutter/material.dart';
import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/photos.dart';
import 'package:locations/providers/settings.dart';
import 'package:locations/providers/storage.dart';
import 'package:locations/screens/daten.dart';
import 'package:locations/screens/karte.dart';
import 'package:locations/screens/photo.dart';
import 'package:locations/screens/zusatz.dart';
import 'package:locations/utils/db.dart';
import 'package:locations/utils/felder.dart';
import 'package:locations/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:tuple/tuple.dart';

/// IndexModel is needed only for the left and right arrows.
/// If we trigger [LocData] notification when moving from
/// one image to another, the image flickers at
/// half the transition, because build() is called in between.
/// This looks bad. So we make the arrows only dependent on IndexModel, and
/// do not notify [LocData] when changing images.
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

/// This class shows images and allows to move between them.
class ImagesScreen extends StatefulWidget {
  static String routeName = "/images";
  @override
  _ImagesScreenState createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen>
    with Felder, SingleTickerProviderStateMixin {
  BaseConfig baseConfigNL;
  LocData locDataNL;
  Storage strgClntNL;
  Markers markersNL;
  Settings settingsNL;
  IndexModel indexModelNL;
  String tableBase;

  @override
  void initState() {
    super.initState();
    baseConfigNL = Provider.of<BaseConfig>(context, listen: false);
    locDataNL = Provider.of<LocData>(context, listen: false);
    strgClntNL = Provider.of<Storage>(context, listen: false);
    markersNL = Provider.of<Markers>(context, listen: false);
    settingsNL = Provider.of<Settings>(context, listen: false);
    indexModelNL = Provider.of<IndexModel>(context, listen: false);
    tableBase = baseConfigNL.getDbTableBaseName();

    indexModelNL.curIndex = 0;
  }

  Future<void> deleteImage() async {
    if (!await areYouSure(context, 'Wollen Sie das Bild wirklich löschen?'))
      return;

    String imgPath = locDataNL.deleteImage(markersNL);
    indexModelNL.set(locDataNL.imagesIndex);
    await LocationsDB.deleteImage(imgPath);
    String tableBase = baseConfigNL.getDbTableBaseName();
    await deleteImageFile(tableBase, imgPath);
  }

  Future<File> getImageFile(String imgPath, String imgUrl) async {
    final settingsNL = Provider.of<Settings>(context, listen: false);
    String tableBase = baseConfigNL.getDbTableBaseName();
    int dim = settingsNL.getConfigValueI("thumbnaildim");
    File f = await strgClntNL.getImage(tableBase, imgPath, dim, true);
    return f;
  }

  Future<Tuple2<File, String>> getImageFileIndexed(
    LocData locData,
    int index,
  ) async {
    String imgPath = locData.getImgPath(index);
    String imgUrl = locData.getImgUrl(index);
    String bemerkung = locData.getImgBemerkung(index);
    File img = await getImageFile(imgPath, imgUrl);
    return Tuple2(img, bemerkung);
  }

  @override
  Widget build(BuildContext context) {
    final baseConfig = Provider.of<BaseConfig>(context);
    final locData = Provider.of<LocData>(context);
    final photosNL = Provider.of<Photos>(context, listen: false);
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
            icon: const Icon(Icons.delete),
            onPressed: locData.isEmptyImages() ? null : () => deleteImage(),
          ),
        ],
      ),
      body: FutureBuilder(
        future: photosNL.retrieveLostData(
          locData,
          settingsNL.getConfigValueS("username"),
          settingsNL.getConfigValueS("region"),
          baseConfig.getDbTableBaseName(),
          markersNL,
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
                    child: const Text(
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
                    child: const Text(
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
                    child: const Text(
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
                        icon: const Icon(Icons.arrow_back),
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
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: () async {
                      int x = await photosNL.takePicture(
                        locData,
                        settingsNL.getConfigValueI("maxdim"),
                        settingsNL.getConfigValueS("username"),
                        settingsNL.getConfigValueS("region"),
                        baseConfig.getDbTableBaseName(),
                        markersNL,
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
                        icon: const Icon(Icons.arrow_forward),
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
                    child: const Text(
                      "Noch keine Bilder aufgenommen",
                      style: TextStyle(
                        backgroundColor: Colors.white,
                        color: Colors.black,
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
                          future: getImageFileIndexed(locData, index),
                          builder: (ctx, snap) {
                            TextEditingController controller =
                                TextEditingController(
                                    text: snap.data != null
                                        ? snap.data.item2
                                        : "");
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: const Text(
                                "Loading Image",
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ));
                            }
                            if (snap.hasError) {
                              return Center(
                                child: Text(
                                  "error ${snap.error}",
                                  style: const TextStyle(
                                    backgroundColor: Colors.white,
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              );
                            }
                            if (snap.data == null) {
                              return Center(
                                  child: const Text(
                                "Bild nicht gefunden",
                                style: TextStyle(
                                  backgroundColor: Colors.white,
                                  color: Colors.black,
                                  fontSize: 20,
                                ),
                              ));
                            }
                            return Column(
                              children: [
                                Padding(
                                  child: TextField(
                                      decoration: InputDecoration(
                                          labelText: "Bemerkung"),
                                      controller: controller,
                                      onSubmitted: (text) {
                                        locData.setImgBemerkung(text, index);
                                      }),
                                  padding: EdgeInsets.all(10),
                                ),
                                Expanded(
                                    child: Stack(
                                  children: [
                                    Image.file(
                                      snap.data.item1,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                    Positioned(
                                      child: Text(
                                        locData.getImgCreated(index),
                                        style: const TextStyle(
                                          backgroundColor: Colors.white,
                                          color: Colors.black,
                                        ),
                                      ),
                                      bottom: 20,
                                      right: 20,
                                    ),
                                  ],
                                ))
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
