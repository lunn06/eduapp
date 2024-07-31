import 'package:flutter/material.dart';
import 'package:eduapp/models/child.model.dart';
import 'package:eduapp/screens/task.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:flutter/services.dart';



class StartScreen extends StatefulWidget {
  final int taskNum;
  const StartScreen({super.key, required this.taskNum});


  @override
  State<StartScreen> createState() => _StartScreenState(taskNum: taskNum);
}

class _StartScreenState extends State<StartScreen> {
  late final int taskNum;

  _StartScreenState({required this.taskNum});
  List _startData = [];

  final playerText = AudioPlayer();

  Future<void> readStartData() async {
    final String response = await rootBundle.loadString('assets/quizes/russia/data.json');
    final data = await jsonDecode(response);

    setState(() {
      _startData = data['data'];
    });
  }

  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readStartData();
      await playerText.play(AssetSource("quizes/russia/audio/1.mp3"));
    });
  }

  void startTask(int taskNum) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Task(taskNum: taskNum)),
      // MaterialPageRoute(builder: (context) => Task(taskNum: taskNum)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Россия',
            style: TextStyle(fontStyle: FontStyle.italic ),
          ),
          backgroundColor: Colors.amber,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              playerText.stop();
              Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned(
              left: 30,
              bottom: 0,
              child: Image.asset(
                "assets/quizes/russia/images/cippa1.png",
                width: 400,
              ),
            ),
            Positioned(
              right: 150, // Расположите вторую картинку и кнопку справа
              bottom: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    _startData[0]['startScreen']['imageSource'],
                    width: 500,
                  ),
                  const SizedBox(height: 30), // Отступ между изображением и кнопкой
                  OutlinedButton(
                    onPressed: () {
                      playerText.stop();
                      startTask(taskNum);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.blue,
                      side: const BorderSide(
                        color: Colors.black12,
                        width: 6,
                      ),
                      fixedSize: const Size(300, 180),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 36.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Начать",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26.0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10), // Отступ между текстом и картинкой
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
