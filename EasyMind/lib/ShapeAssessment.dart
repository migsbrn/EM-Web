import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'ReadingMaterialsPage.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';

class ShapeAssessment extends StatefulWidget {
  final String nickname;
  
  const ShapeAssessment({super.key, required this.nickname});

  @override
  State<ShapeAssessment> createState() => _ShapeAssessmentState();
}

class _ShapeAssessmentState extends State<ShapeAssessment> {
  final _flutterTts = FlutterTts();
  final _random = Random();
  int _index = 0, _score = 0;
  final List<Map<String, dynamic>> _questions = [];
  late ConfettiController _confettiController;
  bool _useAdaptiveMode = true;
  bool _showAnswerSummary = false;
  bool _isAnswerLocked = false; // Prevent multiple answer selections
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  
  // reflection list for summary
  final List<Map<String, String>> reflection = [];

  final List<Map<String, String>> shapes = const [
    {'sides': 'I have 4 sides', 'corners': 'I have 4 corners', 'name': 'I am a square', 'image': 'assets/square.png'},
    {'sides': 'I have 3 sides', 'corners': 'I have 3 corners', 'name': 'I am a triangle', 'image': 'assets/triangle.png'},
    {'sides': 'I have 5 sides', 'corners': 'I have 5 corners', 'name': 'I am a pentagon', 'image': 'assets/pentagon.png'},
    {'sides': 'I have 6 sides', 'corners': 'I have 6 corners', 'name': 'I am a hexagon', 'image': 'assets/hexagon.png'},
    {'sides': 'I have 8 sides', 'corners': 'I have 8 corners', 'name': 'I am an octagon', 'image': 'assets/octagon.png'},
    {'sides': 'I have infinite sides', 'corners': 'I have no corners', 'name': 'I am a circle', 'image': 'assets/circle.png'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setPitch(1);
    _flutterTts.setSpeechRate(0.5);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _generateQuestions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.shapes.value,
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
      lessonType: "Shape Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  void _generateQuestions() {
    _questions.clear();
    final used = <int>{};
    while (_questions.length < 5) {
      int correct = _random.nextInt(shapes.length);
      if (used.add(correct)) {
        final q = _random.nextBool()
            ? '${shapes[correct]['sides']!.replaceFirst('I have', 'Which shape has')}?'
            : '${shapes[correct]['corners']!.replaceFirst('I have', 'Which shape has')}?';
        final options = [shapes[correct]];
        while (options.length < 4) {
          int i = _random.nextInt(shapes.length);
          if (options.every((o) => o['image'] != shapes[i]['image'])) {
            options.add(shapes[i]);
          }
        }
        options.shuffle();
        _questions.add({'question': q, 'correct': shapes[correct]['image'], 'options': options});
      }
    }
  }

  void _speak() async {
    await _flutterTts.stop();
    await _flutterTts.speak(_questions[_index]['question']);
  }

  void _check(String selected) async {
    if (_isAnswerLocked) return; // Prevent multiple selections
    
    // Lock the answer to prevent multiple selections
    setState(() {
      _isAnswerLocked = true;
    });
    
    // Add to reflection list
    reflection.add({
      'question': _questions[_index]['question'],
      'userAnswer': selected,
      'correctAnswer': _questions[_index]['correct'],
    });
    
    if (selected == _questions[_index]['correct']) _score++;
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _isAnswerLocked = false; // Unlock for next question
      });
      _speak();
    } else {
      // Save to memory retention system before showing results
      await _saveToMemoryRetention();
      _showResult();
    }
  }

  void _showResult() {
    _flutterTts.stop();
    _confettiController.play();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final performance = _score / _questions.length;
    String title, message, emoji, celebration;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "SHAPE SUPERSTAR! 🌟";
      message = "You know ALL the shapes! You're amazing! 🔷✨";
      emoji = "🌟🔺";
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
        backgroundColor: const Color(0xFFF7F9FC),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
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
                          "Your Score: $_score/${_questions.length}",
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                      setState(() {
                        _index = 0;
                        _score = 0;
                        _isAnswerLocked = false; // Reset answer lock
                        reflection.clear(); // Clear previous answers
                        _generateQuestions();
                      });
                      _speak(); // Start the assessment
                    },
                    child: const Text("Retry", style: TextStyle(fontSize: 22, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                    ),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                        (route) => false,
                      );
                    },
                    child: const Text("Back to Learning", style: TextStyle(fontSize: 22, color: Colors.white)),
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

  void _showSkipConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Skip Assessment", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black87), textAlign: TextAlign.center),
        content: const Text("Are you sure you want to skip the assessment?", style: TextStyle(fontFamily: 'Poppins', fontSize: 22, color: Colors.black87), textAlign: TextAlign.center),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins', fontSize: 22, color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => Readingmaterialspage(nickname: widget.nickname)),
                  (route) => false,
                );
              },
              child: const Text("Yes, Skip", style: TextStyle(fontFamily: 'Poppins', fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    return WillPopScope(
      onWillPop: () async {
        _showSkipConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Kid-friendly question counter
                    Center(
                      child: Container(
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
                              'Question ${_index + 1} of ${_questions.length} 🌟',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Card(
                                margin: const EdgeInsets.all(16),
                                color: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.volume_up, size: 32),
                                            onPressed: _speak,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              question['question'],
                                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      GridView.builder(
                                        shrinkWrap: true,
                                        itemCount: 4,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: 1.2, // Adjusted for smaller shape size
                                        ),
                                        itemBuilder: (_, i) {
                                          final opt = question['options'][i];
                                          return GestureDetector(
                                            onTap: _isAnswerLocked ? null : () => _check(opt['image']),
                                            child: Card(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              child: Padding(
                                                padding: const EdgeInsets.all(6), // Reduced padding
                                                child: Image.asset(
                                                  opt['image'],
                                                  fit: BoxFit.contain,
                                                  height: 80,
                                                  width: 80,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
        moduleName: "Functional Academics",
        lessonType: "Shapes Assessment",
        score: _score,
        totalQuestions: _questions.length,
        passed: _score >= _questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.shapes.value,
          moduleName: "Functional Academics",
          totalQuestions: _questions.length,
          correctAnswers: _score,
          timeSpent: const Duration(minutes: 5),
          attemptedQuestions: _questions.map((q) => q['question'] as String).toList(),
          correctQuestions: _questions
              .where((q) => q['isCorrect'] == true)
              .map((q) => q['question'] as String)
              .toList(),
        );
      }
      
      // Award XP and check for gamification rewards
      final performance = _score / _questions.length;
      final isPerfect = performance >= 0.9;
      
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isPerfect ? 'perfect_score' : 'assessment_passed',
        metadata: {
          'module': 'shapes',
          'score': _score,
          'total': _questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "Shape Assessment",
        completed: true,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
