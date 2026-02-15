import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'ReadingMaterialsPage.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';

// Removed duplicate main() function - this should only be in main.dart

class ColorAssessment extends StatefulWidget {
  final String nickname;
  
  const ColorAssessment({super.key, required this.nickname});

  @override
  _ColorAssessmentState createState() => _ColorAssessmentState();
}

class _ColorAssessmentState extends State<ColorAssessment>
    with TickerProviderStateMixin {
  int currentIndex = 0;
  int score = 0;
  bool isSpeaking = false;
  bool questionRead = false;
  String? selectedOption;
  bool showAnswerFeedback = false;
  bool _useAdaptiveMode = true;
  bool _showAnswerSummary = false;
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  final FlutterTts flutterTts = FlutterTts();

  // reflection list for summary
  final List<Map<String, String>> reflection = [];

  // shake controller for wrong answers
  late final AnimationController _shakeController;

  // ✅ Tig-3 choices lang bawat question
  final List<Question> questions = [
    Question(
      imagePath: 'assets/shoes.png',
      questionText: 'What is the color of these shoes?',
      options: {
        'Black': Colors.black,
        'Brown': Colors.brown,
        'Red': Colors.redAccent,
      },
      correctAnswer: 'Black',
    ),
    Question(
      imagePath: 'assets/orange.png',
      questionText: 'What is the color of this fruit?',
      options: {
        'Orange': Colors.orange,
        'Green': Colors.green,
        'Brown': Colors.brown,
      },
      correctAnswer: 'Orange',
    ),
    Question(
      imagePath: 'assets/grape.png',
      questionText: 'What is the color of grapes?',
      options: {
        'Purple': Colors.purple,
        'Green': Colors.green,
        'Black': Colors.black,
      },
      correctAnswer: 'Purple',
    ),
    Question(
      imagePath: 'assets/chair.png',
      questionText: 'What is the color of this chair?',
      options: {
        'Brown': Colors.brown,
        'Grey': Colors.grey,
        'Black': Colors.black,
      },
      correctAnswer: 'Brown',
    ),
    Question(
      imagePath: 'assets/board.png',
      questionText: 'What is the color of this board?',
      options: {
        'Green': Colors.green,
        'Orange': Colors.orange,
        'Black': Colors.black,
      },
      correctAnswer: 'Green',
    ),
    Question(
      imagePath: 'assets/flower.png',
      questionText: 'What is the color of this carnation flower?',
      options: {
        'Pink': Colors.pinkAccent,
        'Red': Colors.red,
        'Orange': Colors.orange,
      },
      correctAnswer: 'Pink',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _configureTts();
    _initializeFocusSystem();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    readQuestion();
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.colors.value,
        );
        setState(() {});
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  Future<void> _initializeNLP() async {
    try {
      await IntelligentNLPSystem.initialize();
    } catch (e) {
      print('Error initializing NLP system: $e');
    }
  }

  Future<void> _initializeFocusSystem() async {
    await _focusSystem.initialize();
    await _focusSystem.startFocusSession(
      nickname: widget.nickname,
      moduleName: "Functional Academics",
      lessonType: "Color Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  Future<void> _configureTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.4);
      await flutterTts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  Future<void> readQuestion() async {
    final question = questions[currentIndex];
    setState(() {
      isSpeaking = true;
      questionRead = false;
    });
    await flutterTts.stop();
    await flutterTts.speak(question.questionText);
    setState(() {
      isSpeaking = false;
      questionRead = true;
    });
  }

  Future<void> _speakOption(String option) async {
    await flutterTts.stop();
    await flutterTts.speak(option);
  }

  Future<void> playSoundAndCheck(String selectedColor) async {
    if (!isSpeaking && questionRead) {
      setState(() {
        isSpeaking = true;
        questionRead = false;
        selectedOption = selectedColor;
        showAnswerFeedback = true;
      });

      final currentQuestion = questions[currentIndex];
      final bool isCorrect = selectedColor == currentQuestion.correctAnswer;

      // save to reflection (for summary)
      reflection.add({
        "question": currentQuestion.questionText,
        "userAnswer": selectedColor,
        "correctAnswer": currentQuestion.correctAnswer,
      });

      await flutterTts.speak(selectedColor);
      await Future.delayed(const Duration(milliseconds: 650));

      if (isCorrect) {
        await flutterTts.speak("Correct!");
        score++;
      } else {
        await flutterTts.speak(
            "Wrong! The correct color is ${currentQuestion.correctAnswer}");
        // trigger shake animation
        _shakeController.forward(from: 0.0);
      }

      // wait a bit then go next
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() {
        isSpeaking = false;
        selectedOption = null;
        showAnswerFeedback = false;
      });
      goToNext();
    }
  }

  void goToNext() async {
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        questionRead = false;
      });
      readQuestion();
    } else {
      // Save to memory retention system before showing results
      await _saveToMemoryRetention();
      showResultDialog();
    }
  }

  void resetAssessment() {
    setState(() {
      currentIndex = 0;
      score = 0;
      selectedOption = null;
      questionRead = false;
      reflection.clear();
    });
    readQuestion();
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Colors Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.colors.value,
          moduleName: "Functional Academics",
          totalQuestions: questions.length,
          correctAnswers: score,
          timeSpent: const Duration(minutes: 5), // Placeholder
          attemptedQuestions: questions.map((q) => q.questionText).toList(),
          correctQuestions: reflection
              .where((r) => r['correct'] == 'true')
              .map((r) => r['question']!)
              .toList(),
        );
      }
      
      // Award XP and check for gamification rewards
      final performance = score / questions.length;
      final isPerfect = performance >= 0.9;
      
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isPerfect ? 'perfect_score' : 'assessment_passed',
        metadata: {
          'module': 'colors',
          'score': score,
          'total': questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Color Assessment",
        completed: true,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  void showResultDialog() {
    flutterTts.stop();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final performance = score / questions.length;
    String title, message, emoji;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "WOW! YOU DID IT! 🎉";
      message = "You know ALL the colors! You're super smart! 🌈✨";
      emoji = "🌟🏆";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "GREAT JOB! 🎈";
      message = "You know lots of colors! Keep going! 🌈💪";
      emoji = "⭐🎨";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "GOOD TRY! 🌈";
      message = "You're learning colors! Practice more! 🌟📚";
      emoji = "💪🎯";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "TRY AGAIN! 🌱";
      message = "Colors are fun! You can do it! 🌈💖";
      emoji = "🌻📚";
      titleColor = const Color(0xFFFF9800);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          backgroundColor: const Color(0xFFFFF6DC),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              // Big celebration emoji
              Text(
                emoji,
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 20),
              // Fun title with rainbow effect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      titleColor,
                      titleColor.withOpacity(0.7),
                      titleColor.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: titleColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // Kid-friendly message with bigger text
              Text(
                message,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF4A4E69),
                  fontFamily: 'Poppins',
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Fun score display with stars
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade300, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("⭐ ", style: TextStyle(fontSize: 20)),
                    Text(
                      "Your Score: $score / ${questions.length}",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.blue.shade700,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(" ⭐", style: TextStyle(fontSize: 20)),
                  ],
                ),
              ),
              
              // Reward Animation
              if (_lastReward != null && _lastReward!.xpAwarded > 0)
                RewardAnimationWidget(
                  result: _lastReward!,
                ),
              
              const SizedBox(height: 20),
              
              // Button to show answer summary in separate modal
              ElevatedButton.icon(
                onPressed: () {
                  _showAnswerSummaryModal();
                },
                icon: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 24,
                ),
                label: const Text(
                  "View My Answers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4E69),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
              ),
              
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        resetAssessment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4E69),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Reset",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                          (Route<dynamic> route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DB2FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Back to Learning",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAnswerSummaryModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: const Color(0xFFF7F9FC),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Answers Summary",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 28),
                    color: const Color(0xFF4A4E69),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Answer list
              Expanded(
                child: reflection.isEmpty
                    ? const Center(
                        child: Text(
                          "No answers recorded.",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: reflection.length,
                        itemBuilder: (_, index) {
                          final item = reflection[index];
                          final isCorrect = item['userAnswer'] == item['correctAnswer'];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: isCorrect
                                ? const Color(0xFFD6FFE0)
                                : const Color(0xFFFFD6D6),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Question ${index + 1}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4A4E69),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['question']!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF4A4E69),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Your Answer: ${item['userAnswer']}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isCorrect
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isCorrect)
                                    Text(
                                      "Correct Answer: ${item['correctAnswer']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        isCorrect ? Icons.check_circle : Icons.cancel,
                                        color: isCorrect ? Colors.green : Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isCorrect ? "Correct!" : "Incorrect",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4E69),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSkipConfirmation() {
    flutterTts.stop();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF6DC),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 60, color: Color(0xFFFF6B6B)),
                const SizedBox(height: 20),
                const Text(
                  "Skip Assessment?",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22223B),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to skip this assessment? Your progress will be saved.",
                  style: TextStyle(fontSize: 18, color: Color(0xFF4A4E69)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4E69),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Skip",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
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
  }

  Widget _buildOption(String optionLabel, Color optionColor) {
    final question = questions[currentIndex];
    Color bgColor = optionColor;
    if (showAnswerFeedback && selectedOption != null) {
      if (optionLabel == selectedOption) {
        bgColor = optionLabel == question.correctAnswer ? Colors.green : Colors.red;
      } else if (optionLabel == question.correctAnswer) {
        bgColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          double offset = 0;
          if ((_shakeController.isAnimating || !_shakeController.isDismissed) &&
              selectedOption == optionLabel &&
              optionLabel != question.correctAnswer) {
            offset = sin(_shakeController.value * pi * 10) * 8;
          }
          return Transform.translate(
            offset: Offset(offset, 0),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => playSoundAndCheck(optionLabel),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        optionLabel,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.volume_up,
                          color: Colors.white, size: 28),
                      onPressed: () => _speakOption(optionLabel),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentIndex];
    return WillPopScope(
      onWillPop: () async {
        _showSkipConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF6EC),
        body: SafeArea(
          child: Stack(
            children: [
              // Simple close button in top right
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _showSkipConfirmation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF4A4E69),
                      size: 24,
                    ),
                  ),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Kid-friendly question counter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade100, Colors.blue.shade50],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.blue.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.quiz, color: Colors.blue, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Question ${currentIndex + 1} of ${questions.length} 🌟',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 30),
                        Text(
                          question.questionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3A3B3C),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.volume_up,
                              color: Colors.black87, size: 40),
                          onPressed: readQuestion,
                        ),
                        const SizedBox(height: 30),
                        Image.asset(
                          question.imagePath,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.broken_image,
                            size: 100,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ...question.options.entries.map(
                          (entry) => _buildOption(entry.key, entry.value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _shakeController.dispose();
    super.dispose();
  }
}

class Question {
  final String imagePath;
  final String questionText;
  final Map<String, Color> options;
  final String correctAnswer;

  Question({
    required this.imagePath,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });
}
