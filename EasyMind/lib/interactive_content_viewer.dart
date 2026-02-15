import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'responsive_utils.dart';
import 'gamification_system.dart';
import 'memory_retention_system.dart';
import 'adaptive_assessment_system.dart';
import 'visit_tracking_system.dart';

/// Interactive Content Viewer - Displays teacher-uploaded content as interactive experiences
class InteractiveContentViewer extends StatefulWidget {
  final String nickname;
  final String contentId;
  final Map<String, dynamic> contentData;

  const InteractiveContentViewer({
    super.key,
    required this.nickname,
    required this.contentId,
    required this.contentData,
  });

  @override
  State<InteractiveContentViewer> createState() => _InteractiveContentViewerState();
}

class _InteractiveContentViewerState extends State<InteractiveContentViewer>
    with TickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  final GamificationSystem _gamificationSystem = GamificationSystem();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bounceController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bounceAnimation;

  int currentSection = 0;
  int score = 0;
  bool isCompleted = false;
  
  // Interactive assessment state
  Map<int, String> _selectedAnswers = {};
  Map<int, bool> _showResults = {};
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  List<String> achievements = [];
  
  // Lesson completion tracking
  Set<int> _completedLessonItems = {};
  bool _lessonCompleted = false;
  
  // General settings
  int _timeLimit = 300; // 5 minutes
  int _pointsPerQuestion = 10;
  int _perfectBonus = 50;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupTts();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initializeGeneralSettings();
    _initializeGamificationSystem();
    _checkAssessmentCompletion();
    _trackVisit();
  }
  
  /// Initialize the gamification system
  Future<void> _initializeGamificationSystem() async {
    try {
      await _gamificationSystem.initialize();
      print('DEBUG: Gamification system initialized successfully');
    } catch (e) {
      print('ERROR: Failed to initialize gamification system: $e');
    }
  }

  void _initializeGeneralSettings() {
    // Set general settings for all content
    _timeLimit = 300; // 5 minutes
    _pointsPerQuestion = 10;
    _perfectBonus = 50;
    
    print('DEBUG: General settings initialized - Time Limit: $_timeLimit, Points: $_pointsPerQuestion');
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _setupTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.2);
    await flutterTts.setSpeechRate(0.7);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    flutterTts.stop();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildSimpleHeader(context),
            Expanded(
              child: _buildSimpleContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF648BA2), const Color(0xFF3C7E71)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contentData['title'] ?? 'Interactive Content',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _getContentTypeDisplay(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Score: $score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleContent(BuildContext context) {
    print('DEBUG: _buildSimpleContent called');
    
    final contentType = widget.contentData['type'];
    print('DEBUG: Content type: $contentType');
    
    switch (contentType) {
      case 'interactive-lesson':
      case 'lesson':
        return _buildSimpleLesson(context);
      case 'interactive-assessment':
      case 'assessment':
        return _buildSimpleAssessment(context);
      case 'game-activity':
      case 'game':
        return _buildSimpleGame(context);
      case 'activity':
        return _buildSimpleActivity(context);
      default:
        return _buildSimpleFallback(context);
    }
  }

  Widget _buildSimpleLesson(BuildContext context) {
    print('DEBUG: Building simple lesson');
    
    final lesson = widget.contentData['lessonData'];
    if (lesson == null) {
      print('DEBUG: No lesson data found');
      return _buildSimpleFallback(context);
    }

    final items = lesson['items'] as List<dynamic>? ?? [];
    print('DEBUG: Found ${items.length} lesson items');

    if (items.isEmpty) {
      return _buildSimpleFallback(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introduction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.school,
                  color: Color(0xFF648BA2),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Let\'s Learn!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap on each item to explore and learn',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Lesson Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSimpleLessonItem(context, item, index),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSimpleLessonItem(BuildContext context, Map<String, dynamic> item, int index) {
    return GestureDetector(
      onTap: () {
        print('DEBUG: Tapped lesson item: ${item['name']}');
        // Play TTS if available
        if (item['ttsText'] != null) {
          flutterTts.speak(item['ttsText']);
        }
        // Add score
        setState(() {
          score += 10;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Item number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Color swatch if available
            if (item['color'] != null) ...[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(item['color']),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(width: 16),
            ],
            
            // Item content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Item ${index + 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                  if (item['description'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  if (item['imageUrl'] != null || item['image'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildQuestionImageWidget(item['imageUrl'] ?? item['image']),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // TTS indicator
            if (item['ttsText'] != null)
              const Icon(
                Icons.volume_up,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleAssessment(BuildContext context) {
    print('DEBUG: Building simple assessment');
    
    final assessment = widget.contentData['assessmentData'] ?? widget.contentData['questions'];
    if (assessment == null) {
      print('DEBUG: No assessment data found');
      return _buildSimpleFallback(context);
    }

    List<dynamic> questions = [];
    if (assessment is Map<String, dynamic>) {
      questions = assessment['questions'] as List<dynamic>? ?? [];
    } else if (assessment is List) {
      questions = assessment;
    }

    print('DEBUG: Found ${questions.length} questions');

    if (questions.isEmpty) {
      return _buildSimpleFallback(context);
    }

    // Initialize assessment state
    _totalQuestions = questions.length;
    _correctAnswers = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introduction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.quiz,
                  color: Color(0xFF648BA2),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Assessment Time!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer the questions below',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Questions
          ...questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value as Map<String, dynamic>;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildSimpleQuestion(context, question, index),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build image widget for question images
  Widget _buildQuestionImageWidget(String imageData) {
    // Check if it's a base64 image (starts with data:image)
    if (imageData.startsWith('data:image/')) {
      return Image.memory(
        base64Decode(imageData.split(',')[1]), // Remove the data:image/...;base64, prefix
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    } else {
      // It's an asset image or URL
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorWidget();
          },
        );
      } else {
        return Image.asset(
          imageData,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildImageErrorWidget();
          },
        );
      }
    }
  }

  /// Build error widget for failed image loads
  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleQuestion(BuildContext context, Map<String, dynamic> question, int index) {
    print('DEBUG: Building question $index: $question');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question['question'] ?? question['questionText'] ?? 'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Question Image (if available)
          if (question['questionImage'] != null || question['image'] != null) ...[
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildQuestionImageWidget(question['questionImage'] ?? question['image']),
              ),
            ),
          ],
          
          // Interactive Options - Kids can tap to select
          if (question['options'] != null) ...[
            ...(question['options'] as List<dynamic>).asMap().entries.map((entry) {
              final optIndex = entry.key;
              final optionValue = entry.value;
              
              // Handle both string and object options
              String option;
              if (optionValue is String) {
                option = optionValue;
              } else if (optionValue is Map<String, dynamic>) {
                // Extract the name from the object
                option = optionValue['name']?.toString() ?? 'Unknown';
              } else {
                option = optionValue.toString();
              }
              
              final correctAnswer = question['correctAnswer'];
              final isCorrect = option == correctAnswer;
              final isSelected = _selectedAnswers[index] == option;
              final showResult = _showResults[index] ?? false;
              
              print('DEBUG: Option $optIndex: "$option" vs Correct: "$correctAnswer" (Correct: $isCorrect)');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    print('DEBUG: Student tapped option $optIndex: "$option" for question $index');
                    _onAnswerSelected(context, index, option, isCorrect);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getOptionColor(isSelected, isCorrect, showResult),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getOptionBorderColor(isSelected, isCorrect, showResult),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Option letter (A, B, C, D)
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _getOptionLetterColor(isSelected, isCorrect, showResult),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              String.fromCharCode(65 + optIndex), // A, B, C, D
                              style: TextStyle(
                                color: _getOptionLetterTextColor(isSelected, isCorrect, showResult),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option.isNotEmpty ? option : 'Option ${optIndex + 1}',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87, // Force visible color for debugging
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        // Result indicator
                        if (showResult && isSelected) ...[
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? Colors.green : Colors.red,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
          
          // Explanation - Only show after answer is selected
          if (question['explanation'] != null && (_showResults[index] ?? false)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1976D2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Color(0xFF1976D2),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question['explanation'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1976D2),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleGame(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.games,
              color: Color(0xFF648BA2),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Game Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4E69),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Game functionality coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleActivity(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              color: Color(0xFF648BA2),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Activity Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4E69),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Activity functionality coming soon!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFallback(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school,
              color: Color(0xFF648BA2),
              size: 64,
            ),
            const SizedBox(height: 20),
            const Text(
              'Interactive Learning Content',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4E69),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Content is being prepared...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Assessment Helper Functions
  void _onAnswerSelected(BuildContext context, int questionIndex, String selectedAnswer, bool isCorrect) {
    print('DEBUG: Answer selected - Q${questionIndex + 1}: $selectedAnswer (Correct: $isCorrect)');
    
    // Prevent multiple answers for the same question
    if (_selectedAnswers.containsKey(questionIndex)) {
      print('DEBUG: Question $questionIndex already answered, ignoring');
      return;
    }
    
    // Double-check the correct answer by looking up the question data
    dynamic assessmentData = widget.contentData['assessmentData'] ?? widget.contentData['questions'];
    List<dynamic> questions = [];
    
    if (assessmentData is Map<String, dynamic> && assessmentData['questions'] != null) {
      questions = assessmentData['questions'] as List<dynamic>;
    } else if (assessmentData is List) {
      questions = assessmentData;
    }
    
    print('DEBUG: Found ${questions.length} questions in assessment data');
    
    if (questionIndex < questions.length) {
      final question = questions[questionIndex];
      final correctAnswer = question['correctAnswer'];
      final actualIsCorrect = selectedAnswer == correctAnswer;
      
      print('DEBUG: Verification - Selected: "$selectedAnswer", Correct: "$correctAnswer", Actually Correct: $actualIsCorrect');
      print('DEBUG: Question data: $question');
      
      setState(() {
        _selectedAnswers[questionIndex] = selectedAnswer;
        _showResults[questionIndex] = true;
        
        if (actualIsCorrect) {
          _correctAnswers++;
          score += _pointsPerQuestion; // Points per correct answer
          
          print('DEBUG: CORRECT ANSWER! _correctAnswers incremented to: $_correctAnswers');
          
          // Play success sound (handle missing file gracefully)
          try {
            audioPlayer.play(AssetSource('sound/success.mp3'));
          } catch (e) {
            print('DEBUG: Success sound not available: $e');
            // Use existing sound as fallback
            try {
              audioPlayer.play(AssetSource('sound/dog_bark.mp3'));
            } catch (e2) {
              print('DEBUG: Fallback sound also not available: $e2');
            }
          }
          
          // Speak success message
          flutterTts.speak("Great job! That's correct!");
        } else {
          print('DEBUG: INCORRECT ANSWER! _correctAnswers remains: $_correctAnswers');
          
          // Play error sound (handle missing file gracefully)
          try {
            audioPlayer.play(AssetSource('sound/error.mp3'));
          } catch (e) {
            print('DEBUG: Error sound not available: $e');
            // Use existing sound as fallback
            try {
              audioPlayer.play(AssetSource('sound/bark1.mp3'));
            } catch (e2) {
              print('DEBUG: Fallback sound also not available: $e2');
            }
          }
          
          // Speak encouragement
          flutterTts.speak("Good try! Let's learn from this.");
        }
      });
    } else {
      print('ERROR: Question index $questionIndex out of bounds (${questions.length} questions)');
    }
    
    // Check if all questions are answered
    print('DEBUG: Checking completion - Selected answers: ${_selectedAnswers.length}, Total questions: $_totalQuestions');
    if (_selectedAnswers.length == _totalQuestions) {
      print('DEBUG: All questions answered, showing completion dialog');
      _showAssessmentComplete(context);
    } else {
      print('DEBUG: Not all questions answered yet - ${_selectedAnswers.length}/$_totalQuestions');
    }
  }

  void _showAssessmentComplete(BuildContext context) {
    // Recalculate correct answers to ensure accuracy
    int actualCorrectAnswers = 0;
    
    // Try different data structures for assessment data
    dynamic assessmentData = widget.contentData['assessmentData'] ?? widget.contentData['questions'];
    List<dynamic> questions = [];
    
    if (assessmentData is Map<String, dynamic> && assessmentData['questions'] != null) {
      questions = assessmentData['questions'] as List<dynamic>;
    } else if (assessmentData is List) {
      questions = assessmentData;
    }
    
    print('DEBUG: Assessment completion - Total questions: $_totalQuestions, Questions found: ${questions.length}');
    print('DEBUG: Selected answers map: $_selectedAnswers');
    print('DEBUG: Current _correctAnswers count: $_correctAnswers');
    print('DEBUG: Assessment data structure: $assessmentData');
    
    for (int i = 0; i < _totalQuestions && i < questions.length; i++) {
      if (_selectedAnswers.containsKey(i)) {
        final question = questions[i];
        final correctAnswer = question['correctAnswer'];
        final selectedAnswer = _selectedAnswers[i];
        
        print('DEBUG: Question $i - Selected: "$selectedAnswer", Correct: "$correctAnswer"');
        print('DEBUG: Question $i data: $question');
        
        if (selectedAnswer == correctAnswer) {
          actualCorrectAnswers++;
          print('DEBUG: Question $i - CORRECT! (Total correct so far: $actualCorrectAnswers)');
        } else {
          print('DEBUG: Question $i - INCORRECT');
        }
      } else {
        print('DEBUG: Question $i - NO ANSWER SELECTED');
      }
    }
    
    // Update the correct answers count
    _correctAnswers = actualCorrectAnswers;
    
    // Recalculate score based on actual correct answers
    score = actualCorrectAnswers * _pointsPerQuestion;
    
    final percentage = (actualCorrectAnswers / _totalQuestions * 100).round();
    
    // Add perfect score bonus if all questions are correct
    if (actualCorrectAnswers == _totalQuestions && _totalQuestions > 0) {
      score += _perfectBonus;
      print('DEBUG: Perfect score bonus added: $_perfectBonus points');
    }
    
    print('DEBUG: Assessment completed - Correct: $actualCorrectAnswers/$_totalQuestions, Score: $score, Percentage: $percentage%');
    print('DEBUG: Final _correctAnswers: $_correctAnswers');
    
    // Save using CONSISTENT pattern like all other assessments/games
    _saveAssessmentDataConsistently(percentage, score);
    
    // Mark assessment as completed to prevent retaking
    _markAssessmentAsCompleted();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                percentage >= 70 ? Icons.celebration : Icons.school,
                color: percentage >= 70 ? Colors.green : Colors.orange,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                percentage >= 70 ? 'Excellent!' : 'Good Job!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 70 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Score Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: percentage >= 70 ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: percentage >= 70 ? Colors.green.shade200 : Colors.orange.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Assessment Complete! 🎯',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 70 ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You got $_correctAnswers out of $_totalQuestions questions correct!',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Score: $percentage%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: percentage >= 70 ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Points and XP Breakdown
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Points Earned:', style: TextStyle(fontSize: 14)),
                        Text('$score', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('XP Gained:', style: TextStyle(fontSize: 14)),
                        Text('${(score / 10).round()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    if (actualCorrectAnswers == _totalQuestions && _totalQuestions > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Perfect Score Bonus:', style: TextStyle(fontSize: 14)),
                          Text('+$_perfectBonus', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Completion Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.purple.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assessment marked as completed! ✅',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                percentage >= 70 
                  ? '🎉 Amazing work! You\'re doing great!'
                  : '📚 Keep practicing! You\'re learning!',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to materials page
              },
              child: const Text(
                'Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    
    // Speak completion message
    if (percentage >= 70) {
      flutterTts.speak("Excellent work! You completed the assessment with a great score!");
    } else {
      flutterTts.speak("Good job completing the assessment! Keep practicing!");
    }
  }

  Color _getOptionColor(bool isSelected, bool isCorrect, bool showResult) {
    if (!showResult) {
      return isSelected ? const Color(0xFFE3F2FD) : Colors.grey.shade50;
    } else {
      if (isSelected) {
        return isCorrect ? const Color(0xFFE8F5E8) : const Color(0xFFFFEBEE);
      } else if (isCorrect) {
        return const Color(0xFFE8F5E8);
      } else {
        return Colors.grey.shade50;
      }
    }
  }

  Color _getOptionBorderColor(bool isSelected, bool isCorrect, bool showResult) {
    if (!showResult) {
      return isSelected ? const Color(0xFF1976D2) : Colors.grey.shade300;
    } else {
      if (isSelected) {
        return isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
      } else if (isCorrect) {
        return const Color(0xFF4CAF50);
      } else {
        return Colors.grey.shade300;
      }
    }
  }

  Color _getOptionLetterColor(bool isSelected, bool isCorrect, bool showResult) {
    if (!showResult) {
      return isSelected ? const Color(0xFF1976D2) : Colors.grey.shade400;
    } else {
      if (isSelected) {
        return isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
      } else if (isCorrect) {
        return const Color(0xFF4CAF50);
      } else {
        return Colors.grey.shade400;
      }
    }
  }

  Color _getOptionLetterTextColor(bool isSelected, bool isCorrect, bool showResult) {
    if (!showResult) {
      return isSelected ? Colors.white : Colors.grey.shade600;
    } else {
      if (isSelected) {
        return isCorrect ? Colors.white : Colors.white;
      } else if (isCorrect) {
        return Colors.white;
      } else {
        return Colors.grey.shade600;
      }
    }
  }



  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSpacing(context, mobile: 8)),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 8),
          ),
        ),
        child: ResponsiveIcon(
          Icons.arrow_back,
          color: Colors.white,
          mobileSize: 20,
          tabletSize: 22,
          desktopSize: 24,
          largeDesktopSize: 26,
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
        vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveIcon(
            Icons.star,
            color: Colors.amber,
            mobileSize: 16,
            tabletSize: 18,
            desktopSize: 20,
            largeDesktopSize: 22,
          ),
          ResponsiveSpacing(mobileSpacing: 4, isVertical: false),
          ResponsiveText(
            '$score',
            style: const TextStyle(
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
    );
  }


  Widget _buildContentByType(BuildContext context) {
    final contentType = widget.contentData['type'];
    
    print('DEBUG: Content type: $contentType');
    print('DEBUG: Content data keys: ${widget.contentData.keys}');
    
    switch (contentType) {
      case 'interactive-lesson':
      case 'lesson':
        return _buildInteractiveLesson(context);
      case 'game-activity':
      case 'game':
        return _buildGameActivity(context);
      case 'interactive-assessment':
      case 'assessment':
        return _buildInteractiveAssessment(context);
      case 'activity':
        return _buildActivity(context);
      default:
        print('DEBUG: Using fallback content for type: $contentType');
        return _buildFallbackContent(context);
    }
  }

  Widget _buildInteractiveLesson(BuildContext context) {
    // Try both old and new data structures
    final lesson = widget.contentData['components']?['lesson'] ?? widget.contentData['lessonData'];
    if (lesson == null) {
      print('DEBUG: No lesson data found');
      print('DEBUG: contentData keys: ${widget.contentData.keys}');
      return _buildFallbackContent(context);
    }

    print('DEBUG: Lesson data found: $lesson');

    final content = SingleChildScrollView(
      child: Column(
        children: [
          _buildLessonIntroduction(context, lesson),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildLessonSections(context, lesson),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildLessonProgress(context, lesson),
        ],
      ),
    );
    
    print('DEBUG: Returning lesson content widget');
    return content;
  }

  Widget _buildLessonIntroduction(BuildContext context, Map<String, dynamic> lesson) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveText(
            lesson['title'] ?? 'Interactive Lesson',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
            largeDesktopFontSize: 26,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(mobileSpacing: 12),
          ResponsiveText(
            lesson['introduction'] ?? 'Welcome to this interactive lesson!',
            style: const TextStyle(
              color: Color(0xFF666),
            ),
            mobileFontSize: 16,
            tabletFontSize: 18,
            desktopFontSize: 20,
            largeDesktopFontSize: 22,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSections(BuildContext context, Map<String, dynamic> lesson) {
    // Try both old sections structure and new items structure
    final sections = lesson['sections'] as List<dynamic>? ?? [];
    final items = lesson['items'] as List<dynamic>? ?? [];
    
    print('DEBUG: Lesson sections: $sections');
    print('DEBUG: Lesson items: $items');
    
    if (sections.isEmpty && items.isEmpty) {
      print('DEBUG: No sections or items found, showing sample content');
      return _buildSampleContent(context);
    }

    // Use items if available, otherwise use sections
    final contentList = items.isNotEmpty ? items : sections;
    print('DEBUG: Using content list: $contentList');
    
    return Column(
      children: contentList.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value as Map<String, dynamic>;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
          ),
          child: _buildLessonItemCard(context, item, index),
        );
      }).toList(),
    );
  }

  Widget _buildLessonItemCard(BuildContext context, Map<String, dynamic> item, int index) {
    print('DEBUG: Building lesson item card $index with data: $item');
    
    return GestureDetector(
      onTap: () => _onLessonItemTap(context, item, index),
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: currentSection == index ? _bounceAnimation.value : 1.0,
            child: Container(
              width: double.infinity,
              padding: ResponsiveUtils.getResponsivePadding(context),
              decoration: BoxDecoration(
                color: currentSection == index ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
                ),
                border: Border.all(
                  color: currentSection == index ? const Color(0xFF1976D2) : Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
                        ),
                        decoration: BoxDecoration(
                          color: currentSection == index ? const Color(0xFF1976D2) : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 8),
                          ),
                        ),
                        child: ResponsiveText(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          mobileFontSize: 16,
                          tabletFontSize: 18,
                          desktopFontSize: 20,
                          largeDesktopFontSize: 22,
                        ),
                      ),
                      ResponsiveSpacing(mobileSpacing: 12, isVertical: false),
                      Expanded(
                        child: ResponsiveText(
                          item['name'] ?? 'Item ${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentSection == index ? const Color(0xFF1976D2) : const Color(0xFF4A4E69),
                          ),
                          mobileFontSize: 16,
                          tabletFontSize: 18,
                          desktopFontSize: 20,
                          largeDesktopFontSize: 22,
                        ),
                      ),
                      if (currentSection > index)
                        ResponsiveIcon(
                          Icons.check_circle,
                          color: Colors.green,
                          mobileSize: 20,
                          tabletSize: 22,
                          desktopSize: 24,
                          largeDesktopSize: 26,
                        ),
                    ],
                  ),
                  if (item['description'] != null) ...[
                    ResponsiveSpacing(mobileSpacing: 8),
                    ResponsiveText(
                      item['description'],
                      style: const TextStyle(
                        color: Color(0xFF666),
                      ),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                      largeDesktopFontSize: 20,
                    ),
                  ],
                  if (item['color'] != null) ...[
                    ResponsiveSpacing(mobileSpacing: 8),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(int.parse(item['color'].replaceAll('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                  if (item['imageUrl'] != null || item['image'] != null) ...[
                    ResponsiveSpacing(mobileSpacing: 8),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildQuestionImageWidget(item['imageUrl'] ?? item['image']),
                      ),
                    ),
                  ],
                  if (item['ttsText'] != null) ...[
                    ResponsiveSpacing(mobileSpacing: 8),
                    ResponsiveText(
                      '🔊 "${item['ttsText']}"',
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildSampleContent(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveIcon(
            Icons.school,
            color: const Color(0xFF648BA2),
            mobileSize: 48,
            tabletSize: 56,
            desktopSize: 64,
            largeDesktopSize: 72,
          ),
          ResponsiveSpacing(mobileSpacing: 16),
          ResponsiveText(
            'Interactive Learning Content',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
            mobileFontSize: 18,
            tabletFontSize: 20,
            desktopFontSize: 22,
            largeDesktopFontSize: 24,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(mobileSpacing: 12),
          ResponsiveText(
            'This content has been converted from your teacher\'s uploaded material into an interactive learning experience!',
            style: const TextStyle(
              color: Color(0xFF666),
            ),
            mobileFontSize: 14,
            tabletFontSize: 16,
            desktopFontSize: 18,
            largeDesktopFontSize: 20,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildInteractiveButton(
            context,
            'Start Learning',
            Icons.play_arrow,
            () => _onStartLearning(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveButton(
    BuildContext context,
    String text,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 24),
          vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF648BA2), Color(0xFF3C7E71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 25),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveIcon(
              icon,
              color: Colors.white,
              mobileSize: 20,
              tabletSize: 22,
              desktopSize: 24,
              largeDesktopSize: 26,
            ),
            ResponsiveSpacing(mobileSpacing: 8, isVertical: false),
            ResponsiveText(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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

  Widget _buildLessonProgress(BuildContext context, Map<String, dynamic> lesson) {
    final progress = lesson['progressTracking'];
    if (progress == null) return const SizedBox.shrink();

    final completed = progress['sectionsCompleted'] ?? 0;
    final total = progress['totalSections'] ?? 1;
    final percentage = (completed / total).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Progress',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
              ResponsiveText(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF648BA2),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
            ],
          ),
          ResponsiveSpacing(mobileSpacing: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF648BA2)),
            minHeight: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
          ),
          ResponsiveSpacing(mobileSpacing: 8),
          ResponsiveText(
            '$completed of $total sections completed',
            style: const TextStyle(
              color: Color(0xFF666),
            ),
            mobileFontSize: 12,
            tabletFontSize: 14,
            desktopFontSize: 16,
            largeDesktopFontSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildGameActivity(BuildContext context) {
    // Implementation for game activities
    return _buildSampleContent(context);
  }

  Widget _buildInteractiveAssessment(BuildContext context) {
    // Try both old and new data structures
    final assessment = widget.contentData['assessmentData'] ?? widget.contentData['questions'];
    if (assessment == null) {
      print('DEBUG: No assessment data found');
      print('DEBUG: contentData keys: ${widget.contentData.keys}');
      return _buildSampleContent(context);
    }

    print('DEBUG: Assessment data found: $assessment');

    final content = SingleChildScrollView(
      child: Column(
        children: [
          _buildAssessmentIntroduction(context),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildAssessmentQuestions(context, assessment),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildAssessmentProgress(context),
        ],
      ),
    );
    
    print('DEBUG: Returning assessment content widget');
    return content;
  }

  Widget _buildActivity(BuildContext context) {
    // Try both old and new data structures
    final activity = widget.contentData['activityData'];
    if (activity == null) return _buildSampleContent(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildActivityIntroduction(context, activity),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildActivitySteps(context, activity),
          ResponsiveSpacing(mobileSpacing: 20),
          _buildActivityProgress(context),
        ],
      ),
    );
  }

  Widget _buildFallbackContent(BuildContext context) {
    return _buildSampleContent(context);
  }



  void _saveProgressData(int percentage, int totalScore) async {
    try {
      // Import SharedPreferences for local storage
      final prefs = await SharedPreferences.getInstance();
      
      // Get current progress data
      final progressKey = 'progress_${widget.nickname}_general';
      final existingProgress = prefs.getString(progressKey);
      
      Map<String, dynamic> progressData = {};
      if (existingProgress != null) {
        progressData = Map<String, dynamic>.from(jsonDecode(existingProgress));
      }
      
      // Update progress data
      final now = DateTime.now();
      final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      if (progressData[dateKey] == null) {
        progressData[dateKey] = [];
      }
      
      progressData[dateKey].add({
        'contentId': widget.contentId,
        'contentTitle': widget.contentData['title'] ?? 'Unknown',
        'contentType': widget.contentData['type'] ?? 'unknown',
        'percentage': percentage,
        'score': totalScore,
        'correctAnswers': _correctAnswers,
        'totalQuestions': _totalQuestions,
        'timestamp': now.toIso8601String(),
        'timeSpent': 0, // Could be calculated if we track start time
      });
      
      // Keep only last 30 days of data
      final sortedDates = progressData.keys.toList()..sort();
      if (sortedDates.length > 30) {
        for (int i = 0; i < sortedDates.length - 30; i++) {
          progressData.remove(sortedDates[i]);
        }
      }
      
      // Save updated progress
      await prefs.setString(progressKey, jsonEncode(progressData));
      
      print('DEBUG: Progress saved - percentage: $percentage%, score: $totalScore');
      
      // Also save overall progress
      _saveOverallProgress(percentage, totalScore);
      
    } catch (e) {
      print('ERROR: Failed to save progress data: $e');
    }
  }
  
  void _saveOverallProgress(int percentage, int totalScore) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get overall progress
      final overallKey = 'overall_progress_${widget.nickname}';
      final existingOverall = prefs.getString(overallKey);
      
      Map<String, dynamic> overallData = {};
      if (existingOverall != null) {
        overallData = Map<String, dynamic>.from(jsonDecode(existingOverall));
      }
      
      // Update general progress tracking
      overallData['totalAttempts'] = (overallData['totalAttempts'] ?? 0) + 1;
      overallData['totalScore'] = (overallData['totalScore'] ?? 0) + totalScore;
      overallData['bestScore'] = math.max(overallData['bestScore'] ?? 0, totalScore);
      overallData['averageScore'] = (overallData['totalScore'] / overallData['totalAttempts']).round();
      overallData['lastActivity'] = DateTime.now().toIso8601String();
      
      await prefs.setString(overallKey, jsonEncode(overallData));
      
      print('DEBUG: Overall progress updated - Total attempts: ${overallData['totalAttempts']}, Best score: ${overallData['bestScore']}, Average score: ${overallData['averageScore']}');
      
    } catch (e) {
      print('ERROR: Failed to save overall progress: $e');
    }
  }

  String _getContentTypeDisplay() {
    final type = widget.contentData['type'];
    switch (type) {
      case 'interactive-lesson':
        return '🎓 Interactive Lesson';
      case 'game-activity':
        return '🎮 Game Activity';
      case 'interactive-assessment':
        return '📝 Interactive Quiz';
      default:
        return '📚 Learning Content';
    }
  }


  void _onStartLearning(BuildContext context) {
    setState(() {
      currentSection = 0;
      score = 0;
    });
    
    _bounceController.reset();
    _bounceController.forward();
    
    // Play sound effect
    // Play start sound (handle missing file gracefully)
    try {
      audioPlayer.play(AssetSource('sound/start.mp3'));
    } catch (e) {
      print('DEBUG: Start sound not available: $e');
      // Use existing sound as fallback
      try {
        audioPlayer.play(AssetSource('sound/dog_bark.mp3'));
      } catch (e2) {
        print('DEBUG: Fallback sound also not available: $e2');
      }
    }
    
    // Speak introduction
    flutterTts.speak("Let's start learning! Tap on each section to explore the content.");
  }

  Widget _buildAssessmentIntroduction(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveIcon(
            Icons.quiz,
            color: const Color(0xFF648BA2),
            mobileSize: 48,
            tabletSize: 56,
            desktopSize: 64,
            largeDesktopSize: 72,
          ),
          ResponsiveSpacing(mobileSpacing: 16),
          ResponsiveText(
            widget.contentData['title'] ?? 'Interactive Assessment',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
            largeDesktopFontSize: 26,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(mobileSpacing: 12),
          ResponsiveText(
            widget.contentData['description'] ?? 'Test your knowledge with this interactive quiz!',
            style: const TextStyle(
              color: Color(0xFF666),
            ),
            mobileFontSize: 16,
            tabletFontSize: 18,
            desktopFontSize: 20,
            largeDesktopFontSize: 22,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentQuestions(BuildContext context, dynamic assessment) {
    print('DEBUG: _buildAssessmentQuestions called with: $assessment');
    
    List<dynamic> questions = [];
    
    if (assessment is Map<String, dynamic>) {
      questions = assessment['questions'] as List<dynamic>? ?? [];
      print('DEBUG: Found questions in Map: $questions');
    } else if (assessment is List) {
      questions = assessment;
      print('DEBUG: Assessment is List: $questions');
    }
    
    print('DEBUG: Final questions list: $questions');
    
    if (questions.isEmpty) {
      print('DEBUG: No questions found, showing sample content');
      return _buildSampleContent(context);
    }

    // Update total questions count
    _totalQuestions = questions.length;
    print('DEBUG: Set _totalQuestions to: $_totalQuestions');

    return Column(
      children: questions.asMap().entries.map((entry) {
        final index = entry.key;
        final question = entry.value as Map<String, dynamic>;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
          ),
          child: _buildSimpleQuestion(context, question, index),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCard(BuildContext context, Map<String, dynamic> question, int index) {
    print('DEBUG: Building question card $index with data: $question');
    
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 8),
                  ),
                ),
                child: ResponsiveText(
                  'Q${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  mobileFontSize: 16,
                  tabletFontSize: 18,
                  desktopFontSize: 20,
                  largeDesktopFontSize: 22,
                ),
              ),
              ResponsiveSpacing(mobileSpacing: 12, isVertical: false),
              Expanded(
                child: ResponsiveText(
                  question['question'] ?? question['questionText'] ?? 'Question ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                  mobileFontSize: 16,
                  tabletFontSize: 18,
                  desktopFontSize: 20,
                  largeDesktopFontSize: 22,
                ),
              ),
            ],
          ),
          if (question['options'] != null) ...[
            ResponsiveSpacing(mobileSpacing: 12),
            ...(question['options'] as List<dynamic>).asMap().entries.map((entry) {
              final optionValue = entry.value;
              
              // Handle both string and object options
              String option;
              if (optionValue is String) {
                option = optionValue;
              } else if (optionValue is Map<String, dynamic>) {
                // Extract the name from the object
                option = optionValue['name']?.toString() ?? 'Unknown';
              } else {
                option = optionValue.toString();
              }
              
              final isCorrect = option == question['correctAnswer'];
              
              return Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
                ),
                child: Container(
                  width: double.infinity,
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFFE8F5E8) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCorrect ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: ResponsiveText(
                    option,
                    style: TextStyle(
                      color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFF666),
                      fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    ),
                    mobileFontSize: 14,
                    tabletFontSize: 16,
                    desktopFontSize: 18,
                    largeDesktopFontSize: 20,
                  ),
                ),
              );
            }).toList(),
          ],
          if (question['explanation'] != null) ...[
            ResponsiveSpacing(mobileSpacing: 8),
            Container(
              width: double.infinity,
              padding: ResponsiveUtils.getResponsivePadding(context),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107)),
              ),
              child: ResponsiveText(
                '💡 ${question['explanation']}',
                style: const TextStyle(
                  color: Color(0xFF856404),
                  fontStyle: FontStyle.italic,
                ),
                mobileFontSize: 12,
                tabletFontSize: 14,
                desktopFontSize: 16,
                largeDesktopFontSize: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssessmentProgress(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Assessment Progress',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
              ResponsiveText(
                'Score: $score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF648BA2),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityIntroduction(BuildContext context, Map<String, dynamic> activity) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ResponsiveIcon(
            Icons.extension,
            color: const Color(0xFF648BA2),
            mobileSize: 48,
            tabletSize: 56,
            desktopSize: 64,
            largeDesktopSize: 72,
          ),
          ResponsiveSpacing(mobileSpacing: 16),
          ResponsiveText(
            widget.contentData['title'] ?? 'Interactive Activity',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
            largeDesktopFontSize: 26,
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(mobileSpacing: 12),
          ResponsiveText(
            activity['instructions'] ?? widget.contentData['description'] ?? 'Complete this interactive activity!',
            style: const TextStyle(
              color: Color(0xFF666),
            ),
            mobileFontSize: 16,
            tabletFontSize: 18,
            desktopFontSize: 20,
            largeDesktopFontSize: 22,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySteps(BuildContext context, Map<String, dynamic> activity) {
    final steps = activity['steps'] as List<dynamic>? ?? [];
    
    if (steps.isEmpty) {
      return _buildSampleContent(context);
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value as String;
        
        return Padding(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.getResponsiveSpacing(context, mobile: 16),
          ),
          child: _buildStepCard(context, step, index),
        );
      }).toList(),
    );
  }

  Widget _buildStepCard(BuildContext context, String step, int index) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 8),
              ),
            ),
            child: ResponsiveText(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              mobileFontSize: 16,
              tabletFontSize: 18,
              desktopFontSize: 20,
              largeDesktopFontSize: 22,
            ),
          ),
          ResponsiveSpacing(mobileSpacing: 12, isVertical: false),
          Expanded(
            child: ResponsiveText(
              step,
              style: const TextStyle(
                color: Color(0xFF4A4E69),
              ),
              mobileFontSize: 14,
              tabletFontSize: 16,
              desktopFontSize: 18,
              largeDesktopFontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityProgress(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Activity Progress',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
              ResponsiveText(
                'Score: $score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF648BA2),
                ),
                mobileFontSize: 16,
                tabletFontSize: 18,
                desktopFontSize: 20,
                largeDesktopFontSize: 22,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onLessonItemTap(BuildContext context, Map<String, dynamic> item, int index) {
    setState(() {
      currentSection = index;
      _completedLessonItems.add(index);
    });
    
    _bounceController.reset();
    _bounceController.forward();
    
    // Play sound effect (handle missing file gracefully)
    try {
      audioPlayer.play(AssetSource('sound/success.mp3'));
    } catch (e) {
      print('DEBUG: Success sound not available: $e');
      // Use existing sound as fallback
      try {
        audioPlayer.play(AssetSource('sound/dog_bark.mp3'));
      } catch (e2) {
        print('DEBUG: Fallback sound also not available: $e2');
      }
    }
    
    // Speak the content
    if (item['ttsText'] != null) {
      flutterTts.speak(item['ttsText']);
    } else if (item['description'] != null) {
      flutterTts.speak(item['description']);
    }
    
    // Add score
    setState(() {
      score += 10;
    });
    
    // Check if lesson is completed (all items explored)
    _checkLessonCompletion(context);
  }
  
  /// Check if lesson is completed and trigger progress tracking
  void _checkLessonCompletion(BuildContext context) {
    final contentType = widget.contentData['type'];
    if (contentType == 'lesson' || contentType == 'interactive-lesson') {
      final lessonData = widget.contentData['lessonData'];
      if (lessonData != null && lessonData['items'] != null) {
        final totalItems = (lessonData['items'] as List).length;
        
        // Lesson is completed when all items have been explored
        if (_completedLessonItems.length >= totalItems && !_lessonCompleted) {
          _lessonCompleted = true;
          _onLessonCompleted(context);
        }
      }
    }
  }
  
  /// Handle lesson completion
  void _onLessonCompleted(BuildContext context) {
    final percentage = 100; // Lessons are 100% when all items are explored
    final totalItems = _completedLessonItems.length;
    
    // Add completion bonus
    setState(() {
      score += _perfectBonus; // Perfect bonus for completing all items
    });
    
    // Save using CONSISTENT pattern like all other lessons/games
    _saveLessonDataConsistently(percentage, score);
    
    // Show completion dialog
    _showLessonCompleteDialog(context, percentage, totalItems);
  }
  
  /// Show lesson completion dialog
  void _showLessonCompleteDialog(BuildContext context, int percentage, int totalItems) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.celebration,
                color: Colors.green,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'Lesson Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You explored all $totalItems items in this lesson!',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Score: $percentage% (${score} points)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to materials page
              },
              child: const Text('Continue Learning'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to parse color values (hex codes or descriptive strings)
  Color _parseColor(String? colorValue) {
    if (colorValue == null) return Colors.grey;
    
    // If it's a hex color code (starts with #)
    if (colorValue.startsWith('#')) {
      try {
        return Color(int.parse(colorValue.replaceAll('#', '0xFF')));
      } catch (e) {
        print('Error parsing hex color: $colorValue');
        return Colors.grey;
      }
    }
    
    // If it's a descriptive color string, map it to actual colors
    switch (colorValue.toLowerCase()) {
      case 'red':
      case 'red/green':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'lime':
        return Colors.lime;
      case 'amber':
        return Colors.amber;
      case 'deep orange':
        return Colors.deepOrange;
      case 'light blue':
        return Colors.lightBlue;
      case 'light green':
        return Colors.lightGreen;
      case 'deep purple':
        return Colors.deepPurple;
      case 'blue grey':
      case 'blue gray':
        return Colors.blueGrey;
      default:
        print('Unknown color: $colorValue, using grey');
        return Colors.grey;
    }
  }

  // Comprehensive Progress and Scoring Functions
  
  /// Save assessment data using CONSISTENT pattern like all other assessments/games
  Future<void> _saveAssessmentDataConsistently(int percentage, int totalScore) async {
    try {
      print('DEBUG: Starting CONSISTENT data saving pattern...');
      
      final contentType = widget.contentData['type'] ?? 'unknown';
      final contentTitle = widget.contentData['title'] ?? 'Unknown Content';
      final passed = percentage >= 70;
      
      // 1. Save to Adaptive Assessment System (PRIMARY source for assessments)
      if (contentType == 'assessment' || contentType == 'interactive-assessment') {
        await _saveToAdaptiveAssessmentConsistent(contentTitle, passed);
      }
      
      // 2. Award XP through Gamification System (but don't create duplicate activity entry)
      await _awardXPConsistent(percentage, passed);
      
      // 3. Save local progress (like other assessments)
      await _saveLocalProgressConsistent(totalScore);
      
      print('DEBUG: CONSISTENT data saving completed successfully!');
      
    } catch (e) {
      print('ERROR: Failed to save assessment data consistently: $e');
    }
  }
  
  /// Save to Memory Retention System (CONSISTENT with other assessments)
  Future<void> _saveToMemoryRetentionConsistent(String contentTitle, String contentType, bool passed) async {
    try {
      print('DEBUG: Memory Retention - Starting CONSISTENT save process...');
      final retentionSystem = MemoryRetentionSystem();
      
      // Use CONSISTENT module name pattern like other assessments
      String moduleName = "Teacher's Materials"; // Default module
      String lessonType = contentType;
      
      // Determine module name based on content title (like other assessments)
      if (contentTitle.toLowerCase().contains('alphabet')) {
        moduleName = "Functional Academics";
        lessonType = "Alphabet Assessment";
      } else if (contentTitle.toLowerCase().contains('color')) {
        moduleName = "Functional Academics";
        lessonType = "Colors Assessment";
      } else if (contentTitle.toLowerCase().contains('shape')) {
        moduleName = "Functional Academics";
        lessonType = "Shapes Assessment";
      } else if (contentTitle.toLowerCase().contains('number')) {
        moduleName = "Functional Academics";
        lessonType = "Numbers Assessment";
      } else if (contentType == 'lesson' || contentType == 'interactive-lesson') {
        moduleName = "Teacher's Materials";
        lessonType = "Interactive Lesson";
      } else {
        moduleName = "Teacher's Materials";
        lessonType = "Interactive Assessment";
      }
      
      print('DEBUG: Memory Retention - Data: nickname=${widget.nickname}, moduleName=$moduleName, lessonType=$lessonType, score=$_correctAnswers, totalQuestions=$_totalQuestions, passed=$passed');
      
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: moduleName,
        lessonType: lessonType,
        score: _correctAnswers,
        totalQuestions: _totalQuestions,
        passed: passed,
      );
      
      print('DEBUG: Memory Retention - Successfully saved to lessonRetention collection');
    } catch (e) {
      print('ERROR: Memory Retention - Failed to save: $e');
    }
  }
  
  /// Save to Adaptive Assessment System (CONSISTENT with other assessments)
  Future<void> _saveToAdaptiveAssessmentConsistent(String contentTitle, bool passed) async {
    try {
      print('DEBUG: Adaptive Assessment - Starting CONSISTENT save process...');
      
      // Determine assessment type based on content (like other assessments)
      String assessmentType = 'general';
      String moduleName = "Teacher's Materials";
      
      if (contentTitle.toLowerCase().contains('alphabet')) {
        assessmentType = 'alphabet';
        moduleName = "Functional Academics";
      } else if (contentTitle.toLowerCase().contains('color')) {
        assessmentType = 'colors';
        moduleName = "Functional Academics";
      } else if (contentTitle.toLowerCase().contains('shape')) {
        assessmentType = 'shapes';
        moduleName = "Functional Academics";
      } else if (contentTitle.toLowerCase().contains('number')) {
        assessmentType = 'numbers';
        moduleName = "Functional Academics";
      } else if (contentTitle.toLowerCase().contains('picture') || contentTitle.toLowerCase().contains('story')) {
        assessmentType = 'picture_story';
        moduleName = "Communication Skills";
      } else if (contentTitle.toLowerCase().contains('daily') || contentTitle.toLowerCase().contains('task')) {
        assessmentType = 'daily_tasks';
        moduleName = "Communication Skills";
      } else if (contentTitle.toLowerCase().contains('social') || contentTitle.toLowerCase().contains('family') || contentTitle.toLowerCase().contains('interaction')) {
        assessmentType = 'social_interaction';
        moduleName = "Communication Skills";
      } else if (contentTitle.toLowerCase().contains('rhyme')) {
        assessmentType = 'rhyme';
        moduleName = "Communication Skills";
      } else if (contentTitle.toLowerCase().contains('sound')) {
        assessmentType = 'sounds';
        moduleName = "Communication Skills";
      }
      
      print('DEBUG: Adaptive Assessment - Data: nickname=${widget.nickname}, assessmentType=$assessmentType, moduleName=$moduleName, totalQuestions=$_totalQuestions, correctAnswers=$_correctAnswers');
      
      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: assessmentType,
        moduleName: moduleName,
        totalQuestions: _totalQuestions,
        correctAnswers: _correctAnswers,
        timeSpent: const Duration(minutes: 5), // Estimated time
        attemptedQuestions: List.generate(_totalQuestions, (i) => 'Question ${i + 1}'),
        correctQuestions: List.generate(_correctAnswers, (i) => 'Question ${i + 1}'),
        contentId: widget.contentId, // Add contentId
      );
      
      print('DEBUG: Adaptive Assessment - Successfully saved to adaptiveAssessmentResults collection');
    } catch (e) {
      print('ERROR: Adaptive Assessment - Failed to save: $e');
    }
  }
  
  
  /// Award XP through Gamification System (CONSISTENT with other assessments)
  Future<void> _awardXPConsistent(int percentage, bool passed) async {
    try {
      print('DEBUG: Gamification - Starting CONSISTENT XP award process...');
      final contentType = widget.contentData['type'] ?? 'unknown';
      final contentTitle = widget.contentData['title'] ?? 'Unknown Content';
      final isPerfect = percentage == 100;
      
      print('DEBUG: Gamification - Content: $contentTitle, Type: $contentType, Percentage: $percentage%, Passed: $passed, Perfect: $isPerfect');
      
      // Determine activity type based on content type and performance (like other assessments)
      String activity;
      Map<String, dynamic> metadata = {
        'module': contentType == 'lesson' ? 'interactive_lesson' : 'interactive_assessment',
        'score': _correctAnswers,
        'totalQuestions': _totalQuestions,
        'perfect': isPerfect,
        'contentTitle': contentTitle,
      };
      
      if (contentType == 'assessment' || contentType == 'interactive-assessment') {
        if (isPerfect) {
          activity = 'perfect_score';
        } else if (passed) {
          activity = 'assessment_passed';
        } else {
          activity = 'lesson_completed'; // Still give XP for attempts
        }
      } else if (contentType == 'lesson' || contentType == 'interactive-lesson') {
        if (isPerfect) {
          activity = 'perfect_score';
        } else {
          activity = 'lesson_completed';
        }
      } else {
        activity = 'lesson_completed'; // Default for other content types
      }
      
      print('DEBUG: Gamification - Activity type: $activity, Metadata: $metadata');
      
      final result = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: activity,
        metadata: metadata,
      );
      
      print('DEBUG: Gamification - XP awarded successfully! Activity: $activity, XP: ${result.xpAwarded}, Leveled Up: ${result.leveledUp}, Message: ${result.message}');
      
      // Show XP notification if XP was awarded
      if (result.xpAwarded > 0) {
        _showXPNavigation(context, result);
      }
      
    } catch (e) {
      print('ERROR: Gamification - Failed to award XP: $e');
    }
  }
  
  /// Save lesson data using CONSISTENT pattern like all other lessons/games
  Future<void> _saveLessonDataConsistently(int percentage, int totalScore) async {
    try {
      print('DEBUG: Starting CONSISTENT lesson data saving pattern...');
      
      final contentType = widget.contentData['type'] ?? 'unknown';
      final contentTitle = widget.contentData['title'] ?? 'Unknown Content';
      final passed = percentage >= 70; // Lessons are considered passed if all items explored
      
      // 1. Save to Memory Retention System (like other lessons)
      await _saveToMemoryRetentionConsistent(contentTitle, contentType, passed);
      
      // 2. Award XP through Gamification System (like other lessons)
      await _awardXPConsistent(percentage, passed);
      
      // 3. Save local progress (like other lessons)
      await _saveLocalProgressConsistent(totalScore);
      
      print('DEBUG: CONSISTENT lesson data saving completed successfully!');
      
    } catch (e) {
      print('ERROR: Failed to save lesson data consistently: $e');
    }
  }
  
  /// Mark assessment as completed to prevent retaking
  Future<void> _markAssessmentAsCompleted() async {
    try {
      print('DEBUG: Marking assessment as completed - Content ID: ${widget.contentId}');
      
      await FirebaseFirestore.instance
          .collection('completedAssessments')
          .add({
        'nickname': widget.nickname,
        'contentId': widget.contentId,
        'contentTitle': widget.contentData['title'] ?? 'Unknown Assessment',
        'contentType': widget.contentData['type'] ?? 'assessment',
        'completedAt': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'score': score,
        'correctAnswers': _correctAnswers,
        'totalQuestions': _totalQuestions,
        'percentage': (_correctAnswers / _totalQuestions * 100).round(),
      });
      
      print('DEBUG: Assessment marked as completed successfully');
    } catch (e) {
      print('ERROR: Failed to mark assessment as completed: $e');
    }
  }

  /// Check if assessment is already completed
  Future<bool> _isAssessmentCompleted() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('completedAssessments')
          .where('nickname', isEqualTo: widget.nickname)
          .where('contentId', isEqualTo: widget.contentId)
          .limit(1)
          .get();
      
      return query.docs.isNotEmpty;
    } catch (e) {
      print('ERROR: Failed to check assessment completion status: $e');
      return false;
    }
  }

  /// Track visit to this content
  Future<void> _trackVisit() async {
    try {
      print('DEBUG: Tracking visit for content: ${widget.contentId}');
      
      final contentTitle = widget.contentData['title'] ?? 'Unknown Content';
      final contentType = widget.contentData['type'] ?? 'unknown';
      
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: contentType,
        itemName: contentTitle,
        moduleName: _getModuleName(contentType),
      );
      
      print('DEBUG: Visit tracked successfully');
    } catch (e) {
      print('ERROR: Failed to track visit: $e');
    }
  }

  /// Get module name based on content type
  String _getModuleName(String contentType) {
    switch (contentType) {
      case 'assessment':
      case 'interactive-assessment':
        return 'Teacher\'s Materials';
      case 'interactive-lesson':
      case 'lesson':
        return 'Teacher\'s Materials';
      case 'game-activity':
      case 'game':
        return 'Teacher\'s Materials';
      default:
        return 'Teacher\'s Materials';
    }
  }

  /// Check assessment completion status and show appropriate UI
  Future<void> _checkAssessmentCompletion() async {
    // Only check for assessments, not lessons
    if (widget.contentData['type'] == 'assessment' || 
        widget.contentData['type'] == 'interactive-assessment') {
      
      final isCompleted = await _isAssessmentCompleted();
      
      if (isCompleted) {
        // Show completion status instead of allowing retake
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAlreadyCompletedDialog();
        });
      }
    }
  }

  /// Show dialog when assessment is already completed
  void _showAlreadyCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 32),
              const SizedBox(width: 12),
              Text(
                'Already Completed! ✅',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Great job! 🎉',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have already completed this assessment!',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your progress in the Analytics Hub to see your results!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Keep learning with other assessments and lessons! 📚',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to materials page
              },
              child: const Text(
                'Continue Learning',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Save local progress (CONSISTENT with other assessments)
  Future<void> _saveLocalProgressConsistent(int totalScore) async {
    try {
      print('DEBUG: Local Progress - Starting CONSISTENT save process...');
      final prefs = await SharedPreferences.getInstance();
      
      // Save progress using CONSISTENT key pattern like other assessments
      final contentType = widget.contentData['type'] ?? 'unknown';
      String progressKey;
      
      if (contentType == 'assessment' || contentType == 'interactive-assessment') {
        progressKey = 'interactive_assessment_progress_${widget.nickname}';
      } else if (contentType == 'lesson' || contentType == 'interactive-lesson') {
        progressKey = 'interactive_lesson_progress_${widget.nickname}';
      } else {
        progressKey = 'interactive_content_progress_${widget.nickname}';
      }
      
      // Save current progress
      await prefs.setInt('${progressKey}_score', totalScore);
      await prefs.setInt('${progressKey}_correctAnswers', _correctAnswers);
      await prefs.setInt('${progressKey}_totalQuestions', _totalQuestions);
      await prefs.setString('${progressKey}_lastActivity', DateTime.now().toIso8601String());
      
      print('DEBUG: Local Progress - Successfully saved to SharedPreferences with key: $progressKey');
      
    } catch (e) {
      print('ERROR: Local Progress - Failed to save: $e');
    }
  }
  
  /// Award XP through Gamification System
  Future<void> _awardXP(int percentage) async {
    try {
      print('DEBUG: Gamification - Starting XP award process...');
      final contentType = widget.contentData['type'] ?? 'unknown';
      final contentTitle = widget.contentData['title'] ?? 'Unknown Content';
      final passed = percentage >= 70;
      final isPerfect = percentage == 100;
      
      print('DEBUG: Gamification - Content: $contentTitle, Type: $contentType, Percentage: $percentage%, Passed: $passed, Perfect: $isPerfect');
      
      String activity;
      Map<String, dynamic> metadata = {
        'contentId': widget.contentId,
        'contentTitle': contentTitle,
        'contentType': contentType,
        'score': _correctAnswers,
        'totalQuestions': _totalQuestions,
        'percentage': percentage,
      };
      
      // Determine activity type based on content type and performance
      if (contentType == 'assessment' || contentType == 'interactive-assessment') {
        if (isPerfect) {
          activity = 'perfect_score';
        } else if (passed) {
          activity = 'assessment_passed';
        } else {
          activity = 'lesson_completed'; // Still give XP for attempts
        }
      } else if (contentType == 'lesson' || contentType == 'interactive-lesson') {
        if (isPerfect) {
          activity = 'perfect_score';
        } else {
          activity = 'lesson_completed';
        }
      } else {
        activity = 'lesson_completed'; // Default for other content types
      }
      
      print('DEBUG: Gamification - Activity type: $activity, Metadata: $metadata');
      
      final result = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: activity,
        metadata: metadata,
      );
      
      print('DEBUG: Gamification - XP awarded successfully! Activity: $activity, XP: ${result.xpAwarded}, Leveled Up: ${result.leveledUp}, Message: ${result.message}');
      
      // Show XP notification if XP was awarded
      if (result.xpAwarded > 0) {
        _showXPNavigation(context, result);
      }
      
    } catch (e) {
      print('ERROR: Gamification - Failed to award XP: $e');
    }
  }
  
  /// Show XP notification
  void _showXPNavigation(BuildContext context, GamificationResult result) {
    // Show a brief snackbar with XP information
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.message.isNotEmpty 
                    ? result.message 
                    : '+${result.xpAwarded} XP earned!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: result.leveledUp ? Colors.green : Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
