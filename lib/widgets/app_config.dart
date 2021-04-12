import 'package:flutter/material.dart';
import 'package:locations/providers/settings.dart';
import 'package:provider/provider.dart';

/// AppConfig implements the drawer of the [KartenScreen] screen.
/// It displays the settings from [Settings].
class AppConfig extends StatefulWidget {
  @override
  _AppConfigState createState() => _AppConfigState();
}

class _AppConfigState extends State<AppConfig> {
  final groupValuesMap = {};

  /// initState sets up the groupvalues for the choice radiobuttons.
  @override
  void initState() {
    super.initState();
    final settingsNL = Provider.of<Settings>(context, listen: false);
    final settingsJS = settingsNL.settingsJS();
    for (final settingJS in settingsJS) {
      if (settingJS["type"] == "choice") {
        String key = settingJS["key"];
        groupValuesMap[key] = settingsNL.getConfigValueS(key);
      }
    }
  }

  /// build displays a TextField for int or string settings, or a Column of
  /// RadioButtons for choice settings. Changing a setting will cause a call of
  /// [Settings.setConfigValue].
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      children: [
        AppBar(
          leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          title: const Text('Einstellungen'),
        ),
        Consumer<Settings>(builder: (ctx, settings, _) {
          final settingsJS = settings.settingsJS();
          final controllers =
              List.generate(settingsJS.length, (_) => TextEditingController());
          final List<FocusNode> focusNodes = List.generate(
            settingsJS.length,
            (_) => FocusNode(),
          );
          List<void Function()> focusHandlers = List.generate(
            settingsJS.length,
            (index) {
              void cb() {
                var fn = focusNodes[index];
                if (!fn.hasFocus) {
                  final text = controllers[index].text.trim();
                  final settingJS = settingsJS[index];
                  settings.setConfigValueS(
                      settingJS["key"], settingJS["type"], text);
                }
              }

              return cb;
            },
          );
          return Expanded(
            child: ListView.builder(
              itemCount: settingsJS.length,
              itemBuilder: (ctx, index1) {
                final settingJS = settingsJS[index1];
                final controller = controllers[index1];
                final focusNode = focusNodes[index1];
                final focusHandler = focusHandlers[index1];
                focusNode.addListener(focusHandler);

                if (settingJS["type"] == "int" ||
                    settingJS["type"] == "string") {
                  controller.text =
                      settings.getConfigValue(settingJS["key"]).toString();
                  return Padding(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: settingJS["title"],
                          helperText: settingJS["desc"],
                        ),
                        keyboardType: settingJS["type"] == "int"
                            ? TextInputType.number
                            : TextInputType.text,
                        onSubmitted: (text) {
                          text = text.trim();
                          settings.setConfigValueS(
                              settingJS["key"], settingJS["type"], text);
                        }),
                  );
                }
                if (settingJS["type"] == "float") {
                  controller.text =
                      settings.getConfigValue(settingJS["key"]).toString();
                  return Padding(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: settingJS["title"],
                          helperText: settingJS["desc"],
                        ),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        onSubmitted: (text) {
                          text = text.trim();
                          settings.setConfigValueF(
                              settingJS["key"], double.parse(text));
                        }),
                  );
                }
                if (settingJS["type"] == "choice") {
                  final choices = settingJS["choices"];
                  final key = settingJS["key"];
                  String groupValue = groupValuesMap[key];
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(),
                          Text(
                            settingJS["title"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            children: List.generate(choices.length, (index2) {
                              return Row(children: [
                                SizedBox(
                                  child: Text(choices[index2]),
                                  width: 120,
                                ),
                                Radio(
                                  groupValue: groupValue,
                                  value: choices[index2],
                                  onChanged: (value) {
                                    settings.setConfigValueS(
                                        key, "string", value);
                                    setState(() => groupValuesMap[key] = value);
                                  },
                                ),
                              ]);
                            }),
                          ),
                        ]),
                  );
                }
                // not reached, hopefully
                return Container();
              },
            ),
          );
        }),
      ],
    ));
  }
}
