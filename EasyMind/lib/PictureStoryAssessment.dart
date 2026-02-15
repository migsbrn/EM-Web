import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import '../ReadingMaterialsPage.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';

class PictureStoryAssessment extends StatefulWidget {
  final String nickname;
  const PictureStoryAssessment({super.key, required this.nickname});

  @override
  State<PictureStoryAssessment> createState() => _PictureStoryAssessmentState();
}

class _PictureStoryAssessmentState extends State<PictureStoryAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  int currentQuestion = 0;
  int score = 0;
  bool _useAdaptiveMode = true;
  final List<Map<String, String>> reflection = [];
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  String? selectedOption; // Track selected option for highlight

  final List<Map<String, dynamic>> questions = [
    {
      "question": "Who is lost in the park?",
      "image": 'assets/puppy.png',
      "options": ["puppy", "dog", "cat", "bird"],
      "answer": "puppy",
    },
    {
      "question": "Who finds the lost puppy?",
      "image": 'assets/grl.jpg',
      "options": ["boy", "girl", "dog", "cat"],
      "answer": "girl",
    },
    {
      "question": "Who reunites with the puppy?",
      "image": 'assets/girl.png',
      "options": ["puppy", "owner", "boy", "cat"],
      "answer": "owner",
    },
  ];

  List<String> shuffledOptions = [];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _configureTts();
    shuffleOptions();
    speakQuestion();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  void _configureTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.4);
    try {
      await flutterTts.setVoice({
        "name": "en-us-x-tpf#female_1-local",
        "locale": "en-US",
      });
    } catch (e) {
      try {
        await flutterTts.setVoice({
          "name": "en-us-x-sfg#female_2-local",
          "locale": "en-US",
        });
      } catch (e) {
        print("TTS voice configuration failed: $e");
      }
    }
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speakQuestion() async {
    await flutterTts.stop();
    await flutterTts.speak(questions[currentQuestion]["question"]);
  }

  Future<void> _speakOption(String option) async {
    await flutterTts.stop();
    await flutterTts.speak(option);
  }

  void shuffleOptions() {
    shuffledOptions = List<String>.from(questions[currentQuestion]["options"]);
    shuffledOptions.shuffle(Random());
  }

  void checkAnswer(String selectedOption) async {
    await flutterTts.stop();
    setState(() {
      this.selectedOption = selectedOption; // Highlight selected button
    });

    // Add to reflection
    reflection.add({
      'question': questions[currentQuestion]['question'],
      'userAnswer': selectedOption,
      'correctAnswer': questions[currentQuestion]['answer'],
    });

    if (selectedOption == questions[currentQuestion]["answer"]) {
      score++;
      await flutterTts.speak("Correct");
    } else {
      await flutterTts.speak("Wrong");
    }

    setState(() {
      this.selectedOption = null; // Clear highlight
    });
    
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
        shuffleOptions();
      });
      speakQuestion();
    } else {
      await _saveToMemoryRetention();
      _showResultDialog();
    }
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.pictureStory.value,
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
      moduleName: "Communication Skills",
      lessonType: "Picture Story Assessment",
    );
    
    // Initialize gamification system
    await _gamificationSystem.initialize();
  }

  Future<void> _saveToMemoryRetention() async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Communication Skills",
        lessonType: "Picture Story Assessment",
        score: score,
        totalQuestions: questions.length,
        passed: score >= questions.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.pictureStory.value,
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
          'module': 'pictureStory',
          'score': score,
          'total': questions.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Communication Skills",
        lessonType: "Picture Story Assessment",
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

  void _showAnswerSummaryModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "My Answers",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: reflection.length,
                  itemBuilder: (context, index) {
                    final item = reflection[index];
                    final isCorrect = item['userAnswer'] == item['correctAnswer'];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${index + 1}: ${item['question']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A4E69),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  "Your answer: ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  item['userAnswer'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  "Correct answer: ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  item['correctAnswer'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A4E69),
                                  ),
                                ),
                              ],
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
                                  isCorrect ? "Correct!" : "Try again next time!",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF648BA2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _showCompletionDialog() {
    final performance = score / questions.length;
    String title, message, emoji;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "STORY MASTER! 📖";
      message = "Amazing! You understand stories so well! You're a reading superstar!";
      emoji = "🌟📚";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "STORY CHAMP! 🏆";
      message = "Great job with picture stories! You're getting really good at reading!";
      emoji = "⭐📖";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "STORY HERO! 💪";
      message = "You're learning about stories! Keep practicing and you'll be amazing!";
      emoji = "🎯📚";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "KEEP LEARNING! 🌱";
      message = "Stories are fun to learn! Try again and you'll do great!";
      emoji = "🌻📖";
      titleColor = const Color(0xFFFF9800);
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
            backgroundColor: const Color(0xFFF7F9FC),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                        "Your Score: $score/${questions.length}",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blue.shade700,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Reward Animation
                    if (_lastReward != null && _lastReward!.xpAwarded > 0)
                      RewardAnimationWidget(
                        result: _lastReward!,
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // View My Answers button
                    ElevatedButton.icon(
                      onPressed: _showAnswerSummaryModal,
                      icon: const Icon(
                        Icons.quiz,
                        color: Colors.white,
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
                        backgroundColor: const Color(0xFF4A4E69),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DB2FF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => Readingmaterialspage(nickname: widget.nickname),
                          ),
                          (Route<dynamic> route) => false,
                        );
                      },
                      child: const Text(
                        "Back to Learning",
                        style: TextStyle(fontSize: 22, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
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
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 80),
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
                            Icon(
                              Icons.quiz,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Question ${currentQuestion + 1} of ${questions.length}',
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCE5FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          questionData["question"],
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003366),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          questionData["image"],
                          fit: BoxFit.contain,
                          height: 250,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.broken_image,
                                size: 100,
                                color: Colors.red,
                              ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children:
                            shuffledOptions.map((option) {
                              return GestureDetector(
                                onTap: () => checkAnswer(option),
                                child: SizedBox(
                                  width: isSmall ? screenSize.width * 0.8 : 300,
                                  child: ElevatedButton(
                                    onPressed: () => checkAnswer(option),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          selectedOption == option
                                              ? Colors.orange[300]
                                              : Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        70,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF66B3FF),
                                        width: 3,
                                      ),
                                      shadowColor: Colors.grey.shade300,
                                      elevation: 5,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            option,
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.volume_up,
                                            color: Colors.black87,
                                            size: 30,
                                          ),
                                          onPressed: () => _speakOption(option),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.volume_up),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4D94FF),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          speakQuestion();
                        },
                        label: const Text(
                          "Repeat Question",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
