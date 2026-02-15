import 'package:flutter/material.dart';
import 'sped_friendly_messages.dart';

/// Enhanced Feedback System
/// Provides constructive feedback with explanations, praise, and tips
class EnhancedFeedbackSystem {
  
  /// Generate comprehensive feedback for assessment results
  static AssessmentFeedback generateAssessmentFeedback({
    required String assessmentType,
    required double score,
    required double totalQuestions,
    required List<Map<String, dynamic>> answers,
    required String studentName,
    required bool isFirstAttempt,
    double? previousScore,
  }) {
    final percentage = (score / totalQuestions) * 100;
    final performance = _categorizePerformance(percentage);
    final improvement = previousScore != null ? score - previousScore : 0;
    
    return AssessmentFeedback(
      overallMessage: _generateOverallMessage(percentage, studentName),
      performanceCategory: performance,
      specificFeedback: _generateSpecificFeedback(assessmentType, answers),
      encouragement: _generateEncouragement(percentage, improvement.toDouble()),
      tips: _generateTips(assessmentType, answers),
      nextSteps: _generateNextSteps(performance, assessmentType),
      celebrationLevel: _getCelebrationLevel(percentage),
    );
  }
  
  /// Generate feedback for individual questions
  static QuestionFeedback generateQuestionFeedback({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
    required int attemptNumber,
    required String assessmentType,
  }) {
    return QuestionFeedback(
      isCorrect: isCorrect,
      message: isCorrect 
          ? SPEDFriendlyMessages.getRandomSuccessMessage()
          : SPEDFriendlyMessages.getRandomGentleCorrectionMessage(),
      explanation: _generateExplanation(question, correctAnswer, assessmentType),
      encouragement: _generateQuestionEncouragement(isCorrect, attemptNumber),
      tip: _generateQuestionTip(assessmentType, isCorrect),
    );
  }
  
  /// Generate progress feedback
  static ProgressFeedback generateProgressFeedback({
    required double currentScore,
    required double totalQuestions,
    required double previousScore,
    required String studentName,
    required String assessmentType,
  }) {
    final improvement = currentScore - previousScore;
    final percentage = (currentScore / totalQuestions) * 100;
    
    return ProgressFeedback(
      message: SPEDFriendlyMessages.generateProgressEncouragement(
        currentScore: currentScore,
        totalQuestions: totalQuestions,
        previousScore: previousScore,
      ),
      improvement: improvement,
      percentage: percentage,
      encouragement: _generateProgressEncouragement(improvement, percentage),
      nextGoal: _generateNextGoal(percentage, assessmentType),
    );
  }
  
  // Helper methods
  static String _categorizePerformance(double percentage) {
    if (percentage >= 90) return 'excellent';
    if (percentage >= 80) return 'good';
    if (percentage >= 70) return 'satisfactory';
    if (percentage >= 60) return 'needs_improvement';
    return 'needs_support';
  }
  
  static String _generateOverallMessage(double percentage, String studentName) {
    if (percentage >= 90) {
      return "Wow, $studentName! You're amazing! 🌟";
    } else if (percentage >= 80) {
      return "Great job, $studentName! You did really well! 🎉";
    } else if (percentage >= 70) {
      return "Good work, $studentName! You're learning! 📚";
    } else if (percentage >= 60) {
      return "Nice try, $studentName! Keep practicing! 💪";
    } else {
      return "You're doing great, $studentName! Keep learning! 🌈";
    }
  }
  
  static String _generateSpecificFeedback(String assessmentType, List<Map<String, dynamic>> answers) {
    final correctAnswers = answers.where((answer) => answer['isCorrect'] == true).length;
    final totalAnswers = answers.length;
    
    switch (assessmentType.toLowerCase()) {
      case 'alphabet':
        return "You got $correctAnswers out of $totalAnswers letters right! Letters are the building blocks of words! 🔤";
      case 'colors':
        return "You identified $correctAnswers out of $totalAnswers colors correctly! Colors make our world beautiful! 🌈";
      case 'numbers':
        return "You got $correctAnswers out of $totalAnswers numbers right! Numbers help us count and measure! 🔢";
      case 'shapes':
        return "You recognized $correctAnswers out of $totalAnswers shapes! Shapes are everywhere around us! 🔷";
      case 'reading':
        return "You understood $correctAnswers out of $totalAnswers reading questions! Reading helps us learn! 📖";
      default:
        return "You answered $correctAnswers out of $totalAnswers questions correctly! Great effort! 🎯";
    }
  }
  
  static String _generateEncouragement(double percentage, double improvement) {
    if (improvement > 0) {
      return "Look how much you've improved! You're getting better every time! 📈";
    } else if (percentage >= 80) {
      return "You're doing fantastic! Keep up the great work! 🌟";
    } else if (percentage >= 60) {
      return "You're learning so much! Every try makes you stronger! 💪";
    } else {
      return "You're doing great! Learning takes time and practice! 🌈";
    }
  }
  
  static String _generateTips(String assessmentType, List<Map<String, dynamic>> answers) {
    final incorrectAnswers = answers.where((answer) => answer['isCorrect'] == false).length;
    
    if (incorrectAnswers == 0) {
      return "You're doing perfectly! Keep practicing to stay sharp! ⭐";
    }
    
    switch (assessmentType.toLowerCase()) {
      case 'alphabet':
        return "Try singing the alphabet song! It helps remember the letters! 🎵";
      case 'colors':
        return "Look around you! What colors do you see? Practice with real objects! 👀";
      case 'numbers':
        return "Count things around you! Practice makes numbers easier! 🔢";
      case 'shapes':
        return "Find shapes in your room! Circles, squares, triangles are everywhere! 🔍";
      case 'reading':
        return "Read slowly and take your time! Understanding is more important than speed! 📚";
      default:
        return "Take your time and think carefully! You can do it! 🤔";
    }
  }
  
  static String _generateNextSteps(String performance, String assessmentType) {
    switch (performance) {
      case 'excellent':
        return "You're ready for harder challenges! Let's try something new! 🚀";
      case 'good':
        return "Keep practicing! You're almost perfect! 💪";
      case 'satisfactory':
        return "Good work! Let's practice a bit more! 📚";
      case 'needs_improvement':
        return "Let's try some easier questions first! You're doing great! 🌟";
      case 'needs_support':
        return "Let's take it slow and practice together! You're amazing! 🤝";
      default:
        return "Keep learning and having fun! 🌈";
    }
  }
  
  static int _getCelebrationLevel(double percentage) {
    if (percentage >= 90) return 3; // Big celebration
    if (percentage >= 80) return 2; // Medium celebration
    if (percentage >= 60) return 1; // Small celebration
    return 0; // Encouragement only
  }
  
  static String _generateExplanation(String question, String correctAnswer, String assessmentType) {
    switch (assessmentType.toLowerCase()) {
      case 'alphabet':
        return "The letter '$correctAnswer' makes the sound you heard! 🔤";
      case 'colors':
        return "The color '$correctAnswer' is what you see! 🌈";
      case 'numbers':
        return "The number '$correctAnswer' represents that amount! 🔢";
      case 'shapes':
        return "The shape '$correctAnswer' has those sides and corners! 🔷";
      case 'reading':
        return "The answer '$correctAnswer' comes from the story! 📖";
      default:
        return "The correct answer is '$correctAnswer'! 🎯";
    }
  }
  
  static String _generateQuestionEncouragement(bool isCorrect, int attemptNumber) {
    if (isCorrect) {
      if (attemptNumber == 1) {
        return "Perfect! You got it right away! 🌟";
      } else {
        return "Great! You figured it out! 🎉";
      }
    } else {
      if (attemptNumber == 1) {
        return "Good try! Let's try again! 🤗";
      } else {
        return "You're learning! Keep trying! 📚";
      }
    }
  }
  
  static String _generateQuestionTip(String assessmentType, bool isCorrect) {
    if (isCorrect) {
      return "You're doing great! Keep it up! 💪";
    }
    
    switch (assessmentType.toLowerCase()) {
      case 'alphabet':
        return "Try saying the letter sound out loud! 🗣️";
      case 'colors':
        return "Look carefully at the color! 👀";
      case 'numbers':
        return "Count slowly and carefully! 🔢";
      case 'shapes':
        return "Look at the sides and corners! 🔍";
      case 'reading':
        return "Read the question again slowly! 📖";
      default:
        return "Take your time and think! 🤔";
    }
  }
  
  static String _generateProgressEncouragement(double improvement, double percentage) {
    if (improvement > 0) {
      return "You're improving! Look how much better you're getting! 📈";
    } else if (percentage >= 80) {
      return "You're doing fantastic! Keep up the great work! 🌟";
    } else {
      return "You're learning! Every practice makes you stronger! 💪";
    }
  }
  
  static String _generateNextGoal(double percentage, String assessmentType) {
    if (percentage >= 90) {
      return "Try a harder level! You're ready! 🚀";
    } else if (percentage >= 80) {
      return "Aim for 90%! You're almost there! 🎯";
    } else if (percentage >= 70) {
      return "Try to get 80%! You can do it! 💪";
    } else {
      return "Practice more! You're getting better! 📚";
    }
  }
}

/// Data classes for feedback
class AssessmentFeedback {
  final String overallMessage;
  final String performanceCategory;
  final String specificFeedback;
  final String encouragement;
  final String tips;
  final String nextSteps;
  final int celebrationLevel;
  
  AssessmentFeedback({
    required this.overallMessage,
    required this.performanceCategory,
    required this.specificFeedback,
    required this.encouragement,
    required this.tips,
    required this.nextSteps,
    required this.celebrationLevel,
  });
}

class QuestionFeedback {
  final bool isCorrect;
  final String message;
  final String explanation;
  final String encouragement;
  final String tip;
  
  QuestionFeedback({
    required this.isCorrect,
    required this.message,
    required this.explanation,
    required this.encouragement,
    required this.tip,
  });
}

class ProgressFeedback {
  final String message;
  final double improvement;
  final double percentage;
  final String encouragement;
  final String nextGoal;
  
  ProgressFeedback({
    required this.message,
    required this.improvement,
    required this.percentage,
    required this.encouragement,
    required this.nextGoal,
  });
}

/// Enhanced Feedback Widget
class EnhancedFeedbackWidget extends StatefulWidget {
  final AssessmentFeedback feedback;
  final VoidCallback? onContinue;
  final VoidCallback? onRetry;
  final VoidCallback? onHelp;
  
  const EnhancedFeedbackWidget({
    super.key,
    required this.feedback,
    this.onContinue,
    this.onRetry,
    this.onHelp,
  });
  
  @override
  State<EnhancedFeedbackWidget> createState() => _EnhancedFeedbackWidgetState();
}

class _EnhancedFeedbackWidgetState extends State<EnhancedFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration emoji
                  Text(
                    _getCelebrationEmoji(),
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  
                  // Overall message
                  Text(
                    widget.feedback.overallMessage,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Specific feedback
                  Text(
                    widget.feedback.specificFeedback,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Encouragement
                  Text(
                    widget.feedback.encouragement,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "💡 Tip:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.feedback.tips,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Next steps
                  Text(
                    widget.feedback.nextSteps,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.onRetry != null)
                        ElevatedButton(
                          onPressed: widget.onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Try Again"),
                        ),
                      if (widget.onContinue != null)
                        ElevatedButton(
                          onPressed: widget.onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Continue"),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  String _getCelebrationEmoji() {
    switch (widget.feedback.celebrationLevel) {
      case 3:
        return "🎉🌟🏆";
      case 2:
        return "🎊⭐";
      case 1:
        return "👏";
      default:
        return "💪";
    }
  }
}
