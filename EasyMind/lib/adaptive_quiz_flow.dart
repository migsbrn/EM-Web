import 'package:flutter/material.dart';
import 'adaptive_assessment_system.dart';

/// Adaptive Quiz Flow - Handles dynamic difficulty adjustment during assessment
class AdaptiveQuizFlow extends StatefulWidget {
  final String nickname;
  final String assessmentType;
  final String moduleName;
  final List<Map<String, dynamic>> questions;
  final Function(Map<String, dynamic>) onQuizCompleted;

  const AdaptiveQuizFlow({
    super.key,
    required this.nickname,
    required this.assessmentType,
    required this.moduleName,
    required this.questions,
    required this.onQuizCompleted,
  });

  @override
  State<AdaptiveQuizFlow> createState() => _AdaptiveQuizFlowState();
}

class _AdaptiveQuizFlowState extends State<AdaptiveQuizFlow>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _currentQuestions;
  late String _currentDifficulty;
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  List<String> _attemptedQuestions = [];
  List<String> _correctQuestions = [];
  DateTime? _startTime;
  
  late AnimationController _questionController;
  late AnimationController _feedbackController;
  late Animation<double> _questionAnimation;
  late Animation<double> _feedbackAnimation;
  
  bool _showingFeedback = false;
  String _feedbackMessage = '';
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeQuiz();
  }

  void _initializeAnimations() {
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.elasticOut,
    ));
    
    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.bounceOut,
    ));
  }

  Future<void> _initializeQuiz() async {
    try {
      // Get current difficulty level
      _currentDifficulty = await AdaptiveAssessmentSystem.getCurrentLevel(
        widget.nickname,
        widget.assessmentType,
      );
      
      // Get adaptive questions based on current level
      _currentQuestions = AdaptiveAssessmentSystem.getAdaptiveQuestions(
        widget.assessmentType,
        _currentDifficulty,
        5, // Start with 5 questions
      );
      
      _startTime = DateTime.now();
      
      setState(() {
        _totalQuestions = _currentQuestions.length;
      });
      
      _questionController.forward();
    } catch (e) {
      print('Error initializing adaptive quiz: $e');
      // Fallback to original questions
      _currentQuestions = widget.questions;
      _currentDifficulty = 'beginner';
      _startTime = DateTime.now();
      setState(() {
        _totalQuestions = _currentQuestions.length;
      });
      _questionController.forward();
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _answerQuestion(int selectedIndex) {
    if (_showingFeedback) return;
    
    final question = _currentQuestions[_currentQuestionIndex];
    final correctAnswer = question['correctAnswer'] as int;
    final isCorrect = selectedIndex == correctAnswer;
    
    setState(() {
      _isCorrect = isCorrect;
      _showingFeedback = true;
      _attemptedQuestions.add(question['id'] as String);
      
      if (isCorrect) {
        _correctAnswers++;
        _correctQuestions.add(question['id'] as String);
        _feedbackMessage = _getCorrectFeedback();
      } else {
        _feedbackMessage = _getIncorrectFeedback();
      }
    });
    
    _feedbackController.forward();
    
    // Auto-advance after showing feedback
    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _currentQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _showingFeedback = false;
      });
      
      _feedbackController.reset();
      _questionController.reset();
      _questionController.forward();
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() async {
    final endTime = DateTime.now();
    final timeSpent = endTime.difference(_startTime!);
    
    // Save adaptive assessment result
    await AdaptiveAssessmentSystem.saveAssessmentResult(
      nickname: widget.nickname,
      assessmentType: widget.assessmentType,
      moduleName: widget.moduleName,
      totalQuestions: _totalQuestions,
      correctAnswers: _correctAnswers,
      timeSpent: timeSpent,
      attemptedQuestions: _attemptedQuestions,
      correctQuestions: _correctQuestions,
    );
    
    // Prepare completion data
    final completionData = {
      'totalQuestions': _totalQuestions,
      'correctAnswers': _correctAnswers,
      'performance': _correctAnswers / _totalQuestions,
      'timeSpent': timeSpent,
      'difficultyLevel': _currentDifficulty,
      'feedbackMessage': _getCompletionFeedback(),
    };
    
    widget.onQuizCompleted(completionData);
  }

  String _getCorrectFeedback() {
    final feedbacks = [
      "Awesome! You're so smart! 🌟",
      "Fantastic! You got it right! 🎉",
      "Brilliant! You're learning so well! ✨",
      "Perfect! You're amazing! 🏆",
      "Excellent! You're a superstar! ⭐",
      "Wonderful! You're getting better! 🚀",
      "Great job! You're so clever! 🧠",
      "Superb! You're doing great! 💫",
    ];
    return feedbacks[_correctAnswers % feedbacks.length];
  }

  String _getIncorrectFeedback() {
    final feedbacks = [
      "Good try! Let's learn together! 🌱",
      "No worries! Learning takes practice! 💪",
      "That's okay! You're still awesome! 🌟",
      "Don't give up! You're doing great! 🎈",
      "Keep trying! You're learning! 📚",
      "Nice effort! You're getting better! 🌈",
      "Good attempt! Practice makes perfect! 🎯",
      "You're learning! That's what matters! 🎪",
    ];
    return feedbacks[(_totalQuestions - _correctAnswers) % feedbacks.length];
  }

  String _getCompletionFeedback() {
    final performance = _correctAnswers / _totalQuestions;
    
    if (performance >= 0.9) {
      return "Incredible! You're a learning champion! 🏆🌟";
    } else if (performance >= 0.7) {
      return "Excellent work! You're doing amazing! ⭐🎉";
    } else if (performance >= 0.5) {
      return "Good job! You're learning and growing! 🌱💪";
    } else {
      return "Keep practicing! You're getting better! 📚🌟";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestions.isEmpty) {
      return _buildLoadingWidget();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: _showingFeedback 
                    ? _buildFeedbackWidget()
                    : _buildQuestionWidget(),
              ),
              const SizedBox(height: 20),
              _buildProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Scaffold(
      backgroundColor: Color(0xFFEFE9D5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5DB2FF)),
            ),
            SizedBox(height: 16),
            Text(
              "Preparing your personalized quiz... 🎪",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4E69),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getDifficultyColors(_currentDifficulty),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: _getDifficultyColors(_currentDifficulty).first.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _getDifficultyIcon(_currentDifficulty),
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDifficultyTitle(_currentDifficulty),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Question ${_currentQuestionIndex + 1} of $_totalQuestions",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionWidget() {
    final question = _currentQuestions[_currentQuestionIndex];
    
    return AnimatedBuilder(
      animation: _questionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _questionAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFF5DB2FF),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5DB2FF).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  question['question'] as String,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ...List.generate(
                  (question['options'] as List).length,
                  (index) => _buildOptionButton(
                    question['options'][index] as String,
                    index,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton(String option, int index) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () => _answerQuestion(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: _getOptionColor(index),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
        ),
        child: Text(
          option,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackWidget() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isCorrect ? const Color(0xFF6BCF7F) : const Color(0xFFFF6B6B),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (_isCorrect ? const Color(0xFF6BCF7F) : const Color(0xFFFF6B6B))
                      .withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isCorrect ? "🎉" : "💪",
                  style: const TextStyle(fontSize: 80),
                ),
                const SizedBox(height: 20),
                Text(
                  _feedbackMessage,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _isCorrect 
                      ? "You're getting smarter! 🌟"
                      : "Keep learning! You're awesome! 🌈",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentQuestionIndex + 1) / _totalQuestions;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5DB2FF),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                "${_currentQuestionIndex + 1}/$_totalQuestions",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFF5DB2FF).withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5DB2FF)),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            "Correct: $_correctAnswers/$_totalQuestions",
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF648BA2),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getDifficultyColors(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)];
      case 'intermediate':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      case 'advanced':
        return [const Color(0xFF5DB2FF), const Color(0xFF3B82F6)];
      case 'expert':
        return [const Color(0xFFFF6B6B), const Color(0xFFE53E3E)];
      default:
        return [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)];
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Icons.child_care;
      case 'intermediate':
        return Icons.school;
      case 'advanced':
        return Icons.star;
      case 'expert':
        return Icons.emoji_events;
      default:
        return Icons.child_care;
    }
  }

  String _getDifficultyTitle(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return "Learning Explorer! 🌱";
      case 'intermediate':
        return "Smart Learner! 🎓";
      case 'advanced':
        return "Super Star! ⭐";
      case 'expert':
        return "Genius Master! 👑";
      default:
        return "Learning Explorer! 🌱";
    }
  }

  Color _getOptionColor(int index) {
    final colors = [
      const Color(0xFF5DB2FF),
      const Color(0xFF4ECDC4),
      const Color(0xFF6BCF7F),
      const Color(0xFFFFD93D),
    ];
    return colors[index % colors.length];
  }
}
