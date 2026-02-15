import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Smart Learning Recommendations System
/// Uses AI-like algorithms to provide personalized learning suggestions
class SmartLearningRecommendations {
  static final SmartLearningRecommendations _instance = SmartLearningRecommendations._internal();
  factory SmartLearningRecommendations() => _instance;
  SmartLearningRecommendations._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get personalized learning recommendations for a student
  Future<List<LearningRecommendation>> getRecommendations(String nickname) async {
    try {
      // Get student's learning data
      final studentData = await _getStudentLearningData(nickname);
      
      // Analyze learning patterns
      final analysis = await analyzeLearningPatterns(nickname);
      
      // Generate recommendations based on analysis
      final recommendations = await _generateRecommendations(nickname, studentData, analysis);
      
      return recommendations;
    } catch (e) {
      // Error getting recommendations: $e
      return _getDefaultRecommendations();
    }
  }

  /// Get student's comprehensive learning data
  Future<Map<String, dynamic>> _getStudentLearningData(String nickname) async {
    try {
      // Get user stats
      final userStatsDoc = await _firestore.collection('userStats').doc(nickname).get();
      final userStats = userStatsDoc.exists ? userStatsDoc.data()! : {};

      // Get lesson retention data
      final lessonRetentionQuery = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .get();
      
      final lessons = lessonRetentionQuery.docs.map((doc) => doc.data()).toList();

      // Get adaptive assessment data
      final adaptiveDoc = await _firestore.collection('userAdaptiveLevels').doc(nickname).get();
      final adaptiveData = adaptiveDoc.exists ? adaptiveDoc.data()! : {};

      // Get focus session data
      final focusQuery = await _firestore
          .collection('focusSessions')
          .where('nickname', isEqualTo: nickname)
          .get();
      
      final focusSessions = focusQuery.docs.map((doc) => doc.data()).toList();

      return {
        'userStats': userStats,
        'lessons': lessons,
        'adaptiveData': adaptiveData,
        'focusSessions': focusSessions,
      };
    } catch (e) {
      // Error getting student learning data: $e
      return {};
    }
  }

  /// Analyze learning patterns and identify areas for improvement
  Future<LearningAnalysis> analyzeLearningPatterns(String nickname) async {
    try {
      final data = await _getStudentLearningData(nickname);
      final lessons = data['lessons'] as List<Map<String, dynamic>>? ?? [];
      final focusSessions = data['focusSessions'] as List<Map<String, dynamic>>? ?? [];

      // Analyze subject performance
      final subjectPerformance = _analyzeSubjectPerformance(lessons);
      
      // Analyze learning streaks
      final streakAnalysis = _analyzeLearningStreaks(lessons);
      
      // Analyze focus patterns
      final focusAnalysis = _analyzeFocusPatterns(focusSessions);
      
      // Analyze difficulty progression
      final difficultyAnalysis = _analyzeDifficultyProgression(lessons);
      
      // Identify learning gaps
      final learningGaps = _identifyLearningGaps(lessons, subjectPerformance);
      
      // Calculate learning velocity
      final learningVelocity = _calculateLearningVelocity(lessons);

      return LearningAnalysis(
        subjectPerformance: subjectPerformance,
        streakAnalysis: streakAnalysis,
        focusAnalysis: focusAnalysis,
        difficultyAnalysis: difficultyAnalysis,
        learningGaps: learningGaps,
        learningVelocity: learningVelocity,
        overallScore: _calculateOverallScore(subjectPerformance, streakAnalysis, focusAnalysis),
      );
    } catch (e) {
      // Error analyzing learning patterns: $e
      return LearningAnalysis.empty();
    }
  }

  /// Analyze performance across different subjects
  Map<String, double> _analyzeSubjectPerformance(List<Map<String, dynamic>> lessons) {
    final Map<String, List<double>> subjectScores = {};
    
    for (final lesson in lessons) {
      final moduleName = lesson['moduleName'] ?? 'Unknown';
      final score = lesson['retentionScore'] ?? 0.0;
      
      if (!subjectScores.containsKey(moduleName)) {
        subjectScores[moduleName] = [];
      }
      subjectScores[moduleName]!.add(score);
    }
    
    final Map<String, double> averages = {};
    subjectScores.forEach((subject, scores) {
      averages[subject] = scores.reduce((a, b) => a + b) / scores.length;
    });
    
    return averages;
  }

  /// Analyze learning streaks and consistency
  StreakAnalysis _analyzeLearningStreaks(List<Map<String, dynamic>> lessons) {
    if (lessons.isEmpty) {
      return StreakAnalysis.empty();
    }
    
    // Sort lessons by completion date
    lessons.sort((a, b) {
      final aTime = (a['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });
    
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;
    DateTime? lastDate;
    
    for (final lesson in lessons) {
      final completedAt = (lesson['completedAt'] as Timestamp?)?.toDate();
      if (completedAt == null) continue;
      
      final lessonDate = DateTime(completedAt.year, completedAt.month, completedAt.day);
      
      if (lastDate == null) {
        tempStreak = 1;
      } else {
        final daysDiff = lessonDate.difference(lastDate).inDays;
        if (daysDiff == 1) {
          tempStreak++;
        } else if (daysDiff > 1) {
          longestStreak = math.max(longestStreak, tempStreak);
          tempStreak = 1;
        }
      }
      
      lastDate = lessonDate;
    }
    
    longestStreak = math.max(longestStreak, tempStreak);
    currentStreak = tempStreak;
    
    // Check if current streak is active (within last 2 days)
    final now = DateTime.now();
    final daysSinceLastLesson = lastDate != null ? now.difference(lastDate).inDays : 999;
    if (daysSinceLastLesson > 2) {
      currentStreak = 0;
    }
    
    return StreakAnalysis(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      consistency: lessons.isNotEmpty ? (longestStreak / lessons.length) : 0.0,
      lastActivity: lastDate,
    );
  }

  /// Analyze focus patterns and attention span
  FocusAnalysis _analyzeFocusPatterns(List<Map<String, dynamic>> focusSessions) {
    if (focusSessions.isEmpty) {
      return FocusAnalysis.empty();
    }
    
    final completedSessions = focusSessions.where((s) => s['status'] == 'completed').toList();
    final avgDuration = completedSessions.isNotEmpty 
        ? completedSessions.map((s) => s['duration'] ?? 0).reduce((a, b) => a + b) / completedSessions.length
        : 0.0;
    
    final completionRate = focusSessions.isNotEmpty 
        ? completedSessions.length / focusSessions.length 
        : 0.0;
    
    return FocusAnalysis(
      averageDuration: avgDuration,
      completionRate: completionRate,
      totalSessions: focusSessions.length,
      completedSessions: completedSessions.length,
    );
  }

  /// Analyze difficulty progression
  DifficultyAnalysis _analyzeDifficultyProgression(List<Map<String, dynamic>> lessons) {
    if (lessons.isEmpty) {
      return DifficultyAnalysis.empty();
    }
    
    // Group lessons by module and analyze progression
    final Map<String, List<Map<String, dynamic>>> moduleLessons = {};
    for (final lesson in lessons) {
      final module = lesson['moduleName'] ?? 'Unknown';
      if (!moduleLessons.containsKey(module)) {
        moduleLessons[module] = [];
      }
      moduleLessons[module]!.add(lesson);
    }
    
    final Map<String, double> moduleProgression = {};
    moduleLessons.forEach((module, moduleLessonsList) {
      if (moduleLessonsList.length > 1) {
        // Sort by completion date
        moduleLessonsList.sort((a, b) {
          final aTime = (a['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          final bTime = (b['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
          return aTime.compareTo(bTime);
        });
        
        // Calculate improvement trend
        final firstHalf = moduleLessonsList.take(moduleLessonsList.length ~/ 2).toList();
        final secondHalf = moduleLessonsList.skip(moduleLessonsList.length ~/ 2).toList();
        
        final firstAvg = firstHalf.map((l) => l['retentionScore'] ?? 0.0).reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.map((l) => l['retentionScore'] ?? 0.0).reduce((a, b) => a + b) / secondHalf.length;
        
        moduleProgression[module] = secondAvg - firstAvg;
      } else {
        moduleProgression[module] = 0.0;
      }
    });
    
    return DifficultyAnalysis(
      moduleProgression: moduleProgression,
      overallProgression: moduleProgression.values.isNotEmpty 
          ? moduleProgression.values.reduce((a, b) => a + b) / moduleProgression.length 
          : 0.0,
    );
  }

  /// Identify learning gaps and areas needing attention
  List<String> _identifyLearningGaps(List<Map<String, dynamic>> lessons, Map<String, double> subjectPerformance) {
    final List<String> gaps = [];
    
    // Check for subjects with low performance
    subjectPerformance.forEach((subject, score) {
      if (score < 60.0) {
        gaps.add('Low performance in $subject');
      }
    });
    
    // Check for subjects with no recent activity
    final now = DateTime.now();
    final subjectLastActivity = <String, DateTime>{};
    
    for (final lesson in lessons) {
      final moduleName = lesson['moduleName'] ?? 'Unknown';
      final completedAt = (lesson['completedAt'] as Timestamp?)?.toDate();
      
      if (completedAt != null) {
        if (!subjectLastActivity.containsKey(moduleName) || 
            completedAt.isAfter(subjectLastActivity[moduleName]!)) {
          subjectLastActivity[moduleName] = completedAt;
        }
      }
    }
    
    subjectLastActivity.forEach((subject, lastActivity) {
      final daysSinceLastActivity = now.difference(lastActivity).inDays;
      if (daysSinceLastActivity > 7) {
        gaps.add('No recent activity in $subject');
      }
    });
    
    return gaps;
  }

  /// Calculate learning velocity (lessons per day)
  double _calculateLearningVelocity(List<Map<String, dynamic>> lessons) {
    if (lessons.length < 2) return 0.0;
    
    // Sort by completion date
    lessons.sort((a, b) {
      final aTime = (a['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return aTime.compareTo(bTime);
    });
    
    final firstLesson = lessons.first;
    final lastLesson = lessons.last;
    
    final firstDate = (firstLesson['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final lastDate = (lastLesson['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    final daysDiff = lastDate.difference(firstDate).inDays;
    return daysDiff > 0 ? lessons.length / daysDiff : 0.0;
  }

  /// Calculate overall learning score
  double _calculateOverallScore(Map<String, double> subjectPerformance, StreakAnalysis streakAnalysis, FocusAnalysis focusAnalysis) {
    if (subjectPerformance.isEmpty) return 0.0;
    
    // Subject performance (40%)
    final avgSubjectScore = subjectPerformance.values.reduce((a, b) => a + b) / subjectPerformance.length;
    
    // Streak consistency (30%)
    final streakScore = math.min(streakAnalysis.consistency * 100, 100.0);
    
    // Focus completion rate (30%)
    final focusScore = focusAnalysis.completionRate * 100;
    
    return (avgSubjectScore * 0.4) + (streakScore * 0.3) + (focusScore * 0.3);
  }

  /// Generate personalized recommendations
  Future<List<LearningRecommendation>> _generateRecommendations(
    String nickname, 
    Map<String, dynamic> studentData, 
    LearningAnalysis analysis
  ) async {
    final List<LearningRecommendation> recommendations = [];
    
    // Recommendation 1: Address learning gaps
    for (final gap in analysis.learningGaps) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.improvement,
        priority: Priority.high,
        title: 'Focus on Weak Areas',
        description: gap,
        action: 'Practice more exercises in this area',
        estimatedTime: '15-20 minutes',
        icon: '🎯',
        color: Colors.orange,
      ));
    }
    
    // Recommendation 2: Maintain learning streak
    if (analysis.streakAnalysis.currentStreak > 0 && analysis.streakAnalysis.currentStreak < 7) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.consistency,
        priority: Priority.medium,
        title: 'Keep Your Streak Going!',
        description: 'You have a ${analysis.streakAnalysis.currentStreak}-day streak. Keep it up!',
        action: 'Complete a lesson today to maintain your streak',
        estimatedTime: '10-15 minutes',
        icon: '🔥',
        color: Colors.red,
      ));
    }
    
    // Recommendation 3: Challenge yourself
    final strongSubjects = analysis.subjectPerformance.entries
        .where((e) => e.value > 80.0)
        .map((e) => e.key)
        .toList();
    
    if (strongSubjects.isNotEmpty) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.challenge,
        priority: Priority.medium,
        title: 'Ready for a Challenge?',
        description: 'You\'re doing great in ${strongSubjects.first}! Try advanced exercises.',
        action: 'Attempt more challenging content in this subject',
        estimatedTime: '20-25 minutes',
        icon: '🚀',
        color: Colors.purple,
      ));
    }
    
    // Recommendation 4: Focus improvement
    if (analysis.focusAnalysis.completionRate < 0.7) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.focus,
        priority: Priority.high,
        title: 'Improve Focus',
        description: 'Your focus completion rate is ${(analysis.focusAnalysis.completionRate * 100).round()}%. Let\'s improve it!',
        action: 'Try shorter, more focused learning sessions',
        estimatedTime: '10-15 minutes',
        icon: '🧠',
        color: Colors.blue,
      ));
    }
    
    // Recommendation 5: Explore new subjects
    final allSubjects = ['Alphabet', 'Numbers', 'Colors', 'Shapes', 'Animals', 'Family'];
    final studiedSubjects = analysis.subjectPerformance.keys.toList();
    final unstudiedSubjects = allSubjects.where((s) => !studiedSubjects.any((studied) => studied.toLowerCase().contains(s.toLowerCase()))).toList();
    
    if (unstudiedSubjects.isNotEmpty) {
      recommendations.add(LearningRecommendation(
        type: RecommendationType.exploration,
        priority: Priority.low,
        title: 'Explore New Topics',
        description: 'Try learning about ${unstudiedSubjects.first}!',
        action: 'Start learning about this new subject',
        estimatedTime: '15-20 minutes',
        icon: '🌟',
        color: Colors.green,
      ));
    }
    
    // Sort by priority
    recommendations.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    
    return recommendations.take(5).toList(); // Return top 5 recommendations
  }

  /// Get default recommendations for new students
  List<LearningRecommendation> _getDefaultRecommendations() {
    return [
      LearningRecommendation(
        type: RecommendationType.exploration,
        priority: Priority.high,
        title: 'Start Your Learning Journey!',
        description: 'Welcome! Let\'s begin with the basics.',
        action: 'Try the Alphabet learning module',
        estimatedTime: '15-20 minutes',
        icon: '🌟',
        color: Colors.blue,
      ),
      LearningRecommendation(
        type: RecommendationType.consistency,
        priority: Priority.medium,
        title: 'Build a Learning Habit',
        description: 'Learning a little bit every day helps you grow!',
        action: 'Set a daily learning goal',
        estimatedTime: '10-15 minutes',
        icon: '📅',
        color: Colors.green,
      ),
    ];
  }
}

/// Data models for learning analysis
class LearningAnalysis {
  final Map<String, double> subjectPerformance;
  final StreakAnalysis streakAnalysis;
  final FocusAnalysis focusAnalysis;
  final DifficultyAnalysis difficultyAnalysis;
  final List<String> learningGaps;
  final double learningVelocity;
  final double overallScore;

  LearningAnalysis({
    required this.subjectPerformance,
    required this.streakAnalysis,
    required this.focusAnalysis,
    required this.difficultyAnalysis,
    required this.learningGaps,
    required this.learningVelocity,
    required this.overallScore,
  });

  LearningAnalysis.empty() :
    subjectPerformance = {},
    streakAnalysis = StreakAnalysis.empty(),
    focusAnalysis = FocusAnalysis.empty(),
    difficultyAnalysis = DifficultyAnalysis.empty(),
    learningGaps = [],
    learningVelocity = 0.0,
    overallScore = 0.0;
}

class StreakAnalysis {
  final int currentStreak;
  final int longestStreak;
  final double consistency;
  final DateTime? lastActivity;

  StreakAnalysis({
    required this.currentStreak,
    required this.longestStreak,
    required this.consistency,
    required this.lastActivity,
  });

  StreakAnalysis.empty() :
    currentStreak = 0,
    longestStreak = 0,
    consistency = 0.0,
    lastActivity = null;
}

class FocusAnalysis {
  final double averageDuration;
  final double completionRate;
  final int totalSessions;
  final int completedSessions;

  FocusAnalysis({
    required this.averageDuration,
    required this.completionRate,
    required this.totalSessions,
    required this.completedSessions,
  });

  FocusAnalysis.empty() :
    averageDuration = 0.0,
    completionRate = 0.0,
    totalSessions = 0,
    completedSessions = 0;
}

class DifficultyAnalysis {
  final Map<String, double> moduleProgression;
  final double overallProgression;

  DifficultyAnalysis({
    required this.moduleProgression,
    required this.overallProgression,
  });

  DifficultyAnalysis.empty() :
    moduleProgression = {},
    overallProgression = 0.0;
}

class LearningRecommendation {
  final RecommendationType type;
  final Priority priority;
  final String title;
  final String description;
  final String action;
  final String estimatedTime;
  final String icon;
  final Color color;

  LearningRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    required this.action,
    required this.estimatedTime,
    required this.icon,
    required this.color,
  });
}

enum RecommendationType {
  improvement,
  consistency,
  challenge,
  focus,
  exploration,
}

enum Priority {
  low,
  medium,
  high,
}
