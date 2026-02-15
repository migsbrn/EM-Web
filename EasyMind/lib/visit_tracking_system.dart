import 'package:cloud_firestore/cloud_firestore.dart';

/// Visit Tracking System for EasyMind App
/// Tracks how many times students access specific lessons, assessments, and games
class VisitTrackingSystem {
  static final VisitTrackingSystem _instance = VisitTrackingSystem._internal();
  factory VisitTrackingSystem() => _instance;
  VisitTrackingSystem._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Track a visit to a specific lesson/assessment/game
  Future<void> trackVisit({
    required String nickname,
    required String itemType, // 'lesson', 'assessment', 'game'
    required String itemName,
    required String moduleName,
  }) async {
    try {
      final now = DateTime.now();
      final visitData = {
        'nickname': nickname,
        'itemType': itemType,
        'itemName': itemName,
        'moduleName': moduleName,
        'visitedAt': Timestamp.fromDate(now),
        'date': now.toIso8601String().split('T')[0], // YYYY-MM-DD format
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save individual visit record
      await _firestore.collection('visitTracking').add(visitData);

      // Update visit count summary
      await _updateVisitCount(nickname, itemType, itemName, moduleName);

      print('Visit tracked: $nickname - $itemType - $itemName');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  /// Update visit count summary
  Future<void> _updateVisitCount(String nickname, String itemType, String itemName, String moduleName) async {
    try {
      final docId = '${nickname}_${itemType}_${itemName.replaceAll(' ', '_')}';
      final docRef = _firestore.collection('visitCounts').doc(docId);

      await docRef.set({
        'nickname': nickname,
        'itemType': itemType,
        'itemName': itemName,
        'moduleName': moduleName,
        'visitCount': FieldValue.increment(1),
        'lastVisited': FieldValue.serverTimestamp(),
        'firstVisited': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Visit count updated for: $nickname - $itemName');
    } catch (e) {
      print('Error updating visit count: $e');
    }
  }

  /// Get visit count for a specific item
  Future<int> getVisitCount(String nickname, String itemType, String itemName) async {
    try {
      final docId = '${nickname}_${itemType}_${itemName.replaceAll(' ', '_')}';
      final doc = await _firestore.collection('visitCounts').doc(docId).get();
      
      if (doc.exists) {
        return doc.data()?['visitCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting visit count: $e');
      return 0;
    }
  }

  /// Get all visit counts for a student
  Future<List<Map<String, dynamic>>> getAllVisitCounts(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('visitCounts')
          .where('nickname', isEqualTo: nickname)
          .orderBy('visitCount', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'itemType': data['itemType'],
          'itemName': data['itemName'],
          'moduleName': data['moduleName'],
          'visitCount': data['visitCount'] ?? 0,
          'lastVisited': data['lastVisited'],
          'firstVisited': data['firstVisited'],
        };
      }).toList();
    } catch (e) {
      print('Error getting all visit counts: $e');
      return [];
    }
  }

  /// Get visit counts by type (lessons, assessments, games)
  Future<Map<String, List<Map<String, dynamic>>>> getVisitCountsByType(String nickname) async {
    try {
      final allCounts = await getAllVisitCounts(nickname);
      
      final Map<String, List<Map<String, dynamic>>> groupedCounts = {
        'lessons': [],
        'assessments': [],
        'games': [],
      };

      for (final count in allCounts) {
        final itemType = count['itemType'] as String;
        if (groupedCounts.containsKey(itemType)) {
          groupedCounts[itemType]!.add(count);
        }
      }

      return groupedCounts;
    } catch (e) {
      print('Error getting visit counts by type: $e');
      return {
        'lessons': [],
        'assessments': [],
        'games': [],
      };
    }
  }

  /// Get recent visits (last 7 days)
  Future<List<Map<String, dynamic>>> getRecentVisits(String nickname, {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final querySnapshot = await _firestore
          .collection('visitTracking')
          .where('nickname', isEqualTo: nickname)
          .where('visitedAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('visitedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'itemType': data['itemType'],
          'itemName': data['itemName'],
          'moduleName': data['moduleName'],
          'visitedAt': data['visitedAt'],
          'date': data['date'],
        };
      }).toList();
    } catch (e) {
      print('Error getting recent visits: $e');
      return [];
    }
  }

  /// Get most visited items
  Future<List<Map<String, dynamic>>> getMostVisitedItems(String nickname, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection('visitCounts')
          .where('nickname', isEqualTo: nickname)
          .orderBy('visitCount', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'itemType': data['itemType'],
          'itemName': data['itemName'],
          'moduleName': data['moduleName'],
          'visitCount': data['visitCount'] ?? 0,
          'lastVisited': data['lastVisited'],
        };
      }).toList();
    } catch (e) {
      print('Error getting most visited items: $e');
      return [];
    }
  }

  /// Get historical activities from existing collections
  Future<List<Map<String, dynamic>>> getHistoricalActivities(String nickname) async {
    try {
      final List<Map<String, dynamic>> historicalActivities = [];

      // Fetch from lesson completions
      final lessonCompletions = await _firestore
          .collection('lessonCompletions')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .get();

      for (final doc in lessonCompletions.docs) {
        final data = doc.data();
        historicalActivities.add({
          'itemType': 'lesson',
          'itemName': data['lessonName'] ?? 'Unknown Lesson',
          'moduleName': data['moduleName'] ?? 'Unknown Module',
          'completedAt': data['completedAt'],
          'date': _formatDate(data['completedAt']),
          'score': data['score'] ?? 0,
          'source': 'lessonCompletion',
        });
      }

      // Fetch from assessment results (using correct collection name)
      final assessmentResults = await _firestore
          .collection('adaptiveAssessmentResults')
          .where('nickname', isEqualTo: nickname)
          .orderBy('timestamp', descending: true)
          .get();

      for (final doc in assessmentResults.docs) {
        final data = doc.data();
        historicalActivities.add({
          'itemType': 'assessment',
          'itemName': data['assessmentType'] ?? 'Unknown Assessment',
          'moduleName': data['moduleName'] ?? 'Unknown Module',
          'completedAt': data['timestamp'] ?? data['date'], // Use correct field names
          'date': _formatDate(data['timestamp'] ?? data['date']),
          'score': data['correctAnswers'] ?? 0, // Use correct field name
          'source': 'adaptiveAssessmentResult',
        });
      }

      // Fetch from game sessions
      final gameSessions = await _firestore
          .collection('gameSessions')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .get();

      for (final doc in gameSessions.docs) {
        final data = doc.data();
        historicalActivities.add({
          'itemType': 'game',
          'itemName': data['gameType'] ?? 'Unknown Game',
          'moduleName': data['moduleName'] ?? 'Games',
          'completedAt': data['completedAt'],
          'date': _formatDate(data['completedAt']),
          'score': data['score'] ?? 0,
          'source': 'gameSession',
        });
      }

      // Fetch from flashcard sessions
      final flashcardSessions = await _firestore
          .collection('flashcardSessions')
          .where('nickname', isEqualTo: nickname)
          .orderBy('completedAt', descending: true)
          .get();

      for (final doc in flashcardSessions.docs) {
        final data = doc.data();
        historicalActivities.add({
          'itemType': 'game',
          'itemName': 'Flashcard Game',
          'moduleName': 'Games',
          'completedAt': data['completedAt'],
          'date': _formatDate(data['completedAt']),
          'score': data['score'] ?? 0,
          'source': 'flashcardSession',
        });
      }

      // Sort by completion date (most recent first)
      historicalActivities.sort((a, b) {
        final aTime = a['completedAt'] as Timestamp?;
        final bTime = b['completedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return historicalActivities;
    } catch (e) {
      print('Error getting historical activities: $e');
      return [];
    }
  }

  /// Get historical activities grouped by type
  Future<Map<String, List<Map<String, dynamic>>>> getHistoricalActivitiesByType(String nickname) async {
    try {
      final historicalActivities = await getHistoricalActivities(nickname);
      
      final Map<String, List<Map<String, dynamic>>> groupedActivities = {
        'lessons': [],
        'assessments': [],
        'games': [],
      };

      for (final activity in historicalActivities) {
        final itemType = activity['itemType'] as String;
        if (groupedActivities.containsKey(itemType)) {
          groupedActivities[itemType]!.add(activity);
        }
      }

      return groupedActivities;
    } catch (e) {
      print('Error getting historical activities by type: $e');
      return {
        'lessons': [],
        'assessments': [],
        'games': [],
      };
    }
  }

  /// Get most frequently accessed historical activities
  Future<List<Map<String, dynamic>>> getMostFrequentHistoricalActivities(String nickname, {int limit = 10}) async {
    try {
      final historicalActivities = await getHistoricalActivities(nickname);
      
      // Count occurrences of each activity
      final Map<String, Map<String, dynamic>> activityCounts = {};
      
      for (final activity in historicalActivities) {
        final key = '${activity['itemType']}_${activity['itemName']}';
        if (activityCounts.containsKey(key)) {
          activityCounts[key]!['visitCount'] = (activityCounts[key]!['visitCount'] as int) + 1;
        } else {
          activityCounts[key] = {
            'itemType': activity['itemType'],
            'itemName': activity['itemName'],
            'moduleName': activity['moduleName'],
            'visitCount': 1,
            'lastVisited': activity['completedAt'],
            'source': 'historical',
          };
        }
      }

      // Convert to list and sort by visit count
      final List<Map<String, dynamic>> frequentActivities = activityCounts.values.toList();
      frequentActivities.sort((a, b) => (b['visitCount'] as int).compareTo(a['visitCount'] as int));

      return frequentActivities.take(limit).toList();
    } catch (e) {
      print('Error getting most frequent historical activities: $e');
      return [];
    }
  }

  /// Format timestamp to date string
  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } else if (timestamp is DateTime) {
        return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      }
      return 'Unknown';
    } catch (e) {
      print('Error formatting date: $e');
      return 'Unknown';
    }
  }
}
