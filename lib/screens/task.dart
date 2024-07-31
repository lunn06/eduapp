import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Task extends StatefulWidget {
  final int taskNum;
  const Task({super.key, required this.taskNum});

  @override
  State<Task> createState() => _TaskState();
}

class _TaskState extends State<Task> {
  late List _taskScreens;
  final List<List<String>> _answers = [
    ['startDatetime', 'answerDatetime', 'task', 'question', 'answer', 'rightAnswer']
  ];
  DateTime _startTime = DateTime.now();

  int _currentScreen = 0;
  bool _completed = false;
  bool _showImage = false;
  String _imageSource = '';
  String _screenText = '';
  List _options = [];
  bool _showVariants = false;
  bool _right = false;
  int? _highlightedAnswer;
  final playerText = AudioPlayer();
  final playerQuestion = AudioPlayer();
  final playerAnswer = AudioPlayer();
  final playerRegion = AudioPlayer();

  Offset _textPosition = Offset(500, 50);
  Offset _imagePosition = Offset(500, 50);
  Offset _buttonPosition = Offset(50, 350);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await readTaskData();
      await playCurrentScreen();
    });
  }

  Future<void> readTaskData() async {
    try {
      final String response = await rootBundle.loadString('assets/quizes/russia/data.json');
      final data = await jsonDecode(response);

      setState(() {
        _taskScreens = data['data'][widget.taskNum]['screens'];
      });
    } catch (e) {
      print('Error loading task data: $e');
    }
  }

  Future<void> playCurrentScreen() async {
    if (_currentScreen < 0 || _currentScreen >= _taskScreens.length) {
      setState(() {
        _completed = true;
      });
      // await saveResults();
      return;
    }

    final currentScreen = _taskScreens[_currentScreen];
    final screenType = currentScreen['type'];

    if (screenType == 'story') {
      await _playStory(currentScreen);
    } else if (screenType == 'choose') {
      _showChooseScreen(currentScreen);
    } else if (screenType == 'question') {
      await _playQuestion(currentScreen);
    } else {
      print('Unknown screen type: $screenType');
    }
  }

  Future<void> _playStory(Map<String, dynamic> currentScreen) async {
    setState(() {
      _showImage = currentScreen.containsKey('imageSource') && currentScreen['imageSource'].isNotEmpty;
      _imageSource = _showImage ? currentScreen['imageSource'] : '';
      _screenText = currentScreen['screenText'] ?? '';
    });

    try {
      await playerText.play(AssetSource(currentScreen['screenTextSource']));
    } catch (e) {
      print('Error playing story audio: $e');
    }

    playerText.onPlayerComplete.listen((_) async {
      if (mounted) {
        setState(() {
          _currentScreen++;
        });
        await playCurrentScreen();
      }
    });
  }

  void _showChooseScreen(Map<String, dynamic> currentScreen) {
    setState(() {
      _showImage = false;
      _imageSource = '';
      _screenText = currentScreen['screenText'] ?? '';
      _options = currentScreen['options'] ?? [];
      _showVariants = false;
    });
  }

  Future<void> _playQuestion(Map<String, dynamic> currentScreen) async {
    setState(() {
      _showImage = currentScreen.containsKey('imageSource') && currentScreen['imageSource'].isNotEmpty;
      _imageSource = _showImage ? currentScreen['imageSource'] : '';
      _screenText = currentScreen['screenText'] ?? '';
      _showVariants = false;
    });

    try {
      await playerText.play(AssetSource(currentScreen['screenTextSource']));
    } catch (e) {
      print('Error playing question text audio: $e');
    }

    playerText.onPlayerComplete.listen((_) async {
      try {
        await playerQuestion.play(AssetSource(currentScreen['questionSource']));
      } catch (e) {
        print('Error playing question audio: $e');
      }
    });

    playerQuestion.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _showVariants = true;
          _startTime = DateTime.now();
        });
      }
    });
  }

  // Future<void> saveResults() async {
  //   try {
  //     final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(_answers);
  //     final date = DateFormat('dd-MM-yyyy hh-mm-ss').format(DateTime.now());
  //     final path = '/storage/emulated/0/Download/$date-results.csv';
  //     final file = await File(path).create();
  //     await file.writeAsString(csv);
  //   } catch (e) {
  //     print('Error saving results: $e');
  //   }
  // }

  void playRegionAudio(String audioSource) async {
    try {
      await playerRegion.play(AssetSource(audioSource));
    } catch (e) {
      print('Error playing region audio: $e');
    }

    playerRegion.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _showImage = false;
          _imageSource = '';
          _screenText = _taskScreens[_currentScreen]['screenText'] ?? '';
        });
      }
    });
  }

  Future<void> nextScreen() async {
    if (_currentScreen < _taskScreens.length - 1) {
      setState(() {
        _currentScreen++;
      });
      await playCurrentScreen();
    } else {
      setState(() {
        _completed = true;
      });
      // Обработка завершения задания, например, показать сообщение о завершении
    }
  }

  void _repeatQuestion() async {
    setState(() {
      _showVariants = false;
      _right = false;
      _highlightedAnswer = null;
    });

    try {
      await playerQuestion.play(AssetSource(_taskScreens[_currentScreen]['questionSource']));
    } catch (e) {
      print('Error repeating question audio: $e');
    }
  }

  void _checkAnswer(int answerIndex) {
    final currentScreen = _taskScreens[_currentScreen];
    if (answerIndex >= currentScreen['answers'].length) {
      print('Invalid answer index');
      return;
    }

    final answer = currentScreen['answers'][answerIndex];
    final rightAnswer = currentScreen['rightAnswer'];
    final taskText = currentScreen['taskText'];
    final questionText = currentScreen['questionText'];

    setState(() {
      _highlightedAnswer = answerIndex;
      _answers.add([
        _startTime.toString(),
        DateTime.now().toString(),
        taskText,
        questionText,
        answer.toString(),
        rightAnswer.toString()
      ]);
    });

    if (answer == rightAnswer) {
      setState(() {
        _right = true;
      });
      try {
        playerAnswer.play(AssetSource(currentScreen['rightAnswerSource']));
      } catch (e) {
        print('Error playing right answer audio: $e');
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedAnswer = null;
          });
          nextScreen();
        }
      });
    } else {
      setState(() {
        _right = false;
      });
    }
  }

  List<Widget> _buildAnswerButtons() {
    final currentScreen = _taskScreens[_currentScreen];
    final answers = currentScreen['answers'] ?? [];
    return List<Widget>.generate(
      answers.length,
          (i) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: OutlinedButton(
          onPressed: () => _checkAnswer(i),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.blue,
            side: BorderSide(
              color: _highlightedAnswer == i
                  ? (_right ? Colors.green : Colors.red)
                  : Colors.blue,
              width: 2.0,
            ),
          ),
          child: Text(
            answers[i],
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionButtons() {
    final buttons = <Widget>[];
    for (int i = 0; i < _options.length; i++) {
      buttons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
          child: ElevatedButton(
            onPressed: () {
              final option = _options[i];
              playRegionAudio(option['audioSource']);
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.blue,
            ),
            child: Text(
              _options[i]['region'],
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return Scaffold(
        appBar: AppBar(title: Text('Task ${widget.taskNum + 1}')),
        body: Center(
          child: Text(
            'Task Completed!',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      );
    }

    if (_currentScreen < 0 || _currentScreen >= _taskScreens.length) {
      return Scaffold(
        appBar: AppBar(title: Text('Task ${widget.taskNum + 1}')),
        body: Center(
          child: Text(
            'Invalid screen index: $_currentScreen',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      );
    }

    final currentScreen = _taskScreens[_currentScreen];
    final screenType = currentScreen['type'];

    return Scaffold(
      appBar: AppBar(title: Text('Task ${widget.taskNum + 1}')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/quizes/russia/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Stack(
            children: [
              if (_showImage)
                Positioned(
                  left: _imagePosition.dx,
                  top: _imagePosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _imagePosition += details.delta;
                      });
                    },
                    child: Image.asset(_imageSource, height: 450),
                  ),
                ),
              if (screenType == 'choose')
                Positioned(
                  left: _buttonPosition.dx,
                  top: _buttonPosition.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        _buttonPosition += details.delta;
                      });
                    },
                    child: ElevatedButton(
                      onPressed: nextScreen,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Далее',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_showVariants && screenType == 'question')
            Positioned(
              left: 50,
              top: 400,
              child: Column(
                children: _buildAnswerButtons(),
              ),
            ),
          if (screenType == 'choose')
            Positioned(
              left: 50,
              top: 500,
              child: Column(
                children: _buildOptionButtons(),
              ),
            ),
        ],
      ),
    );
  }
}
