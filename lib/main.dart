import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Trivia Quiz', home: QuizScreen());
  }
}

class QuizScreen extends StatefulWidget {
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List _questions = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _answered = false;
  String _correctAnswer = '';
  String? _selectedAnswer;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  void _fetchQuestions() async {
    const url =
        'https://opentdb.com/api.php?amount=10&type=multiple&difficulty=easy&category=9';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _questions = data['results'];
        _loading = false;
        _correctAnswer = _questions[_currentIndex]['correct_answer'];
      });
    } else {
      print('Failed to load questions');
    }
  }

  List<String> _getShuffledAnswers(Map question) {
    final answers = List<String>.from(question['incorrect_answers']);
    answers.add(question['correct_answer']);
    answers.shuffle(Random());
    return answers;
  }

  void _selectAnswer(String answer) {
    if (_answered) return;

    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _questions.length) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _selectedAnswer = null;
        _correctAnswer = _questions[_currentIndex]['correct_answer'];
      });
    } else {
      _showFinishDialog();
    }
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Quiz Finished"),
            content: const Text("You reached the end!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentIndex = 0;
                    _answered = false;
                    _selectedAnswer = null;
                  });
                },
                child: const Text("Restart"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final question = _questions[_currentIndex];
    final answers = _getShuffledAnswers(question);

    return Scaffold(
      appBar: AppBar(title: const Text('Trivia Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${_currentIndex + 1} of ${_questions.length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _decodeHtml(question['question']),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ...answers.map((answer) {
              Color? color;
              if (_answered) {
                if (answer == _correctAnswer) {
                  color = Colors.green;
                } else if (answer == _selectedAnswer) {
                  color = Colors.red;
                }
              }

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  onPressed: () => _selectAnswer(answer),
                  child: Text(_decodeHtml(answer)),
                ),
              );
            }),
            const SizedBox(height: 20),
            if (_answered)
              Center(
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: const Text("Next Question"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _decodeHtml(String input) {
    return input.replaceAll('&quot;', '"').replaceAll('&#039;', "'");
  }
}
