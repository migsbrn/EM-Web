import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'memory_retention_system.dart';
import 'attention_focus_system.dart';
import 'gamification_system.dart';
import 'visit_tracking_system.dart';
import 'LearnMyFamily.dart';
import 'MyFamilyAssessment.dart';
import 'LetterTracing.dart';
import 'flashcard_system.dart';
import 'responsive_utils.dart';

/// Unified Analytics Dashboard - Combines all analytics and tracking features
class UnifiedAnalyticsDashboard extends StatefulWidget {
  final String nickname;
  
  const UnifiedAnalyticsDashboard({
    super.key,
    required this.nickname,
  });

  @override
  State<UnifiedAnalyticsDashboard> createState() => _UnifiedAnalyticsDashboardState();
}

class _UnifiedAnalyticsDashboardState extends State<UnifiedAnalyticsDashboard> with TickerProviderStateMixin {
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  final GamificationSystem _gamificationSystem = GamificationSystem();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  
  late TabController _tabController;
  
  // Data variables
  List<Map<String, dynamic>> _lessonsDue = [];
  Map<String, dynamic> _retentionStats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  FocusStatistics? _focusStats;
  UserGamificationStats? _userStats;
  List<UserBadge> _badges = [];
  List<LeaderboardEntry> _leaderboard = [];
  Map<String, List<Map<String, dynamic>>> _visitCounts = {};
  List<Map<String, dynamic>> _mostVisitedItems = [];
  Map<String, List<Map<String, dynamic>>> _historicalActivitiesByType = {};
  List<Map<String, dynamic>> _mostFrequentHistoricalActivities = [];
  bool _isLoading = true;
  
  // Debounce mechanism to prevent excessive updates
  DateTime? _lastUpdateTime;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Debounced update to prevent excessive setState calls
  void _debouncedUpdate(VoidCallback updateCallback) {
    final now = DateTime.now();
    if (_lastUpdateTime == null || 
        now.difference(_lastUpdateTime!) > const Duration(milliseconds: 500)) {
      _lastUpdateTime = now;
      if (mounted) {
        updateCallback();
      }
    }
  }

  Future<void> _loadAllData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load all data in parallel
      final results = await Future.wait([
        _retentionSystem.getLessonsDueForReview(widget.nickname),
        _retentionSystem.getUserRetentionStats(widget.nickname),
        _getRecentActivity(),
        _focusSystem.getUserFocusStats(widget.nickname),
        _gamificationSystem.getUserStats(widget.nickname),
        _gamificationSystem.getUserBadges(widget.nickname),
        _gamificationSystem.getLeaderboard(limit: 5),
        _visitTrackingSystem.getVisitCountsByType(widget.nickname),
        _visitTrackingSystem.getMostVisitedItems(widget.nickname, limit: 10),
        _visitTrackingSystem.getHistoricalActivitiesByType(widget.nickname),
        _visitTrackingSystem.getMostFrequentHistoricalActivities(widget.nickname, limit: 10),
      ]);
      
      setState(() {
        _lessonsDue = results[0] as List<Map<String, dynamic>>;
        _retentionStats = results[1] as Map<String, dynamic>;
        _recentActivity = results[2] as List<Map<String, dynamic>>;
        _focusStats = results[3] as FocusStatistics?;
        _userStats = results[4] as UserGamificationStats?;
        _badges = results[5] as List<UserBadge>;
        _leaderboard = results[6] as List<LeaderboardEntry>;
        _visitCounts = results[7] as Map<String, List<Map<String, dynamic>>>;
        _mostVisitedItems = results[8] as List<Map<String, dynamic>>;
        _historicalActivitiesByType = results[9] as Map<String, List<Map<String, dynamic>>>;
        _mostFrequentHistoricalActivities = results[10] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading dashboard data: $e');
    }
  }

  /// Setup real-time listeners for live data updates
  void _setupRealtimeListeners() {
    // Real-time listener for lessons due for review
    FirebaseFirestore.instance
        .collection('lessonRetention')
        .where('nickname', isEqualTo: widget.nickname)
        .where('nextReviewDate', isLessThanOrEqualTo: Timestamp.now())
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _debouncedUpdate(() {
        setState(() {
          _lessonsDue = snapshot.docs
              .map((doc) => doc.data())
              .toList();
          });
        });
      }
    });

    // Real-time listener for recent activity - reload all data when any collection changes
    FirebaseFirestore.instance
        .collection('lessonRetention')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Only update recent activity, don't reload everything
        _getRecentActivity().then((activity) {
          _debouncedUpdate(() {
        setState(() {
              _recentActivity = activity;
            });
          });
        });
      }
    });
    
    FirebaseFirestore.instance
        .collection('adaptiveAssessmentResults')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Only update recent activity, don't reload everything
        _getRecentActivity().then((activity) {
          _debouncedUpdate(() {
            setState(() {
              _recentActivity = activity;
            });
          });
        });
      }
    });
    
    FirebaseFirestore.instance
        .collection('userActivities')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        // Only update recent activity, don't reload everything
        _getRecentActivity().then((activity) {
          _debouncedUpdate(() {
            setState(() {
              _recentActivity = activity;
            });
          });
        });
      }
    });

    // Real-time listener for focus sessions
    FirebaseFirestore.instance
        .collection('focusSessions')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _debouncedUpdate(() {
        setState(() {
          _focusStats = _calculateFocusStats(snapshot.docs);
          });
        });
      }
    });

    // Real-time listener for break sessions
    FirebaseFirestore.instance
        .collection('breakSessions')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _debouncedUpdate(() {
        setState(() {
          _focusStats = _calculateFocusStatsWithBreaks(_focusStats, snapshot.docs);
          });
        });
      }
    });

    // Real-time listener for user stats (XP, level, badges)
    FirebaseFirestore.instance
        .collection('userStats')
        .doc(widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.exists) {
        final data = snapshot.data()!;
        _debouncedUpdate(() {
        setState(() {
          _userStats = UserGamificationStats(
            nickname: widget.nickname,
            totalXP: data['totalXP'] ?? 0,
            currentLevel: data['currentLevel'] ?? 1,
            badgeCount: data['badgeCount'] ?? 0,
            streakDays: data['streakDays'] ?? 0,
            lastLoginDate: data['lastLoginDate'] != null 
                ? (data['lastLoginDate'] as Timestamp).toDate() 
                : null,
          );
          });
        });
      }
    });

    // Real-time listener for user badges
    FirebaseFirestore.instance
        .collection('userBadges')
        .where('nickname', isEqualTo: widget.nickname)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _debouncedUpdate(() {
        setState(() {
          _badges = snapshot.docs.map((doc) {
            final data = doc.data();
            return UserBadge(
              badgeId: data['badgeId'],
              earnedAt: (data['earnedAt'] as Timestamp).toDate(),
              badgeDefinition: _gamificationSystem.getBadgeDefinition(data['badgeId']),
            );
          }).toList();
          });
        });
      }
    });

    // Real-time listener for leaderboard
    FirebaseFirestore.instance
        .collection('userStats')
        .orderBy('totalXP', descending: true)
        .limit(5)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        _debouncedUpdate(() {
        setState(() {
          _leaderboard = snapshot.docs.asMap().entries.map((entry) {
            final data = entry.value.data();
            return LeaderboardEntry(
              rank: entry.key + 1,
              nickname: data['nickname'] ?? 'Unknown',
              totalXP: data['totalXP'] ?? 0,
              level: data['currentLevel'] ?? 1,
              badgeCount: data['badgeCount'] ?? 0,
            );
          }).toList();
          });
        });
      }
    });
  }

  /// Calculate focus statistics from real-time data
  FocusStatistics? _calculateFocusStats(List<QueryDocumentSnapshot> focusDocs) {
    if (focusDocs.isEmpty) return null;

    int totalSessions = 0;
    int completedSessions = 0;
    int totalFocusTime = 0;

    for (var doc in focusDocs) {
      final data = doc.data() as Map<String, dynamic>;
      totalSessions++;
      
      if (data['status'] == 'completed') {
        completedSessions++;
      }
      
      if (data['duration'] != null) {
        totalFocusTime += data['duration'] as int;
      }
    }

    final averageSessionLength = totalSessions > 0 ? (totalFocusTime / totalSessions).toDouble() : 0.0;
    final focusScore = _calculateFocusScore(completedSessions, totalSessions, averageSessionLength);

    return FocusStatistics(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      totalFocusTime: totalFocusTime,
      totalBreakTime: 0, // Will be updated by break listener
      averageSessionLength: averageSessionLength,
      focusScore: focusScore,
    );
  }

  /// Update focus stats with break data
  FocusStatistics? _calculateFocusStatsWithBreaks(FocusStatistics? currentStats, List<QueryDocumentSnapshot> breakDocs) {
    if (currentStats == null) return null;

    int totalBreakTime = 0;
    for (var doc in breakDocs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['duration'] != null) {
        totalBreakTime += data['duration'] as int;
      }
    }

    return FocusStatistics(
      totalSessions: currentStats.totalSessions,
      completedSessions: currentStats.completedSessions,
      totalFocusTime: currentStats.totalFocusTime,
      totalBreakTime: totalBreakTime,
      averageSessionLength: currentStats.averageSessionLength,
      focusScore: currentStats.focusScore,
    );
  }

  /// Calculate focus score based on completion rate and session length
  double _calculateFocusScore(int completed, int total, double avgLength) {
    if (total == 0) return 0;
    
    final completionRate = completed / total;
    final lengthScore = (avgLength / 15.0).clamp(0.0, 1.0); // 15 minutes default
    
    return ((completionRate * 0.7) + (lengthScore * 0.3)) * 100;
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    // Get comprehensive recent activity from multiple Firebase collections
    try {
      print('DEBUG: Analytics Dashboard - Fetching recent activity for ${widget.nickname}');
      final List<Map<String, dynamic>> allActivities = [];
      final Set<String> processedContentIds = {}; // Track processed content to avoid duplicates
      
      // Get activities from adaptiveAssessmentResults collection (primary source for assessments)
      final adaptiveAssessmentQuery = await FirebaseFirestore.instance
          .collection('adaptiveAssessmentResults')
          .where('nickname', isEqualTo: widget.nickname)
          .limit(20)
          .get();
      
      print('DEBUG: Analytics Dashboard - Found ${adaptiveAssessmentQuery.docs.length} adaptive assessment records');
      for (final doc in adaptiveAssessmentQuery.docs) {
        final data = doc.data();
        print('DEBUG: Analytics Dashboard - Assessment data: ${data}');
        
        // Get the actual assessment title from the contents collection
        String assessmentTitle = 'Unknown Assessment';
        try {
          if (data['contentId'] != null && data['contentId'].toString().isNotEmpty) {
            final contentDoc = await FirebaseFirestore.instance
                .collection('contents')
                .doc(data['contentId'].toString())
                .get();
            if (contentDoc.exists) {
              assessmentTitle = contentDoc.data()?['title'] ?? 'Unknown Assessment';
            }
          }
          
          // If still unknown, try to use moduleName as fallback
          if (assessmentTitle == 'Unknown Assessment' && data['moduleName'] != null) {
            assessmentTitle = data['moduleName'].toString();
          }
        } catch (e) {
          print('DEBUG: Could not fetch assessment title: $e');
          // Use moduleName as fallback if available
          if (data['moduleName'] != null) {
            assessmentTitle = data['moduleName'].toString();
          }
        }
        
        // Mark this content as processed
        if (data['contentId'] != null) {
          processedContentIds.add(data['contentId'].toString());
        }
        
        allActivities.add({
          ...data,
          'source': 'adaptiveAssessmentResults',
          'activityType': 'assessment_completion',
          'moduleName': data['moduleName'] ?? 'Unknown Assessment',
          'lessonType': assessmentTitle, // Use actual assessment title
          'assessmentTitle': assessmentTitle, // Store the title separately too
          'score': data['correctAnswers'] ?? 0,
          'totalQuestions': data['totalQuestions'] ?? 0,
          'completedAt': data['timestamp'] ?? data['date'],
          'passed': (data['performance'] ?? 0.0) >= 0.7,
        });
      }
      
      // Get activities from lessonRetention collection (for lessons, not assessments)
      final lessonRetentionQuery = await FirebaseFirestore.instance
          .collection('lessonRetention')
          .where('nickname', isEqualTo: widget.nickname)
          .limit(20)
          .get();

      print('DEBUG: Analytics Dashboard - Found ${lessonRetentionQuery.docs.length} lesson retention records');
      for (final doc in lessonRetentionQuery.docs) {
        final data = doc.data();
        
        // Skip if this is an assessment that we already processed
        if (data['contentId'] != null && processedContentIds.contains(data['contentId'].toString())) {
          continue; // Skip duplicate
        }
        
        allActivities.add({
          ...data,
          'source': 'lessonRetention',
          'activityType': 'lesson_completion',
        });
      }
      
      // Get activities from userActivities collection (gamification - only for non-assessment activities)
      final userActivitiesQuery = await FirebaseFirestore.instance
          .collection('userActivities')
          .where('nickname', isEqualTo: widget.nickname)
          .limit(20)
          .get();
      
      print('DEBUG: Analytics Dashboard - Found ${userActivitiesQuery.docs.length} user activity records');
      for (final doc in userActivitiesQuery.docs) {
        final data = doc.data();
        print('DEBUG: Analytics Dashboard - User activity data: ${data}');
        
        // Skip gamification activities that are related to assessments we already processed
        if (data['contentId'] != null && processedContentIds.contains(data['contentId'].toString())) {
          continue; // Skip duplicate
        }
        
        // Skip assessment-related gamification activities (even without contentId)
        final activity = data['activity']?.toString().toLowerCase() ?? '';
        if (activity == 'perfect_score' || 
            activity == 'assessment_passed' || 
            activity == 'lesson_completed' ||
            activity.contains('assessment') ||
            activity.contains('lesson')) {
          continue; // Skip assessment-related gamification activities
        }
        
        // Only include pure gamification activities (like badges, streaks, etc.)
        if (data['activity'] != null && 
            !activity.contains('assessment') &&
            !activity.contains('lesson') &&
            !activity.contains('score') &&
            !activity.contains('passed')) {
          allActivities.add({
            ...data,
            'source': 'userActivities',
            'activityType': 'gamification_activity',
            'moduleName': data['activity'] ?? 'Unknown Activity',
            'lessonType': data['activity'] ?? 'activity',
            'score': data['xpAwarded'] ?? 0,
            'totalQuestions': 1, // XP activities are single events
            'completedAt': data['timestamp'] ?? data['date'],
            'passed': true, // XP activities are always "passed"
          });
        }
      }
      
      // Consolidate duplicate activities (same contentId and similar timestamp)
      final Map<String, Map<String, dynamic>> consolidatedActivities = {};
      
      for (final activity in allActivities) {
        final contentId = activity['contentId']?.toString();
        final timestamp = activity['completedAt'] ?? activity['timestamp'];
        
        if (contentId != null && contentId.isNotEmpty) {
          final key = contentId;
          
          if (consolidatedActivities.containsKey(key)) {
            // Merge with existing activity, prioritizing adaptiveAssessmentResults
            final existing = consolidatedActivities[key]!;
            if (activity['source'] == 'adaptiveAssessmentResults') {
              // Replace with assessment data (more complete)
              consolidatedActivities[key] = activity;
            } else if (existing['source'] != 'adaptiveAssessmentResults') {
              // Keep the existing one if it's not assessment data
              continue;
            }
          } else {
            consolidatedActivities[key] = activity;
          }
        } else {
          // Activities without contentId (like pure gamification activities)
          final key = '${activity['source']}_${activity['activity']}_${timestamp}';
          consolidatedActivities[key] = activity;
        }
      }
      
      // Convert back to list
      final consolidatedList = consolidatedActivities.values.toList();
      
      // Sort all activities by completedAt/timestamp in descending order
      consolidatedList.sort((a, b) {
        Timestamp? aTime;
        Timestamp? bTime;
        
        // Try different timestamp fields
        if (a['completedAt'] != null) {
          aTime = a['completedAt'] as Timestamp?;
        } else if (a['timestamp'] != null) {
          aTime = a['timestamp'] as Timestamp?;
        }
        
        if (b['completedAt'] != null) {
          bTime = b['completedAt'] as Timestamp?;
        } else if (b['timestamp'] != null) {
          bTime = b['timestamp'] as Timestamp?;
        }
        
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      // Return only the first 10 after sorting
      return consolidatedList.take(10).toList();
    } catch (e) {
      print('Error getting recent activity: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: ResponsiveText(
          '📊 Analytics Hub',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          mobileFontSize: 20,
          tabletFontSize: 24,
          desktopFontSize: 28,
          largeDesktopFontSize: 32,
        ),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          labelStyle: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
              largeDesktop: 18,
            ),
          ),
          tabs: const [
            Tab(text: '📋 Learning', icon: Icon(Icons.school)),
            Tab(text: '📈 Progress', icon: Icon(Icons.trending_up)),
            Tab(text: '🧠 Focus', icon: Icon(Icons.psychology)),
          ],
        ),
        actions: [
          IconButton(
            icon: ResponsiveIcon(
              Icons.refresh,
              color: Colors.white,
              mobileSize: 20,
              tabletSize: 24,
              desktopSize: 28,
              largeDesktopSize: 32,
            ),
            onPressed: () {
              print('DEBUG: Analytics Dashboard - Manual refresh triggered');
              _loadAllData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF648BA2)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLearningTab(),
                _buildProgressTab(),
                _buildFocusTab(),
              ],
            ),
    );
  }

  Widget _buildLearningTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kid-friendly header
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                ResponsiveText(
                  '📚 Learning Hub',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  mobileFontSize: 24,
                  tabletFontSize: 28,
                  desktopFontSize: 32,
                  largeDesktopFontSize: 36,
                ),
                ResponsiveSpacing(mobileSpacing: 8),
                ResponsiveText(
                  'Track your learning progress and activity!',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  mobileFontSize: 14,
                  tabletFontSize: 16,
                  desktopFontSize: 18,
                  largeDesktopFontSize: 20,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
        
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Lessons Due Section
          _buildLessonsDueSection(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Recent Activity Section
          _buildRecentActivitySection(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Most Active Items Section
          _buildMostActiveSection(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Activity by Category Section
          _buildActivityByCategorySection(),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: ResponsiveUtils.getResponsivePadding(context),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                ResponsiveText(
                  '📈 Progress & Achievements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  mobileFontSize: 24,
                  tabletFontSize: 28,
                  desktopFontSize: 32,
                  largeDesktopFontSize: 36,
                ),
                ResponsiveSpacing(mobileSpacing: 8),
                ResponsiveText(
                  'Track your learning progress and unlock achievements!',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  mobileFontSize: 14,
                  tabletFontSize: 16,
                  desktopFontSize: 18,
                  largeDesktopFontSize: 20,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Progress Overview
          _buildProgressOverview(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // User Stats (Gamification)
          if (_userStats != null) _buildUserStats(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Retention Statistics
          _buildRetentionStats(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Badges Section
          _buildBadgesSection(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Progress Chart
          _buildProgressChart(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Leaderboard Section
          _buildLeaderboardSection(),
          
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Level Ranks Guide
          _buildLevelRanksGuide(),
        ],
      ),
    );
  }

  Widget _buildFocusTab() {
    return SingleChildScrollView(
      padding: ResponsiveUtils.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interactive Focus Widget removed; show a lightweight placeholder with test controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                const Text(
                  'Focus tracking is available in the full experience.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _showBreakDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Test Break', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loadAllData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Refresh Focus', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ResponsiveSpacing(mobileSpacing: 30),
          
          // Focus Statistics
          if (_focusStats != null) _buildFocusStats(),
        ],
      ),
    );
  }

  Widget _buildVisitItem(Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final visitCount = item['visitCount'] as int;
    final itemName = item['itemName'] as String;
    final itemType = item['itemType'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getItemTypeColor(itemType).withOpacity(0.1),
            _getItemTypeColor(itemType).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getItemTypeColor(itemType).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getItemTypeColor(itemType).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getItemTypeIcon(itemType),
              color: _getItemTypeColor(itemType),
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  _getItemTypeLabel(itemType),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 12,
              vertical: isSmallScreen ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: _getItemTypeColor(itemType),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$visitCount visits',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String category, List<Map<String, dynamic>> items) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final totalVisits = items.fold<int>(0, (sum, item) => sum + (item['visitCount'] as int? ?? 1));
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getItemTypeColor(category).withOpacity(0.1),
            _getItemTypeColor(category).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getItemTypeColor(category).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _getItemTypeIcon(category),
            color: _getItemTypeColor(category),
            size: isSmallScreen ? 24 : 32,
          ),
          const SizedBox(height: 8),
          Text(
            _getItemTypeLabel(category),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$totalVisits visits',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: _getItemTypeColor(category),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${items.length} items',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'lesson':
        return const Color(0xFF4CAF50); // Green
      case 'assessment':
        return const Color(0xFF2196F3); // Blue
      case 'game':
        return const Color(0xFFFF9800); // Orange
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'lesson':
        return Icons.school;
      case 'assessment':
        return Icons.quiz;
      case 'game':
        return Icons.games;
      default:
        return Icons.help;
    }
  }

  String _getItemTypeLabel(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'lesson':
        return 'Lesson';
      case 'assessment':
        return 'Assessment';
      case 'game':
        return 'Game';
      default:
        return 'Activity';
    }
  }

  Widget _buildLessonsDueSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📚 Lessons Ready for Review',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_lessonsDue.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${_lessonsDue.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 15 : 20),
          if (_lessonsDue.isEmpty)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
            const Text(
                    '🎉',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Awesome! No lessons to review right now! Keep up the great work! 🌟',
              style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: const Color(0xFF4A4E69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._lessonsDue.map((lesson) => _buildLessonCard(lesson)),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                '⭐ Your Recent Achievements',
            style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20, // Reduced font size
              fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    const Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
              ),
              if (_recentActivity.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '${_recentActivity.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 15 : 20),
          if (_recentActivity.isEmpty)
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
            const Text(
                    '🚀',
                    style: TextStyle(fontSize: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Start learning to see your amazing progress here! You\'re going to do great! 💪',
              style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: const Color(0xFF4A4E69),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._recentActivity.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  Widget _buildMostActiveSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 10),
              Text(
                '🌟 Most Active Items',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_mostVisitedItems.isEmpty && _mostFrequentHistoricalActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No activity data yet!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring lessons, assessments, and games to see your activity statistics!',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...(_mostVisitedItems.isNotEmpty 
                ? _mostVisitedItems.take(5).map((item) => _buildVisitItem(item))
                : _mostFrequentHistoricalActivities.take(5).map((item) => _buildVisitItem(item))),
        ],
      ),
    );
  }

  Widget _buildActivityByCategorySection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.category, color: Color(0xFF4CAF50), size: 24),
              const SizedBox(width: 10),
              Text(
                '📂 Activity by Category',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildCategoryCard('lessons', 
                _visitCounts['lessons']?.isNotEmpty == true 
                  ? _visitCounts['lessons']! 
                  : _historicalActivitiesByType['lessons'] ?? [])),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoryCard('assessments', 
                _visitCounts['assessments']?.isNotEmpty == true 
                  ? _visitCounts['assessments']! 
                  : _historicalActivitiesByType['assessments'] ?? [])),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoryCard('games', 
                _visitCounts['games']?.isNotEmpty == true 
                  ? _visitCounts['games']! 
                  : _historicalActivitiesByType['games'] ?? [])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Progress Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Lessons',
                  '${_retentionStats['totalLessons'] ?? 0}',
                  Icons.school,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Mastered',
                  '${_retentionStats['masteredLessons'] ?? 0}',
                  Icons.check_circle,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Due for Review',
                  '${_retentionStats['lessonsDueForReview'] ?? 0}',
                  Icons.schedule,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetentionStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 Memory Retention Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Mastery %',
                  '${(_retentionStats['masteryPercentage'] ?? 0).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Score',
                  '${(_retentionStats['averageRetentionScore'] ?? 0).toStringAsFixed(1)}',
                  Icons.star,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📈 Progress Trend',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 4),
                      const FlSpot(2, 5),
                      const FlSpot(3, 4),
                      const FlSpot(4, 6),
                      const FlSpot(5, 7),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 Focus Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sessions',
                  '${_focusStats!.totalSessions}',
                  Icons.play_circle_filled,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  '${_focusStats!.completedSessions}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Focus Time',
                  '${_focusStats!.totalFocusTime}m',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.pink.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎮 Gamification Stats',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total XP',
                  '${_userStats!.totalXP}',
                  Icons.star,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Level',
                  '${_userStats!.currentLevel}',
                  Icons.emoji_events,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Badges',
                  '${_badges.length}',
                  Icons.military_tech,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Level Title Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  GamificationSystem.getLevelTitle(_userStats!.currentLevel),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GamificationSystem.getLevelColor(_userStats!.currentLevel),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  GamificationSystem.getLevelDescription(_userStats!.currentLevel),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Badges Earned',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          if (_badges.isEmpty)
            const Text(
              'No badges earned yet. Keep learning! 🎯',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _badges.map((badge) => _buildBadgeCard(badge)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Leaderboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          if (_leaderboard.isEmpty)
            const Text(
              'No leaderboard data available yet.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            )
          else
            ..._leaderboard.asMap().entries.map((entry) => 
              _buildLeaderboardEntry(entry.key + 1, entry.value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: () => _startReview(lesson),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
      decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF8F9FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade200, width: 2),
      ),
      child: Row(
        children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Colors.orange.shade600,
                    size: isSmallScreen ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 12 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson['lessonType'] ?? 'Unknown Lesson',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A4E69),
                  ),
                ),
                      const SizedBox(height: 4),
                Text(
                  lesson['moduleName'] ?? 'Unknown Module',
                  style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.touch_app,
                    color: Colors.orange.shade600,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get display title for activity with proper fallback logic
  String _getDisplayTitle(Map<String, dynamic> activity) {
    // Try different title fields in order of preference
    if (activity['assessmentTitle'] != null && 
        activity['assessmentTitle'].toString().isNotEmpty &&
        activity['assessmentTitle'] != 'Unknown Assessment') {
      return activity['assessmentTitle'].toString();
    }
    
    if (activity['lessonType'] != null && 
        activity['lessonType'].toString().isNotEmpty &&
        activity['lessonType'] != 'assessment_passed' &&
        activity['lessonType'] != 'perfect_score' &&
        activity['lessonType'] != 'lesson_completed' &&
        activity['lessonType'] != 'Unknown Activity') {
      return activity['lessonType'].toString();
    }
    
    if (activity['moduleName'] != null && 
        activity['moduleName'].toString().isNotEmpty &&
        activity['moduleName'] != 'perfect_score' &&
        activity['moduleName'] != 'assessment_passed') {
      return activity['moduleName'].toString();
    }
    
    if (activity['activity'] != null && 
        activity['activity'].toString().isNotEmpty &&
        activity['activity'] != 'perfect_score' &&
        activity['activity'] != 'assessment_passed' &&
        activity['activity'] != 'lesson_completed') {
      return activity['activity'].toString();
    }
    
    // Final fallback
    return 'Learning Activity';
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 15),
      decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Row(
        children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.blue.shade600,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayTitle(activity),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A4E69),
                  ),
                ),
                    const SizedBox(height: 4),
                Text(
                  'Score: ${activity['score']}/${activity['totalQuestions']}',
                  style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '✅',
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeCard(UserBadge badge) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade300),
      ),
      child: Column(
        children: [
          Icon(Icons.military_tech, color: Colors.yellow.shade700, size: 32),
          const SizedBox(height: 8),
          Text(
            badge.badgeDefinition.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(int rank, LeaderboardEntry entry) {
    final levelTitle = GamificationSystem.getLevelTitle(entry.level);
    final levelColor = GamificationSystem.getLevelColor(entry.level);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank == 1 ? Colors.yellow.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank == 1 ? Colors.yellow.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Text(
            '#$rank',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: rank == 1 ? Colors.yellow.shade700 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getLevelIcon(entry.level),
                      color: levelColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.nickname,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  levelTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: levelColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXP} XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Text(
                'Lv.${entry.level}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: levelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelRanksGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎓 Learning Levels',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Progress through different learning levels as you complete lessons and activities.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          // Level Ranks Grid - Responsive single column layout
          Column(
            children: List.generate(10, (index) {
              final level = index + 1;
              final levelTitle = GamificationSystem.getLevelTitle(level);
              final levelColor = GamificationSystem.getLevelColor(level);
              final levelIcon = _getLevelIcon(level);
              final xpRequired = _getXPRequired(level);
              
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left side - Level info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: levelColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Level $level',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  levelTitle,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A4E69),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            GamificationSystem.getLevelDescription(level),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                                Text(
                                  '$xpRequired XP Required',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Right side - Big icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: levelColor.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        levelIcon,
                        color: levelColor,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          // Motivation Text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                const Text(
                  'Keep Learning to Level Up!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete lessons and unlock new learning levels!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get XP required for a specific level
  int _getXPRequired(int level) {
    const Map<int, int> levelRequirements = {
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
    return levelRequirements[level] ?? 0;
  }
  IconData _getLevelIcon(int level) {
    switch (level) {
      case 1: return Icons.child_care; // Baby/child icon for novice
      case 2: return Icons.school; // School icon for apprentice
      case 3: return Icons.menu_book; // Book icon for student
      case 4: return Icons.lightbulb_outline; // Lightbulb for scholar
      case 5: return Icons.psychology; // Brain icon for learner
      case 6: return Icons.star; // Star for achiever
      case 7: return Icons.track_changes; // Target icon for expert
      case 8: return Icons.emoji_events; // Trophy for master
      case 9: return Icons.military_tech; // Medal for champion
      case 10: return Icons.auto_awesome; // Sparkles for genius
      default: return level > 10 ? Icons.diamond : Icons.child_care;
    }
  }

  void _startReview(Map<String, dynamic> lesson) {
    final lessonType = lesson['lessonType'] ?? '';
    
    // Navigate based on lesson type
    try {
      switch (lessonType.toLowerCase()) {
        case 'my family':
        case 'my family lesson':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearnMyFamily(nickname: widget.nickname),
            ),
          );
          break;
        case 'my family assessment':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyFamilyAssessment(nickname: widget.nickname),
            ),
          );
          break;
        case 'letter tracing':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LetterTracingGame(nickname: widget.nickname),
            ),
          );
          break;
        case 'flashcard game':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FlashcardGame(nickname: widget.nickname),
            ),
          );
          break;
        default:
          // For unknown lesson types, do nothing for now
          break;
      }
    } catch (e) {
      // Handle navigation errors silently
      print('Navigation error: $e');
    }
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Take a short break?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Would you like to take a short break now or continue?',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Break time! Take a rest! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Take Break', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keep going! You\'re doing great! 💪'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
