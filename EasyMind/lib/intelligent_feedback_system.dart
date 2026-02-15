import 'package:flutter/material.dart';
import 'intelligent_nlp_system.dart';

/// Intelligent Feedback System - Provides smart, contextual feedback based on NLP analysis
class IntelligentFeedbackSystem {
  
  /// Generate intelligent feedback for assessment results
  static String generateAssessmentFeedback({
    required double performance,
    required String assessmentType,
    required String userSpeech,
    required String nickname,
  }) {
    final analysis = IntelligentNLPSystem.analyzeSpeech(userSpeech);
    
    // Base performance feedback
    String baseFeedback = _getPerformanceFeedback(performance, assessmentType);
    
    // Combine with NLP analysis
    String intelligentResponse = _combineFeedback(baseFeedback, analysis, nickname);
    
    return intelligentResponse;
  }
  
  /// Get performance-based feedback
  static String _getPerformanceFeedback(double performance, String assessmentType) {
    if (performance >= 0.9) {
      return _getExcellentFeedback(assessmentType);
    } else if (performance >= 0.7) {
      return _getGoodFeedback(assessmentType);
    } else if (performance >= 0.5) {
      return _getNeedsImprovementFeedback(assessmentType);
    } else {
      return _getStrugglingFeedback(assessmentType);
    }
  }
  
  /// Excellent performance feedback
  static String _getExcellentFeedback(String assessmentType) {
    final feedbacks = {
      'alphabet': "Wow! You know your letters perfectly! You're a letter master! 🌟",
      'colors': "Amazing! You know all your colors! You're a color expert! 🌈",
      'shapes': "Fantastic! You know all your shapes! You're a shape wizard! 🔷",
      'numbers': "Incredible! You're a number genius! You can count anything! 🔢",
      'family': "Wonderful! You know your family so well! You're so loving! 👨‍👩‍👧‍👦",
      'rhyme': "Brilliant! You're a rhyming champion! You're so creative! 🎵",
      'dailyTasks': "Excellent! You know your daily tasks! You're so responsible! ✅",
      'pictureStory': "Outstanding! You understand stories so well! You're a storyteller! 📚",
      'sounds': "Perfect! You know your sounds! You're a sound detective! 🔊",
    };
    
    return feedbacks[assessmentType] ?? "Incredible! You're a superstar! 🌟";
  }
  
  /// Good performance feedback
  static String _getGoodFeedback(String assessmentType) {
    final feedbacks = {
      'alphabet': "Great job with your letters! You're getting really good! 📚",
      'colors': "Nice work with colors! You're learning so well! 🌈",
      'shapes': "Good job with shapes! You're getting better! 🔷",
      'numbers': "Well done with numbers! You're counting great! 🔢",
      'family': "Good work! You know your family well! 👨‍👩‍👧‍👦",
      'rhyme': "Nice rhyming! You're getting creative! 🎵",
      'dailyTasks': "Good job! You're learning your tasks! ✅",
      'pictureStory': "Well done! You understand stories! 📚",
      'sounds': "Good work! You're learning sounds! 🔊",
    };
    
    return feedbacks[assessmentType] ?? "Great job! You're doing amazing! 🎉";
  }
  
  /// Needs improvement feedback
  static String _getNeedsImprovementFeedback(String assessmentType) {
    final feedbacks = {
      'alphabet': "Good try with letters! Let's practice more! 📚",
      'colors': "Nice effort with colors! We'll learn more! 🌈",
      'shapes': "Good attempt with shapes! Let's try again! 🔷",
      'numbers': "Good try with numbers! We'll practice more! 🔢",
      'family': "Nice effort! Let's learn more about family! 👨‍👩‍👧‍👦",
      'rhyme': "Good try! Let's practice rhyming more! 🎵",
      'dailyTasks': "Nice effort! Let's learn more tasks! ✅",
      'pictureStory': "Good try! Let's read more stories! 📚",
      'sounds': "Nice effort! Let's learn more sounds! 🔊",
    };
    
    return feedbacks[assessmentType] ?? "Good try! You're learning! 💪";
  }
  
  /// Struggling feedback
  static String _getStrugglingFeedback(String assessmentType) {
    final feedbacks = {
      'alphabet': "Don't worry! Letters take time to learn! Let's practice! 📚",
      'colors': "It's okay! Colors are fun to learn! Let's try again! 🌈",
      'shapes': "No problem! Shapes are everywhere! Let's find them! 🔷",
      'numbers': "That's fine! Numbers are tricky! Let's count together! 🔢",
      'family': "It's okay! Families are special! Let's learn together! 👨‍👩‍👧‍👦",
      'rhyme': "No worries! Rhyming is fun! Let's try again! 🎵",
      'dailyTasks': "That's fine! Tasks take practice! Let's learn! ✅",
      'pictureStory': "It's okay! Stories are fun! Let's read together! 📚",
      'sounds': "No problem! Sounds are everywhere! Let's listen! 🔊",
    };
    
    return feedbacks[assessmentType] ?? "Don't worry! Learning takes time! 🌱";
  }
  
  /// Combine base feedback with NLP analysis
  static String _combineFeedback(String baseFeedback, NLPAnalysis analysis, String nickname) {
    if (analysis.emotion == 'positive') {
      return "$baseFeedback ${analysis.response}";
    } else if (analysis.emotion == 'negative') {
      return "Don't worry, $nickname! ${analysis.response} $baseFeedback";
    } else if (analysis.intent == 'help') {
      return "$baseFeedback ${analysis.response}";
    } else if (analysis.intent == 'completion') {
      return "$baseFeedback ${analysis.response}";
    } else {
      return baseFeedback;
    }
  }
  
  /// Get contextual encouragement based on speech
  static String getContextualEncouragement(String speechInput, String assessmentType) {
    final analysis = IntelligentNLPSystem.analyzeSpeech(speechInput);
    
    if (analysis.emotion == 'negative') {
      return _getEncouragementForStruggle(assessmentType);
    } else if (analysis.intent == 'encouragement') {
      return analysis.response;
    } else {
      return _getGeneralEncouragement(assessmentType);
    }
  }
  
  /// Get encouragement for struggling students
  static String _getEncouragementForStruggle(String assessmentType) {
    final encouragements = {
      'alphabet': "Letters are tricky! But you're getting better! Keep trying! 📚",
      'colors': "Colors are fun! Don't give up! You're learning! 🌈",
      'shapes': "Shapes are everywhere! You'll find them! Keep looking! 🔷",
      'numbers': "Numbers take practice! You're doing great! Keep counting! 🔢",
      'family': "Families are special! You're learning! Keep going! 👨‍👩‍👧‍👦",
      'rhyme': "Rhyming is creative! You're getting it! Keep trying! 🎵",
      'dailyTasks': "Tasks take time! You're learning! Keep practicing! ✅",
      'pictureStory': "Stories are fun! You're understanding! Keep reading! 📚",
      'sounds': "Sounds are everywhere! You're listening! Keep trying! 🔊",
    };
    
    return encouragements[assessmentType] ?? "You're doing great! Don't give up! 🌟";
  }
  
  /// Get general encouragement
  static String _getGeneralEncouragement(String assessmentType) {
    final encouragements = {
      'alphabet': "You're learning letters so well! Keep it up! 📚",
      'colors': "You're a color expert! Amazing work! 🌈",
      'shapes': "You're finding shapes everywhere! Great job! 🔷",
      'numbers': "You're counting like a pro! Wonderful! 🔢",
      'family': "You know your family so well! Beautiful! 👨‍👩‍👧‍👦",
      'rhyme': "You're rhyming like a poet! Fantastic! 🎵",
      'dailyTasks': "You're learning your tasks! Excellent! ✅",
      'pictureStory': "You understand stories so well! Amazing! 📚",
      'sounds': "You're listening to sounds! Great work! 🔊",
    };
    
    return encouragements[assessmentType] ?? "You're doing amazing! Keep it up! ⭐";
  }
  
  /// Get help suggestions based on speech input
  static String getHelpSuggestion(String speechInput, String assessmentType) {
    final analysis = IntelligentNLPSystem.analyzeSpeech(speechInput);
    
    if (analysis.intent == 'help' || analysis.intent == 'confusion') {
      return _getContextualHelp(assessmentType);
    }
    
    return analysis.response;
  }
  
  /// Get contextual help for specific assessment types
  static String _getContextualHelp(String assessmentType) {
    final helpMessages = {
      'alphabet': "Let me help you with letters! Try saying each letter out loud! A, B, C... 📚",
      'colors': "Colors are everywhere! Look around and tell me what colors you see! 🌈",
      'shapes': "Shapes are all around us! Can you find a circle or square? 🔷",
      'numbers': "Numbers help us count! Let's count together! 1, 2, 3... 🔢",
      'family': "Families are special! Tell me about your mom, dad, or siblings! 👨‍👩‍👧‍👦",
      'rhyme': "Rhyming is fun! Words that sound the same rhyme! Cat, hat, bat! 🎵",
      'dailyTasks': "Daily tasks are things we do every day! Like brushing teeth! ✅",
      'pictureStory': "Stories have pictures that tell us what's happening! Look carefully! 📚",
      'sounds': "Sounds are what we hear! Listen carefully to each sound! 🔊",
    };
    
    return helpMessages[assessmentType] ?? "I'm here to help! What would you like to learn? 🤗";
  }
  
  /// Generate next step suggestions
  static String getNextStepSuggestion(String speechInput, String assessmentType, double performance) {
    final analysis = IntelligentNLPSystem.analyzeSpeech(speechInput);
    
    if (analysis.intent == 'completion') {
      return _getCompletionSuggestion(assessmentType, performance);
    } else if (analysis.intent == 'encouragement') {
      return _getEncouragementSuggestion(assessmentType);
    } else if (analysis.emotion == 'negative') {
      return _getSupportSuggestion(assessmentType);
    } else {
      return _getGeneralSuggestion(assessmentType, performance);
    }
  }
  
  /// Get completion suggestions
  static String _getCompletionSuggestion(String assessmentType, double performance) {
    if (performance >= 0.8) {
      return "Amazing work! You're ready for the next level! 🚀";
    } else if (performance >= 0.6) {
      return "Great job! Let's practice a bit more! 💪";
    } else {
      return "Good effort! Let's try some easier questions! 📚";
    }
  }
  
  /// Get encouragement suggestions
  static String _getEncouragementSuggestion(String assessmentType) {
    return "You're doing great! Let's keep learning together! 🌟";
  }
  
  /// Get support suggestions
  static String _getSupportSuggestion(String assessmentType) {
    return "Don't worry! Learning takes time! I'm here to help! 🤗";
  }
  
  /// Get general suggestions
  static String _getGeneralSuggestion(String assessmentType, double performance) {
    if (performance >= 0.8) {
      return "You're doing amazing! Ready for more challenges? 🎯";
    } else if (performance >= 0.6) {
      return "Good work! Let's practice some more! 📚";
    } else {
      return "Let's try some easier questions first! 🌱";
    }
  }
}

/// Intelligent Feedback Widget for Assessments
class IntelligentFeedbackWidget extends StatefulWidget {
  final String nickname;
  final String assessmentType;
  final double performance;
  final String userSpeech;
  final VoidCallback? onNextStep;
  final VoidCallback? onHelp;
  
  const IntelligentFeedbackWidget({
    super.key,
    required this.nickname,
    required this.assessmentType,
    required this.performance,
    required this.userSpeech,
    this.onNextStep,
    this.onHelp,
  });
  
  @override
  State<IntelligentFeedbackWidget> createState() => _IntelligentFeedbackWidgetState();
}

class _IntelligentFeedbackWidgetState extends State<IntelligentFeedbackWidget>
    with TickerProviderStateMixin {
  late AnimationController _feedbackController;
  late AnimationController _buttonController;
  late Animation<double> _feedbackAnimation;
  late Animation<double> _buttonAnimation;
  
  String _feedback = '';
  String _encouragement = '';
  String _nextStep = '';
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _generateIntelligentFeedback();
  }
  
  void _initializeAnimations() {
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _feedbackAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.elasticOut,
    ));
    
    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.bounceOut,
    ));
    
    _feedbackController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
  }
  
  void _generateIntelligentFeedback() {
    setState(() {
      _feedback = IntelligentFeedbackSystem.generateAssessmentFeedback(
        performance: widget.performance,
        assessmentType: widget.assessmentType,
        userSpeech: widget.userSpeech,
        nickname: widget.nickname,
      );
      
      _encouragement = IntelligentFeedbackSystem.getContextualEncouragement(
        widget.userSpeech,
        widget.assessmentType,
      );
      
      _nextStep = IntelligentFeedbackSystem.getNextStepSuggestion(
        widget.userSpeech,
        widget.assessmentType,
        widget.performance,
      );
    });
  }
  
  @override
  void dispose() {
    _feedbackController.dispose();
    _buttonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getPerformanceColors(widget.performance),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getPerformanceColors(widget.performance).first.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Feedback Message
                Text(
                  _feedback,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Encouragement
                Text(
                  _encouragement,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Next Step Suggestion
                AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _nextStep,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonAnimation.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.onNextStep,
                            icon: const Icon(Icons.arrow_forward, color: Colors.white),
                            label: const Text(
                              "Next",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: widget.onHelp,
                            icon: const Icon(Icons.help, color: Colors.white),
                            label: const Text(
                              "Help",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  List<Color> _getPerformanceColors(double performance) {
    if (performance >= 0.8) {
      return [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)]; // Green
    } else if (performance >= 0.6) {
      return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]; // Teal
    } else if (performance >= 0.4) {
      return [const Color(0xFFFFD93D), const Color(0xFFFFB74D)]; // Yellow
    } else {
      return [const Color(0xFFFF6B6B), const Color(0xFFE53E3E)]; // Red
    }
  }
}
