import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Gamification System for EasyMind App
/// Implements levels, points, badges, and rewards to make learning fun
class GamificationSystem {
  static final GamificationSystem _instance = GamificationSystem._internal();
  factory GamificationSystem() => _instance;
  GamificationSystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts _flutterTts = FlutterTts();

  // XP and Level System
  static const Map<int, int> _levelRequirements = {
    1: 0,    // Level 1: Starting level
    2: 100,  // Level 2: 100 XP
    3: 250,  // Level 3: 250 XP
    4: 450,  // Level 4: 450 XP
    5: 700,  // Level 5: 700 XP
    6: 1000, // Level 6: 1000 XP
    7: 1350, // Level 7: 1350 XP
    8: 1750, // Level 8: 1750 XP
    9: 2200, // Level 9: 2200 XP
    10: 2700, // Level 10: 2700 XP
  };

  /// Get level title based on level number
  static String getLevelTitle(int level) {
    switch (level) {
      case 1: return '🌱 Novice Learner';
      case 2: return '📚 Apprentice';
      case 3: return '🎓 Student';
      case 4: return '📖 Scholar';
      case 5: return '🧠 Learner';
      case 6: return '⭐ Achiever';
      case 7: return '🎯 Expert';
      case 8: return '🏆 Master';
      case 9: return '👑 Champion';
      case 10: return '🌟 Genius';
      default: return level > 10 ? '🌟 Legendary Genius' : '🌱 Novice Learner';
    }
  }

  /// Get level description based on level number
  static String getLevelDescription(int level) {
    switch (level) {
      case 1: return 'Just starting your learning journey!';
      case 2: return 'Learning the basics with enthusiasm!';
      case 3: return 'Building a strong foundation!';
      case 4: return 'Expanding your knowledge!';
      case 5: return 'Developing deeper understanding!';
      case 6: return 'Achieving great progress!';
      case 7: return 'Becoming an expert learner!';
      case 8: return 'Mastering new concepts!';
      case 9: return 'Championing your education!';
      case 10: return 'A true learning genius!';
      default: return level > 10 ? 'A legendary learning master!' : 'Just starting your learning journey!';
    }
  }

  /// Get level color based on level number - Softer, easier on the eyes
  static Color getLevelColor(int level) {
    switch (level) {
      case 1: return Colors.green.shade300; // Softer green for Novice Learner
      case 2: return Colors.blue.shade300; // Softer blue for Apprentice
      case 3: return Colors.purple.shade300; // Softer purple for Student
      case 4: return Colors.orange.shade300; // Softer orange for Scholar
      case 5: return Colors.teal.shade300; // Softer teal for Learner
      case 6: return Colors.pink.shade300; // Softer pink for Achiever
      case 7: return Colors.indigo.shade300; // Softer indigo for Expert
      case 8: return Colors.amber.shade400; // Softer amber for Master
      case 9: return Colors.deepPurple.shade300; // Softer deep purple for Champion
      case 10: return Colors.red.shade300; // Softer red for Genius
      default: return level > 10 ? Colors.purple.shade400 : Colors.green.shade300;
    }
  }
  static const Map<String, int> _xpRewards = {
    'lesson_completed': 50,
    'assessment_passed': 75,
    'perfect_score': 100,
    'first_attempt': 25,
    'streak_bonus': 30,
    'daily_login': 20,
    'review_completed': 40,
    'focus_session': 35,
    'break_taken': 15,
    // Educational Games XP Rewards
    'perfect_speech': 80,
    'good_speech': 60,
    'speech_practice': 40,
    'perfect_sound_match': 80,
    'sound_match_practice': 40,
    'perfect_word_formation': 80,
    'good_word_formation': 60,
    'word_formation_practice': 40,
    'perfect_categorization': 80,
    'good_categorization': 60,
    'categorization_practice': 40,
    'perfect_letter_tracing': 80,
    'good_letter_tracing': 60,
    'letter_tracing_practice': 40,
    'perfect_color_matching': 80,
    'good_color_matching': 60,
    'color_matching_practice': 40,
    'perfect_flashcard_review': 80,
    'good_flashcard_review': 60,
    'flashcard_review_practice': 40,
    'perfect_flashcard_quiz': 80,
    'good_flashcard_quiz': 60,
    'flashcard_quiz': 40,
  };

  // Badge definitions
  static const Map<String, BadgeDefinition> _badges = {
    'first_lesson': BadgeDefinition(
      id: 'first_lesson',
      name: 'First Steps! 🌱',
      description: 'Completed your first lesson!',
      icon: '🌱',
      rarity: BadgeRarity.common,
      requirement: 1,
      requirementType: 'lessons_completed',
    ),
    'alphabet_master': BadgeDefinition(
      id: 'alphabet_master',
      name: 'Alphabet Master! 🔤',
      description: 'Mastered the alphabet!',
      icon: '🔤',
      rarity: BadgeRarity.rare,
      requirement: 5,
      requirementType: 'alphabet_perfect',
    ),
    'color_expert': BadgeDefinition(
      id: 'color_expert',
      name: 'Color Expert! 🌈',
      description: 'Knows all the colors!',
      icon: '🌈',
      rarity: BadgeRarity.rare,
      requirement: 5,
      requirementType: 'color_perfect',
    ),
    'shape_wizard': BadgeDefinition(
      id: 'shape_wizard',
      name: 'Shape Wizard! 🔷',
      description: 'Master of shapes!',
      icon: '🔷',
      rarity: BadgeRarity.rare,
      requirement: 5,
      requirementType: 'shape_perfect',
    ),
    'streak_champion': BadgeDefinition(
      id: 'streak_champion',
      name: 'Streak Champion! 🔥',
      description: '7 days in a row!',
      icon: '🔥',
      rarity: BadgeRarity.epic,
      requirement: 7,
      requirementType: 'daily_streak',
    ),
    'focus_master': BadgeDefinition(
      id: 'focus_master',
      name: 'Focus Master! 🧠',
      description: 'Completed 10 focus sessions!',
      icon: '🧠',
      rarity: BadgeRarity.epic,
      requirement: 10,
      requirementType: 'focus_sessions',
    ),
    'speed_demon': BadgeDefinition(
      id: 'speed_demon',
      name: 'Speed Demon! ⚡',
      description: 'Completed lesson in under 2 minutes!',
      icon: '⚡',
      rarity: BadgeRarity.legendary,
      requirement: 1,
      requirementType: 'speed_completion',
    ),
    'perfect_perfectionist': BadgeDefinition(
      id: 'perfect_perfectionist',
      name: 'Perfect Perfectionist! 💎',
      description: 'Got 10 perfect scores!',
      icon: '💎',
      rarity: BadgeRarity.legendary,
      requirement: 10,
      requirementType: 'perfect_scores',
    ),
  };

  /// Initialize the gamification system
  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  /// Award XP for an activity
  Future<GamificationResult> awardXP({
    required String nickname,
    required String activity,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('🎮 Awarding XP for $nickname: $activity');
      final xpAmount = _xpRewards[activity] ?? 0;
      print('🎮 XP Amount: $xpAmount');
      
      if (xpAmount == 0) {
        print('🎮 No XP reward for activity: $activity');
        return GamificationResult.noReward();
      }

      // Get current user stats
      final userStats = await _getUserStats(nickname);
      print('🎮 Current stats: XP=${userStats.totalXP}, Level=${userStats.currentLevel}');
      
      final oldLevel = _calculateLevel(userStats.totalXP);
      
      // Add XP
      final newTotalXP = userStats.totalXP + xpAmount;
      final newLevel = _calculateLevel(newTotalXP);
      
      // Check for level up
      final leveledUp = newLevel > oldLevel;
      print('🎮 New stats: XP=$newTotalXP, Level=$newLevel, LeveledUp=$leveledUp');
      
      // Update user stats
      await _updateUserStats(nickname, {
        'totalXP': newTotalXP,
        'currentLevel': newLevel,
        'lastActivity': activity,
        'lastActivityTime': Timestamp.fromDate(DateTime.now()),
      });
      print('🎮 User stats updated in Firebase');

      // Check for new badges
      final newBadges = await _checkForNewBadges(nickname, activity, metadata);
      print('🎮 New badges earned: ${newBadges.length}');
      
      // Save activity
      await _saveActivity(nickname, activity, xpAmount, metadata);
      print('🎮 Activity saved to Firebase');

      // Announce level up
      if (leveledUp) {
        await _announceLevelUp(nickname, newLevel);
      }

      // Announce new badges
      for (final badge in newBadges) {
        await _announceBadgeEarned(nickname, badge);
      }

      return GamificationResult(
        xpAwarded: xpAmount,
        newTotalXP: newTotalXP,
        leveledUp: leveledUp,
        newLevel: newLevel,
        newBadges: newBadges,
        message: _generateRewardMessage(activity, xpAmount, leveledUp, newBadges.isNotEmpty),
      );
    } catch (e) {
      print('❌ Error awarding XP: $e');
      return GamificationResult.error();
    }
  }

  /// Get user's gamification stats
  Future<UserGamificationStats> getUserStats(String nickname) async {
    return await _getUserStats(nickname);
  }

  /// Get user's badges
  Future<List<UserBadge>> getUserBadges(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('userBadges')
          .where('nickname', isEqualTo: nickname)
          .orderBy('earnedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return UserBadge(
          badgeId: data['badgeId'],
          earnedAt: (data['earnedAt'] as Timestamp).toDate(),
          badgeDefinition: _badges[data['badgeId']]!,
        );
      }).toList();
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  /// Get badge definition by ID
  BadgeDefinition getBadgeDefinition(String badgeId) {
    return _badges[badgeId] ?? BadgeDefinition(
      id: badgeId,
      name: 'Unknown Badge',
      description: 'Unknown badge',
      icon: '❓',
      rarity: BadgeRarity.common,
      requirement: 0,
      requirementType: 'unknown',
    );
  }

  /// Get leaderboard data
  Future<List<LeaderboardEntry>> getLeaderboard({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('userStats')
          .orderBy('totalXP', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.asMap().entries.map((entry) {
        final data = entry.value.data();
        return LeaderboardEntry(
          rank: entry.key + 1,
          nickname: data['nickname'],
          totalXP: data['totalXP'],
          level: data['currentLevel'],
          badgeCount: data['badgeCount'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Error getting leaderboard: $e');
      return [];
    }
  }

  /// Get user's current level and progress
  LevelProgress getLevelProgress(int totalXP) {
    final currentLevel = _calculateLevel(totalXP);
    final nextLevel = currentLevel + 1;
    final currentLevelXP = _levelRequirements[currentLevel] ?? 0;
    final nextLevelXP = _levelRequirements[nextLevel] ?? (currentLevelXP + 500);
    
    final progressXP = totalXP - currentLevelXP;
    final requiredXP = nextLevelXP - currentLevelXP;
    final progressPercentage = requiredXP > 0 ? (progressXP / requiredXP).clamp(0.0, 1.0) : 1.0;

    return LevelProgress(
      currentLevel: currentLevel,
      nextLevel: nextLevel,
      currentXP: progressXP,
      requiredXP: requiredXP,
      progressPercentage: progressPercentage,
      totalXP: totalXP,
    );
  }

  /// Private helper methods
  Future<UserGamificationStats> _getUserStats(String nickname) async {
    try {
      final doc = await _firestore
          .collection('userStats')
          .doc(nickname)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return UserGamificationStats(
          nickname: nickname,
          totalXP: data['totalXP'] ?? 0,
          currentLevel: data['currentLevel'] ?? 1,
          badgeCount: data['badgeCount'] ?? 0,
          streakDays: data['streakDays'] ?? 0,
          lastLoginDate: data['lastLoginDate'] != null 
              ? (data['lastLoginDate'] as Timestamp).toDate() 
              : null,
        );
      } else {
        // Create new user stats
        final newStats = UserGamificationStats(
          nickname: nickname,
          totalXP: 0,
          currentLevel: 1,
          badgeCount: 0,
          streakDays: 0,
        );
        await _firestore.collection('userStats').doc(nickname).set({
          'nickname': nickname,
          'totalXP': 0,
          'currentLevel': 1,
          'badgeCount': 0,
          'streakDays': 0,
          'createdAt': Timestamp.fromDate(DateTime.now()),
        });
        return newStats;
      }
    } catch (e) {
      print('Error getting user stats: $e');
      return UserGamificationStats.empty(nickname);
    }
  }

  int _calculateLevel(int totalXP) {
    for (int level = _levelRequirements.length; level >= 1; level--) {
      if (totalXP >= (_levelRequirements[level] ?? 0)) {
        return level;
      }
    }
    return 1;
  }

  Future<void> _updateUserStats(String nickname, Map<String, dynamic> updates) async {
    // Update userStats collection
    await _firestore.collection('userStats').doc(nickname).set(updates, SetOptions(merge: true));
    
    // Also update students collection to keep them synchronized
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('nickname', isEqualTo: nickname)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final studentDoc = querySnapshot.docs.first;
        final studentUpdates = <String, dynamic>{};
        
        // Map userStats fields to students collection fields
        if (updates.containsKey('totalXP')) {
          studentUpdates['totalXP'] = updates['totalXP'];
        }
        if (updates.containsKey('currentLevel')) {
          studentUpdates['currentLevel'] = updates['currentLevel'];
        }
        if (updates.containsKey('streakDays')) {
          studentUpdates['currentStreak'] = updates['streakDays'];
        }
        if (updates.containsKey('badgeCount')) {
          studentUpdates['badgeCount'] = updates['badgeCount'];
        }
        
        // Always update lastActivity
        studentUpdates['lastActivity'] = Timestamp.now();
        
        if (studentUpdates.isNotEmpty) {
          await studentDoc.reference.update(studentUpdates);
          print('Students collection updated for $nickname: $studentUpdates');
        }
      }
    } catch (e) {
      print('Error updating students collection: $e');
    }
  }

  Future<int> _getLessonCount(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: nickname)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting lesson count: $e');
      return 0;
    }
  }

  Future<List<UserBadge>> _checkForNewBadges(String nickname, String activity, Map<String, dynamic>? metadata) async {
    final newBadges = <UserBadge>[];
    final userStats = await _getUserStats(nickname);
    final userBadges = await getUserBadges(nickname);
    final earnedBadgeIds = userBadges.map((b) => b.badgeId).toSet();

    for (final badge in _badges.values) {
      if (earnedBadgeIds.contains(badge.id)) continue;

      bool shouldAward = false;
      switch (badge.requirementType) {
        case 'lessons_completed':
          // Check actual lessons completed from lessonRetention collection
          final lessonCount = await _getLessonCount(nickname);
          shouldAward = lessonCount >= badge.requirement;
          break;
        case 'alphabet_perfect':
          shouldAward = metadata?['module'] == 'alphabet' && metadata?['perfect'] == true;
          break;
        case 'color_perfect':
          shouldAward = metadata?['module'] == 'color' && metadata?['perfect'] == true;
          break;
        case 'shape_perfect':
          shouldAward = metadata?['module'] == 'shape' && metadata?['perfect'] == true;
          break;
        case 'daily_streak':
          shouldAward = userStats.streakDays >= badge.requirement;
          break;
        case 'focus_sessions':
          shouldAward = activity == 'focus_session';
          break;
        case 'speed_completion':
          shouldAward = metadata?['duration'] != null && metadata!['duration'] < 120; // 2 minutes
          break;
        case 'perfect_scores':
          shouldAward = metadata?['perfect'] == true;
          break;
      }

      if (shouldAward) {
        await _awardBadge(nickname, badge);
        newBadges.add(UserBadge(
          badgeId: badge.id,
          earnedAt: DateTime.now(),
          badgeDefinition: badge,
        ));
      }
    }

    return newBadges;
  }

  Future<void> _awardBadge(String nickname, BadgeDefinition badge) async {
    await _firestore.collection('userBadges').add({
      'nickname': nickname,
      'badgeId': badge.id,
      'earnedAt': Timestamp.fromDate(DateTime.now()),
    });

    // Update badge count
    final userStats = await _getUserStats(nickname);
    await _updateUserStats(nickname, {
      'badgeCount': userStats.badgeCount + 1,
    });
  }

  Future<void> _saveActivity(String nickname, String activity, int xp, Map<String, dynamic>? metadata) async {
    await _firestore.collection('userActivities').add({
      'nickname': nickname,
      'activity': activity,
      'xpAwarded': xp,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'metadata': metadata ?? {},
    });
  }

  Future<void> _announceLevelUp(String nickname, int newLevel) async {
    // Voice announcement disabled for immediate modal display
    // await _flutterTts.speak(
    //   "Congratulations $nickname! 🎉 You reached level $newLevel! You're getting so smart! 🌟"
    // );
  }

  Future<void> _announceBadgeEarned(String nickname, UserBadge badge) async {
    // Voice announcement disabled for immediate modal display
    // await _flutterTts.speak(
    //   "Amazing! $nickname earned the ${badge.badgeDefinition.name} badge! ${badge.badgeDefinition.description} 🏆"
    // );
  }

  String _generateRewardMessage(String activity, int xp, bool leveledUp, bool newBadge) {
    if (leveledUp && newBadge) {
      return "Level Up + New Badge! 🎉🌟";
    } else if (leveledUp) {
      return "Level Up! 🎉";
    } else if (newBadge) {
      return "New Badge! 🏆";
    } else {
      return "+$xp XP! ⭐";
    }
  }
}

/// Data models
class UserGamificationStats {
  final String nickname;
  final int totalXP;
  final int currentLevel;
  final int badgeCount;
  final int streakDays;
  final DateTime? lastLoginDate;

  UserGamificationStats({
    required this.nickname,
    required this.totalXP,
    required this.currentLevel,
    required this.badgeCount,
    required this.streakDays,
    this.lastLoginDate,
  });

  factory UserGamificationStats.empty(String nickname) {
    return UserGamificationStats(
      nickname: nickname,
      totalXP: 0,
      currentLevel: 1,
      badgeCount: 0,
      streakDays: 0,
    );
  }
}

class LevelProgress {
  final int currentLevel;
  final int nextLevel;
  final int currentXP;
  final int requiredXP;
  final double progressPercentage;
  final int totalXP;

  LevelProgress({
    required this.currentLevel,
    required this.nextLevel,
    required this.currentXP,
    required this.requiredXP,
    required this.progressPercentage,
    required this.totalXP,
  });
}

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRarity rarity;
  final int requirement;
  final String requirementType;

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.requirement,
    required this.requirementType,
  });
}

class UserBadge {
  final String badgeId;
  final DateTime earnedAt;
  final BadgeDefinition badgeDefinition;

  UserBadge({
    required this.badgeId,
    required this.earnedAt,
    required this.badgeDefinition,
  });
}

class LeaderboardEntry {
  final int rank;
  final String nickname;
  final int totalXP;
  final int level;
  final int badgeCount;

  LeaderboardEntry({
    required this.rank,
    required this.nickname,
    required this.totalXP,
    required this.level,
    required this.badgeCount,
  });
}

class GamificationResult {
  final int xpAwarded;
  final int newTotalXP;
  final bool leveledUp;
  final int newLevel;
  final List<UserBadge> newBadges;
  final String message;

  GamificationResult({
    required this.xpAwarded,
    required this.newTotalXP,
    required this.leveledUp,
    required this.newLevel,
    required this.newBadges,
    required this.message,
  });

  factory GamificationResult.noReward() {
    return GamificationResult(
      xpAwarded: 0,
      newTotalXP: 0,
      leveledUp: false,
      newLevel: 1,
      newBadges: [],
      message: '',
    );
  }

  factory GamificationResult.error() {
    return GamificationResult(
      xpAwarded: 0,
      newTotalXP: 0,
      leveledUp: false,
      newLevel: 1,
      newBadges: [],
      message: 'Error occurred',
    );
  }
}

enum BadgeRarity {
  common,
  rare,
  epic,
  legendary,
}
