import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:playgemini/settingpage.dart';

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldState = useRef("");
    final resultsw = useState(false);
    final loadingsw = useState<bool>(false);
    final percentdata = useState<String>("");
    final editcontroller = useTextEditingController();
    final picker = ImagePicker();
    final image = useState<File?>(null);
    final aiEssaystext = useState<String>("");
    final aiSuggestedtext = useState<String>("");

    createmodel() {
      debugPrint("モデル作成");
      String apiKey = "AIzaSyCCNA6dVfOOna2aQeV7yAmBS7eWbUkpnK4";
      return GenerativeModel(model: "gemini-pro-vision", apiKey: apiKey);
    }

    final model = useMemoized(() => createmodel(), []);

    void getImageFromCamera() async {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        image.value = File(pickedFile.path);
      }
    }

    void getImageFromGallery() async {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        image.value = File(pickedFile.path);
      }
    }

    void valuereset() {
      resultsw.value = false;
      percentdata.value = "";
      aiEssaystext.value = "";
      aiSuggestedtext.value = "";
    }

    void statechange() {
      if (oldState.value == "") {
        debugPrint("保存");
        var newState = image.value.toString();
        oldState.value = newState;
      } else {
        if (oldState.value == image.value.toString()) {
          resultsw.value = true;
        } else {
          resultsw.value = false;
          editcontroller.text = "";
          valuereset();
        }
      }
    }

    useValueChanged(image.value, (oldValue, oldResult) => statechange());

    void essaysdata(File imagedata, String text) async {
      debugPrint("送信");
      final image = await imagedata.readAsBytes();
      final prompt = TextPart("この$textの評価をしてください。点数はつけないでください。");
      final imageParts = DataPart('image/jpeg', image);
      final response = await model.generateContent([
        Content.multi([prompt, imageParts])
      ]);
      debugPrint(response.text);
      aiEssaystext.value = response.text!;
    }

    void suggesteddata(File imagedata, String text) async {
      debugPrint("送信");
      final image = await imagedata.readAsBytes();
      final prompt = TextPart("この$textをもっとおいしそうに見せるにはどこを改善したらよいですか？");
      final imageParts = DataPart('image/jpeg', image);
      final response = await model.generateContent([
        Content.multi([prompt, imageParts])
      ]);
      debugPrint(response.text);
      aiSuggestedtext.value = response.text!;
    }

    void gettruedata(File imagedata, String text) async {
      valuereset();
      essaysdata(imagedata, text);
      suggesteddata(imagedata, text);
      loadingsw.value = true;
      debugPrint("送信");
      final image = await imagedata.readAsBytes();
      final prompt = TextPart(
          "これは$textです。見た目は何点ですか？100点満点で点数だけ答えてください。食べられるもの以外は０％と答えてください");
      final imageParts = DataPart('image/jpeg', image);
      final response = await model.generateContent([
        Content.multi([prompt, imageParts])
      ]);
      debugPrint(response.text);
      loadingsw.value = false;
      percentdata.value = response.text!.replaceAll(RegExp(r"[^0-9]"), "");
      debugPrint(percentdata.value);
      resultsw.value = true;
    }

    const selectedValue = "メイン";
    const usStates = ["メイン", "設定", "広告off"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("評価画面"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          PopupMenuButton<String>(
            initialValue: selectedValue,
            onSelected: (String s) {
              if (s == "設定") {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (build) => const SettingsPage()));
              } else if (s == "広告off") {
                //             Navigator.push(
                // context,
                // MaterialPageRoute(
                //     builder: (build) => ));
              }
            },
            itemBuilder: (BuildContext context) {
              return usStates.map((String s) {
                return PopupMenuItem(
                  value: s,
                  child: Text(s),
                );
              }).toList();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
          child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          image.value == null
              ? const Text(
                  "料理の写真を選択してね",
                  style: TextStyle(fontSize: 30),
                )
              : SizedBox(
                  height: 200,
                  child: Image.file(
                    image.value!,
                    fit: BoxFit.contain,
                  )),
          loadingsw.value
              ? const Padding(
                  padding: EdgeInsets.all(5),
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ))
              : percentdata.value.isEmpty
                  ? const SizedBox()
                  : Text(
                      "${percentdata.value}点",
                      style: const TextStyle(fontSize: 60),
                    ),
          if (resultsw.value == true)
            ExpansionTile(
              title: const Text(
                '評価',
                style: TextStyle(fontSize: 30),
              ),
              children: <Widget>[
                aiEssaystext.value.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ))
                    : Text(
                        aiEssaystext.value,
                        style: const TextStyle(fontSize: 20),
                      )
              ],
            ),
          if (resultsw.value == true)
            ExpansionTile(
              title: const Text(
                '改善案',
                style: TextStyle(fontSize: 30),
              ),
              children: <Widget>[
                aiSuggestedtext.value.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          color: Colors.green,
                        ))
                    : Text(
                        aiSuggestedtext.value,
                        style: const TextStyle(fontSize: 20),
                      )
              ],
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 100,
            ),
          )
        ],
      ))),
      bottomSheet: Container(
        width: MediaQuery.of(context).size.width,
        height: 100,
        color: Colors.blue,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                    child: TextFormField(
                      controller: editcontroller,
                      decoration: const InputDecoration(
                          hintText: "料理名", hintStyle: TextStyle(fontSize: 30)),
                      onChanged: (data) {
                        valuereset();
                      },
                    ))),
            IconButton(
              onPressed: () {
                getImageFromCamera();
              },
              icon: const Icon(Icons.photo_camera),
              iconSize: 40,
            ),
            IconButton(
              onPressed: () {
                getImageFromGallery();
              },
              icon: const Icon(Icons.photo_album),
              iconSize: 40,
            ),
            IconButton(
              onPressed: loadingsw.value == true
                  ? null
                  : () {
                      try {
                        if (image.value == null) {
                          debugPrint("画像がない");
                          throw ("画像を選択してください");
                        } else if (editcontroller.text.isEmpty == true) {
                          debugPrint("料理名がない");
                          throw ("料理名を入力してください");
                        }
                        gettruedata(image.value!, editcontroller.text);
                      } catch (e) {
                        Fluttertoast.showToast(
                          msg: e.toString(),
                          fontSize: 18,
                        );
                      }
                    },
              icon: const Icon(Icons.send),
              iconSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}
