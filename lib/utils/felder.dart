import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:locations/providers/base_config.dart';
import 'package:locations/providers/loc_data.dart';

class Felder {
  List<FocusNode> focusNodes;
  List<void Function()> focusHandlers;
  List<TextField> textFields;
  List<TextEditingController> controllers;

  void initFelder(BuildContext context, LocData locData, bool useZusatz) {
    print("1initFel");
    List felder = useZusatz ? BaseConfig.zusatzFelder : BaseConfig.datenFelder;
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
          print("focus $index ${fn.hasFocus}");
          if (!fn.hasFocus) {
            final l = fixText(controllers[index].text, felder[index]);
            print("Text $l");
            controllers[index].text = l[0];
            // can call Provider here because cb is called in other context
            Provider.of<LocData>(context, listen: false)
                .setFeld(felder[index]['name'], felder[index]["type"], l[1]);
          }
        }

        return cb;
      },
    );
    controllers = List.generate(
      felderLength,
      (index) {
        final feld = felder[index];
        return TextEditingController(
          text: locData.getFeldText(feld['name'], feld["type"]),
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
            print("onsubmitted $text");
            Provider.of<LocData>(context, listen: false)
                .setFeld(feld['name'], feldType, l[1]);
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
    print("2initFel");
  }

  void setFelder(LocData locData, bool useZusatz) {
    List felder = useZusatz ? BaseConfig.zusatzFelder : BaseConfig.datenFelder;
    int felderLength = felder.length;
    for (int i = 0; i < felderLength; i++) {
      final feld = felder[i];
      controllers[i].text = locData.getFeldText(feld['name'], feld["type"]);
    }
  }

  void deleteFelder() {
    print("1delfel");
    for (var i = 0; i < focusNodes.length; i++) {
      focusNodes[i].removeListener(focusHandlers[i]);
      // focusNodes[i].dispose();
      // controllers[i].dispose();
    }
    print("2delfel");
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
