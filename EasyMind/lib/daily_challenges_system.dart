import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Daily Challenges System - Advanced gamification with daily challenges
class DailyChallengesSystem {
  static final DailyChallengesSystem _instance = DailyChallengesSystem._internal();
  factory DailyChallengesSystem() => _instance;
  DailyChallengesSystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Challenge types
  static const Map<String, ChallengeType> challengeTypes = {
    'lesson_streak': ChallengeType(
      id: 'lesson_streak',
      name: 'Learning Streak',
      description: 'Complete lessons for consecutive days',
      icon: '🔥',
      xpReward: 100,
      difficulty: ChallengeDifficulty.medium,
    ),
    'perfect_scores': ChallengeType(
      id: 'perfect_scores',
      name: 'Perfect Performance',
      description: 'Get perfect scores in assessments',
      icon: '💎',
      xpReward: 150,
      difficulty: ChallengeDifficulty.hard,
    ),
    'focus_master': ChallengeType(
      id: 'focus_master',
      name: 'Focus Master',
      description: 'Complete focus sessions without breaks',
      icon: '🧠',
      xpReward: 80,
      difficulty: ChallengeDifficulty.medium,
    ),
    'explorer': ChallengeType(
      id: 'explorer',
      name: 'Subject Explorer',
      description: 'Try different learning subjects',
      icon: '🌟',
      xpReward: 60,
      difficulty: ChallengeDifficulty.easy,
    ),
    'speed_learner': ChallengeType(
      id: 'speed_learner',
      name: 'Speed Learner',
      description: 'Complete lessons quickly',
      icon: '⚡',
      xpReward: 120,
      difficulty: ChallengeDifficulty.hard,
    ),
    'consistency_king': ChallengeType(
      id: 'consistency_king',
      name: 'Consistency King',
      description: 'Maintain regular learning schedule',
      icon: '👑',
      xpReward: 200,
      difficulty: ChallengeDifficulty.expert,
    ),
  };

  /// Generate daily challenges for a student
  Future<List<DailyChallenge>> generateDailyChallenges(String nickname) async {
    try {
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      
      // Check if challenges already exist for today
      final existingChallenges = await _getExistingChallenges(nickname, todayKey);
      if (existingChallenges.isNotEmpty) {
        return existingChallenges;
      }
      
      // Generate new challenges based on student's learning patterns
      final studentData = await _getStudentLearningData(nickname);
      final challenges = await _createPersonalizedChallenges(nickname, studentData, todayKey);
      
      // Save challenges to Firebase
      await _saveChallenges(nickname, challenges);
      
      return challenges;
    } catch (e) {
      print('Error generating daily challenges: $e');
      return _getDefaultChallenges();
    }
  }

  /// Get existing challenges for today
  Future<List<DailyChallenge>> _getExistingChallenges(String nickname, String dateKey) async {
    try {
      final querySnapshot = await _firestore
          .collection('dailyChallenges')
          .where('nickname', isEqualTo: nickname)
          .where('dateKey', isEqualTo: dateKey)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return DailyChallenge.fromMap(data);
      }).toList();
    } catch (e) {
      print('Error getting existing challenges: $e');
      return [];
    }
  }

  /// Get student's learning data for personalization
  Future<Map<String, dynamic>> _getStudentLearningData(String nickname) async {
    try {
      // Get recent learning activity
      final lessonQuery = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .limit(50)
          .get();
      
      final lessons = lessonQuery.docs.map((doc) => doc.data()).toList();
      
      // Get focus sessions
      final focusQuery = await _firestore
          .collection('focusSessions')
          .where('nickname', isEqualTo: nickname)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();
      
      final focusSessions = focusQuery.docs.map((doc) => doc.data()).toList();
      
      // Get user stats
      final userStatsDoc = await _firestore.collection('userStats').doc(nickname).get();
      final userStats = userStatsDoc.exists ? userStatsDoc.data()! : {};
      
      return {
        'lessons': lessons,
        'focusSessions': focusSessions,
        'userStats': userStats,
      };
    } catch (e) {
      print('Error getting student learning data: $e');
      return {};
    }
  }

  /// Create personalized challenges based on student data
  Future<List<DailyChallenge>> _createPersonalizedChallenges(
    String nickname, 
    Map<String, dynamic> studentData, 
    String dateKey
  ) async {
    final List<DailyChallenge> challenges = [];
    final lessons = studentData['lessons'] as List<Map<String, dynamic>>? ?? [];
    final focusSessions = studentData['focusSessions'] as List<Map<String, dynamic>>? ?? [];
    final userStats = studentData['userStats'] as Map<String, dynamic>? ?? {};
    
    // Analyze learning patterns
    final analysis = _analyzeLearningPatterns(lessons, focusSessions, userStats);
    
    // Generate 3-5 challenges based on analysis
    final challengeIds = _selectChallengeTypes(analysis);
    
    for (final challengeId in challengeIds) {
      final challengeType = challengeTypes[challengeId]!;
      final challenge = _createChallenge(nickname, challengeType, analysis, dateKey);
      challenges.add(challenge);
    }
    
    return challenges;
  }

  /// Analyze learning patterns to determine appropriate challenges
  LearningAnalysis _analyzeLearningPatterns(
    List<Map<String, dynamic>> lessons,
    List<Map<String, dynamic>> focusSessions,
    Map<String, dynamic> userStats
  ) {
    // Calculate learning streak
    int currentStreak = 0;
    final now = DateTime.now();
    final Set<String> recentDays = {};
    
    for (final lesson in lessons) {
      final completedAt = (lesson['completedAt'] as Timestamp?)?.toDate();
      if (completedAt != null) {
        final dayKey = _getDateKey(completedAt);
        recentDays.add(dayKey);
      }
    }
    
    // Calculate current streak
    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dayKey = _getDateKey(checkDate);
      if (recentDays.contains(dayKey)) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    // Calculate perfect score rate
    final perfectScores = lessons.where((l) => (l['retentionScore'] ?? 0.0) >= 90.0).length;
    final perfectScoreRate = lessons.isNotEmpty ? perfectScores / lessons.length : 0.0;
    
    // Calculate focus completion rate
    final completedFocusSessions = focusSessions.where((f) => f['status'] == 'completed').length;
    final focusCompletionRate = focusSessions.isNotEmpty ? completedFocusSessions / focusSessions.length : 0.0;
    
    // Calculate subject diversity
    final subjects = lessons.map((l) => l['moduleName'] ?? 'Unknown').toSet();
    final subjectDiversity = subjects.length;
    
    // Calculate average completion time (if available)
    double avgCompletionTime = 15.0; // Default 15 minutes
    if (focusSessions.isNotEmpty) {
      final durations = focusSessions
          .where((f) => f['duration'] != null)
          .map((f) => f['duration'] as double)
          .toList();
      if (durations.isNotEmpty) {
        avgCompletionTime = durations.reduce((a, b) => a + b) / durations.length;
      }
    }
    
    return LearningAnalysis(
      currentStreak: currentStreak,
      perfectScoreRate: perfectScoreRate,
      focusCompletionRate: focusCompletionRate,
      subjectDiversity: subjectDiversity,
      avgCompletionTime: avgCompletionTime,
      totalLessons: lessons.length,
      totalFocusSessions: focusSessions.length,
    );
  }

  /// Select appropriate challenge types based on analysis
  List<String> _selectChallengeTypes(LearningAnalysis analysis) {
    final List<String> selectedChallenges = [];
    final random = Random();
    
    // Always include a streak challenge if streak is low
    if (analysis.currentStreak < 3) {
      selectedChallenges.add('lesson_streak');
    }
    
    // Add perfect scores challenge if performance is good
    if (analysis.perfectScoreRate >= 0.7) {
      selectedChallenges.add('perfect_scores');
    }
    
    // Add focus challenge if focus completion is low
    if (analysis.focusCompletionRate < 0.6) {
      selectedChallenges.add('focus_master');
    }
    
    // Add explorer challenge if subject diversity is low
    if (analysis.subjectDiversity < 3) {
      selectedChallenges.add('explorer');
    }
    
    // Add speed challenge if completion time is high
    if (analysis.avgCompletionTime > 20) {
      selectedChallenges.add('speed_learner');
    }
    
    // Add consistency challenge for advanced learners
    if (analysis.totalLessons > 20 && analysis.currentStreak >= 5) {
      selectedChallenges.add('consistency_king');
    }
    
    // Fill remaining slots with random challenges
    final availableChallenges = challengeTypes.keys.toList();
    while (selectedChallenges.length < 3 && selectedChallenges.length < availableChallenges.length) {
      final randomChallenge = availableChallenges[random.nextInt(availableChallenges.length)];
      if (!selectedChallenges.contains(randomChallenge)) {
        selectedChallenges.add(randomChallenge);
      }
    }
    
    return selectedChallenges.take(5).toList(); // Maximum 5 challenges per day
  }

  /// Create a specific challenge
  DailyChallenge _createChallenge(
    String nickname,
    ChallengeType challengeType,
    LearningAnalysis analysis,
    String dateKey
  ) {
    
    switch (challengeType.id) {
      case 'lesson_streak':
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: analysis.currentStreak + 2, // Extend current streak by 2
          current: analysis.currentStreak,
          description: 'Complete lessons for ${analysis.currentStreak + 2} consecutive days',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      case 'perfect_scores':
        final target = max(3, (analysis.totalLessons * 0.3).round());
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: target,
          current: 0,
          description: 'Get perfect scores in $target assessments',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      case 'focus_master':
        final target = max(2, (analysis.totalFocusSessions * 0.4).round());
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: target,
          current: 0,
          description: 'Complete $target focus sessions without breaks',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      case 'explorer':
        final target = max(2, 5 - analysis.subjectDiversity);
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: target,
          current: 0,
          description: 'Try $target different learning subjects',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      case 'speed_learner':
        final target = max(3, (analysis.totalLessons * 0.2).round());
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: target,
          current: 0,
          description: 'Complete $target lessons in under 10 minutes each',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      case 'consistency_king':
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: 7,
          current: 0,
          description: 'Maintain a 7-day learning schedule',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
        
      default:
        return DailyChallenge(
          id: '${nickname}_${challengeType.id}_$dateKey',
          nickname: nickname,
          challengeType: challengeType,
          dateKey: dateKey,
          target: 3,
          current: 0,
          description: 'Complete 3 learning activities',
          xpReward: challengeType.xpReward,
          isCompleted: false,
          createdAt: Timestamp.now(),
        );
    }
  }

  /// Save challenges to Firebase
  Future<void> _saveChallenges(String nickname, List<DailyChallenge> challenges) async {
    try {
      final batch = _firestore.batch();
      
      for (final challenge in challenges) {
        final docRef = _firestore.collection('dailyChallenges').doc(challenge.id);
        batch.set(docRef, challenge.toMap());
      }
      
      await batch.commit();
      print('✅ Daily challenges saved for $nickname');
    } catch (e) {
      print('❌ Error saving daily challenges: $e');
    }
  }

  /// Update challenge progress
  Future<void> updateChallengeProgress(String nickname, String challengeId, int increment) async {
    try {
      final docRef = _firestore.collection('dailyChallenges').doc(challengeId);
      final doc = await docRef.get();
      
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final current = data['current'] ?? 0;
      final target = data['target'] ?? 1;
      final newCurrent = current + increment;
      final isCompleted = newCurrent >= target;
      
      await docRef.update({
        'current': newCurrent,
        'isCompleted': isCompleted,
        'completedAt': isCompleted ? Timestamp.now() : null,
        'lastUpdated': Timestamp.now(),
      });
      
      // Award XP if completed
      if (isCompleted && !(data['isCompleted'] ?? false)) {
        final xpReward = data['xpReward'] ?? 0;
        await _awardChallengeXP(nickname, xpReward, challengeId);
      }
      
      print('✅ Challenge progress updated: $challengeId');
    } catch (e) {
      print('❌ Error updating challenge progress: $e');
    }
  }

  /// Award XP for completed challenge
  Future<void> _awardChallengeXP(String nickname, int xpReward, String challengeId) async {
    try {
      // Update user stats
      final userStatsDoc = await _firestore.collection('userStats').doc(nickname).get();
      if (userStatsDoc.exists) {
        final currentXP = userStatsDoc.data()!['totalXP'] ?? 0;
        await _firestore.collection('userStats').doc(nickname).update({
          'totalXP': currentXP + xpReward,
          'lastActivity': 'daily_challenge_completed',
          'lastActivityTime': Timestamp.now(),
        });
      }
      
      // Log challenge completion
      await _firestore.collection('challengeCompletions').add({
        'nickname': nickname,
        'challengeId': challengeId,
        'xpAwarded': xpReward,
        'completedAt': Timestamp.now(),
      });
      
      print('✅ Challenge XP awarded: $xpReward XP to $nickname');
    } catch (e) {
      print('❌ Error awarding challenge XP: $e');
    }
  }

  /// Get default challenges for new students
  List<DailyChallenge> _getDefaultChallenges() {
    final today = DateTime.now();
    final dateKey = _getDateKey(today);
    
    return [
      DailyChallenge(
        id: 'default_lesson_streak_$dateKey',
        nickname: 'default',
        challengeType: challengeTypes['lesson_streak']!,
        dateKey: dateKey,
        target: 3,
        current: 0,
        description: 'Complete lessons for 3 consecutive days',
        xpReward: 100,
        isCompleted: false,
        createdAt: Timestamp.now(),
      ),
      DailyChallenge(
        id: 'default_explorer_$dateKey',
        nickname: 'default',
        challengeType: challengeTypes['explorer']!,
        dateKey: dateKey,
        target: 2,
        current: 0,
        description: 'Try 2 different learning subjects',
        xpReward: 60,
        isCompleted: false,
        createdAt: Timestamp.now(),
      ),
    ];
  }

  /// Get date key for challenge tracking
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get challenge statistics
  Future<ChallengeStats> getChallengeStats(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('dailyChallenges')
          .where('nickname', isEqualTo: nickname)
          .get();
      
      final challenges = querySnapshot.docs.map((doc) => DailyChallenge.fromMap(doc.data())).toList();
      
      final completedChallenges = challenges.where((c) => c.isCompleted).length;
      final totalChallenges = challenges.length;
      final totalXPEarned = challenges.where((c) => c.isCompleted).fold<int>(0, (sum, c) => sum + c.xpReward);
      
      return ChallengeStats(
        totalChallenges: totalChallenges,
        completedChallenges: completedChallenges,
        completionRate: totalChallenges > 0 ? completedChallenges / totalChallenges : 0.0,
        totalXPEarned: totalXPEarned,
        currentStreak: _calculateChallengeStreak(challenges),
      );
    } catch (e) {
      print('Error getting challenge stats: $e');
      return ChallengeStats.empty();
    }
  }

  /// Calculate challenge completion streak
  int _calculateChallengeStreak(List<DailyChallenge> challenges) {
    final completedChallenges = challenges.where((c) => c.isCompleted).toList();
    if (completedChallenges.isEmpty) return 0;
    
    // Sort by completion date
    completedChallenges.sort((a, b) {
      final aDate = a.completedAt?.toDate() ?? DateTime(1970);
      final bDate = b.completedAt?.toDate() ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    
    int streak = 0;
    final now = DateTime.now();
    
    for (int i = 0; i < completedChallenges.length; i++) {
      final challenge = completedChallenges[i];
      final completedDate = challenge.completedAt?.toDate() ?? DateTime(1970);
      final daysDiff = now.difference(completedDate).inDays;
      
      if (daysDiff == i) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }
}

/// Data Models
class ChallengeType {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  final ChallengeDifficulty difficulty;

  const ChallengeType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.difficulty,
  });
}

enum ChallengeDifficulty {
  easy,
  medium,
  hard,
  expert,
}

class DailyChallenge {
  final String id;
  final String nickname;
  final ChallengeType challengeType;
  final String dateKey;
  final int target;
  final int current;
  final String description;
  final int xpReward;
  final bool isCompleted;
  final Timestamp createdAt;
  final Timestamp? completedAt;

  DailyChallenge({
    required this.id,
    required this.nickname,
    required this.challengeType,
    required this.dateKey,
    required this.target,
    required this.current,
    required this.description,
    required this.xpReward,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'challengeTypeId': challengeType.id,
      'challengeTypeName': challengeType.name,
      'challengeTypeIcon': challengeType.icon,
      'challengeTypeDescription': challengeType.description,
      'challengeTypeXpReward': challengeType.xpReward,
      'challengeTypeDifficulty': challengeType.difficulty.name,
      'dateKey': dateKey,
      'target': target,
      'current': current,
      'description': description,
      'xpReward': xpReward,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  static DailyChallenge fromMap(Map<String, dynamic> map) {
    return DailyChallenge(
      id: map['id'] ?? '',
      nickname: map['nickname'] ?? '',
      challengeType: ChallengeType(
        id: map['challengeTypeId'] ?? '',
        name: map['challengeTypeName'] ?? '',
        description: map['challengeTypeDescription'] ?? '',
        icon: map['challengeTypeIcon'] ?? '🎯',
        xpReward: map['challengeTypeXpReward'] ?? 0,
        difficulty: ChallengeDifficulty.values.firstWhere(
          (d) => d.name == map['challengeTypeDifficulty'],
          orElse: () => ChallengeDifficulty.medium,
        ),
      ),
      dateKey: map['dateKey'] ?? '',
      target: map['target'] ?? 1,
      current: map['current'] ?? 0,
      description: map['description'] ?? '',
      xpReward: map['xpReward'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      completedAt: map['completedAt'],
    );
  }
}

class LearningAnalysis {
  final int currentStreak;
  final double perfectScoreRate;
  final double focusCompletionRate;
  final int subjectDiversity;
  final double avgCompletionTime;
  final int totalLessons;
  final int totalFocusSessions;

  LearningAnalysis({
    required this.currentStreak,
    required this.perfectScoreRate,
    required this.focusCompletionRate,
    required this.subjectDiversity,
    required this.avgCompletionTime,
    required this.totalLessons,
    required this.totalFocusSessions,
  });
}

class ChallengeStats {
  final int totalChallenges;
  final int completedChallenges;
  final double completionRate;
  final int totalXPEarned;
  final int currentStreak;

  ChallengeStats({
    required this.totalChallenges,
    required this.completedChallenges,
    required this.completionRate,
    required this.totalXPEarned,
    required this.currentStreak,
  });

  ChallengeStats.empty() :
    totalChallenges = 0,
    completedChallenges = 0,
    completionRate = 0.0,
    totalXPEarned = 0,
    currentStreak = 0;
}
