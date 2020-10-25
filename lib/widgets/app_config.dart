import 'package:flutter/material.dart';
import 'package:locations/providers/settings.dart';
import 'package:provider/provider.dart';

class AppConfig extends StatelessWidget {
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
              itemCount: settingsJS.length + 1,
              itemBuilder: (ctx, index) {
                if (index == settingsJS.length) {
                  return SizedBox(height: 200);
                }
                final settingJS = settingsJS[index];
                final controller = controllers[index];
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
                ); // textFields[index];
              },
            ),
          );
        }),
      ],
    ));
  }
}
