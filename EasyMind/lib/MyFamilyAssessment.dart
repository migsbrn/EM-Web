import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import '../LearnMyFamily.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';
import 'visit_tracking_system.dart';

class MyFamilyAssessment extends StatefulWidget {
  final String nickname;
  
  const MyFamilyAssessment({super.key, required this.nickname});

  @override
  _MyFamilyAssessmentState createState() => _MyFamilyAssessmentState();
}

class _MyFamilyAssessmentState extends State<MyFamilyAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  late ConfettiController _confettiController;
  int currentQuestion = 0;
  int score = 0;
  bool _useAdaptiveMode = true;
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  // reflection list for summary
  final List<Map<String, String>> reflection = [];

  final List<Map<String, Object>> questions = [
    {
      'question': 'Who do I live with?',
      'image': 'assets/happy.jpg',
      'options': [
        'My mother and father',
        'My friend and teacher',
        'My neighbor',
      ],
      'answer': 'My mother and father',
    },
    {
      'question': 'When do we eat dinner together?',
      'image': 'assets/eating_dinner.jpg',
      'options': ['Every night', 'In the morning', 'At school'],
      'answer': 'Every night',
    },
    {
      'question': 'Why do I love my family?',
      'image': 'assets/love_family.jpg',
      'options': [
        'They take care of me',
        'They give me homework',
        'They ride bikes',
      ],
      'answer': 'They take care of me',
    },
    {
      'question': 'What do my sister and I do after school?',
      'image': 'assets/playing.jpg',
      'options': ['Play with toys', 'Do the dishes', 'Go to the store'],
      'answer': 'Play with toys',
    },
    {
      'question': 'What does my father do when my mother is working?',
      'image': 'assets/cooking.jpg',
      'options': ['He cooks dinner', 'He watches TV', 'He reads a book'],
      'answer': 'He cooks dinner',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _trackVisit();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _configureTts();
    _speakQuestion();
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.family.value,
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
      lessonType: "My Family Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  Future<void> _trackVisit() async {
    try {
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: 'assessment',
        itemName: 'My Family Assessment',
        moduleName: 'Functional Academics',
      );
      print('Visit tracked for My Family Assessment');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  void _configureTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.4); // Higher pitch for feminine voice
    try {
      await flutterTts.setVoice({
        "name": "en-us-x-tpf#female_1-local",
        "locale": "en-US",
      });
    } catch (e) {
      await flutterTts.setVoice({
        "name": "en-us-x-sfg#female_2-local",
        "locale": "en-US",
      });
    }
    await flutterTts.awaitSpeakCompletion(true);
  }

  void _speakQuestion() async {
    await flutterTts.stop();
    await flutterTts.speak(questions[currentQuestion]['question'] as String);
  }

  void _speakOption(String option) async {
    await flutterTts.stop();
    await flutterTts.speak(option);
  }

  void answerQuestion(String selected) async {
    await flutterTts.stop();
    bool isCorrect = selected == questions[currentQuestion]['answer'];
    
    // Add to reflection list
    reflection.add({
      'question': questions[currentQuestion]['question'] as String,
      'userAnswer': selected,
      'correctAnswer': questions[currentQuestion]['answer'] as String,
    });
    
    if (isCorrect) {
      score++;
      await flutterTts.speak("Correct");
    } else {
      await flutterTts.speak("Wrong");
    }
    
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
      _speakQuestion();
    } else {
      // Save to memory retention system before showing results
      await _saveToMemoryRetention();
      setState(() {
        _showResultDialog();
      });
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
      title = "FAMILY SUPERSTAR! 🌟";
      message = "You know ALL about family! You're so caring! 👨‍👩‍👧‍👦✨";
      emoji = "🏠💕";
      celebration = "🎊🎈🎁";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "FAMILY CHAMP! 🏆";
      message = "You know lots about family! Keep going! 👨‍👩‍👧💪";
      emoji = "⭐👨‍👩‍👧";
      celebration = "🎉✨";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "FAMILY HERO! 💪";
      message = "You're learning about family! Practice more! 👨‍👩‍👦🌟";
      emoji = "🎯👨‍👩‍👦";
      celebration = "⭐";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "TRY AGAIN! 🌱";
      message = "Family is special! You can do it! 👨‍👩‍👧‍👦💖";
      emoji = "🌻👨‍👩‍👧‍👦";
      celebration = "💪";
      titleColor = const Color(0xFFFF9800);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.purple,
                    ],
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                      // Celebration emojis with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          celebration,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Main emoji with bounce animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 60),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Fun title with rainbow effect and animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    titleColor,
                                    titleColor.withOpacity(0.8),
                                    titleColor.withOpacity(0.6),
                                    Colors.white.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: titleColor.withOpacity(0.6),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
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
                                  letterSpacing: 1.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 15),
                      // Kid-friendly message with bigger text
                        Text(
                        message,
                          style: const TextStyle(
                            fontSize: 18,
                          color: Color(0xFF4A4E69),
                          fontFamily: 'Poppins',
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      // Fun score display with stars and animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1200),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade200,
                                    Colors.cyan.shade100,
                                    Colors.white,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue.shade400, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.shade300,
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
                                    "Your Score: $score/${questions.length}",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.blue.shade800,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white.withOpacity(0.8),
                                          blurRadius: 1,
                                          offset: const Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Text(" ⭐", style: TextStyle(fontSize: 20)),
                                ],
                              ),
                            ),
                          );
                        },
                        ),
                        
                        // Reward Animation
                        if (_lastReward != null && _lastReward!.xpAwarded > 0)
                          RewardAnimationWidget(
                            result: _lastReward!,
                          ),
                      
                      const SizedBox(height: 20),
                      
                      // Button to show answer summary in separate modal with animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.95 + (0.05 * value),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _showAnswerSummaryModal();
                              },
                              icon: const Icon(
                                Icons.quiz,
                                color: Colors.white,
                                size: 20,
                              ),
                              label: const Text(
                                "View My Answers",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A4C93),
                                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFF6A4C93).withOpacity(0.5),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Back to Learning button with animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.9 + (0.1 * value),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C9FF),
                            padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                            ),
                                elevation: 6,
                                shadowColor: const Color(0xFF00C9FF).withOpacity(0.6),
                          ),
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LearnMyFamily(nickname: widget.nickname),
                              ),
                            );
                          },
                          child: const Text(
                            "Back to Learning",
                                style: TextStyle(
                                  fontSize: 20, 
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 1,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
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
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
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
                fontSize: 22,
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
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      color: Colors.black87,
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 3,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LearnMyFamily(nickname: widget.nickname)),
                    );
                  },
                  child: const Text(
                    "Yes, Skip",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
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

  @override
  void dispose() {
    _confettiController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;
    final isVerySmall = screenSize.width < 400;

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
              Positioned(
                bottom: 20,
                right: 0,
                child: SizedBox(
                  width: isSmall ? 200 : 350,
                  height: isSmall ? 200 : 350,
                ),
              ),
              // Simple close button in top right
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _showSkipConfirmation,
                  child: Container(
                    padding: EdgeInsets.all(isSmall ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.red.shade600,
                      size: isSmall ? 20 : 24,
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: isSmall ? 40 : 60),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
                      child: Text(
                        "My Family - Assessment",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 22 : 28,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4E69),
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black26,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 8 : 10),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
                      child: Text(
                        "Answer each question by selecting the correct option.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 20,
                          fontFamily: 'Poppins',
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 15 : 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: isSmall ? 15 : 20),
                          // Kid-friendly question counter
                          Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmall ? 16 : 20, 
                                vertical: isSmall ? 8 : 12,
                              ),
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
                                  Icon(
                                    Icons.quiz,
                                    color: Colors.blue.shade600,
                                    size: isSmall ? 16 : 20,
                                  ),
                                  SizedBox(width: isSmall ? 6 : 8),
                                  Text(
                                    'Question ${currentQuestion + 1} of ${questions.length}',
                                    style: TextStyle(
                                      fontSize: isSmall ? 14 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isSmall ? 15 : 20),
                          Center(
                            child: Image.asset(
                              questions[currentQuestion]['image'] as String,
                              height: isSmall ? 200 : 300,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: isSmall ? 200 : 300,
                                  width: isSmall ? screenSize.width * 0.7 : 400,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: isSmall ? 50 : 80,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: isSmall ? 15 : 20),
                          Text(
                            questions[currentQuestion]['question'] as String,
                            style: TextStyle(
                              fontSize: isSmall ? 24 : 32,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: isVerySmall ? 2 : null,
                            overflow: isVerySmall ? TextOverflow.ellipsis : null,
                          ),
                          SizedBox(height: isSmall ? 8 : 10),
                          IconButton(
                            icon: Icon(
                              Icons.volume_up,
                              color: Colors.black87,
                              size: isSmall ? 32 : 40,
                            ),
                            onPressed: _speakQuestion,
                          ),
                          SizedBox(height: isSmall ? 20 : 30),
                          ...((questions[currentQuestion]['options']
                                  as List<String>)
                              .map((option) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmall ? 4 : 6,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () => answerQuestion(option),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF648BA2),
                                      padding: EdgeInsets.symmetric(
                                        vertical: isSmall ? 12 : 16,
                                        horizontal: isSmall ? 8 : 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size(
                                        double.infinity,
                                        isSmall ? 55 : 65,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontSize: isVerySmall ? 16 : (isSmall ? 18 : 22),
                                              color: Colors.white,
                                              height: 1.1,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: isVerySmall ? 2 : null,
                                            overflow: isVerySmall ? TextOverflow.ellipsis : null,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.volume_up,
                                            color: Colors.white,
                                            size: isVerySmall ? 20 : (isSmall ? 24 : 28),
                                          ),
                                          onPressed: () => _speakOption(option),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              })
                              .toList()),
                        ],
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
        lessonType: "My Family Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: "social_interaction",
          moduleName: "Communication Skills",
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
          'module': 'family',
          'score': score,
          'total': questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Functional Academics",
        lessonType: "My Family Assessment",
        completed: true,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
