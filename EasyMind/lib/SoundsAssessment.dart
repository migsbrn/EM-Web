import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import '../SoftLoudSoundsPage.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';
import 'intelligent_nlp_system.dart';

class SoundsAssessment extends StatefulWidget {
  final String nickname;
  const SoundsAssessment({super.key, required this.nickname});

  @override
  _SoundsAssessmentState createState() => _SoundsAssessmentState();
}

class _SoundsAssessmentState extends State<SoundsAssessment> {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  int score = 0;
  bool _useAdaptiveMode = true;
  
  // Focus and Gamification systems
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;
  
  // reflection list for summary
  final List<Map<String, String>> reflection = [];
  
  // Track answered items (correct/incorrect)
  final Map<int, bool> answeredItems = {}; // itemIndex -> isCorrect
  final Set<int> lockedItems = {}; // Items that have been answered and locked

  final List<Map<String, dynamic>> items = [
    {'name': 'Alarm Clock', 'image': 'assets/clock.png', 'category': 'loud', 'position': -1},
    {'name': 'Bird Chirping', 'image': 'assets/bird.png', 'category': 'soft', 'position': -1},
    {'name': 'Police Siren', 'image': 'assets/police.jpg', 'category': 'loud', 'position': -1},
    {'name': 'Wind', 'image': 'assets/wind.jpg', 'category': 'soft', 'position': -1},
    {'name': 'Fireworks', 'image': 'assets/fireworks.jpg', 'category': 'loud', 'position': -1},
    {'name': 'Dripping Water', 'image': 'assets/water.png', 'category': 'soft', 'position': -1},
    {'name': 'Chainsaw', 'image': 'assets/chainsaw.png', 'category': 'loud', 'position': -1},
    {'name': 'Whispering', 'image': 'assets/whisper.png', 'category': 'soft', 'position': -1},
    {'name': 'Dog Barking', 'image': 'assets/dog_barking.png', 'category': 'loud', 'position': -1},
    {'name': 'Snake Hiss', 'image': 'assets/snake.png', 'category': 'soft', 'position': -1},
  ];

  final List<int> loudDropped = [];
  final List<int> softDropped = [];

  @override
  void initState() {
    super.initState();
    _initializeAdaptiveMode();
    _initializeNLP();
    _initializeFocusSystem();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _speakInstruction();
  }

  Future<void> _speakInstruction() async {
    try {
      final bool isAvailable = await flutterTts.isLanguageAvailable("en-US");
      if (!isAvailable || !mounted) return;
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.stop();
      await flutterTts.speak("Drag each sound to the correct loud or soft category.");
    } catch (e) {
      if (mounted) {
        print("TTS Error in _speakInstruction: $e");
      }
    }
  }

  Future<void> _speakWrong() async {
    try {
      final bool isAvailable = await flutterTts.isLanguageAvailable("en-US");
      if (!isAvailable || !mounted) return;
      await flutterTts.stop(); // Stop any current speech
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.6);
      await flutterTts.setPitch(0.8); // Lower pitch for "wrong"
      await flutterTts.setVolume(1.0);
      await flutterTts.speak("Wrong");
    } catch (e) {
      if (mounted) {
        print("TTS Error in _speakWrong: $e");
      }
    }
  }

  Future<void> _speakCorrect() async {
    try {
      final bool isAvailable = await flutterTts.isLanguageAvailable("en-US");
      if (!isAvailable || !mounted) return;
      await flutterTts.stop(); // Stop any current speech
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.7);
      await flutterTts.setPitch(1.2); // Higher pitch for "correct"
      await flutterTts.setVolume(1.0);
      await flutterTts.speak("Correct");
    } catch (e) {
      if (mounted) {
        print("TTS Error in _speakCorrect: $e");
      }
    }
  }

  void _checkCompletion() {
    if (!mounted) return;
    // Check if all items have been answered (either correctly or incorrectly)
    final bool allAnswered = items.length == lockedItems.length;
    if (allAnswered) {
      _calculateScore();
      _saveToMemoryRetention();
      _showResultDialog();
    }
  }

  void _calculateScore() {
    // Score is already calculated in _onAccept method
    // This method is kept for compatibility but score is now tracked incrementally
  }

  void _onAccept(int itemIndex, String category) {
    if (!mounted) return;
    
    // Check if item is already locked (answered)
    if (lockedItems.contains(itemIndex)) {
      return; // Don't allow movement of already answered items
    }
    
    setState(() {
      if (itemIndex >= 0 && itemIndex < items.length && items[itemIndex]['position'] == -1) {
        final correctCategory = items[itemIndex]['category'];
        final isCorrect = category == correctCategory;
        
        // Mark item as answered and lock it
        answeredItems[itemIndex] = isCorrect;
        lockedItems.add(itemIndex);
        
        if (isCorrect) {
          // Correct answer - add to appropriate category
        if (category == 'loud' && loudDropped.length < 5) {
          loudDropped.add(itemIndex);
          items[itemIndex]['position'] = itemIndex;
            score++; // Increment score for correct answer
            // Speak "Correct" for correct answer
            _speakCorrect();
        } else if (category == 'soft' && softDropped.length < 5) {
          softDropped.add(itemIndex);
          items[itemIndex]['position'] = itemIndex;
            score++; // Increment score for correct answer
            // Speak "Correct" for correct answer
            _speakCorrect();
          } else {
            // Correct category but drop target is full - still mark as correct but don't move
            items[itemIndex]['position'] = -3; // Special marker for correct but no space
            score++; // Still give credit for correct answer
            _speakCorrect();
          }
        } else {
          // Incorrect answer - mark as wrong but don't move
          // Item stays in original position but is locked
          items[itemIndex]['position'] = -2; // Special marker for incorrect placement
          // Speak "Wrong" for incorrect answer
          _speakWrong();
        }
        
        // Add to reflection list
        reflection.add({
          'question': 'Sort ${items[itemIndex]['name']} into $category sounds',
          'userAnswer': category,
          'correctAnswer': correctCategory,
        });
      }
    });
    _checkCompletion();
  }

  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.sounds.value,
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
      lessonType: "Sounds Assessment",
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
        lessonType: "Sounds Assessment",
        score: score,
        totalQuestions: items.length,
        passed: score >= items.length / 2,
      );
      
      // Save adaptive assessment result
      if (_useAdaptiveMode) {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: AssessmentType.sounds.value,
          moduleName: "Communication Skills",
          totalQuestions: items.length,
          correctAnswers: score,
          timeSpent: const Duration(minutes: 5),
          attemptedQuestions: items.map((q) => q['name'] as String).toList(),
          correctQuestions: items
              .where((q) => q['isCorrect'] == true)
              .map((q) => q['name'] as String)
              .toList(),
        );
      }
      
      // Award XP and check for gamification rewards
      final performance = score / items.length;
      final isPerfect = performance >= 0.9;
      
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isPerfect ? 'perfect_score' : 'assessment_passed',
        metadata: {
          'module': 'sounds',
          'score': score,
          'total': items.length,
          'perfect': isPerfect,
        },
      );
      
      // End focus session
      await _focusSystem.endFocusSession(
        nickname: widget.nickname,
        moduleName: "Communication Skills",
        lessonType: "Sounds Assessment",
        completed: true,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  void _showResultDialog() {
    if (!mounted) return;
    _confettiController.play();
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    final performance = score / items.length;
    String title, message, emoji;
    Color titleColor;
    
    if (performance >= 0.9) {
      title = "SOUND EXPERT! 🔊";
      message = "Wow! You know all about loud and soft sounds! You're amazing!";
      emoji = "🌟🎵";
      titleColor = const Color(0xFFFFD700);
    } else if (performance >= 0.7) {
      title = "SOUND CHAMP! 🏆";
      message = "Great job with sounds! You're getting really good at listening!";
      emoji = "⭐🎶";
      titleColor = const Color(0xFF4CAF50);
    } else if (performance >= 0.5) {
      title = "SOUND HERO! 💪";
      message = "You're learning about sounds! Keep practicing and you'll be amazing!";
      emoji = "🎯🎼";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "KEEP LEARNING! 🌱";
      message = "Sounds are fun to learn! Try again and you'll do great!";
      emoji = "🌻🎪";
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
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
              child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height < 600 ? 16.0 : 24.0,
                      horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 20.0,
                    ),
                child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated celebration emojis
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 48 : MediaQuery.of(context).size.width < 600 ? 64 : 80,
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                    
                    // Main emoji with animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400 ? 72 : MediaQuery.of(context).size.width < 600 ? 96 : 120,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                    // Title with enhanced styling and animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                              vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  titleColor.withOpacity(0.8),
                                  titleColor.withOpacity(0.6),
                                  Colors.white.withOpacity(0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 25 : MediaQuery.of(context).size.width < 600 ? 35 : 45),
                              boxShadow: [
                                BoxShadow(
                                  color: titleColor.withOpacity(0.4),
                                  blurRadius: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width < 600 ? 16 : 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 24 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: MediaQuery.of(context).size.width < 400 ? 1.0 : MediaQuery.of(context).size.width < 600 ? 1.5 : 2.0,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 12 : 16),
                    // Kid-friendly message
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width < 600 ? 20 : 28,
                      ),
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 20 : 24,
                          color: const Color(0xFF4A4E69),
                        fontFamily: 'Poppins',
                          height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 12 : 16),
                    // Enhanced score display with animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 700),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 24 : 32,
                              vertical: MediaQuery.of(context).size.height < 600 ? 12 : 16,
                            ),
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
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 24 : 30),
                              border: Border.all(
                                color: Colors.blue.shade300,
                                width: MediaQuery.of(context).size.width < 400 ? 2 : MediaQuery.of(context).size.width < 600 ? 3 : 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: MediaQuery.of(context).size.width < 400 ? 6 : MediaQuery.of(context).size.width < 600 ? 10 : 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "🎯",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36,
                                  ),
                                ),
                                SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : MediaQuery.of(context).size.width < 600 ? 12 : 16),
                                Text(
                                  "Your Score: $score/${items.length}",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 18 : MediaQuery.of(context).size.width < 600 ? 24 : 30,
                                    color: Colors.blue.shade800,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withOpacity(0.8),
                                        offset: const Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
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
                    
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                    
                    // View My Answers button with animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _showAnswerSummaryModal();
                            },
                            icon: Icon(
                              Icons.quiz,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 26 : 32,
                            ),
                            label: Text(
                              "View My Answers",
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                      style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A4C93),
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width < 400 ? 24 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                                vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36),
                              ),
                              elevation: 8,
                              shadowColor: Colors.purple.withOpacity(0.4),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                    // Back to Learning button with animation
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: ElevatedButton(
                      onPressed: () {
                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => SoftLoudSoundsPage(nickname: widget.nickname)),
                              (Route<dynamic> route) => false);
                        }
                      },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C9FF),
                              padding: EdgeInsets.symmetric(
                                horizontal: MediaQuery.of(context).size.width < 400 ? 32 : MediaQuery.of(context).size.width < 600 ? 40 : 48,
                                vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36),
                              ),
                              elevation: 10,
                              shadowColor: Colors.cyan.withOpacity(0.5),
                            ),
                            child: Text(
                              "Back to Learning",
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 18 : MediaQuery.of(context).size.width < 600 ? 24 : 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
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
              ),
            ),
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
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                color: const Color(0xFF4A4E69),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  isCorrect ? "🎉" : "😔",
                                  style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Your Answer: ${item['userAnswer']}",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                      color: isCorrect
                                          ? Colors.green[800]
                                          : Colors.red[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isCorrect) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    "✅",
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Correct Answer: ${item['correctAnswer']}",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle : Icons.cancel,
                                  color: isCorrect ? Colors.green : Colors.red,
                                  size: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCorrect ? "Great Job! 🌟" : "Try Again! 💪",
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
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
              
              // Kid-friendly close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4E69),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "✨",
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Close",
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "✨",
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20),
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

  void _showSkipConfirmation() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "🤔",
              style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 30 : 40),
            ),
            const SizedBox(width: 12),
            Text(
              "Skip Assessment?",
          textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width < 400 ? 22 : 28,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
          "Are you sure you want to skip the assessment?",
          textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "🎯 You're doing great! Keep going!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                color: Colors.green.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
            onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Keep Playing! 🎮",
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => SoftLoudSoundsPage(nickname: widget.nickname)),
                    (Route<dynamic> route) => false);
              }
            },
                  child: Text(
                    "Skip 😔",
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmall = screenSize.width < 600;
    final itemSize = isSmall ? screenSize.width * 0.25 : screenSize.width * 0.15;

    return WillPopScope(
      onWillPop: () async {
        if (items.every((item) => item['position'] != -1)) return true;
        _showSkipConfirmation();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
        body: SafeArea(
          child: Stack(
            children: [
              // Kid-friendly close button in top right
              Positioned(
                top: 20,
                right: 20,
                child: GestureDetector(
                  onTap: _showSkipConfirmation,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.pink.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.red.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 60),
                  // Kid-friendly title with emoji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🎵",
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 30 : 40),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Sounds Assessment",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A4E69),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "🔊",
                        style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 30 : 40),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Drop Targets Row - moved to top
                  Container(
                    height: 160,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Loud
                      Expanded(
                        child: DragTarget<int>(
                          builder: (context, candidateData, rejectedData) => Container(
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.orange.shade300,
                                    Colors.yellow.shade200,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "🔊",
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 40 : 50),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "LOUD",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Sounds",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ),
                          onWillAcceptWithDetails: (details) {
                            final data = details.data;
                            return data >= 0 &&
                                data < items.length &&
                                  !lockedItems.contains(data);
                          },
                          onAcceptWithDetails: (details) => _onAccept(details.data, 'loud'),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Soft
                      Expanded(
                        child: DragTarget<int>(
                          builder: (context, candidateData, rejectedData) => Container(
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.cyan.shade300,
                                    Colors.teal.shade200,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.shade300,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "🔉",
                                    style: TextStyle(fontSize: MediaQuery.of(context).size.width < 400 ? 40 : 50),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "SOFT",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Sounds",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: const Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ),
                          onWillAcceptWithDetails: (details) {
                            final data = details.data;
                            return data >= 0 &&
                                data < items.length &&
                                  !lockedItems.contains(data);
                          },
                          onAcceptWithDetails: (details) => _onAccept(details.data, 'soft'),
                        ),
                      ),
                    ],
                  ),
                ),
                  const SizedBox(height: 20),
                  // Draggable Items Grid - moved to bottom
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isSmall ? 3 : 5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          
                          // Handle different states
                          if (item['position'] == -2) {
                            // Incorrectly answered item - show as locked with red border
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.red.shade400,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      item['image'],
                                      width: itemSize,
                                      height: itemSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Red overlay for incorrect
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: itemSize * 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (item['position'] == -3) {
                            // Correctly answered but no space - show as correct with green border
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.green.shade400,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      item['image'],
                                      width: itemSize,
                                      height: itemSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Green overlay for correct
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: itemSize * 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (item['position'] == -1) {
                            // Unanswered item - draggable
                            return Draggable<int>(
                              data: index,
                              feedback: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      item['image'],
                                      width: itemSize,
                                      height: itemSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.orange.shade300,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.asset(
                                    item['image'],
                                    width: itemSize,
                                    height: itemSize,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          } else {
                            // Correctly answered item - show as placed with green border
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.green.shade400,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset(
                                      item['image'],
                                      width: itemSize,
                                      height: itemSize,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Green overlay for correct
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: itemSize * 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
}
