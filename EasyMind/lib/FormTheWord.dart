import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';

class AppleWordGame extends StatelessWidget {
  final String nickname;
  const AppleWordGame({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return WordGameScreen(nickname: nickname);
  }
}

class WordGameScreen extends StatefulWidget {
  final String nickname;
  const WordGameScreen({super.key, required this.nickname});

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  bool isFlashing = true;
  int flashDuration = 8;
  
  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  String _currentDifficulty = 'beginner';
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  int _score = 0;

  final List<Map<String, dynamic>> wordData = [
    {
      'word': 'APPLE',
      'image': 'assets/apt.jpg',
      'jumbled': ['P', 'A', 'P', 'E', 'L'],
      'tts': 'Apple',
      'pronunciation': 'AP-uhl',
    },
    {
      'word': 'BALL',
      'image': 'assets/pic1.jpg',
      'jumbled': ['B', 'L', 'L', 'A'],
      'tts': 'Ball',
      'pronunciation': 'BAWL',
    },
    {
      'word': 'CAT',
      'image': 'assets/pic4.jpg',
      'jumbled': ['A', 'C', 'T'],
      'tts': 'Cat',
      'pronunciation': 'KAT',
    },
    {
      'word': 'COW',
      'image': 'assets/pic2.jpg',
      'jumbled': ['O', 'W', 'C'],
      'tts': 'Cow',
      'pronunciation': 'KOW',
    },
    {
      'word': 'MANGO',
      'image': 'assets/pic3.jpg',
      'jumbled': ['M', 'O', 'A', 'G', 'N'],
      'tts': 'Mango',
      'pronunciation': 'MANG-goh',
    },
  ];

  int currentWordIndex = 0;
  List<String> selectedLetters = [];
  List<int> selectedIndices = [];
  List<bool> isLetterUsed = [];
  List<bool> isLetterSticky = [];
  bool isCorrect = false;
  bool isIncorrect = false;
  int correctAnswers = 0;
  int incorrectAnswers = 0;
  List<Map<String, dynamic>> answerSummary = [];

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  String get correctWord => wordData[currentWordIndex]['word'];
  String get wordImage => wordData[currentWordIndex]['image'];
  List<String> get jumbledLetters => wordData[currentWordIndex]['jumbled'];
  String get ttsWord => wordData[currentWordIndex]['tts'];
  String get pronunciation => wordData[currentWordIndex]['pronunciation'];

  @override
  void initState() {
    super.initState();
    isLetterUsed = List.filled(jumbledLetters.length, false);
    isLetterSticky = List.filled(correctWord.length, false);
    _startFlash();
    _initializeAdaptiveMode();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  void _startFlash() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(ttsWord);
    setState(() {
      isFlashing = true;
    });
    await Future.delayed(Duration(seconds: flashDuration));
    setState(() {
      isFlashing = false;
    });
  }

  void speakWord() async {
    await flutterTts.stop();
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(ttsWord);
  }

  void onLetterTap(String letter, int index) {
    if (selectedLetters.length < correctWord.length &&
        !isLetterUsed[index] &&
        !isFlashing) {
      setState(() {
        selectedLetters.add(letter);
        selectedIndices.add(index);
        isLetterUsed[index] = true;
        if (selectedLetters.length <= correctWord.length &&
            letter == correctWord[selectedLetters.length - 1]) {
          isLetterSticky[selectedLetters.length - 1] = true;
        }
      });

      if (selectedLetters.length == correctWord.length) {
        String formedWord = selectedLetters.join('');
        answerSummary.add({
          'word': correctWord,
          'userAnswer': formedWord,
          'isCorrect': formedWord == correctWord,
        });

        if (formedWord == correctWord) {
          flutterTts.speak("Correct!");
          setState(() {
            isCorrect = true;
            isIncorrect = false;
            correctAnswers++;
          });
          Future.delayed(const Duration(seconds: 1), _startNextFlash);
        } else {
          setState(() {
            isCorrect = false;
            isIncorrect = true;
            incorrectAnswers++;
          });

          _shakeController.forward(from: 0);

          Future.delayed(const Duration(milliseconds: 700), () {
            setState(() {
              List<String> newSelectedLetters = [];
              List<int> newSelectedIndices = [];
              for (int i = 0; i < selectedLetters.length; i++) {
                if (!isLetterSticky[i]) {
                  isLetterUsed[selectedIndices[i]] = false;
                } else {
                  newSelectedLetters.add(selectedLetters[i]);
                  newSelectedIndices.add(selectedIndices[i]);
                }
              }
              selectedLetters = newSelectedLetters;
              selectedIndices = newSelectedIndices;
              isIncorrect = false;
            });
          });
        }
      }
    }
  }

  void onSelectedLetterTap(int index) {
    if (index < selectedLetters.length &&
        !isFlashing &&
        !isLetterSticky[index]) {
      setState(() {
        int jumbledIndex = selectedIndices[index];
        isLetterUsed[jumbledIndex] = false;
        selectedLetters.removeAt(index);
        selectedIndices.removeAt(index);
        isCorrect = false;
        isIncorrect = false;
      });
    }
  }

  void _startNextFlash() async {
    await Future.delayed(const Duration(seconds: 2));
    if (currentWordIndex < wordData.length - 1) {
      String formedWord = selectedLetters.join('');
      if (formedWord == correctWord) {
        setState(() {
          currentWordIndex++;
          _score++; // Increment score for correct word
          selectedLetters.clear();
          selectedIndices.clear();
          isLetterUsed = List.filled(
            wordData[currentWordIndex]['jumbled'].length,
            false,
          );
          isLetterSticky = List.filled(
            wordData[currentWordIndex]['word'].length,
            false,
          );
          isCorrect = false;
          isIncorrect = false;
        });
        await flutterTts.speak(ttsWord);
        setState(() {
          isFlashing = true;
        });
        await Future.delayed(Duration(seconds: flashDuration));
        setState(() {
          isFlashing = false;
        });
      }
    } else if (currentWordIndex == wordData.length - 1) {
      String formedWord = selectedLetters.join('');
      if (formedWord == correctWord) {
        _score++; // Increment score for final word
        flutterTts.speak("You finished the game!");
        
        // Save to adaptive assessment and memory retention
        _saveToAdaptiveAssessment();
        _saveToMemoryRetention();
        
        showScoreDialog();
      }
    }
  }

  void showScoreDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFBEED9),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.06),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.8,
                maxWidth: screenWidth * 0.9,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up,
                      size: screenWidth * 0.12,
                      color: const Color(0xFF4A6C82),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      "Score",
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF22223B),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Text(
                      "$correctAnswers",
                      style: TextStyle(
                        fontSize: screenWidth * 0.1,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      "Answer Summary",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: answerSummary.length,
                      itemBuilder: (_, index) {
                        final item = answerSummary[index];
                        final isCorrect = item['isCorrect'];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green[50] : Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Word: ${item['word']}",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                Text(
                                  "Your Answer: ${item['userAnswer']}",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    color: isCorrect ? Colors.green : Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (!isCorrect)
                                  Text(
                                    "Correct Answer: ${item['word']}",
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.045,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    if (incorrectAnswers == 0 && correctAnswers == wordData.length)
                      Column(
                        children: [
                          Text(
                            "Congratulations! Perfect Game!",
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (index) => Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: screenWidth * 0.08,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "Congratulations on completing the game!",
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                currentWordIndex = 0;
                                correctAnswers = 0;
                                incorrectAnswers = 0;
                                answerSummary.clear();
                                selectedLetters.clear();
                                selectedIndices.clear();
                                isLetterUsed = List.filled(
                                  wordData[currentWordIndex]['jumbled'].length,
                                  false,
                                );
                                isLetterSticky = List.filled(
                                  wordData[currentWordIndex]['word'].length,
                                  false,
                                );
                                isCorrect = false;
                                isIncorrect = false;
                              });
                              Navigator.of(context).pop();
                              _startFlash();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DB2FF),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.022,
                                horizontal: screenWidth * 0.05,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.replay, size: screenWidth * 0.06),
                                SizedBox(width: screenWidth * 0.02),
                                Text("Retry"),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              try {
                                flutterTts.stop();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              } catch (e) {
                                print('Error navigating back: $e');
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF648BA2),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.022,
                                horizontal: screenWidth * 0.05,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: TextStyle(
                                fontSize: screenWidth * 0.05,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Text("Back to Games"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBD8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: screenHeight * 0.08,
                  width: screenWidth * 0.4,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        flutterTts.stop();
                        Navigator.pop(context);
                      } catch (e) {
                        print('Error navigating back: $e');
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              if (!isFlashing) SizedBox(height: screenHeight * 0.02),
              if (!isFlashing)
                Text(
                  "Form The Word",
                  style: TextStyle(
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A6C82),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!isFlashing) SizedBox(height: screenHeight * 0.02),
              SizedBox(
                height: screenHeight * 0.8,
                child: Center(
                  child: isFlashing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              correctWord,
                              style: TextStyle(
                                fontSize: screenWidth * 0.15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A6C82),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    pronunciation,
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.06,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF4A6C82),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                GestureDetector(
                                  onTap: speakWord,
                                  child: Container(
                                    padding: EdgeInsets.all(screenWidth * 0.03),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF648BA2),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: const Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.volume_up_rounded,
                                      size: screenWidth * 0.08,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                Container(
                                  width: screenWidth * 0.4,
                                  height: screenWidth * 0.4,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.asset(
                                      wordImage,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: GestureDetector(
                                    onTap: speakWord,
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF648BA2),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.volume_up_rounded,
                                        size: screenWidth * 0.08,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            AnimatedBuilder(
                              animation: _shakeController,
                              builder: (context, child) {
                                final offset = _shakeAnimation.value;
                                return Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: screenWidth * 0.02,
                                  children: List.generate(
                                    correctWord.length,
                                    (index) {
                                      return Transform.translate(
                                        offset: Offset(
                                          isIncorrect &&
                                                  !isLetterSticky[index]
                                              ? sin(index + offset) * 4
                                              : 0,
                                          0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => onSelectedLetterTap(index),
                                          child: Container(
                                            width: screenWidth * 0.15,
                                            height: screenWidth * 0.15,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.01,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                              color: isLetterSticky[index]
                                                  ? Colors.green[100]
                                                  : isIncorrect &&
                                                          selectedLetters.length > index
                                                      ? Colors.red
                                                      : const Color(0xFFE7F0F9),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              index < selectedLetters.length
                                                  ? selectedLetters[index]
                                                  : '',
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.06,
                                                fontWeight: FontWeight.bold,
                                                color: index < selectedLetters.length
                                                    ? const Color(0xFF4A6C82)
                                                    : Colors.grey.withOpacity(0.4),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            Wrap(
                              spacing: screenWidth * 0.03,
                              runSpacing: screenWidth * 0.03,
                              alignment: WrapAlignment.center,
                              children: List.generate(jumbledLetters.length, (index) {
                                return GestureDetector(
                                  onTap: () => onLetterTap(jumbledLetters[index], index),
                                  child: Opacity(
                                    opacity: isLetterUsed[index] ? 0.3 : 1.0,
                                    child: Container(
                                      width: screenWidth * 0.15,
                                      height: screenWidth * 0.15,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A6C82),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        jumbledLetters[index],
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.06,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: screenHeight * 0.03),
                            if (isCorrect)
                              Text(
                                "Great Job!",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  // Adaptive Assessment Methods
  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await _gamificationSystem.initialize();
        _currentDifficulty = await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.alphabet.value,
        );
        setState(() {});
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  Future<void> _saveToAdaptiveAssessment() async {
    if (!_useAdaptiveMode) return;
    
    try {
      // Calculate performance based on score
      final performance = _score / wordData.length;
      final totalQuestions = wordData.length;
      final correctAnswers = _score;
      
      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: AssessmentType.alphabet.value,
        moduleName: "Word Formation Game",
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        timeSpent: const Duration(minutes: 5),
        attemptedQuestions: wordData.map((w) => w['word'] as String).toList(),
        correctQuestions: wordData.take(_score).map((w) => w['word'] as String).toList(),
      );
      
      // Award XP based on performance
      final isPerfect = _score == wordData.length;
      final isGood = _score >= wordData.length * 0.7;
      
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isPerfect ? 'perfect_word_formation' : (isGood ? 'good_word_formation' : 'word_formation_practice'),
        metadata: {
          'module': 'formTheWord',
          'score': _score,
          'total': wordData.length,
          'perfect': isPerfect,
        },
      );
      
      print('Adaptive assessment saved for FormTheWord game');
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Word Formation",
        lessonType: "FormTheWord Game",
        score: _score,
        totalQuestions: wordData.length,
        passed: _score >= wordData.length * 0.7,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
