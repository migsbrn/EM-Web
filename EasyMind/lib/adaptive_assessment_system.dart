import 'package:cloud_firestore/cloud_firestore.dart';

/// Adaptive Assessment System - Measures user performance and adjusts difficulty
class AdaptiveAssessmentSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Difficulty levels
  static const List<String> difficultyLevels = [
    'beginner',    // Basic concepts
    'intermediate', // Moderate difficulty
    'advanced',    // Challenging concepts
    'expert',      // Mastery level
  ];
  
  // Performance thresholds
  static const double excellentThreshold = 0.9;  // 90%+ correct
  static const double goodThreshold = 0.7;       // 70-89% correct
  static const double needsImprovementThreshold = 0.5; // 50-69% correct
  static const double strugglingThreshold = 0.3; // Below 50% correct
  
  /// Save assessment result and update user's adaptive level
  static Future<void> saveAssessmentResult({
    required String nickname,
    required String assessmentType,
    required String moduleName,
    required int totalQuestions,
    required int correctAnswers,
    required Duration timeSpent,
    required List<String> attemptedQuestions,
    required List<String> correctQuestions,
    String? contentId, // Add contentId parameter
  }) async {
    try {
      final performance = _calculatePerformance(correctAnswers, totalQuestions);
      final newLevel = await _determineNewLevel(nickname, assessmentType, performance);
      
      // Save detailed result
      await _firestore.collection('adaptiveAssessmentResults').add({
        'nickname': nickname,
        'assessmentType': assessmentType,
        'moduleName': moduleName,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'performance': performance,
        'timeSpent': timeSpent.inSeconds,
        'attemptedQuestions': attemptedQuestions,
        'correctQuestions': correctQuestions,
        'difficultyLevel': newLevel,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
        'contentId': contentId, // Add contentId to saved data
      });
      
      // Update user's current level for this assessment type
      await _updateUserLevel(nickname, assessmentType, newLevel);
      
      // Update overall progress
      await _updateOverallProgress(nickname, assessmentType, performance);
      
    } catch (e) {
      print('Error saving adaptive assessment result: $e');
    }
  }
  
  /// Calculate performance percentage
  static double _calculatePerformance(int correct, int total) {
    if (total == 0) return 0.0;
    return correct / total;
  }
  
  /// Determine new difficulty level based on performance
  static Future<String> _determineNewLevel(String nickname, String assessmentType, double performance) async {
    try {
      // Get current level
      final currentLevel = await getCurrentLevel(nickname, assessmentType);
      final currentIndex = difficultyLevels.indexOf(currentLevel);
      
      String newLevel;
      
      if (performance >= excellentThreshold) {
        // Excellent performance - move up one level (if not already at expert)
        if (currentIndex < difficultyLevels.length - 1) {
          newLevel = difficultyLevels[currentIndex + 1];
        } else {
          newLevel = currentLevel; // Stay at expert level
        }
      } else if (performance >= goodThreshold) {
        // Good performance - stay at current level
        newLevel = currentLevel;
      } else if (performance >= needsImprovementThreshold) {
        // Needs improvement - stay at current level or move down if at advanced/expert
        if (currentIndex >= 2) {
          newLevel = difficultyLevels[currentIndex - 1];
        } else {
          newLevel = currentLevel;
        }
      } else {
        // Struggling - move down one level (if not already at beginner)
        if (currentIndex > 0) {
          newLevel = difficultyLevels[currentIndex - 1];
        } else {
          newLevel = currentLevel; // Stay at beginner level
        }
      }
      
      return newLevel;
    } catch (e) {
      print('Error determining new level: $e');
      return 'beginner'; // Default to beginner on error
    }
  }
  
  /// Update user's current level for specific assessment type
  static Future<void> _updateUserLevel(String nickname, String assessmentType, String newLevel) async {
    try {
      await _firestore.collection('userAdaptiveLevels').doc(nickname).set({
        'nickname': nickname,
        'levels': {
          assessmentType: {
            'currentLevel': newLevel,
            'lastUpdated': FieldValue.serverTimestamp(),
          }
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user level: $e');
    }
  }
  
  /// Update overall progress tracking
  static Future<void> _updateOverallProgress(String nickname, String assessmentType, double performance) async {
    try {
      await _firestore.collection('userProgress').doc(nickname).set({
        'nickname': nickname,
        'assessmentProgress': {
          assessmentType: {
            'totalAttempts': FieldValue.increment(1),
            'averagePerformance': FieldValue.increment(performance),
            'lastPerformance': performance,
            'lastUpdated': FieldValue.serverTimestamp(),
          }
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating overall progress: $e');
    }
  }
  
  /// Get current difficulty level for user and assessment type
  static Future<String> getCurrentLevel(String nickname, String assessmentType) async {
    try {
      final doc = await _firestore.collection('userAdaptiveLevels').doc(nickname).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final levels = data['levels'] as Map<String, dynamic>?;
        
        if (levels != null && levels.containsKey(assessmentType)) {
          final assessmentData = levels[assessmentType] as Map<String, dynamic>;
          return assessmentData['currentLevel'] as String? ?? 'beginner';
        }
      }
      
      return 'beginner'; // Default level
    } catch (e) {
      print('Error getting current level: $e');
      return 'beginner';
    }
  }
  
  /// Get user's performance history for an assessment type
  static Future<List<Map<String, dynamic>>> getPerformanceHistory(
    String nickname, 
    String assessmentType,
    {int limit = 10}
  ) async {
    try {
      final query = await _firestore
          .collection('adaptiveAssessmentResults')
          .where('nickname', isEqualTo: nickname)
          .where('assessmentType', isEqualTo: assessmentType)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();
      
      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error getting performance history: $e');
      return [];
    }
  }
  
  /// Get adaptive questions based on current level
  static List<Map<String, dynamic>> getAdaptiveQuestions(
    String assessmentType,
    String difficultyLevel,
    int questionCount,
  ) {
    // This would be implemented based on your specific assessment types
    // For now, returning a placeholder structure
    return _generateQuestionsForLevel(assessmentType, difficultyLevel, questionCount);
  }
  
  /// Generate questions based on difficulty level
  static List<Map<String, dynamic>> _generateQuestionsForLevel(
    String assessmentType,
    String difficultyLevel,
    int questionCount,
  ) {
    // This is a placeholder implementation
    // In a real app, you'd have a database of questions organized by difficulty
    final questions = <Map<String, dynamic>>[];
    
    for (int i = 0; i < questionCount; i++) {
      questions.add({
        'id': '${assessmentType}_${difficultyLevel}_${i + 1}',
        'question': 'Sample question ${i + 1} for $difficultyLevel level',
        'options': ['Option A', 'Option B', 'Option C', 'Option D'],
        'correctAnswer': 0,
        'difficulty': difficultyLevel,
        'assessmentType': assessmentType,
        'points': _getPointsForDifficulty(difficultyLevel),
      });
    }
    
    return questions;
  }
  
  /// Get points based on difficulty level
  static int _getPointsForDifficulty(String difficultyLevel) {
    switch (difficultyLevel) {
      case 'beginner':
        return 10;
      case 'intermediate':
        return 20;
      case 'advanced':
        return 30;
      case 'expert':
        return 50;
      default:
        return 10;
    }
  }
  
  /// Get user's overall adaptive statistics
  static Future<Map<String, dynamic>> getUserAdaptiveStats(String nickname) async {
    try {
      final results = await _firestore
          .collection('adaptiveAssessmentResults')
          .where('nickname', isEqualTo: nickname)
          .get();
      
      if (results.docs.isEmpty) {
        return {
          'totalAssessments': 0,
          'averagePerformance': 0.0,
          'currentLevels': {},
          'improvementTrend': 'stable',
        };
      }
      
      final assessments = results.docs.map((doc) => doc.data()).toList();
      final totalAssessments = assessments.length;
      
      // Calculate average performance
      final totalPerformance = assessments.fold<double>(
        0.0, 
        (sum, assessment) => sum + (assessment['performance'] as double? ?? 0.0)
      );
      final averagePerformance = totalPerformance / totalAssessments;
      
      // Get current levels for each assessment type
      final currentLevels = <String, String>{};
      final assessmentTypes = assessments.map((a) => a['assessmentType'] as String).toSet();
      
      for (final type in assessmentTypes) {
        currentLevels[type] = await getCurrentLevel(nickname, type);
      }
      
      // Calculate improvement trend
      final recentPerformance = assessments.take(5).fold<double>(
        0.0, 
        (sum, assessment) => sum + (assessment['performance'] as double? ?? 0.0)
      ) / (assessments.length >= 5 ? 5 : assessments.length);
      
      final olderPerformance = assessments.skip(5).take(5).fold<double>(
        0.0, 
        (sum, assessment) => sum + (assessment['performance'] as double? ?? 0.0)
      ) / (assessments.length >= 10 ? 5 : assessments.length - 5);
      
      String improvementTrend = 'stable';
      if (recentPerformance > olderPerformance + 0.1) {
        improvementTrend = 'improving';
      } else if (recentPerformance < olderPerformance - 0.1) {
        improvementTrend = 'declining';
      }
      
      return {
        'totalAssessments': totalAssessments,
        'averagePerformance': averagePerformance,
        'currentLevels': currentLevels,
        'improvementTrend': improvementTrend,
        'recentPerformance': recentPerformance,
      };
    } catch (e) {
      print('Error getting user adaptive stats: $e');
      return {
        'totalAssessments': 0,
        'averagePerformance': 0.0,
        'currentLevels': {},
        'improvementTrend': 'stable',
      };
    }
  }
  
  /// Get performance feedback message for kids
  static String getPerformanceFeedback(double performance, String difficultyLevel) {
    if (performance >= excellentThreshold) {
      return "Wow! You're a superstar! 🌟 You mastered the $difficultyLevel level!";
    } else if (performance >= goodThreshold) {
      return "Great job! You're doing really well! 🎉 Keep practicing!";
    } else if (performance >= needsImprovementThreshold) {
      return "Good try! You're learning! 💪 Let's practice some more!";
    } else {
      return "Don't worry! Learning takes time! 🌱 Let's try easier questions!";
    }
  }
  
  /// Get next level suggestion
  static String getNextLevelSuggestion(String currentLevel, double performance) {
    final currentIndex = difficultyLevels.indexOf(currentLevel);
    
    if (performance >= excellentThreshold && currentIndex < difficultyLevels.length - 1) {
      return "You're ready for the next level! 🚀";
    } else if (performance < needsImprovementThreshold && currentIndex > 0) {
      return "Let's practice the basics first! 📚";
    } else {
      return "Keep practicing at this level! 💪";
    }
  }
}

/// Enum for assessment types
enum AssessmentType {
  alphabet,
  colors,
  shapes,
  family,
  rhyme,
  dailyTasks,
  pictureStory,
  sounds,
  shapeLearning,
}

/// Extension to get string representation
extension AssessmentTypeExtension on AssessmentType {
  String get value {
    switch (this) {
      case AssessmentType.alphabet:
        return 'alphabet';
      case AssessmentType.colors:
        return 'colors';
      case AssessmentType.shapes:
        return 'shapes';
      case AssessmentType.family:
        return 'family';
      case AssessmentType.rhyme:
        return 'rhyme';
      case AssessmentType.dailyTasks:
        return 'dailyTasks';
      case AssessmentType.pictureStory:
        return 'pictureStory';
      case AssessmentType.sounds:
        return 'sounds';
      case AssessmentType.shapeLearning:
        return 'shapeLearning';
    }
  }
}
