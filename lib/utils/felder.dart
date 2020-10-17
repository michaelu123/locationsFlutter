import 'package:flutter/material.dart';
import 'package:locations/providers/markers.dart';
import 'package:locations/providers/settings.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';

class Felder {
  List<FocusNode> focusNodes;
  List<void Function()> focusHandlers;
  List<TextField> textFields;
  List<TextEditingController> controllers;

  void initFelder(BuildContext context, BaseConfig baseConfig, bool useZusatz) {
    print("1initFelder ${baseConfig.base}");
    List felder =
        useZusatz ? baseConfig.getZusatzFelder() : baseConfig.getDatenFelder();
    int felderLength = felder.length;
    focusNodes = List.generate(
      felderLength,
      (index) => FocusNode(),
    );
    focusHandlers = List.generate(
      felderLength,
      (index) {
        void cb() {
          var fn = focusNodes[index];
          if (!fn.hasFocus) {
            final l = fixText(controllers[index].text, felder[index]);
            controllers[index].text = l[0];
            // can call Provider here because cb is called in other context
            final locDataNL = Provider.of<LocData>(context, listen: false);
            final markersNL = Provider.of<Markers>(context, listen: false);
            final settingsNL = Provider.of<Settings>(context, listen: false);
            final nickName = settingsNL.getConfigValueS("nickname");

            locDataNL.setFeld(markersNL, felder[index]['name'],
                felder[index]["type"], l[1], nickName);
          }
        }

        return cb;
      },
    );
    print("controllers $felderLength");
    controllers = List.generate(
      felderLength,
      (index) {
        return TextEditingController(
          text: "",
        );
      },
    );
    textFields = List.generate(
      felderLength,
      (index) {
        final feld = felder[index];
        final feldType = feld["type"];
        return TextField(
          enabled: index < felderLength - 2,
          textInputAction: TextInputAction.next,
          controller: controllers[index],
          focusNode: focusNodes[index],
          decoration: InputDecoration(
            labelText: feld["hint_text"],
            helperText: feld['helper_text'],
          ),
          onSubmitted: (text) {
            final l = fixText(text, feld);
            controllers[index].text = l[0];
            // print("onsubmitted $text");

            final locDataNL = Provider.of<LocData>(context, listen: false);
            final markersNL = Provider.of<Markers>(context, listen: false);
            final settingsNL = Provider.of<Settings>(context, listen: false);
            final nickName = settingsNL.getConfigValueS("nickname");

            locDataNL.setFeld(
                markersNL, feld['name'], feldType, l[1], nickName);
            int x1 = (index + 1) % felderLength;
            if (controllers[x1].text == "") {
              FocusScope.of(context).requestFocus(focusNodes[x1]);
            } else {
              // FocusScope.of(context).requestFocus(focusNodes[index]);
              FocusScope.of(context)
                  .unfocus(disposition: UnfocusDisposition.scope);
            }
          },
          keyboardType: feldType == "int" || feldType == "prozent"
              ? TextInputType.number
              : TextInputType.text,
        );
      },
    );
    for (int i = 0; i < felderLength; i++) {
      focusNodes[i].addListener(focusHandlers[i]);
    }
    print("2initFelder");
  }

  void setFelder(LocData locDaten, BaseConfig baseConfig, bool useZusatz) {
    print("1setFelder");
    List felder =
        useZusatz ? baseConfig.getZusatzFelder() : baseConfig.getDatenFelder();
    int felderLength = felder.length;
    for (int i = 0; i < felderLength; i++) {
      final feld = felder[i];
      controllers[i].text = locDaten.getFeldText(feld['name'], feld["type"]);
    }
    print("2setFelder");
  }

  void deleteFelder() {
    if (focusNodes == null) return;
    print("deleteFelder");
    for (var i = 0; i < focusNodes.length; i++) {
      focusNodes[i].removeListener(focusHandlers[i]);
      // focusNodes[i].dispose();
      // controllers[i].dispose();
    }
    focusNodes = null;
    controllers = null;
    focusHandlers = null;
    textFields = null;
  }

  List yes(String text) {
    text = text.toLowerCase();
    if (text == "") return ["", null];
    if (text == "1" || text[0] == "y" || text[0] == "j") return ["ja", 1];
    return ["nein", 0];
  }

  List limit(String text, Map<String, dynamic> feld) {
    text = text.toLowerCase();
    if (text == "") return ["", null];
    final limits = feld["limited"];
    for (final l in limits) {
      if (text[0] == l[0].toLowerCase()) return [l, l];
    }
    return ["", null];
  }

  List fixText(String text, Map<String, dynamic> feld) {
    text = text.trim();
    String feldType = feld["type"];
    try {
      if (feldType == "bool") return yes(text);
      if (feldType == "int" || feldType == "prozent") {
        int v = int.parse(text);
        if (feldType == "int") return [text, v];
        if (v < 0 || v > 100) return ["", null];
        return [text, v];
      }
      if (feld["limited"] != null) return limit(text, feld);
      return [text, text == "" ? null : text];
    } catch (e) {
      return ["", null];
    }
  }
}
