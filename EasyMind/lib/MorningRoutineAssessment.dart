import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';
import 'intelligent_feedback_system.dart';

class MorningRoutineAssessment extends StatefulWidget {
  final String nickname;
  const MorningRoutineAssessment({super.key, required this.nickname});

  @override
  State<MorningRoutineAssessment> createState() =>
      _MorningRoutineAssessmentState();
}

class _MorningRoutineAssessmentState extends State<MorningRoutineAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  int currentQuestion = 0;
  int score = 0;
  bool isOptionDisabled = false;
  bool isSpeaking = false;
  late ConfettiController _confettiController;
  bool _useAdaptiveMode = true;
  bool _showAnswerSummary = false;
  String _userSpeechInput = '';
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  final List<Map<String, dynamic>> questions = [
    {"task": "Wash my face upon waking up.", "answer": "wash face"},
    {"task": "Brush my teeth three times daily.", "answer": "brush teeth"},
    {"task": "Take a bath daily.", "answer": "take bath"},
    {"task": "Wear clean clothes.", "answer": "wear clean clothes"},
    {"task": "Sleep early at night.", "answer": "sleep early"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    setupTts();
    loadProgress().then((_) {
      speakQuestion();
    });
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.dailyTasks.value, // Using dailyTasks as it's similar
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
      moduleName: "Pre-Vocational Skills",
      lessonType: "Morning Routine Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  void setupTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.45);
    flutterTts.setStartHandler(() {
      setState(() => isSpeaking = true);
    });
    flutterTts.setCompletionHandler(() {
      setState(() => isSpeaking = false);
    });
    flutterTts.setErrorHandler((msg) {
      setState(() => isSpeaking = false);
    });
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentQuestion = prefs.getInt('morning_currentQuestion') ?? 0;
      score = prefs.getInt('morning_score') ?? 0;
    });
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_currentQuestion', currentQuestion);
    await prefs.setInt('morning_score', score);
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('morning_currentQuestion');
    await prefs.remove('morning_score');
  }

  Future<void> speak(String text) async {
    if (isSpeaking) await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> speakQuestion() async {
    await flutterTts.stop();
    await speak("What should I do? ${questions[currentQuestion]["task"]}");
  }

  void checkAnswer() async {
    if (isOptionDisabled) return;

    final userAnswer = _controller.text.trim().toLowerCase();

    if (userAnswer.isEmpty) {
      await speak("Please enter an answer before submitting.");
      return;
    }

    setState(() {
      isOptionDisabled = true;
    });

    await flutterTts.stop();

    if (userAnswer == questions[currentQuestion]["answer"]) {
      await speak("Correct! Good job!");
      _confettiController.play();
      score++;
    } else {
      await speak(
        "Wrong. The correct answer is ${questions[currentQuestion]["answer"]}",
      );
    }

    await saveProgress();

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        _controller.clear();
        isOptionDisabled = false;
      });
      await Future.delayed(const Duration(milliseconds: 800));
      await speakQuestion();
    } else {
      await _saveResult();
      await _saveToMemoryRetention();
      await clearProgress();
      await Future.delayed(const Duration(milliseconds: 400));
      await _showCompletionDialog();
    }
  }

  Future<void> _saveResult({
    String status = 'Completed',
    bool passed = false,
  }) async {
    await firestore.collection('functionalAssessments').add({
      'nickname': widget.nickname,
      'assessmentType': 'MorningRoutine',
      'score': score,
      'totalQuestions': questions.length,
      'status': status,
      'passed': status == 'Completed' ? score >= questions.length / 2 : passed,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Skip Assessment",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              "Are you sure you want to skip the assessment?",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DB2FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    await _saveResult(status: 'Skipped', passed: false);
                    await clearProgress();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Yes, Skip",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }


  Future<void> _showCompletionDialog() async {
    final performance = score / questions.length;
    String title, message, emoji;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "ROUTINE MASTER! 🌅";
      message = "Wow! You know your morning routine perfectly! You're so organized!";
      emoji = "🌟⏰";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "ROUTINE CHAMP! 🏆";
      message = "Great job with morning routines! You're getting really good at daily tasks!";
      emoji = "⭐🌅";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "ROUTINE HERO! 💪";
      message = "You're learning about morning routines! Keep practicing and you'll be amazing!";
      emoji = "🎯⏰";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "KEEP LEARNING! 🌱";
      message = "Morning routines are fun to learn! Try again and you'll do great!";
      emoji = "🌻🌅";
      titleColor = const Color(0xFFFF9800);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 10,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
              
              // Show reward animation if available
              if (_lastReward != null)
                RewardAnimationWidget(result: _lastReward!),
              
              // Animated emoji
              Text(
                emoji,
                style: const TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 16),
              // Title with gradient
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [titleColor.withOpacity(0.8), titleColor.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: titleColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Kid-friendly message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A4E69),
                  fontFamily: 'Poppins',
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Score display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200, width: 2),
                ),
                child: Text(
                  "Your Score: $score / ${questions.length}",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade700,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Toggle button for answer summary
              ElevatedButton.icon(
                onPressed: () {
                  setDialogState(() {
                    _showAnswerSummary = !_showAnswerSummary;
                  });
                },
                icon: Icon(
                  _showAnswerSummary ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                label: Text(
                  _showAnswerSummary ? "Hide Answers" : "Show My Answers",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A4E69),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              // Answer Summary (conditionally shown)
              if (_showAnswerSummary) ...[
                const SizedBox(height: 16),
                const Text(
                  "My Answers",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (_, index) {
                      final question = questions[index];
                      final isCorrect = question['userAnswer'] == question['answer'];
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: isCorrect
                            ? const Color(0xFFD6FFE0)
                            : const Color(0xFFFFD6D6),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Q${index + 1}: ${question['task']}",
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A4E69)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "My Answer: ${question['userAnswer'] ?? 'Not answered'}",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: isCorrect
                                        ? Colors.green[800]
                                        : Colors.red[800]),
                              ),
                              if (!isCorrect)
                                Text(
                                  "Correct: ${question['answer']}",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Back to Learning",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionData = questions[currentQuestion];
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;

    return WillPopScope(
      onWillPop: () async {
        _showSkipConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF6DC),
        body: SafeArea(
          child: Column(
            children: [
              // Simple close button in top right
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Morning Routine Assessment",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: Color(0xFF3A405A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        questionData["task"],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: Color(0xFF3A405A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: isSmall ? 280 : 360,
                        child: TextField(
                          controller: _controller,
                          enabled: !isOptionDisabled,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            color: Color(0xFF3A405A),
                          ),
                          decoration: InputDecoration(
                            hintText: "Enter answer",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onSubmitted: (_) => checkAnswer(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 160,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isOptionDisabled ? null : checkAnswer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5DB2FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Pre-Vocational Skills",
        lessonType: "Morning Routine Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.dailyTasks.value, // Using dailyTasks as it's similar
          moduleName: "Pre-Vocational Skills",
          totalQuestions: questions.length,
          correctAnswers: score,
          timeSpent: const Duration(minutes: 5),
          attemptedQuestions: questions.map((q) => q['task'] as String).toList(),
          correctQuestions: questions
              .where((q) => q['isCorrect'] == true)
              .map((q) => q['task'] as String)
              .toList(),
        );
      }

      // Award XP and end focus session
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: "Morning Routine Assessment",
        metadata: {
          'score': score,
          'totalQuestions': questions.length,
          'moduleName': "Pre-Vocational Skills",
        },
      );
      
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Pre-Vocational Skills",
        lessonType: "Morning Routine Assessment",
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
