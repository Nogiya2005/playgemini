import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const selectedValue = "設定";
    const usStates = ["メイン", "設定", "広告off"];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("設定"),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
              initialValue: selectedValue,
              onSelected: (String s) {
                // Navigator.push(context, MaterialPageRoute(builder: (build)=>))
              },
              itemBuilder: (BuildContext context) {
                return usStates.map((String s) {
                  return PopupMenuItem(
                    value: s,
                    child: Text(s),
                  );
                }).toList();
              })
        ],
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('セクション'),
            tiles: [SettingsTile.navigation(title: const Text('text'))],
          )
        ],
      ),
    );
  }
}
