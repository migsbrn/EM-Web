import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Memory Retention System for EasyMind App
/// Implements spaced repetition algorithm to help users retain lessons
class MemoryRetentionSystem {
  static final MemoryRetentionSystem _instance = MemoryRetentionSystem._internal();
  factory MemoryRetentionSystem() => _instance;
  MemoryRetentionSystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Spaced repetition intervals (in days)
  static const List<int> _intervals = [1, 3, 7, 14, 30, 60, 120];

  /// Save lesson completion with retention tracking
  Future<void> saveLessonCompletion({
    required String nickname,
    required String moduleName,
    required String lessonType,
    required int score,
    required int totalQuestions,
    required bool passed,
  }) async {
    try {
      final now = DateTime.now();
      final lessonData = {
        'nickname': nickname,
        'moduleName': moduleName,
        'lessonType': lessonType,
        'score': score,
        'totalQuestions': totalQuestions,
        'passed': passed,
        'completedAt': Timestamp.fromDate(now),
        'nextReviewDate': Timestamp.fromDate(now.add(Duration(days: _intervals[0]))),
        'reviewCount': 0,
        'masteryLevel': passed ? 1 : 0,
        'lastReviewDate': null,
        'retentionScore': _calculateRetentionScore(score, totalQuestions),
      };

      await _firestore.collection('lessonRetention').add(lessonData);
      
      // Update local progress tracking
      await _updateLocalProgress(nickname, moduleName, lessonType);
      
      // Update student profile with lesson completion
      await _updateStudentProfile(nickname, passed);
      
      print('Lesson completion saved: $moduleName - $lessonType');
    } catch (e) {
      print('Error saving lesson completion: $e');
    }
  }

  /// Get all completed lessons for a user
  Future<List<Map<String, dynamic>>> getAllCompletedLessons(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting all completed lessons: $e');
      return [];
    }
  }

  /// Get lessons due for review
  Future<List<Map<String, dynamic>>> getLessonsDueForReview(String nickname) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('nextReviewDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting lessons due for review: $e');
      return [];
    }
  }

  /// Update lesson after review
  Future<void> updateLessonAfterReview({
    required String lessonId,
    required bool correct,
    required String nickname,
  }) async {
    try {
      final docRef = _firestore.collection('lessonRetention').doc(lessonId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final reviewCount = (data['reviewCount'] ?? 0) + 1;
      final masteryLevel = data['masteryLevel'] ?? 0;
      
      // Calculate next review date based on spaced repetition
      int nextInterval;
      if (correct) {
        // Correct answer - increase interval
        final currentLevel = masteryLevel.clamp(0, _intervals.length - 1);
        nextInterval = _intervals[currentLevel];
        final newMasteryLevel = (masteryLevel + 1).clamp(0, _intervals.length - 1);
        
        await docRef.update({
          'masteryLevel': newMasteryLevel,
          'reviewCount': reviewCount,
          'lastReviewDate': Timestamp.now(),
          'nextReviewDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: nextInterval))
          ),
        });
      } else {
        // Wrong answer - reset to first interval
        await docRef.update({
          'masteryLevel': 0,
          'reviewCount': reviewCount,
          'lastReviewDate': Timestamp.now(),
          'nextReviewDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: _intervals[0]))
          ),
        });
      }
      
      print('Lesson review updated: $lessonId');
    } catch (e) {
      print('Error updating lesson review: $e');
    }
  }

  /// Get user's retention statistics
  Future<Map<String, dynamic>> getUserRetentionStats(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .get();

      int totalLessons = querySnapshot.docs.length;
      int masteredLessons = 0;
      int lessonsDueForReview = 0;
      double averageRetentionScore = 0.0;
      
      final now = DateTime.now();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final masteryLevel = data['masteryLevel'] ?? 0;
        final nextReviewDate = (data['nextReviewDate'] as Timestamp).toDate();
        final retentionScore = data['retentionScore'] ?? 0.0;
        
        if (masteryLevel >= 3) masteredLessons++;
        if (nextReviewDate.isBefore(now)) lessonsDueForReview++;
        averageRetentionScore += retentionScore;
      }
      
      if (totalLessons > 0) {
        averageRetentionScore /= totalLessons;
      }
      
      return {
        'totalLessons': totalLessons,
        'masteredLessons': masteredLessons,
        'lessonsDueForReview': lessonsDueForReview,
        'averageRetentionScore': averageRetentionScore,
        'masteryPercentage': totalLessons > 0 ? (masteredLessons / totalLessons) * 100 : 0.0,
      };
    } catch (e) {
      print('Error getting retention stats: $e');
      return {
        'totalLessons': 0,
        'masteredLessons': 0,
        'lessonsDueForReview': 0,
        'averageRetentionScore': 0.0,
        'masteryPercentage': 0.0,
      };
    }
  }

  /// Calculate retention score based on performance
  double _calculateRetentionScore(int score, int totalQuestions) {
    if (totalQuestions == 0) return 0.0;
    return (score / totalQuestions) * 100.0;
  }

  /// Update student profile with lesson completion data
  Future<void> _updateStudentProfile(String nickname, bool passed) async {
    try {
      // Find student by nickname
      final querySnapshot = await _firestore
          .collection('students')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final studentDoc = querySnapshot.docs.first;
        final currentData = studentDoc.data();
        
        final newTotalLessons = (currentData['totalLessonsCompleted'] ?? 0) + 1;
        final newCurrentStreak = passed ? (currentData['currentStreak'] ?? 0) + 1 : 0;
        final newLongestStreak = passed 
            ? ((currentData['currentStreak'] ?? 0) + 1).clamp(0, currentData['longestStreak'] ?? 0)
            : (currentData['longestStreak'] ?? 0);
        
        // Update student profile
        await studentDoc.reference.update({
          'totalLessonsCompleted': newTotalLessons,
          'lastActivity': Timestamp.now(),
          'currentStreak': newCurrentStreak,
          'longestStreak': newLongestStreak,
        });
        
        // Also update userStats collection to keep them synchronized
        try {
          await _firestore.collection('userStats').doc(nickname).set({
            'nickname': nickname,
            'streakDays': newCurrentStreak,
            'lastActivity': Timestamp.now(),
          }, SetOptions(merge: true));
          print('UserStats collection updated for $nickname');
        } catch (e) {
          print('Error updating userStats collection: $e');
        }
        
        print('Student profile updated: $nickname');
      }
    } catch (e) {
      print('Error updating student profile: $e');
    }
  }

  /// Update local progress tracking
  Future<void> _updateLocalProgress(String nickname, String moduleName, String lessonType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${nickname}_${moduleName}_${lessonType}_lastCompleted';
      await prefs.setString(key, DateTime.now().toIso8601String());
      
      // Track completion streak
      final streakKey = '${nickname}_${moduleName}_streak';
      final currentStreak = prefs.getInt(streakKey) ?? 0;
      await prefs.setInt(streakKey, currentStreak + 1);
      
    } catch (e) {
      print('Error updating local progress: $e');
    }
  }

  /// Get completion streak for a module
  Future<int> getCompletionStreak(String nickname, String moduleName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streakKey = '${nickname}_${moduleName}_streak';
      return prefs.getInt(streakKey) ?? 0;
    } catch (e) {
      print('Error getting completion streak: $e');
      return 0;
    }
  }

  /// Check if user has lessons due for review
  Future<bool> hasLessonsDueForReview(String nickname) async {
    try {
      final lessonsDue = await getLessonsDueForReview(nickname);
      return lessonsDue.isNotEmpty;
    } catch (e) {
      print('Error checking lessons due for review: $e');
      return false;
    }
  }

  /// Get user's learning patterns for smart scheduling
  Future<Map<String, dynamic>> getUserLearningPatterns(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'preferredHours': [9, 15, 19],
          'averageSessionDuration': 15,
          'bestPerformanceHour': 10,
          'learningStreak': 0,
          'totalSessions': 0,
        };
      }

      // Analyze learning patterns
      final sessions = querySnapshot.docs.map((doc) => doc.data()).toList();
      final hours = <int>[];
      final durations = <int>[];
      final performanceByHour = <int, List<double>>{};
      
      for (final session in sessions) {
        final completedAt = (session['completedAt'] as Timestamp).toDate();
        final hour = completedAt.hour;
        hours.add(hour);
        
        // Calculate session duration (simplified)
        final score = session['score'] ?? 0;
        final totalQuestions = session['totalQuestions'] ?? 1;
        final performance = (score / totalQuestions) * 100;
        
        performanceByHour.putIfAbsent(hour, () => []).add(performance);
      }

      // Find preferred learning hours
      final hourFrequency = <int, int>{};
      for (final hour in hours) {
        hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
      }
      
      final sortedHours = hourFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final preferredHours = sortedHours.take(3).map((e) => e.key).toList();

      // Find best performance hour
      double bestPerformance = 0;
      int bestHour = 10;
      for (final entry in performanceByHour.entries) {
        final averagePerformance = entry.value.reduce((a, b) => a + b) / entry.value.length;
        if (averagePerformance > bestPerformance) {
          bestPerformance = averagePerformance;
          bestHour = entry.key;
        }
      }

      // Calculate learning streak
      int streak = 0;
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final hasSessionOnDate = sessions.any((session) {
          final sessionDate = (session['completedAt'] as Timestamp).toDate();
          return sessionDate.year == checkDate.year &&
                 sessionDate.month == checkDate.month &&
                 sessionDate.day == checkDate.day;
        });
        
        if (hasSessionOnDate) {
          streak++;
        } else {
          break;
        }
      }

      return {
        'preferredHours': preferredHours.isNotEmpty ? preferredHours : [9, 15, 19],
        'averageSessionDuration': durations.isNotEmpty 
            ? durations.reduce((a, b) => a + b) / durations.length 
            : 15,
        'bestPerformanceHour': bestHour,
        'learningStreak': streak,
        'totalSessions': sessions.length,
        'averagePerformance': sessions.isNotEmpty 
            ? sessions.map((s) => (s['score'] ?? 0) / (s['totalQuestions'] ?? 1) * 100)
                     .reduce((a, b) => a + b) / sessions.length
            : 0,
      };
    } catch (e) {
      print('Error getting learning patterns: $e');
      return {
        'preferredHours': [9, 15, 19],
        'averageSessionDuration': 15,
        'bestPerformanceHour': 10,
        'learningStreak': 0,
        'totalSessions': 0,
      };
    }
  }

  /// Get retention analytics data
  Future<Map<String, dynamic>> getRetentionAnalytics(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'masteryDistribution': [0, 0, 0, 0, 0, 0],
          'reviewFrequency': [0, 0, 0, 0, 0, 0, 0],
          'performanceTrend': [],
          'modulePerformance': {},
          'retentionRate': 0.0,
        };
      }

      final sessions = querySnapshot.docs.map((doc) => doc.data()).toList();
      
      // Mastery level distribution
      final masteryDistribution = [0, 0, 0, 0, 0, 0];
      for (final session in sessions) {
        final masteryLevel = (session['masteryLevel'] ?? 0).clamp(0, 5);
        masteryDistribution[masteryLevel]++;
      }

      // Review frequency (last 7 days)
      final reviewFrequency = [0, 0, 0, 0, 0, 0, 0];
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final reviewsOnDate = sessions.where((session) {
          final lastReviewDate = session['lastReviewDate'] as Timestamp?;
          if (lastReviewDate == null) return false;
          final reviewDate = lastReviewDate.toDate();
          return reviewDate.year == checkDate.year &&
                 reviewDate.month == checkDate.month &&
                 reviewDate.day == checkDate.day;
        }).length;
        reviewFrequency[6 - i] = reviewsOnDate;
      }

      // Performance trend (last 7 days)
      final performanceTrend = <double>[];
      for (int i = 6; i >= 0; i--) {
        final checkDate = now.subtract(Duration(days: i));
        final sessionsOnDate = sessions.where((session) {
          final completedAt = (session['completedAt'] as Timestamp).toDate();
          return completedAt.year == checkDate.year &&
                 completedAt.month == checkDate.month &&
                 completedAt.day == checkDate.day;
        }).toList();
        
        if (sessionsOnDate.isNotEmpty) {
          final averagePerformance = sessionsOnDate
              .map((s) => (s['score'] ?? 0) / (s['totalQuestions'] ?? 1) * 100)
              .reduce((a, b) => a + b) / sessionsOnDate.length;
          performanceTrend.add(averagePerformance);
        } else {
          performanceTrend.add(0);
        }
      }

      // Module performance
      final modulePerformance = <String, double>{};
      final moduleGroups = <String, List<Map<String, dynamic>>>{};
      
      for (final session in sessions) {
        final moduleName = session['moduleName'] ?? 'Unknown';
        moduleGroups.putIfAbsent(moduleName, () => []).add(session);
      }
      
      for (final entry in moduleGroups.entries) {
        final moduleSessions = entry.value;
        final averagePerformance = moduleSessions
            .map((s) => (s['score'] ?? 0) / (s['totalQuestions'] ?? 1) * 100)
            .reduce((a, b) => a + b) / moduleSessions.length;
        modulePerformance[entry.key] = averagePerformance;
      }

      // Calculate retention rate
      final totalSessions = sessions.length;
      final masteredSessions = sessions.where((s) => (s['masteryLevel'] ?? 0) >= 3).length;
      final retentionRate = totalSessions > 0 ? (masteredSessions / totalSessions) * 100 : 0.0;

      return {
        'masteryDistribution': masteryDistribution,
        'reviewFrequency': reviewFrequency,
        'performanceTrend': performanceTrend,
        'modulePerformance': modulePerformance,
        'retentionRate': retentionRate,
        'totalSessions': totalSessions,
        'masteredSessions': masteredSessions,
      };
    } catch (e) {
      print('Error getting retention analytics: $e');
      return {
        'masteryDistribution': [0, 0, 0, 0, 0, 0],
        'reviewFrequency': [0, 0, 0, 0, 0, 0, 0],
        'performanceTrend': [],
        'modulePerformance': {},
        'retentionRate': 0.0,
      };
    }
  }

  /// Update user's last active time for smart scheduling
  Future<void> updateUserActivity(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${nickname}_last_active_time', DateTime.now().toIso8601String());
      
      // Also save to Firestore for analytics
      await _firestore.collection('userActivity').add({
        'nickname': nickname,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'activityType': 'app_open',
      });
    } catch (e) {
      print('Error updating user activity: $e');
    }
  }

  /// Get optimal review times based on user patterns
  Future<List<DateTime>> getOptimalReviewTimes(String nickname) async {
    try {
      final patterns = await getUserLearningPatterns(nickname);
      final preferredHours = patterns['preferredHours'] as List<int>;
      final bestPerformanceHour = patterns['bestPerformanceHour'] as int;
      
      final now = DateTime.now();
      final optimalTimes = <DateTime>[];
      
      // Schedule reviews at preferred hours
      for (final hour in preferredHours) {
        final reviewTime = DateTime(now.year, now.month, now.day, hour, 0);
        if (reviewTime.isAfter(now)) {
          optimalTimes.add(reviewTime);
        } else {
          // Schedule for next day
          optimalTimes.add(reviewTime.add(const Duration(days: 1)));
        }
      }
      
      // Add best performance hour if not already included
      if (!preferredHours.contains(bestPerformanceHour)) {
        final bestTime = DateTime(now.year, now.month, now.day, bestPerformanceHour, 0);
        if (bestTime.isAfter(now)) {
          optimalTimes.add(bestTime);
        } else {
          optimalTimes.add(bestTime.add(const Duration(days: 1)));
        }
      }
      
      optimalTimes.sort();
      return optimalTimes;
    } catch (e) {
      print('Error getting optimal review times: $e');
      // Return default times
      final now = DateTime.now();
      return [
        DateTime(now.year, now.month, now.day, 9, 0),
        DateTime(now.year, now.month, now.day, 15, 0),
        DateTime(now.year, now.month, now.day, 19, 0),
      ];
    }
  }
}
