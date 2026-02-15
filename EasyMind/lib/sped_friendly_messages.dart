import 'package:flutter/material.dart';

/// SPED-Friendly Message System
/// Provides simple, encouraging, and accessible messages for students with special needs
class SPEDFriendlyMessages {
  
  // Simple, encouraging success messages
  static const List<String> successMessages = [
    "Great job! 🌟",
    "You did it! 🎉",
    "Awesome! ⭐",
    "Perfect! ✨",
    "Well done! 👏",
    "You're amazing! 🌈",
    "Keep it up! 🚀",
    "Fantastic! 🎊",
    "You got it! 💪",
    "Excellent! 🏆"
  ];
  
  // Gentle, encouraging messages for incorrect answers
  static const List<String> gentleCorrectionMessages = [
    "Good try! Let's try again! 🤗",
    "Almost there! You can do it! 💪",
    "Nice effort! Try once more! 🌟",
    "You're learning! Keep going! 📚",
    "Great attempt! Let's try again! 🎯",
    "You're doing great! One more time! ⭐",
    "Good thinking! Try again! 🧠",
    "You're getting better! Keep trying! 🌈",
    "Nice work! Let's try one more time! 🎨",
    "You're improving! Try again! 🚀"
  ];
  
  // Encouraging messages for improvement
  static const List<String> improvementMessages = [
    "You're getting better! 🌟",
    "Look how much you've improved! 📈",
    "You're learning so much! 🎓",
    "Great progress! Keep going! 🏃‍♂️",
    "You're doing amazing! 🌈",
    "Keep up the great work! 💪",
    "You're becoming a star! ⭐",
    "Fantastic improvement! 🎉",
    "You're getting stronger! 💪",
    "Amazing progress! 🚀"
  ];
  
  // Simple tips for better learning
  static const List<String> learningTips = [
    "Take your time! ⏰",
    "Read carefully! 👀",
    "Listen well! 👂",
    "Think about it! 🤔",
    "You can do it! 💪",
    "Try your best! 🌟",
    "Take a deep breath! 🫁",
    "Focus and try again! 🎯",
    "Believe in yourself! 💖",
    "Keep practicing! 📚"
  ];
  
  // Simple validation messages
  static const Map<String, String> validationMessages = {
    'empty_field': "Please fill this in! 📝",
    'invalid_input': "Let's try again! 🔄",
    'required_field': "This is important! ⭐",
    'too_short': "Add a bit more! 📏",
    'too_long': "Make it shorter! ✂️",
    'invalid_format': "Try a different way! 🔄",
    'network_error': "Oops! Try again! 🌐",
    'loading': "Please wait! ⏳",
    'success': "All done! 🎉",
    'error': "Something went wrong! Let's try again! 🔄"
  };
  
  // Accessibility-friendly instructions
  static const Map<String, String> accessibilityInstructions = {
    'tap_to_answer': "Tap your answer! 👆",
    'swipe_to_continue': "Swipe to go next! 👉",
    'speak_clearly': "Speak clearly! 🗣️",
    'listen_carefully': "Listen carefully! 👂",
    'read_aloud': "Read out loud! 📖",
    'take_break': "Take a break if needed! 😊",
    'ask_for_help': "Ask for help anytime! 🤝",
    'try_again': "Try again when ready! 🔄",
    'well_done': "You did great! 🌟",
    'keep_going': "Keep going! You're doing amazing! 🚀"
  };
  
  /// Get a random success message
  static String getRandomSuccessMessage() {
    final random = DateTime.now().millisecondsSinceEpoch % successMessages.length;
    return successMessages[random];
  }
  
  /// Get a random gentle correction message
  static String getRandomGentleCorrectionMessage() {
    final random = DateTime.now().millisecondsSinceEpoch % gentleCorrectionMessages.length;
    return gentleCorrectionMessages[random];
  }
  
  /// Get a random improvement message
  static String getRandomImprovementMessage() {
    final random = DateTime.now().millisecondsSinceEpoch % improvementMessages.length;
    return improvementMessages[random];
  }
  
  /// Get a random learning tip
  static String getRandomLearningTip() {
    final random = DateTime.now().millisecondsSinceEpoch % learningTips.length;
    return learningTips[random];
  }
  
  /// Get validation message by key
  static String getValidationMessage(String key) {
    return validationMessages[key] ?? "Please try again! 🔄";
  }
  
  /// Get accessibility instruction by key
  static String getAccessibilityInstruction(String key) {
    return accessibilityInstructions[key] ?? "Keep trying! 💪";
  }
  
  /// Generate contextual feedback based on performance
  static String generateContextualFeedback({
    required bool isCorrect,
    required int attemptNumber,
    required double performance,
    String? previousPerformance,
  }) {
    if (isCorrect) {
      if (attemptNumber == 1) {
        return "Perfect! You got it right away! 🌟";
      } else if (attemptNumber <= 3) {
        return "Great! You figured it out! 🎉";
      } else {
        return "Awesome! You didn't give up! 💪";
      }
    } else {
      if (attemptNumber == 1) {
        return "Good try! Let's try again! 🤗";
      } else if (attemptNumber <= 3) {
        return "You're learning! Try once more! 📚";
      } else {
        return "You're doing great! Take your time! ⏰";
      }
    }
  }
  
  /// Generate progress-based encouragement
  static String generateProgressEncouragement({
    required double currentScore,
    required double totalQuestions,
    required double previousScore,
  }) {
    final percentage = (currentScore / totalQuestions) * 100;
    final improvement = currentScore - previousScore;
    
    if (percentage >= 90) {
      return "You're amazing! Almost perfect! 🌟";
    } else if (percentage >= 80) {
      return "Great job! You're doing really well! 🎉";
    } else if (percentage >= 70) {
      return "Good work! Keep it up! 💪";
    } else if (percentage >= 60) {
      return "You're learning! Keep trying! 📚";
    } else if (improvement > 0) {
      return "You're getting better! Keep going! 📈";
    } else {
      return "You're doing great! Don't give up! 🌈";
    }
  }
  
  /// Generate completion message based on performance
  static String generateCompletionMessage({
    required double score,
    required double totalQuestions,
    required bool isFirstAttempt,
  }) {
    final percentage = (score / totalQuestions) * 100;
    
    if (percentage >= 90) {
      return "Fantastic! You're a star! ⭐";
    } else if (percentage >= 80) {
      return "Great job! You did really well! 🎉";
    } else if (percentage >= 70) {
      return "Good work! You're learning! 📚";
    } else if (percentage >= 60) {
      return "Nice try! Keep practicing! 💪";
    } else {
      return "You're doing great! Keep learning! 🌈";
    }
  }
}

/// SPED-Friendly Message Widget
class SPEDFriendlyMessageWidget extends StatelessWidget {
  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool showIcon;
  final IconData? icon;
  
  const SPEDFriendlyMessageWidget({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.borderRadius,
    this.showIcon = true,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue.shade50,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              icon ?? Icons.star,
              color: textColor ?? Colors.blue.shade700,
              size: fontSize != null ? fontSize! + 4 : 24,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                fontSize: fontSize ?? 18,
                fontWeight: FontWeight.w600,
                color: textColor ?? Colors.blue.shade700,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// SPED-Friendly Validation Widget
class SPEDFriendlyValidationWidget extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;
  
  const SPEDFriendlyValidationWidget({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? Colors.red.shade200 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isError ? Icons.info_outline : Icons.lightbulb_outline,
                color: isError ? Colors.red.shade700 : Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isError ? Colors.red.shade700 : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: isError ? Colors.red.shade600 : Colors.orange.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
