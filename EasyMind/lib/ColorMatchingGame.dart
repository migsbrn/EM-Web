import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';
import 'visit_tracking_system.dart';
import 'responsive_utils.dart';

class ColorMatchingGame extends StatelessWidget {
  final String nickname;
  const ColorMatchingGame({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return ColorGameScreen(nickname: nickname);
  }
}

class ColorGameScreen extends StatefulWidget {
  final String nickname;
  const ColorGameScreen({super.key, required this.nickname});

  @override
  State<ColorGameScreen> createState() => _ColorGameScreenState();
}

class _ColorGameScreenState extends State<ColorGameScreen>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  late ConfettiController _confettiController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Game state
  int currentLevel = 0;
  int score = 0;
  int correctAnswers = 0;
  int totalQuestions = 0;
  bool gameCompleted = false;
  String? selectedColor;
  bool isAnswerCorrect = false;
  bool isDragDropMode = false; // New: Track if we're in drag-drop mode
  String? draggedColor; // New: Track which color is being dragged

  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  final GamificationSystem _gamificationSystem = GamificationSystem();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  GamificationResult? _lastReward;

  // Color data for the game
  final List<Map<String, dynamic>> colorLevels = [
    {
      'level': 1,
      'difficulty': 'beginner',
      'colors': [
        {'name': 'Red', 'color': Colors.red, 'emoji': '🔴', 'image': 'assets/red.png'},
        {'name': 'Blue', 'color': Colors.blue, 'emoji': '🔵', 'image': 'assets/blue.png'},
        {'name': 'Green', 'color': Colors.green, 'emoji': '🟢', 'image': 'assets/green.png'},
        {'name': 'Yellow', 'color': Colors.yellow, 'emoji': '🟡', 'image': 'assets/yellow.png'},
      ],
      'questions': [
        {'target': 'Red', 'options': ['Red', 'Blue', 'Green', 'Yellow'], 'correct': 0},
        {'target': 'Blue', 'options': ['Yellow', 'Blue', 'Red', 'Green'], 'correct': 1},
        {'target': 'Green', 'options': ['Green', 'Yellow', 'Blue', 'Red'], 'correct': 0},
        {'target': 'Yellow', 'options': ['Red', 'Green', 'Yellow', 'Blue'], 'correct': 2},
      ]
    },
    {
      'level': 2,
      'difficulty': 'intermediate',
      'colors': [
        {'name': 'Orange', 'color': Colors.orange, 'emoji': '🟠', 'image': 'assets/orange.png'},
        {'name': 'Purple', 'color': Colors.purple, 'emoji': '🟣', 'image': 'assets/purple.png'},
        {'name': 'Pink', 'color': Colors.pink, 'emoji': '🩷', 'image': 'assets/pink.png'},
        {'name': 'Brown', 'color': Colors.brown, 'emoji': '🤎', 'image': 'assets/brown.png'},
      ],
      'questions': [
        {'target': 'Orange', 'options': ['Orange', 'Purple', 'Pink', 'Brown'], 'correct': 0},
        {'target': 'Purple', 'options': ['Brown', 'Purple', 'Orange', 'Pink'], 'correct': 1},
        {'target': 'Pink', 'options': ['Pink', 'Brown', 'Purple', 'Orange'], 'correct': 0},
        {'target': 'Brown', 'options': ['Orange', 'Pink', 'Brown', 'Purple'], 'correct': 2},
      ]
    },
    {
      'level': 3,
      'difficulty': 'advanced',
      'colors': [
        {'name': 'Black', 'color': Colors.black, 'emoji': '⚫', 'image': 'assets/black.png'},
        {'name': 'White', 'color': Colors.white, 'emoji': '⚪', 'image': 'assets/white.png'},
        {'name': 'Gray', 'color': Colors.grey, 'emoji': '🔘', 'image': 'assets/gray.png'},
        {'name': 'Cyan', 'color': Colors.cyan, 'emoji': '🔵', 'image': 'assets/cyan.png'},
      ],
      'questions': [
        {'target': 'Black', 'options': ['Black', 'White', 'Gray', 'Cyan'], 'correct': 0},
        {'target': 'White', 'options': ['Gray', 'White', 'Black', 'Cyan'], 'correct': 1},
        {'target': 'Gray', 'options': ['Gray', 'Cyan', 'White', 'Black'], 'correct': 0},
        {'target': 'Cyan', 'options': ['Black', 'White', 'Cyan', 'Gray'], 'correct': 2},
      ]
    }
  ];

  int currentQuestionIndex = 0;
  Map<String, dynamic> currentLevelData = {};
  Map<String, dynamic>? currentQuestion;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut));
    
    _setupTTS();
    _initializeGame();
    _initializeAdaptiveMode();
    _trackVisit();
  }

  Future<void> _setupTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.6);
    await flutterTts.setPitch(1.2);
    await flutterTts.setVolume(1.0);
  }

  void _initializeGame() {
    setState(() {
      currentLevelData = colorLevels[currentLevel];
      currentQuestionIndex = 0;
      totalQuestions = currentLevelData['questions'].length;
      isDragDropMode = currentLevel > 0; // Enable drag-drop after level 1
      _loadNextQuestion();
    });
  }

  void _loadNextQuestion() {
    if (currentQuestionIndex < totalQuestions) {
      setState(() {
        currentQuestion = currentLevelData['questions'][currentQuestionIndex];
        selectedColor = null;
        draggedColor = null; // Reset drag state
      });
      _speakQuestion();
    } else {
      _completeLevel();
    }
  }

  Future<void> _speakQuestion() async {
    if (currentQuestion != null) {
      String instruction = isDragDropMode 
        ? "Drag the color ${currentQuestion!['target']} to the target area"
        : "Find the color ${currentQuestion!['target']}";
      await flutterTts.speak(instruction);
    }
  }

  void _selectColor(String colorName) {
    if (selectedColor != null || draggedColor != null) return; // Prevent multiple selections

    setState(() {
      selectedColor = colorName;
    });

    bool isCorrect = colorName == currentQuestion!['target'];
    
    if (isCorrect) {
      setState(() {
        isAnswerCorrect = true;
        correctAnswers++;
        score += 10;
      });
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
      _speakCorrectAnswer();
      
      // Move to next question after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          currentQuestionIndex++;
          _loadNextQuestion();
        }
      });
    } else {
      _speakWrongAnswer();
      // Allow retry after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            selectedColor = null;
          });
        }
      });
    }
  }

  void _onDragStart(String colorName) {
    if (selectedColor != null || draggedColor != null) return;
    setState(() {
      draggedColor = colorName;
    });
  }

  void _onDragEnd(String colorName) {
    if (draggedColor == null) return;
    
    setState(() {
      draggedColor = null;
    });
    
    // Check if dropped on target area
    _selectColor(colorName);
  }

  Future<void> _speakCorrectAnswer() async {
    await flutterTts.speak("Great job! That's ${currentQuestion!['target']}!");
  }

  Future<void> _speakWrongAnswer() async {
    await flutterTts.speak("Try again! Look for ${currentQuestion!['target']}!");
  }

  void _completeLevel() {
    if (currentLevel < colorLevels.length - 1) {
      // Move to next level
      setState(() {
        currentLevel++;
        currentQuestionIndex = 0;
      });
      _initializeGame();
    } else {
      // Game completed
      setState(() {
        gameCompleted = true;
      });
      _confettiController.play();
      _saveToAdaptiveAssessment();
      _saveToMemoryRetention();
      _awardGamificationRewards();
    }
  }

  void _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        // Set default difficulty for now
        print('Adaptive mode initialized for Color Matching Game');
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  Future<void> _trackVisit() async {
    try {
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: 'game',
        itemName: 'Color Matching Game',
        moduleName: 'Games',
      );
      print('Visit tracked for Color Matching Game');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  void _saveToAdaptiveAssessment() async {
    if (_useAdaptiveMode) {
      try {
        await AdaptiveAssessmentSystem.saveAssessmentResult(
          nickname: widget.nickname,
          assessmentType: 'Color Matching',
          moduleName: 'Color Recognition',
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          timeSpent: const Duration(minutes: 5),
          attemptedQuestions: List.generate(totalQuestions, (index) => 'Question ${index + 1}'),
          correctQuestions: List.generate(correctAnswers, (index) => 'Question ${index + 1}'),
        );
      } catch (e) {
        print('Error saving to adaptive assessment: $e');
      }
    }
  }

  void _saveToMemoryRetention() async {
    try {
      final system = MemoryRetentionSystem();
      await system.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: 'Color Recognition',
        lessonType: 'Color Matching Game',
        score: score,
        totalQuestions: totalQuestions,
        passed: correctAnswers >= (totalQuestions * 0.7), // 70% pass rate
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  void _awardGamificationRewards() async {
    try {
      // Calculate performance and determine reward type
      final performance = correctAnswers / totalQuestions;
      String activity;
      
      if (performance >= 0.9) {
        activity = 'perfect_color_matching';
      } else if (performance >= 0.7) {
        activity = 'good_color_matching';
      } else {
        activity = 'color_matching_practice';
      }
      
      final result = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: activity,
        metadata: {
          'score': score,
          'correctAnswers': correctAnswers,
          'totalQuestions': totalQuestions,
          'performance': performance,
          'level': currentLevel + 1,
        },
      );
      setState(() {
        _lastReward = result;
      });
    } catch (e) {
      print('Error awarding gamification rewards: $e');
    }
  }

  void _restartGame() {
    setState(() {
      currentLevel = 0;
      score = 0;
      correctAnswers = 0;
      totalQuestions = 0;
      gameCompleted = false;
      selectedColor = null;
      isAnswerCorrect = false;
      isDragDropMode = false;
      draggedColor = null;
    });
    _initializeGame();
  }

  @override
  void dispose() {
    flutterTts.stop();
    _confettiController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (gameCompleted) {
      return _buildCompletionScreen(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildMobileLayout(context),
          tablet: _buildTabletLayout(context),
          desktop: _buildDesktopLayout(context),
          largeDesktop: _buildLargeDesktopLayout(context),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          _buildHeader(context),
          ResponsiveSpacing(mobileSpacing: 10),
          _buildQuestion(context),
          ResponsiveSpacing(mobileSpacing: 15),
          _buildProgressIndicator(context),
          ResponsiveSpacing(mobileSpacing: 15),
          Expanded(
            child: _buildColorOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          _buildHeader(context),
          ResponsiveSpacing(mobileSpacing: 15),
          _buildQuestion(context),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildProgressIndicator(context),
          ResponsiveSpacing(mobileSpacing: 20),
          Expanded(
            child: _buildColorOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          _buildHeader(context),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildQuestion(context),
          ResponsiveSpacing(mobileSpacing: 25),
          _buildProgressIndicator(context),
          ResponsiveSpacing(mobileSpacing: 25),
          Expanded(
            child: _buildColorOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        children: [
          _buildHeader(context),
          ResponsiveSpacing(mobileSpacing: 25),
          _buildQuestion(context),
          ResponsiveSpacing(mobileSpacing: 30),
          _buildProgressIndicator(context),
          ResponsiveSpacing(mobileSpacing: 30),
          Expanded(
            child: _buildColorOptions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        ElevatedButton(
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
            backgroundColor: const Color(0xFF6B73FF),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
              horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
              ),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF6B73FF).withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveIcon(
                Icons.arrow_back,
                color: Colors.white,
                mobileSize: 18,
                tabletSize: 20,
                desktopSize: 22,
                largeDesktopSize: 24,
              ),
              ResponsiveSpacing(mobileSpacing: 8, isVertical: false),
              ResponsiveText(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                largeDesktopFontSize: 20,
              ),
            ],
          ),
        ),
        
        // Level indicator
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
            vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B59B6), Color(0xFFE74C3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveIcon(
                Icons.star,
                color: Colors.white,
                mobileSize: 18,
                tabletSize: 20,
                desktopSize: 22,
                largeDesktopSize: 24,
              ),
              ResponsiveSpacing(mobileSpacing: 8, isVertical: false),
              ResponsiveText(
                'Level ${currentLevel + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                mobileFontSize: 14,
                tabletFontSize: 16,
                desktopFontSize: 18,
                largeDesktopFontSize: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF9B59B6).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '📊 Progress',
                style: TextStyle(
                  fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 20, // Increased from 16/20
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(
                '${currentQuestionIndex + 1} / $totalQuestions',
                style: TextStyle(
                  fontSize: ResponsiveUtils.isSmallScreen(context) ? 14 : 16, // Increased from 12/14
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: currentQuestionIndex / totalQuestions,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
            minHeight: ResponsiveUtils.isSmallScreen(context) ? 8 : 10, // Increased from 6/8
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context) {
    if (currentQuestion == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 15 : 20), // Reduced padding
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20), // More rounded
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6B73FF).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            isDragDropMode ? '🎯 Drag the color to the shape:' : '🔍 Find the color:',
            style: TextStyle(
              fontSize: ResponsiveUtils.isSmallScreen(context) ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 20),
          
          // Show target shape for drag-drop mode
          if (isDragDropMode) ...[
            DragTarget<String>(
              onWillAccept: (data) => data == currentQuestion!['target'],
              onAccept: (data) {
                if (data == currentQuestion!['target']) {
                  _selectColor(data);
                }
              },
              builder: (context, candidateData, rejectedData) {
                final isAccepting = candidateData.isNotEmpty && candidateData.first == currentQuestion!['target'];
                final isRejecting = rejectedData.isNotEmpty;
                
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: ResponsiveUtils.isSmallScreen(context) ? 80 : 100,
                  height: ResponsiveUtils.isSmallScreen(context) ? 80 : 100,
                  decoration: BoxDecoration(
                    color: _getColorByName(currentQuestion!['target']),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAccepting 
                          ? Colors.green 
                          : isRejecting 
                              ? Colors.red 
                              : Colors.white,
                      width: isAccepting || isRejecting ? 6 : 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isAccepting 
                            ? Colors.green.withOpacity(0.5)
                            : isRejecting 
                                ? Colors.red.withOpacity(0.5)
                                : Colors.black.withOpacity(0.3),
                        spreadRadius: isAccepting || isRejecting ? 3 : 2,
                        blurRadius: isAccepting || isRejecting ? 12 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: isAccepting 
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        )
                      : isRejecting
                          ? const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 40,
                            )
                          : null,
                );
              },
            ),
            const SizedBox(height: 15),
          ] else ...[
            // Show text for tap mode
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isAnswerCorrect ? _bounceAnimation.value : 1.0,
                  child: Text(
                    currentQuestion!['target'],
                    style: TextStyle(
                      fontSize: ResponsiveUtils.isSmallScreen(context) ? 36 : 44,
                      fontWeight: FontWeight.bold,
                      color: _getColorByName(currentQuestion!['target']),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
          
          IconButton(
            onPressed: _speakQuestion,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6B73FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFF6B73FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.volume_up,
                size: ResponsiveUtils.isSmallScreen(context) ? 36 : 44,
                color: const Color(0xFF6B73FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOptions(BuildContext context) {
    if (currentQuestion == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Color options grid
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: ResponsiveUtils.isSmallScreen(context) ? 15 : 20, // Reduced from 20/25 to 15/20
              mainAxisSpacing: ResponsiveUtils.isSmallScreen(context) ? 15 : 20, // Reduced from 20/25 to 15/20
              childAspectRatio: 1.0,
            ),
            itemCount: currentQuestion!['options'].length,
            itemBuilder: (context, index) {
              final colorName = currentQuestion!['options'][index];
              final isSelected = selectedColor == colorName;
              final isCorrect = colorName == currentQuestion!['target'];
              
              Widget colorShape = Container(
                width: ResponsiveUtils.isSmallScreen(context) ? 70 : 80, // Same size as target
                height: ResponsiveUtils.isSmallScreen(context) ? 70 : 80, // Same size as target
                decoration: BoxDecoration(
                  color: _getColorByName(colorName),
                  borderRadius: BorderRadius.circular(20), // Same rounded corners as target
                  border: Border.all(
                    color: Colors.white,
                    width: 4, // Same border width as target
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              );

              if (isDragDropMode) {
                return Draggable<String>(
                  data: colorName,
                  onDragStarted: () => _onDragStart(colorName),
                  onDragEnd: (_) => _onDragEnd(colorName),
                  feedback: Transform.scale(
                    scale: 1.2,
                    child: Container(
                      width: ResponsiveUtils.isSmallScreen(context) ? 70 : 80,
                      height: ResponsiveUtils.isSmallScreen(context) ? 70 : 80,
                      decoration: BoxDecoration(
                        color: _getColorByName(colorName),
                        borderRadius: BorderRadius.circular(20), // Same rounded corners as target
                        border: Border.all(
                          color: Colors.white,
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            spreadRadius: 3,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Container(
                    width: ResponsiveUtils.isSmallScreen(context) ? 70 : 80,
                    height: ResponsiveUtils.isSmallScreen(context) ? 70 : 80,
                    decoration: BoxDecoration(
                      color: _getColorByName(colorName).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20), // Same rounded corners as target
                      border: Border.all(
                        color: Colors.grey,
                        width: 4,
                        style: BorderStyle.solid,
                      ),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      // Show helpful message for drag-drop mode
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.info, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Drag the color to the target shape!'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF6B73FF),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15), // Reduced from 20 to 15
                        border: Border.all(
                          color: isSelected 
                            ? (isCorrect ? Colors.green : Colors.red)
                            : const Color(0xFF648BA2),
                          width: isSelected ? 4 : 2, // Reduced from 5/3 to 4/2
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                              ? (isCorrect ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4))
                              : Colors.black.withOpacity(0.15),
                            spreadRadius: isSelected ? 2 : 1, // Reduced from 3/2 to 2/1
                            blurRadius: isSelected ? 8 : 6, // Reduced from 12/8 to 8/6
                            offset: const Offset(0, 2), // Reduced from 3 to 2
                          ),
                        ],
                      ),
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 8 : 12), // Added padding to make containers smaller
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          colorShape,
                          const SizedBox(height: 8), // Reduced from 10 to 8
                          if (isSelected) ...[
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: ResponsiveUtils.isSmallScreen(context) ? 20 : 24, // Further reduced from 24/28 to 20/24
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  )
                );
              } else {
                return GestureDetector(
                  onTap: () => _selectColor(colorName),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15), // Reduced from 20 to 15
                      border: Border.all(
                        color: isSelected 
                          ? (isCorrect ? Colors.green : Colors.red)
                          : const Color(0xFF648BA2),
                        width: isSelected ? 4 : 2, // Reduced from 5/3 to 4/2
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                            ? (isCorrect ? Colors.green.withOpacity(0.4) : Colors.red.withOpacity(0.4))
                            : Colors.black.withOpacity(0.15),
                          spreadRadius: isSelected ? 2 : 1, // Reduced from 3/2 to 2/1
                          blurRadius: isSelected ? 8 : 6, // Reduced from 12/8 to 8/6
                          offset: const Offset(0, 2), // Reduced from 3 to 2
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 8 : 12), // Added padding to make containers smaller
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          colorShape,
                          const SizedBox(height: 8), // Reduced from 10 to 8
                          if (isSelected) ...[
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect ? Colors.green : Colors.red,
                              size: ResponsiveUtils.isSmallScreen(context) ? 20 : 24, // Further reduced from 24/28 to 20/24
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF), // Match main screen background
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Confetti
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.orange,
                Colors.purple,
                Colors.pink,
              ],
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 20 : 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebration icon
                  Icon(
                    Icons.celebration,
                    size: ResponsiveUtils.isSmallScreen(context) ? 80 : 100,
                    color: Colors.amber,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    '🎉 Congratulations! 🎉',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.isSmallScreen(context) ? 28 : 36,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message
                  Text(
                    'You completed all color levels!',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.isSmallScreen(context) ? 18 : 22,
                      color: const Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Final score
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 20 : 30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B73FF).withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF6B73FF).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🏆 Final Results 🏆',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.isSmallScreen(context) ? 22 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Score breakdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildCompletionScoreItem(
                              'Score',
                              '$score',
                              Icons.star,
                              const Color(0xFF6B73FF),
                              context,
                            ),
                            _buildCompletionScoreItem(
                              'Correct',
                              '$correctAnswers/$totalQuestions',
                              Icons.check_circle,
                              const Color(0xFF4CAF50),
                              context,
                            ),
                            _buildCompletionScoreItem(
                              'Level',
                              '${currentLevel + 1}',
                              Icons.trending_up,
                              const Color(0xFF9B59B6),
                              context,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Performance message
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _getPerformanceColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: _getPerformanceColor().withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getPerformanceIcon(),
                                color: _getPerformanceColor(),
                                size: ResponsiveUtils.isSmallScreen(context) ? 24 : 28,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  _getPerformanceMessage(),
                                  style: TextStyle(
                                    fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: _getPerformanceColor(),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Gamification reward
                  if (_lastReward != null) ...[
                    Container(
                      padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 15 : 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A4E69),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🏆 Rewards Earned! 🏆',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.isSmallScreen(context) ? 18 : 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${_lastReward!.xpAwarded} XP gained!',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 18,
                              color: Colors.white,
                            ),
                          ),
                          if (_lastReward!.leveledUp) ...[
                            const SizedBox(height: 5),
                            Text(
                              'Level Up! 🎉',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF648BA2),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.08,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Play Again',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      ElevatedButton(
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
                          backgroundColor: const Color(0xFF4A4E69),
                          padding: EdgeInsets.symmetric(
                            horizontal: MediaQuery.of(context).size.width * 0.08,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Back to Games',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScoreItem(String label, String value, IconData icon, Color color, BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: ResponsiveUtils.isSmallScreen(context) ? 20 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.isSmallScreen(context) ? 12 : 14,
            color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveUtils.isSmallScreen(context) ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor() {
    final performance = correctAnswers / totalQuestions;
    if (performance >= 0.9) return const Color(0xFF4CAF50); // Green
    if (performance >= 0.7) return const Color(0xFF2196F3); // Blue
    if (performance >= 0.5) return const Color(0xFFFF9800); // Orange
    return const Color(0xFFF44336); // Red
  }

  IconData _getPerformanceIcon() {
    final performance = correctAnswers / totalQuestions;
    if (performance >= 0.9) return Icons.star;
    if (performance >= 0.7) return Icons.thumb_up;
    if (performance >= 0.5) return Icons.sentiment_satisfied;
    return Icons.sentiment_dissatisfied;
  }

  String _getPerformanceMessage() {
    final performance = correctAnswers / totalQuestions;
    if (performance >= 0.9) return 'Outstanding! You\'re a color expert! 🌟';
    if (performance >= 0.7) return 'Great job! You did really well! 👍';
    if (performance >= 0.5) return 'Good effort! Keep practicing! 😊';
    return 'Nice try! Practice makes perfect! 💪';
  }

  Color _getColorByName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'orange': return Colors.orange;
      case 'purple': return Colors.purple;
      case 'pink': return Colors.pink;
      case 'brown': return Colors.brown;
      case 'black': return Colors.black;
      case 'white': return Colors.white;
      case 'gray': return Colors.grey;
      case 'cyan': return Colors.cyan;
      default: return Colors.grey;
    }
  }
}
