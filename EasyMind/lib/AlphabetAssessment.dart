// Imports
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'ReadingMaterialsPage.dart';
import 'memory_retention_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'adaptive_assessment_system.dart';
import 'intelligent_nlp_system.dart';

class AlphabetAssessment extends StatefulWidget {
  final String nickname;
  
  const AlphabetAssessment({super.key, required this.nickname});

  @override
  State<AlphabetAssessment> createState() => _AlphabetAssessmentState();
}

class _AlphabetAssessmentState extends State<AlphabetAssessment>
    with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final TextEditingController _controller = TextEditingController();
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();

  int currentQuestion = 0;
  int score = 0;
  bool isOptionDisabled = false;
  bool isSpeaking = false;
  GamificationResult? _lastReward;
  bool _useAdaptiveMode = true;
  bool _showAnswerSummary = false;

  late AnimationController _waveController;
  late AnimationController _borderAnimationController;
  late ConfettiController _confettiController;
  Color borderColor = const Color(0xFF5DB2FF);

  final List<Map<String, dynamic>> questions = [
    {"letter": "A", "answer": "A"},
    {"letter": "E", "answer": "E"},
    {"letter": "M", "answer": "M"},
    {"letter": "T", "answer": "T"},
    {"letter": "Z", "answer": "Z"},
  ];

  List<Map<String, String>> reflection = [];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    setupTts();
    _initializeFocusSystem();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _borderAnimationController.reverse();
        }
      });

    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    loadProgress().then((_) => speakQuestion());
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.alphabet.value,
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

  @override
  void dispose() {
    flutterTts.stop();
    _waveController.dispose();
    _borderAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void setupTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.45);

    flutterTts.setStartHandler(() {
      setState(() => isSpeaking = true);
      _waveController.repeat();
    });

    flutterTts.setCompletionHandler(() {
      setState(() => isSpeaking = false);
      _waveController.stop();
    });

    flutterTts.setErrorHandler((msg) {
      setState(() => isSpeaking = false);
      _waveController.stop();
    });
  }

  Future<void> _initializeFocusSystem() async {
    await _focusSystem.initialize();
    await _focusSystem.startFocusSession(
      nickname: widget.nickname,
      moduleName: "Functional Academics",
      lessonType: "Alphabet Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentQuestion = prefs.getInt('alphabet_currentQuestion') ?? 0;
      score = prefs.getInt('alphabet_score') ?? 0;
    });
  }

  Future<void> saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('alphabet_currentQuestion', currentQuestion);
    await prefs.setInt('alphabet_score', score);
  }

  Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alphabet_currentQuestion');
    await prefs.remove('alphabet_score');
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Alphabet Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.alphabet.value,
          moduleName: "Functional Academics",
          totalQuestions: questions.length,
          correctAnswers: score,
          timeSpent: const Duration(minutes: 5), // Placeholder - you can track actual time
          attemptedQuestions: questions.map((q) => q['letter'] as String).toList(),
          correctQuestions: reflection
              .where((r) => r['correct'] == 'true')
              .map((r) => r['question']!)
              .toList(),
        );
      }
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Alphabet Assessment",
        completed: true,
      );
      
      // Award XP based on performance
      String activity = 'lesson_completed';
      Map<String, dynamic> metadata = {
        'module': 'alphabet',
        'score': score,
        'totalQuestions': questions.length,
        'perfect': score == questions.length,
        'adaptiveLevel': 'beginner',
      };
      
      if (score == questions.length) {
        activity = 'perfect_score';
      } else if (score >= questions.length * 0.8) {
        activity = 'assessment_passed';
      }
      
      final reward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: activity,
        metadata: metadata,
      );
      
      setState(() {
        _lastReward = reward;
      });
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  Future<void> speak(String text) async {
    if (isSpeaking) await flutterTts.stop();
    await flutterTts.speak(text);
  }

  Future<void> speakQuestion() async {
    await flutterTts.stop();
    await speak("Listen carefully.");
    await Future.delayed(const Duration(milliseconds: 500));
    await speak(questions[currentQuestion]["letter"]);
  }

  void checkAnswer() async {
    if (isOptionDisabled) return;

    final userAnswer = _controller.text.trim().toUpperCase();
    if (userAnswer.isEmpty) {
      await speak("Please enter a letter before submitting.");
      return;
    }

    setState(() => isOptionDisabled = true);
    await flutterTts.stop();

    final correctAnswer = questions[currentQuestion]["answer"];
    final isCorrect = userAnswer == correctAnswer;

    reflection.add({
      'question': questions[currentQuestion]["letter"],
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
    });

    setState(() {
      borderColor = isCorrect ? Colors.green : Colors.red;
    });
    _borderAnimationController.forward();

    if (isCorrect) {
      await speak("Correct! Well done.");
      score++;
    } else {
      await speak("Wrong. The correct answer is $correctAnswer.");
    }

    await saveProgress();

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      borderColor = const Color(0xFF5DB2FF);
    });

    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        _controller.clear();
        isOptionDisabled = false;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      await speakQuestion();
    } else {
      // Save to memory retention system before clearing progress
      await _saveToMemoryRetention();
      await clearProgress();
      _confettiController.play();
      await Future.delayed(const Duration(milliseconds: 400));
      _showCompletionDialog();
    }
  }


  void _showSkipConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFFF6DC),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 60,
                  color: Color(0xFFFF6B6B),
                ),
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
                        onPressed: () async {
                          await saveProgress();
                          Navigator.pop(context);
                          Navigator.pop(context);
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

  void _showCompletionDialog() async {
    final performance = score / questions.length;
    String title, message, emoji, celebration;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "ABC SUPERSTAR! 🌟";
      message = "You know ALL the letters! You're amazing! 🔤✨";
      emoji = "🌟📚";
      celebration = "🎊🎈🎁";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "LETTER CHAMP! 🏆";
      message = "You know lots of letters! Keep going! 🔤💪";
      emoji = "⭐🔤";
      celebration = "🎉✨";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "LEARNING HERO! 💪";
      message = "You're learning letters! Practice more! 📚🌟";
      emoji = "🎯📖";
      celebration = "⭐";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "TRY AGAIN! 🌱";
      message = "Letters are fun! You can do it! 🔤💖";
      emoji = "🌻✏️";
      celebration = "💪";
      titleColor = const Color(0xFFFF9800);
    }
    
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => Dialog.fullscreen(
          backgroundColor: const Color(0xFFFFF6DC),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 25,
                colors: const [
                  Color(0xFF5DB2FF),
                  Color(0xFF4A4E69),
                  Color(0xFF22223B)
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  // Celebration emojis
                  Text(
                    celebration,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 12),
                  // Main emoji
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 60),
                  ),
                  const SizedBox(height: 16),
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
                        fontSize: 20,
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
                      fontSize: 18,
                      color: Color(0xFF4A4E69),
                      fontFamily: 'Poppins',
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  
                  // Reward Animation
                  if (_lastReward != null && _lastReward!.xpAwarded > 0)
                    RewardAnimationWidget(
                      result: _lastReward!,
                      onAnimationComplete: () {
                        setState(() {
                          _lastReward = null;
                        });
                      },
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
                  SizedBox(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DB2FF),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text(
                        "Back to Learning",
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
              )
            ],
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
                child: ListView.builder(
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

  Widget buildWaveform(double width, double height) {
    return Center(
      child: SizedBox(
        height: height,
        width: width,
        child: AnimatedBuilder(
          animation: _waveController,
          builder: (_, __) =>
              CustomPaint(painter: WaveformPainter(_waveController.value)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // breakpoint
    final bool isSmall = screenWidth < 600; // phones
    // responsive sizes
    final double closeIconSize = isSmall ? 20.0 : 24.0;
    final double waveformHeight = isSmall ? 120.0 : 150.0;
    final double waveformWidth = screenWidth * 0.9 > 650 ? 650.0 : screenWidth * 0.9;
    final double questionFont = isSmall ? 16.0 : 18.0;
    final double repeatIconSize = isSmall ? 28.0 : 36.0;
    final double repeatFontSize = isSmall ? 18.0 : 26.0;
    final double inputContainerWidth = screenWidth * 0.8 > 400 ? 400.0 : screenWidth * 0.8;
    final double inputFont = isSmall ? 22.0 : 28.0;
    final double submitWidth = isSmall ? 200.0 : 240.0;
    final double submitHeight = isSmall ? 56.0 : 80.0;
    final double submitFont = isSmall ? 20.0 : 26.0;

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
              Expanded(
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
                                child: Icon(
                                  Icons.close,
                                  color: const Color(0xFF4A4E69),
                                  size: closeIconSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ),
              const Spacer(),
              buildWaveform(waveformWidth, waveformHeight),
              SizedBox(height: isSmall ? 12 : 20),

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
                      'Question ${currentQuestion + 1} of ${questions.length} 🌟',
                      style: TextStyle(
                        fontSize: questionFont,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: isSpeaking ? null : speakQuestion,
                icon: Icon(Icons.replay_rounded, size: repeatIconSize, color: Colors.white),
                label: Text(
                  "Repeat Sound",
                  style: TextStyle(
                      fontSize: repeatFontSize, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5DB2FF),
                  padding: EdgeInsets.symmetric(horizontal: repeatFontSize * 2, vertical: repeatFontSize * 0.9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),

              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _borderAnimationController,
                builder: (context, child) {
                  final glow = (sin(_borderAnimationController.value * pi) + 0.5) * 4;
                      return Column(
                    children: [
                      Container(
                        width: inputContainerWidth,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor, width: glow),
                        ),
                        child: child,
                      ),
                      const SizedBox(height: 8),
                      if (isOptionDisabled &&
                          _controller.text.toUpperCase() !=
                              questions[currentQuestion]["answer"])
                        Text(
                          "Correct Answer: ${questions[currentQuestion]["answer"]}",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  );
                },
                child: TextField(
                  controller: _controller,
                  enabled: !isOptionDisabled,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 1,
                  style: TextStyle(
                      fontSize: inputFont,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3A405A)),
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "Enter letter",
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: isSmall ? 14 : 20, vertical: isSmall ? 12 : 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => checkAnswer(),
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: submitWidth,
                height: submitHeight,
                child: ElevatedButton(
                  onPressed: isOptionDisabled ? null : checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5DB2FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    "Submit",
                    style: TextStyle(
                        fontSize: submitFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Waveform Painter ===
class WaveformPainter extends CustomPainter {
  final double progress;
  WaveformPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFF5DB2FF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final waveWidth = size.width / 30;

    for (int i = 0; i < 30; i++) {
      final dx = waveWidth * i;
      final height = sin(progress * 2 * pi + i * 0.5) * 20 + 30;
      canvas.drawLine(
          Offset(dx, centerY - height / 2),
          Offset(dx, centerY + height / 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
