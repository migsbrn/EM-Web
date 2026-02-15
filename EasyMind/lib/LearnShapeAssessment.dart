import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import '../ReadingMaterialsPage.dart';
import 'dart:math';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';
import 'responsive_utils.dart';

class LearnShapeAssessment extends StatefulWidget {
  final String nickname;
  const LearnShapeAssessment({super.key, required this.nickname});

  @override
  _LearnShapeAssessmentState createState() => _LearnShapeAssessmentState();
}

class _LearnShapeAssessmentState extends State<LearnShapeAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  int currentQuestion = 0;
  int score = 0;
  final bool _useAdaptiveMode = true;
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  
  // reflection list for summary
  final List<Map<String, String>> reflection = [];
  int attempts = 0;
  bool isCorrectShapeDropped = false;
  bool showIncorrectIcon = false;
  bool isQuestionFinished = false;

  final List<Map<String, Object>> questions = [
    {
      'question': 'Drop the correct shape to the broken line',
      'matchWith': 'Circle',
      'options': [
        {'shape': 'Circle', 'image': 'assets/circle.png'},
        {'shape': 'Square', 'image': 'assets/square.png'},
        {'shape': 'Triangle', 'image': 'assets/triangle.png'},
        {'shape': 'Rectangle', 'image': 'assets/rectangle.png'},
      ],
      'answer': 'Circle',
    },
    {
      'question': 'Drop the correct shape to the broken line',
      'matchWith': 'Square',
      'options': [
        {'shape': 'Rectangle', 'image': 'assets/rectangle.png'},
        {'shape': 'Square', 'image': 'assets/square.png'},
        {'shape': 'Star', 'image': 'assets/sta.png'},
        {'shape': 'Circle', 'image': 'assets/circle.png'},
      ],
      'answer': 'Square',
    },
    {
      'question': 'Drop the correct shape to the broken line',
      'matchWith': 'Triangle',
      'options': [
        {'shape': 'Star', 'image': 'assets/sta.png'},
        {'shape': 'Triangle', 'image': 'assets/triangle.png'},
        {'shape': 'Rectangle', 'image': 'assets/rectangle.png'},
        {'shape': 'Square', 'image': 'assets/square.png'},
      ],
      'answer': 'Triangle',
    },
    {
      'question': 'Drop the correct shape to the broken line',
      'matchWith': 'Rectangle',
      'options': [
        {'shape': 'Triangle', 'image': 'assets/triangle.png'},
        {'shape': 'Circle', 'image': 'assets/circle.png'},
        {'shape': 'Rectangle', 'image': 'assets/rectangle.png'},
        {'shape': 'Star', 'image': 'assets/sta.png'},
      ],
      'answer': 'Rectangle',
    },
    {
      'question': 'Drop the correct shape to the broken line',
      'matchWith': 'Star',
      'options': [
        {'shape': 'Square', 'image': 'assets/square.png'},
        {'shape': 'Circle', 'image': 'assets/circle.png'},
        {'shape': 'Triangle', 'image': 'assets/triangle.png'},
        {'shape': 'Star', 'image': 'assets/sta.png'},
      ],
      'answer': 'Star',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializeTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakQuestion();
    });
  }

  Future<void> _initializeTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakQuestion() async {
    await flutterTts.stop();
    if (currentQuestion < questions.length) {
      final question = questions[currentQuestion]['question'] as String;
      await flutterTts.speak(question);
    }
  }

  Future<void> _repeatQuestion() async {
    await _speakQuestion();
  }

  void _handleDrop(String? droppedShape) async {
    if (isQuestionFinished) return;

    await flutterTts.stop();
    setState(() {
      attempts++;
      isCorrectShapeDropped = droppedShape == questions[currentQuestion]['answer'];
      showIncorrectIcon = !isCorrectShapeDropped;
    });

    // Add to reflection list
    reflection.add({
      'question': questions[currentQuestion]['question'] as String,
      'userAnswer': droppedShape ?? 'No answer',
      'correctAnswer': questions[currentQuestion]['answer'] as String,
    });

    if (isCorrectShapeDropped) {
      score++;
      await flutterTts.speak("Correct");
      setState(() => isQuestionFinished = true);
      _proceedToNextQuestion();
    } else {
      await flutterTts.speak("Incorrect. Try again.");
      if (attempts >= 3) {
        setState(() => isQuestionFinished = true);
        _proceedToNextQuestion();
      } else {
        setState(() => isCorrectShapeDropped = false);
        await _speakQuestion();
      }
    }
  }

  void _proceedToNextQuestion() async {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        attempts = 0;
        isCorrectShapeDropped = false;
        showIncorrectIcon = false;
        isQuestionFinished = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _speakQuestion();
        });
      });
    } else {
      await _saveToMemoryRetention();
      setState(() {
        _showResultDialog();
      });
    }
  }


  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.shapeLearning.value,
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
      lessonType: "Learn Shape Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Pre-Vocational Skills",
        lessonType: "Learn Shape Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.shapeLearning.value,
          moduleName: "Functional Academics",
          totalQuestions: questions.length,
          correctAnswers: score,
          timeSpent: const Duration(minutes: 5),
          attemptedQuestions: questions.map((q) => q['question'] as String).toList(),
          correctQuestions: questions
              .where((q) => q['isCorrect'] == true)
              .map((q) => q['question'] as String)
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
          'module': 'shapeLearning',
          'score': score,
          'total': questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Learn Shape Assessment",
        completed: true,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  void _showResultDialog() {
    _confettiController.play();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final performance = score / questions.length;
    String title, message, emoji, celebration;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "SHAPE SUPERSTAR! 🌟";
      message = "You know ALL the shapes! You're amazing! 🔷✨";
      emoji = "🌟🔷";
      celebration = "🎊🎈🎁";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "SHAPE CHAMP! 🏆";
      message = "You know lots of shapes! Keep going! 🔸💪";
      emoji = "⭐🔸";
      celebration = "🎉✨";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "SHAPE HERO! 💪";
      message = "You're learning shapes! Practice more! 🔹🌟";
      emoji = "🎯🔹";
      celebration = "⭐";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "TRY AGAIN! 🌱";
      message = "Shapes are fun! You can do it! 🔶💖";
      emoji = "🌻🔶";
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
                colors: const [Color(0xFF5DB2FF), Color(0xFF4A4E69), Color(0xFF22223B)],
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
                          titleColor.withValues(alpha: 0.7),
                          titleColor.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: titleColor.withValues(alpha: 0.4),
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
                    icon: ResponsiveIcon(
                      Icons.quiz,
                      color: Colors.white,
                      mobileSize: 20,
                      tabletSize: 22,
                      desktopSize: 24,
                      largeDesktopSize: 26,
                    ),
                    label: ResponsiveText(
                      "View My Answers",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      mobileFontSize: 16,
                      tabletFontSize: 18,
                      desktopFontSize: 20,
                      largeDesktopFontSize: 22,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A4E69),
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 25),
                        ),
                      ),
                      elevation: 5,
                    ),
                  ),
                  
                  ResponsiveSpacing(mobileSpacing: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: ResponsiveText(
                      "Back to Learning",
                      style: TextStyle(color: Colors.white),
                      mobileFontSize: 16,
                      tabletFontSize: 18,
                      desktopFontSize: 20,
                      largeDesktopFontSize: 22,
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
                  itemCount: questions.length,
                  itemBuilder: (_, index) {
                    final question = questions[index];
                    final isCorrect = question['userAnswer'] == question['answer'];
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
                              question['question'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF4A4E69),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your Answer: ${question['userAnswer'] ?? 'Not answered'}",
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
                                "Correct Answer: ${question['answer']}",
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF6DC),
        title: const Text("Skip Assessment", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to skip?", style: TextStyle(fontSize: 20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF4A4E69), fontSize: 18)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                (Route<dynamic> route) => false,
              );
            },
            child: const Text("Yes, Skip", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionData = questions[currentQuestion];
    final options = questionData['options'] as List<Map<String, String>>;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showSkipConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
        body: SafeArea(
          child: ResponsiveWidget(
            mobile: _buildMobileLayout(context, questionData, options),
            tablet: _buildTabletLayout(context, questionData, options),
            desktop: _buildDesktopLayout(context, questionData, options),
            largeDesktop: _buildLargeDesktopLayout(context, questionData, options),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    return Stack(
      children: [
        _buildCloseButton(context),
        SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              ResponsiveSpacing(mobileSpacing: 60),
              _buildQuestionCounter(context),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildQuestionContent(context, questionData, options),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildDraggableOptions(context, options),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    return Stack(
      children: [
        _buildCloseButton(context),
        SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              ResponsiveSpacing(mobileSpacing: 60),
              _buildQuestionCounter(context),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildQuestionContent(context, questionData, options),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildDraggableOptions(context, options),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    return Stack(
      children: [
        _buildCloseButton(context),
        SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              ResponsiveSpacing(mobileSpacing: 60),
              _buildQuestionCounter(context),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildQuestionContent(context, questionData, options),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildDraggableOptions(context, options),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    return Stack(
      children: [
        _buildCloseButton(context),
        SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              ResponsiveSpacing(mobileSpacing: 60),
              _buildQuestionCounter(context),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildQuestionContent(context, questionData, options),
              ResponsiveSpacing(mobileSpacing: 20),
              _buildDraggableOptions(context, options),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: GestureDetector(
        onTap: _showSkipConfirmation,
        child: Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
            ),
            border: Border.all(
              color: Colors.red.shade300,
              width: ResponsiveUtils.isSmallScreen(context) ? 1 : 2,
            ),
          ),
          child: ResponsiveIcon(
            Icons.close,
            color: Colors.red.shade600,
            mobileSize: 20,
            tabletSize: 22,
            desktopSize: 24,
            largeDesktopSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCounter(BuildContext context) {
    return Center(
      child: Container(
        padding: ResponsiveUtils.getResponsivePadding(context),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 25),
          ),
          border: Border.all(
            color: Colors.blue.shade300,
            width: ResponsiveUtils.isSmallScreen(context) ? 1 : 2,
          ),
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
            ResponsiveIcon(
              Icons.quiz,
              color: Colors.blue.shade600,
              mobileSize: 18,
              tabletSize: 20,
              desktopSize: 22,
              largeDesktopSize: 24,
            ),
            ResponsiveSpacing(mobileSpacing: 8, isVertical: false),
            ResponsiveText(
              'Question ${currentQuestion + 1} of ${questions.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
                fontFamily: 'Poppins',
              ),
              mobileFontSize: 16,
              tabletFontSize: 18,
              desktopFontSize: 20,
              largeDesktopFontSize: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionContent(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveText(
          questionData['question'] as String,
          style: TextStyle(fontWeight: FontWeight.w600),
          mobileFontSize: 18,
          tabletFontSize: 20,
          desktopFontSize: 22,
          largeDesktopFontSize: 24,
        ),
        ResponsiveSpacing(mobileSpacing: 10),
        IconButton(
          icon: ResponsiveIcon(
            Icons.volume_up,
            color: Colors.black,
            mobileSize: 24,
            tabletSize: 26,
            desktopSize: 28,
            largeDesktopSize: 30,
          ),
          onPressed: _repeatQuestion,
        ),
        ResponsiveSpacing(mobileSpacing: 20),
        _buildDragTarget(context, questionData, options),
        ResponsiveSpacing(mobileSpacing: 12),
        ResponsiveText(
          "Attempts: $attempts/3",
          style: TextStyle(fontWeight: FontWeight.w600),
          mobileFontSize: 16,
          tabletFontSize: 18,
          desktopFontSize: 20,
          largeDesktopFontSize: 22,
        ),
      ],
    );
  }

  Widget _buildDragTarget(BuildContext context, Map<String, dynamic> questionData, List<Map<String, String>> options) {
    final targetSize = ResponsiveUtils.isSmallScreen(context) 
      ? ResponsiveUtils.getResponsiveIconSize(context, mobile: 200)
      : ResponsiveUtils.getResponsiveIconSize(context, mobile: 250);

    return DragTarget<String>(
      onAcceptWithDetails: (details) => _handleDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        return SizedBox(
          width: targetSize,
          height: targetSize,
          child: isCorrectShapeDropped
              ? Image.asset(
                  options.firstWhere((opt) => opt['shape'] == questionData['answer'])['image']!,
                  fit: BoxFit.contain,
                )
              : CustomPaint(
                  size: Size(targetSize, targetSize), 
                  painter: DashedShapePainter(questionData['matchWith'] as String)
                ),
        );
      },
    );
  }

  Widget _buildDraggableOptions(BuildContext context, List<Map<String, String>> options) {
    final optionSize = ResponsiveUtils.isSmallScreen(context) 
      ? ResponsiveUtils.getResponsiveIconSize(context, mobile: 80)
      : ResponsiveUtils.getResponsiveIconSize(context, mobile: 120);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: ResponsiveUtils.isSmallScreen(context) ? 12 : 16,
      runSpacing: ResponsiveUtils.isSmallScreen(context) ? 12 : 16,
      children: options.map((option) {
        return Draggable<String>(
          data: option['shape'],
          feedback: Material(
            child: Container(
              width: optionSize,
              height: optionSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black26), 
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
                ),
              ),
              child: Image.asset(option['image']!, fit: BoxFit.contain),
            ),
          ),
          child: Container(
            width: optionSize,
            height: optionSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26), 
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
              ),
            ),
            child: Image.asset(option['image']!, fit: BoxFit.contain),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    flutterTts.stop();
    super.dispose();
  }
}

class DashedShapePainter extends CustomPainter {
  final String shape;
  DashedShapePainter(this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final dashWidth = 6.0;
    final dashSpace = 4.0;
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    const double shapeSize = 150.0;

    if (shape == 'Circle') {
      final rect = Rect.fromCircle(center: center, radius: shapeSize / 2);
      _drawDashedCircle(canvas, rect, paint, dashWidth, dashSpace);
    } else if (shape == 'Square') {
      path.addRect(Rect.fromCenter(center: center, width: shapeSize, height: shapeSize));
      _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
    } else if (shape == 'Triangle') {
      path.moveTo(center.dx, center.dy - shapeSize / 2);
      path.lineTo(center.dx - shapeSize / 2, center.dy + shapeSize / 2);
      path.lineTo(center.dx + shapeSize / 2, center.dy + shapeSize / 2);
      path.close();
      _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
    } else if (shape == 'Rectangle') {
      path.addRect(Rect.fromCenter(center: center, width: shapeSize * 1.5, height: shapeSize));
      _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
    } else if (shape == 'Star') {
      for (int i = 0; i < 5; i++) {
        final angle = (i * 4 * pi / 5) - pi / 2;
        final outerX = center.dx + cos(angle) * (shapeSize / 2);
        final outerY = center.dy + sin(angle) * (shapeSize / 2);
        final innerAngle = angle + pi / 5;
        final innerX = center.dx + cos(innerAngle) * (shapeSize / 4);
        final innerY = center.dy + sin(innerAngle) * (shapeSize / 4);
        if (i == 0) {
          path.moveTo(outerX, outerY);
        } else {
          path.lineTo(outerX, outerY);
        }
        path.lineTo(innerX, innerY);
      }
      path.close();
      _drawDashedPath(canvas, path, paint, dashWidth, dashSpace);
    }
  }

  void _drawDashedCircle(Canvas canvas, Rect rect, Paint paint, double dashWidth, double dashSpace) {
    double circumference = 2 * pi * (rect.width / 2);
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i * (dashWidth + dashSpace)) * 2 * pi / circumference;
      final sweepAngle = dashWidth * 2 * pi / circumference;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint, double dashWidth, double dashSpace) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedShapePainter oldDelegate) => oldDelegate.shape != shape;
}
