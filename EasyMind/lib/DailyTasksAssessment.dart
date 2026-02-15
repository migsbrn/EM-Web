import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'package:confetti/confetti.dart';
import 'ReadingMaterialsPage.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';

class DailyTasksAssessment extends StatefulWidget {
  final String nickname;
  const DailyTasksAssessment({super.key, required this.nickname});

  @override
  State<DailyTasksAssessment> createState() => _DailyTasksAssessmentState();
}

class _DailyTasksAssessmentState extends State<DailyTasksAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  late VideoPlayerController _videoController;
  late ConfettiController _confettiController;
  int currentIndex = 0;
  int score = 0;
  List<Map<String, String>> reflections = [];
  String? selectedAnswer;
  bool _useAdaptiveMode = true;
  bool _showAnswerSummary = false;
  bool _isAnswerLocked = false; // Prevent multiple answer selections
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  final List<Map<String, dynamic>> questions = [
    {
      'video': 'assets/videos/wake.mp4',
      'question': 'What did Maria do first?',
      'answer': 'woke up early',
      'options': ['woke up early', 'went to bed', 'ate breakfast'],
    },
    {
      'video': 'assets/videos/sweep.mp4',
      'question': 'What did she use to sweep the room?',
      'answer': 'broom',
      'options': ['broom', 'mop', 'vacuum'],
    },
    {
      'video': 'assets/videos/wash.mp4',
      'question': 'What did Maria use to wash the dishes?',
      'answer': 'soap and water',
      'options': ['soap and water', 'sponge', 'detergent'],
    },
    {
      'video': 'assets/videos/drinking.mp4',
      'question': 'What did Maria drink?',
      'answer': 'cold water',
      'options': ['cold water', 'hot tea', 'juice'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset(
        questions[currentIndex]['video'],
      )
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
        _videoController.setLooping(false);
        _speakQuestion();
      });
  }

  Future<void> _speakQuestion() async {
    await flutterTts.stop();
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.2);
    await flutterTts.speak(questions[currentIndex]['question']);
  }

  void _speakOption(String option) async {
    await flutterTts.stop();
    await flutterTts.speak(option);
  }

  void _checkAnswer() async {
    if (selectedAnswer == null || _isAnswerLocked) return;

    // Lock the answer to prevent multiple selections
    setState(() {
      _isAnswerLocked = true;
    });

    final correctAnswer = questions[currentIndex]['answer'].toLowerCase();

    await flutterTts.stop();
    if (selectedAnswer!.toLowerCase() == correctAnswer) {
      score++;
      await flutterTts.speak("Correct");
    } else {
      await flutterTts.speak("Wrong");
    }

    reflections.add({
      'question': questions[currentIndex]['question'],
      'userAnswer': selectedAnswer!,
      'correctAnswer': correctAnswer,
    });

    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedAnswer = null;
        _isAnswerLocked = false; // Unlock for next question
        _initializeVideo();
      });
    } else {
      await _saveToMemoryRetention();
      _confettiController.play();
      _showResultDialog();
    }
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.dailyTasks.value,
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
      lessonType: "Daily Tasks Assessment",
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
        lessonType: "Daily Tasks Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.dailyTasks.value,
          moduleName: "Pre-Vocational Skills",
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
          'module': 'dailyTasks',
          'score': score,
          'total': questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Pre-Vocational Skills",
        lessonType: "Daily Tasks Assessment",
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFF7F9FC),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: 25,
                  colors: const [
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 80,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Congratulations!",
                            style: TextStyle(
                              fontSize: 24,
                              color: Color(0xFF4A4E69),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "You completed the Daily Tasks Assessment!\nYour score: $score/${questions.length}",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF34495E),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          // Reward Animation
                          if (_lastReward != null && _lastReward!.xpAwarded > 0)
                            RewardAnimationWidget(
                              result: _lastReward!,
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
                                itemCount: reflections.length,
                                itemBuilder: (_, index) {
                                  final item = reflections[index];
                                  final isCorrect = item['userAnswer'] == item['correctAnswer'];
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
                                            "Q${index + 1}: ${item['question']}",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4A4E69)),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "My Answer: ${item['userAnswer']}",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: isCorrect
                                                    ? Colors.green[800]
                                                    : Colors.red[800]),
                                          ),
                                          if (!isCorrect)
                                            Text(
                                              "Correct: ${item['correctAnswer']}",
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
                          
                          // Retry Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A4E69),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context); // Close the dialog
                                setState(() {
                                  currentIndex = 0;
                                  score = 0;
                                  selectedAnswer = null;
                                  _isAnswerLocked = false;
                                  reflections.clear();
                                });
                                _initializeVideo(); // Restart the assessment
                              },
                              child: const Text(
                                "Retry Assessment",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Back to Learning Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DB2FF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => Readingmaterialspage(nickname: widget.nickname),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: const Text(
                                "Back to Learning",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              "Are you sure you want to skip the assessment?",
              style: TextStyle(fontSize: 22, color: Colors.black87),
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
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => Readingmaterialspage(nickname: widget.nickname),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: const Text(
                    "Yes, Skip",
                    style: TextStyle(
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

  void _showBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Take a short break?',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Would you like to take a short break now or continue the assessment?',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Break time! Take a rest! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Take Break', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keep going! You\'re doing great! 💪'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxVideoWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.9;
    final options = questions[currentIndex]['options'] as List<String>;

    return WillPopScope(
      onWillPop: () async {
        _showSkipConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EAD5),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Simple close button in top right
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: _showSkipConfirmation,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.red.shade300, width: 2),
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.red.shade600,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const SizedBox(height: 20),
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
                          Icon(
                            Icons.quiz,
                            color: Colors.blue.shade600,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Question ${currentIndex + 1} of ${questions.length}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Text(
                    questions[currentIndex]['question'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_videoController.value.isInitialized)
                    Center(
                      child: Container(
                        width: maxVideoWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black12,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: AspectRatio(
                          aspectRatio: _videoController.value.aspectRatio,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 40),
                  ...options.map(
                    (option) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        onPressed: _isAnswerLocked ? null : () {
                          setState(() {
                            selectedAnswer = option;
                          });
                          _checkAnswer();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selectedAnswer == option
                                  ? Colors.orange[300]
                                  : const Color(0xFF648BA2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(double.infinity, 70),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.volume_up,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () => _speakOption(option),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    flutterTts.stop();
    _confettiController.dispose();
    super.dispose();
  }
}
