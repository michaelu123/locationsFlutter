import 'package:flutter/material.dart';
import 'package:locations/providers/settings.dart';
import 'package:provider/provider.dart';

class AppConfig extends StatefulWidget {
  @override
  _AppConfigState createState() => _AppConfigState();
}

class _AppConfigState extends State<AppConfig> {
  final groupValuesMap = {};

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

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Column(
      children: [
        AppBar(
          title: const Text('Einstellungen'),
        ),
        Consumer<Settings>(builder: (ctx, settings, _) {
          final settingsJS = settings.settingsJS();
          final controllers =
              List.generate(settingsJS.length, (_) => TextEditingController());
          return Expanded(
            child: ListView.builder(
              itemCount: settingsJS.length,
              itemBuilder: (ctx, index1) {
                final settingJS = settingsJS[index1];
                final controller = controllers[index1];
                if (settingJS["type"] == "int" ||
                    settingJS["type"] == "string") {
                  controller.text =
                      settings.getConfigValue(settingJS["key"]).toString();
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: settingJS["title"],
                          helperText: settingJS["desc"],
                        ),
                        keyboardType: settingJS["type"] == "int"
                            ? TextInputType.number
                            : TextInputType.text,
                        onSubmitted: (text) {
                          settings.setConfigValueS(
                              settingJS["key"], settingJS["type"], text);
                        }),
                  );
                }
                if (settingJS["type"] == "choice") {
                  final choices = settingJS["choices"];
                  final key = settingJS["key"];
                  String groupValue = groupValuesMap[key];
                  return Column(
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
                      ]);
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
