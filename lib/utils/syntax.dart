Map syntax = {
  "name": {"required": true, "type": "string"},
  "db_name": {"required": true, "type": "string"},
  "db_tabellenname": {"required": true, "type": "string"},
  "spreadsheet_id": {"required": false, "type": "string"},
  "protected": {"required": false, "type": "bool"},
  "gps": {
    "required": true,
    "type": {
      "min_lat": {"required": true, "type": "float"},
      "max_lat": {"required": true, "type": "float"},
      "min_lon": {"required": true, "type": "float"},
      "max_lon": {"required": true, "type": "float"},
      "center_lat": {"required": true, "type": "float"},
      "center_lon": {"required": true, "type": "float"},
      "nachkommastellen": {"required": true, "type": "int"},
      "min_zoom": {"required": true, "type": "int"}
    }
  },
  "daten": {
    "required": true,
    "type": {
      "protected": {"required": false, "type": "bool"},
      "felder": {
        "required": true,
        "type": "array",
        "elem": {
          "name": {"required": true, "type": "string"},
          "hint_text": {"required": true, "type": "string"},
          "helper_text": {"required": true, "type": "string"},
          "type": {
            "required": true,
            "type": "auswahl",
            "auswahl": ["string", "bool", "int", "float", "prozent"]
          },
          "limited": {"required": false, "type": "array", "elem": "string"},
          "required": {"required": false, "type": "bool"},
        }
      }
    }
  },
  "zusatz": {
    "required": false,
    "type": {
      "protected": {"required": false, "type": "bool"},
      "felder": {
        "required": true,
        "type": "array",
        "elem": {
          "name": {"required": true, "type": "string"},
          "hint_text": {"required": true, "type": "string"},
          "helper_text": {"required": true, "type": "string"},
          "type": {
            "required": true,
            "type": "auswahl",
            "auswahl": ["string", "bool", "int", "float", "prozent"]
          },
          "limited": {"required": false, "type": "array", "elem": "string"},
          "required": {"required": false, "type": "bool"},
        }
      }
    }
  }
};

void checkSyntax(Map js) {
  checkSubSyntax(js, syntax);
}

void checkSubSyntax(Map js, Map syn) {
  for (String synkey in syn.keys) {
    bool required = syn[synkey]["required"];
    // print("checksyntax key: $synkey req: $required");
    if (js.keys.contains(synkey)) {
      checkType(synkey, syn[synkey], js[synkey]);
    } else if (required) {
      throw ("$synkey wurde nicht spezifiziert");
    }
  }
}

void checkType(String key, dynamic syn, dynamic js) {
  dynamic syntype = syn["type"];
  // print("checktype key: $key type: $syntype js: $js");
  if (syntype == "string") {
    if (js is! String) {
      throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt String";
    }
  } else if (syntype == "int") {
    if (js is! int) {
      throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt int (d.h. eine ganze Zahl";
    }
  } else if (syntype == "bool") {
    if (js is! bool) {
      throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt bool (d.h. true oder false";
    }
  } else if (syntype == "float") {
    if (js is! double) {
      throw "Das Feld " +
          key +
          " hat den Typ ${js.runtimeType} anstatt float (d.h. eine Gleitkommazahl";
    }
  } else if (syntype == "auswahl") {
    List auswahl = syn["auswahl"];
    if (auswahl != null && !auswahl.contains(js)) {
      throw "$js nicht enthalten in der Auswahl $auswahl";
    }
  } else if (syntype == "array") {
    if (js is! List) {
      throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt eine Liste zu sein";
    } else {
      syn = syn["elem"];
      if (syn is Map) {
        for (dynamic v in js) {
          checkSubSyntax(v, syn);
        }
      } else {
        for (String x in js) {
          checkSimpleType(key, x, syn);
        }
      }
    }
  } else if (syntype is Map) {
    if (js is Map) {
      checkSubSyntax(js, syntype);
    } else {
      throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt zusammengesetzt zu sein";
    }
  } else if (syntype is List) {
    throw "Das Feld $key hat den Typ ${js.runtimeType} anstatt eine Liste zu sein";
  } else {
    // if isinstance(syntype, array):
    throw "!!";
  }
}

void checkSimpleType(String key, dynamic js, String syntype) {
  // print("checksimpletype key:$key type:$syntype js:$js");
  if (syntype == "string") {
    if (js is! String) {
      throw "Der wert $js im Feld $key hat den Typ ${js.runtimeType} anstatt string";
    }
  } else if (syntype == "int") {
    if (js is! int) {
      throw "Der wert $js im Feld $key hat den Typ ${js.runtimeType} anstatt int (d.h. eine ganze Zahl";
    }
  } else if (syntype == "bool") {
    if (js is! bool) {
      throw "Der wert $js im Feld $key hat den Typ ${js.runtimeType} anstatt bool (d.h. true oder false)";
    }
  } else if (syntype == "float") {
    if (js is! double) {
      throw "Der wert $js im Feld $key hat den Typ ${js.runtimeType} anstatt float (d.h. eine Gleitkommazahl)";
    }
  } else {
    throw "Unbekannter Typ $syntype im Feld $key";
  }
}
