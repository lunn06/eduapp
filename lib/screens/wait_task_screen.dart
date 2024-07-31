import 'package:flutter/material.dart';
import 'package:eduapp/models/child.model.dart';
import 'package:eduapp/screens/start_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart';



class WaitForTheTask extends StatefulWidget {
  const WaitForTheTask({Key? key, required this.child}) : super(key: key);

  final Child child;

  @override
  State<WaitForTheTask> createState() => _WaitForTheTaskState();
}

class _WaitForTheTaskState extends State<WaitForTheTask> {
  List _taskScreens = [];
  late int _currentText;

  void initState(){
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readTaskData();
    });
  }

  Future<void> readTaskData() async {
    final String response = await rootBundle.loadString('assets/quizes/russia/data.json');
    final data = await jsonDecode(response);

    setState(() {
      _taskScreens = data['data'];
    });
  }

  void startScreen(int taskNum) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StartScreen(taskNum: taskNum)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            title: const Text(
              'Выберите тему',
              style: TextStyle(fontStyle: FontStyle.italic ),
            ),
          backgroundColor: Colors.amber,

        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => startScreen(0),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
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
                            "Путешествие по России",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26.0,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 10), //Отступ между текстом и картинкой
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}
