import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'smart_learning_recommendations.dart';
import 'dart:math' as math;

/// Comprehensive Progress Analytics Dashboard
/// Provides detailed insights into student learning progress
class ProgressAnalyticsDashboard extends StatefulWidget {
  final String nickname;

  const ProgressAnalyticsDashboard({
    super.key,
    required this.nickname,
  });

  @override
  State<ProgressAnalyticsDashboard> createState() => _ProgressAnalyticsDashboardState();
}

class _ProgressAnalyticsDashboardState extends State<ProgressAnalyticsDashboard> with TickerProviderStateMixin {
  final SmartLearningRecommendations _recommendations = SmartLearningRecommendations();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  late TabController _tabController;
  
  // Data variables
  LearningAnalysis? _learningAnalysis;
  List<LearningRecommendation> _recommendationsList = [];
  Map<String, dynamic> _progressData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load all analytics data in parallel
      final results = await Future.wait([
        _getLearningAnalysis(),
        _getRecommendations(),
        _getProgressData(),
      ]);
      
      setState(() {
        _learningAnalysis = results[0] as LearningAnalysis?;
        _recommendationsList = results[1] as List<LearningRecommendation>;
        _progressData = results[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Error loading analytics data: $e
    }
  }

  Future<LearningAnalysis?> _getLearningAnalysis() async {
    try {
      return await _recommendations.analyzeLearningPatterns(widget.nickname);
    } catch (e) {
      // Error getting learning analysis: $e
      return null;
    }
  }

  Future<List<LearningRecommendation>> _getRecommendations() async {
    try {
      return await _recommendations.getRecommendations(widget.nickname);
    } catch (e) {
      // Error getting recommendations: $e
      return [];
    }
  }

  Future<Map<String, dynamic>> _getProgressData() async {
    try {
      print('DEBUG: Progress Analytics - Fetching progress data for ${widget.nickname}');
      
      // Get comprehensive progress data from multiple collections
      final userStatsDoc = await _firestore.collection('userStats').doc(widget.nickname).get();
      final userStats = userStatsDoc.exists ? userStatsDoc.data()! : {};
      print('DEBUG: Progress Analytics - User stats: ${userStats}');

      // Get lesson retention data
      final lessonRetentionQuery = await _firestore
          .collection('lessonRetention')
          .where('nickname', isEqualTo: widget.nickname)
          .get();
      
      final lessons = lessonRetentionQuery.docs.map((doc) => doc.data()).toList();
      print('DEBUG: Progress Analytics - Found ${lessons.length} lesson retention records');

      // Get adaptive assessment results
      final adaptiveAssessmentQuery = await _firestore
          .collection('adaptiveAssessmentResults')
          .where('nickname', isEqualTo: widget.nickname)
          .get();
      
      final assessments = adaptiveAssessmentQuery.docs.map((doc) => doc.data()).toList();
      print('DEBUG: Progress Analytics - Found ${assessments.length} adaptive assessment records');

      // Get focus sessions
      final focusQuery = await _firestore
          .collection('focusSessions')
          .where('nickname', isEqualTo: widget.nickname)
          .get();
      
      final focusSessions = focusQuery.docs.map((doc) => doc.data()).toList();

      // Get badges
      final badgesQuery = await _firestore
          .collection('userBadges')
          .where('nickname', isEqualTo: widget.nickname)
          .get();
      
      final badges = badgesQuery.docs.map((doc) => doc.data()).toList();

      // Get user activities (gamification)
      final userActivitiesQuery = await _firestore
          .collection('userActivities')
          .where('nickname', isEqualTo: widget.nickname)
          .get();
      
      final userActivities = userActivitiesQuery.docs.map((doc) => doc.data()).toList();
      print('DEBUG: Progress Analytics - Found ${userActivities.length} user activity records');

      return {
        'userStats': userStats,
        'lessons': lessons,
        'assessments': assessments,
        'focusSessions': focusSessions,
        'badges': badges,
        'userActivities': userActivities,
      };
    } catch (e) {
      print('Error getting progress data: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '📊 Learning Analytics',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: '📈 Overview', icon: Icon(Icons.analytics_outlined)),
            Tab(text: '🎯 Recommendations', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: '📊 Progress', icon: Icon(Icons.trending_up)),
            Tab(text: '🏆 Achievements', icon: Icon(Icons.emoji_events)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRecommendationsTab(),
                _buildProgressTab(),
                _buildAchievementsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_learningAnalysis == null) {
      return const Center(
        child: Text('No analytics data available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall Score Card
          _buildOverallScoreCard(),
          const SizedBox(height: 20),
          
          // Subject Performance Chart
          _buildSubjectPerformanceChart(),
          const SizedBox(height: 20),
          
          // Learning Velocity Card
          _buildLearningVelocityCard(),
          const SizedBox(height: 20),
          
          // Focus Analysis Card
          _buildFocusAnalysisCard(),
        ],
      ),
    );
  }

  Widget _buildOverallScoreCard() {
    final overallScore = _learningAnalysis?.overallScore ?? 0.0;
    final scoreColor = _getScoreColor(overallScore);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withValues(alpha: 0.8), scoreColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🌟 Overall Learning Score',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${overallScore.round()}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _getScoreDescription(overallScore),
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectPerformanceChart() {
    final subjectPerformance = _learningAnalysis?.subjectPerformance ?? {};
    
    if (subjectPerformance.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No subject performance data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Subject Performance',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final subjects = subjectPerformance.keys.toList();
                        if (value.toInt() < subjects.length) {
                          return Text(
                            subjects[value.toInt()].substring(0, math.min(8, subjects[value.toInt()].length)),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: subjectPerformance.entries.map((entry) {
                  final index = subjectPerformance.keys.toList().indexOf(entry.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: _getSubjectColor(entry.key),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningVelocityCard() {
    final velocity = _learningAnalysis?.learningVelocity ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ Learning Velocity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${velocity.toStringAsFixed(1)} lessons/day',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    Text(
                      _getVelocityDescription(velocity),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.speed,
                size: 48,
                color: _getVelocityColor(velocity),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusAnalysisCard() {
    final focusAnalysis = _learningAnalysis?.focusAnalysis ?? FocusAnalysis.empty();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧠 Focus Analysis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFocusMetric(
                  'Completion Rate',
                  '${(focusAnalysis.completionRate * 100).round()}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildFocusMetric(
                  'Avg Duration',
                  '${focusAnalysis.averageDuration.round()} min',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildFocusMetric(
                  'Sessions',
                  '${focusAnalysis.totalSessions}',
                  Icons.play_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusMetric(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            '🎯 Personalized Recommendations',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          if (_recommendationsList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'No recommendations available at the moment',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            ..._recommendationsList.map((recommendation) => _buildRecommendationCard(recommendation)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(LearningRecommendation recommendation) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: recommendation.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
                recommendation.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: recommendation.color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendation.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: recommendation.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.action,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                recommendation.estimatedTime,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab() {
    final lessons = _progressData['lessons'] as List<Map<String, dynamic>>? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress Timeline
          _buildProgressTimeline(lessons),
          const SizedBox(height: 20),
          
          // Weekly Progress Chart
          _buildWeeklyProgressChart(lessons),
          const SizedBox(height: 20),
          
          // Subject Breakdown
          _buildSubjectBreakdown(lessons),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(List<Map<String, dynamic>> lessons) {
    if (lessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No progress data available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Sort lessons by completion date
    lessons.sort((a, b) {
      final aTime = (a['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['completedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...lessons.take(10).map((lesson) => _buildTimelineItem(lesson)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> lesson) {
    final completedAt = (lesson['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final moduleName = lesson['moduleName'] ?? 'Unknown';
    final score = lesson['retentionScore'] ?? 0.0;
    final passed = lesson['passed'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: passed ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passed ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.help_outline,
            color: passed ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  '${score.round()}% • ${_formatDate(completedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressChart(List<Map<String, dynamic>> lessons) {
    // Group lessons by week
    final Map<String, int> weeklyData = {};
    final now = DateTime.now();
    
    for (final lesson in lessons) {
      final completedAt = (lesson['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final weekKey = _getWeekKey(completedAt);
      weeklyData[weekKey] = (weeklyData[weekKey] ?? 0) + 1;
    }
    
    // Get last 8 weeks
    final List<String> last8Weeks = [];
    for (int i = 7; i >= 0; i--) {
      final weekDate = now.subtract(Duration(days: i * 7));
      last8Weeks.add(_getWeekKey(weekDate));
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Weekly Progress',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value.toInt() < last8Weeks.length) {
                          return Text(
                            'W${value.toInt() + 1}',
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text('${value.toInt()}', style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: last8Weeks.asMap().entries.map((entry) {
                      final weekKey = entry.value;
                      final count = weeklyData[weekKey] ?? 0;
                      return FlSpot(entry.key.toDouble(), count.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: const Color(0xFF6C63FF),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectBreakdown(List<Map<String, dynamic>> lessons) {
    final Map<String, int> subjectCounts = {};
    final Map<String, double> subjectScores = {};
    
    for (final lesson in lessons) {
      final moduleName = lesson['moduleName'] ?? 'Unknown';
      final score = lesson['retentionScore'] ?? 0.0;
      
      subjectCounts[moduleName] = (subjectCounts[moduleName] ?? 0) + 1;
      subjectScores[moduleName] = (subjectScores[moduleName] ?? 0.0) + score;
    }
    
    // Calculate averages
    subjectScores.forEach((subject, totalScore) {
      subjectScores[subject] = totalScore / subjectCounts[subject]!;
    });
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Subject Breakdown',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...subjectCounts.entries.map((entry) {
            final subject = entry.key;
            final count = entry.value;
            final avgScore = subjectScores[subject] ?? 0.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getSubjectColor(subject).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getSubjectColor(subject).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          '$count lessons • ${avgScore.round()}% avg',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: avgScore / 100,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(_getSubjectColor(subject)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final badges = _progressData['badges'] as List<Map<String, dynamic>>? ?? [];
    final userStats = _progressData['userStats'] as Map<String, dynamic>? ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Achievement Summary
          _buildAchievementSummary(userStats, badges),
          const SizedBox(height: 20),
          
          // Badge Collection
          _buildBadgeCollection(badges),
          const SizedBox(height: 20),
          
          // Achievement Timeline
          _buildAchievementTimeline(badges),
        ],
      ),
    );
  }

  Widget _buildAchievementSummary(Map<String, dynamic> userStats, List<Map<String, dynamic>> badges) {
    final totalXP = userStats['totalXP'] ?? 0;
    final currentLevel = userStats['currentLevel'] ?? 1;
    final badgeCount = badges.length;
    
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
        children: [
          const Text(
            '🏆 Achievement Summary',
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
                child: _buildAchievementMetric(
                  'Level',
                  '$currentLevel',
                  Icons.emoji_events,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildAchievementMetric(
                  'Total XP',
                  '$totalXP',
                  Icons.star,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildAchievementMetric(
                  'Badges',
                  '$badgeCount',
                  Icons.military_tech,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementMetric(String title, String value, IconData icon, Color color) {
    return Column(
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
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCollection(List<Map<String, dynamic>> badges) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎖️ Badge Collection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          if (badges.isEmpty)
            const Center(
              child: Text(
                'No badges earned yet. Keep learning to earn badges!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                final badgeId = badge['badgeId'] ?? 'unknown';
                final earnedAt = (badge['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🏆', // You can customize this based on badge type
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badgeId.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _formatDate(earnedAt),
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementTimeline(List<Map<String, dynamic>> badges) {
    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort badges by earned date
    badges.sort((a, b) {
      final aTime = (a['earnedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final bTime = (b['earnedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📅 Achievement Timeline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          ...badges.take(10).map((badge) {
            final badgeId = badge['badgeId'] ?? 'unknown';
            final earnedAt = (badge['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          badgeId.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          _formatDate(earnedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Helper methods
  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 90) return 'Outstanding! You\'re a learning superstar! 🌟';
    if (score >= 80) return 'Excellent! Keep up the great work! 🎉';
    if (score >= 70) return 'Good job! You\'re making great progress! 👍';
    if (score >= 60) return 'Not bad! Keep practicing to improve! 💪';
    return 'Keep learning! Every step counts! 🌱';
  }

  Color _getVelocityColor(double velocity) {
    if (velocity >= 1.0) return Colors.green;
    if (velocity >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _getVelocityDescription(double velocity) {
    if (velocity >= 1.0) return 'Excellent learning pace!';
    if (velocity >= 0.5) return 'Good learning pace';
    return 'Try to learn more regularly';
  }

  Color _getSubjectColor(String subject) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[subject.hashCode % colors.length];
  }

  String _getWeekKey(DateTime date) {
    final year = date.year;
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final week = ((dayOfYear - date.weekday + 10) / 7).floor();
    return '${year}W$week';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    return '${(difference / 30).floor()} months ago';
  }
}
