import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'memory_retention_system.dart';
import 'notification_service.dart';

/// Dedicated Review Dashboard for Memory Retention
class ReviewDashboard extends StatefulWidget {
  final String nickname;
  
  const ReviewDashboard({
    super.key,
    required this.nickname,
  });

  @override
  State<ReviewDashboard> createState() => _ReviewDashboardState();
}

class _ReviewDashboardState extends State<ReviewDashboard> with TickerProviderStateMixin {
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  final NotificationService _notificationService = NotificationService();
  
  late TabController _tabController;
  
  List<Map<String, dynamic>> _lessonsDue = [];
  Map<String, dynamic> _retentionStats = {};
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;
  
  // Settings state
  bool _dailyReminders = true;
  bool _smartScheduling = true;
  bool _reviewNotifications = true;
  double _reviewFrequency = 3.0;
  double _sessionDuration = 15.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
    _setupRealtimeListeners(); // Setup real-time listeners
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);
      
      // Load settings (not real-time)
      await _loadSettings();
      
      // Load dashboard data in parallel
      final results = await Future.wait([
        _retentionSystem.getLessonsDueForReview(widget.nickname),
        _retentionSystem.getUserRetentionStats(widget.nickname),
        _getRecentActivity(),
      ]);
      
      setState(() {
        _lessonsDue = results[0] as List<Map<String, dynamic>>;
        _retentionStats = results[1] as Map<String, dynamic>;
        _recentActivity = results[2] as List<Map<String, dynamic>>;
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
        setState(() {
          _lessonsDue = snapshot.docs
              .map((doc) => doc.data())
              .toList();
        });
      }
    });

    // Real-time listener for recent activity
    FirebaseFirestore.instance
        .collection('lessonRetention')
        .where('nickname', isEqualTo: widget.nickname)
        .orderBy('completedAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _recentActivity = snapshot.docs
              .map((doc) => doc.data())
              .toList();
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> _getRecentActivity() async {
    // Simulate recent activity data
    return [
      {
        'moduleName': 'Functional Academics',
        'lessonType': 'Alphabet Assessment',
        'score': 4,
        'totalQuestions': 5,
        'completedAt': DateTime.now().subtract(const Duration(hours: 2)),
        'masteryLevel': 2,
      },
      {
        'moduleName': 'Functional Academics',
        'lessonType': 'Colors Assessment',
        'score': 3,
        'totalQuestions': 5,
        'completedAt': DateTime.now().subtract(const Duration(days: 1)),
        'masteryLevel': 1,
      },
      {
        'moduleName': 'Functional Academics',
        'lessonType': 'Shapes Assessment',
        'score': 5,
        'totalQuestions': 5,
        'completedAt': DateTime.now().subtract(const Duration(days: 2)),
        'masteryLevel': 3,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: Text(
          '📚 Review Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '📋 Today\'s Reviews', icon: Icon(Icons.today)),
            Tab(text: '📊 Analytics', icon: Icon(Icons.analytics)),
            Tab(text: '⚙️ Settings', icon: Icon(Icons.settings)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF648BA2)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildLessonsDueSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Lessons Due for Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (_lessonsDue.isEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Great job! No lessons need review right now. You\'re doing amazing! 🌟',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._lessonsDue.map((lesson) => _buildLessonCard(lesson)).toList(),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map<String, dynamic> lesson) {
    final moduleName = lesson['moduleName'] ?? 'Unknown';
    final lessonType = lesson['lessonType'] ?? 'Unknown';
    final masteryLevel = lesson['masteryLevel'] ?? 0;
    final reviewCount = lesson['reviewCount'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              Icons.school,
              color: Colors.blue.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$moduleName - $lessonType',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    _buildProgressChip('Mastery', masteryLevel, 6, Colors.purple),
                    const SizedBox(width: 10),
                    _buildProgressChip('Reviews', reviewCount, 10, Colors.green),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _startReview(lesson),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade500,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Review',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChip(String label, int current, int max, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $current/$max',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade100,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.purple.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Schedule Reminders',
                  Icons.notifications,
                  Colors.orange,
                  () => _scheduleReminders(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  'View Progress',
                  Icons.trending_up,
                  Colors.green,
                  () => _viewProgress(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade100,
            Colors.green.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.green.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ..._recentActivity.map((activity) => _buildActivityItem(activity)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final moduleName = activity['moduleName'] ?? 'Unknown';
    final lessonType = activity['lessonType'] ?? 'Unknown';
    final score = activity['score'] ?? 0;
    final totalQuestions = activity['totalQuestions'] ?? 0;
    final completedAt = activity['completedAt'] as DateTime;
    final masteryLevel = activity['masteryLevel'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$moduleName - $lessonType',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Score: $score/$totalQuestions • Mastery Level: $masteryLevel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green.shade600,
                  ),
                ),
                Text(
                  _formatDateTime(completedAt),
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

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Retention Statistics
          _buildRetentionStatsCard(),
          
          const SizedBox(height: 30),
          
          // Mastery Level Chart
          _buildMasteryChart(),
          
          const SizedBox(height: 30),
          
          // Review Frequency Chart
          _buildReviewFrequencyChart(),
          
          const SizedBox(height: 30),
          
          // Performance Trends
          _buildPerformanceTrends(),
        ],
      ),
    );
  }

  Widget _buildRetentionStatsCard() {
    final totalLessons = _retentionStats['totalLessons'] ?? 0;
    final masteredLessons = _retentionStats['masteredLessons'] ?? 0;
    final lessonsDueForReview = _retentionStats['lessonsDueForReview'] ?? 0;
    final averageRetentionScore = _retentionStats['averageRetentionScore'] ?? 0.0;
    final masteryPercentage = _retentionStats['masteryPercentage'] ?? 0.0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo.shade100,
            Colors.indigo.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.indigo.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Retention Statistics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Lessons', totalLessons.toString(), Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Mastered', masteredLessons.toString(), Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Due for Review', lessonsDueForReview.toString(), Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard('Avg Score', '${averageRetentionScore.toStringAsFixed(1)}%', Colors.purple),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Column(
              children: [
                Text(
                  'Mastery Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: masteryPercentage / 100,
                  backgroundColor: Colors.indigo.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade500),
                  minHeight: 8,
                ),
                const SizedBox(height: 5),
                Text(
                  '${masteryPercentage.toStringAsFixed(1)}% Mastered',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryChart() {
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
          Text(
            'Mastery Level Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 20,
                    title: 'Level 1',
                    color: Colors.red.shade300,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: 'Level 2',
                    color: Colors.orange.shade300,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 25,
                    title: 'Level 3',
                    color: Colors.yellow.shade300,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 15,
                    title: 'Level 4+',
                    color: Colors.green.shade300,
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewFrequencyChart() {
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
          Text(
            'Review Frequency (Last 7 Days)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 4, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 6, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 3, color: Colors.blue.shade300)]),
                  BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 4, color: Colors.blue.shade300)]),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTrends() {
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
          Text(
            'Performance Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 4),
                      const FlSpot(2, 3),
                      const FlSpot(3, 5),
                      const FlSpot(4, 4),
                      const FlSpot(5, 5),
                      const FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: Colors.blue.shade400,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.shade100,
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startReview(Map<String, dynamic> lesson) {
    // Navigate to the specific lesson for review
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting review for ${lesson['lessonType']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _scheduleReminders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scheduling reminders...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _viewProgress() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing progress...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dailyReminders = prefs.getBool('${widget.nickname}_daily_reminders') ?? true;
        _smartScheduling = prefs.getBool('${widget.nickname}_smart_scheduling') ?? true;
        _reviewNotifications = prefs.getBool('${widget.nickname}_review_notifications') ?? true;
        _reviewFrequency = prefs.getDouble('${widget.nickname}_review_frequency') ?? 3.0;
        _sessionDuration = prefs.getDouble('${widget.nickname}_session_duration') ?? 15.0;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notification Settings
          _buildSettingsCard(
            '🔔 Notification Settings',
            [
              _buildSwitchTile(
                'Daily Reminders',
                'Receive daily learning reminders',
                _dailyReminders,
                (value) => _toggleDailyReminders(value),
              ),
              _buildSwitchTile(
                'Smart Scheduling',
                'Personalized reminder times based on your activity',
                _smartScheduling,
                (value) => _toggleSmartScheduling(value),
              ),
              _buildSwitchTile(
                'Review Notifications',
                'Get notified when lessons are due for review',
                _reviewNotifications,
                (value) => _toggleReviewNotifications(value),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Learning Preferences
          _buildSettingsCard(
            '🎯 Learning Preferences',
            [
              _buildSliderTile(
                'Review Frequency',
                'How often to schedule reviews',
                _reviewFrequency,
                1.0,
                7.0,
                (value) => _updateReviewFrequency(value),
              ),
              _buildSliderTile(
                'Session Duration',
                'Preferred learning session length (minutes)',
                _sessionDuration,
                5.0,
                30.0,
                (value) => _updateSessionDuration(value),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Data Management
          _buildSettingsCard(
            '📊 Data Management',
            [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Export Progress Data'),
                subtitle: const Text('Download your learning progress'),
                onTap: _exportProgressData,
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.orange),
                title: const Text('Reset Progress'),
                subtitle: const Text('Start fresh (this cannot be undone)'),
                onTap: _resetProgress,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, List<Widget> children) {
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A4E69),
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      leading: const Icon(Icons.toggle_on, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF648BA2),
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.tune, color: Colors.green),
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: value.round().toString(),
            onChanged: onChanged,
            activeColor: const Color(0xFF648BA2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}', style: const TextStyle(fontSize: 12)),
              Text('${value.round()}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${max.round()}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _toggleDailyReminders(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.nickname}_daily_reminders', value);
      
      setState(() {
        _dailyReminders = value;
      });
      
      if (value) {
        await _notificationService.scheduleDailyReminders(widget.nickname);
      } else {
        await _notificationService.cancelAllNotifications();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Daily reminders enabled' : 'Daily reminders disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling daily reminders: $e');
    }
  }

  Future<void> _toggleSmartScheduling(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.nickname}_smart_scheduling', value);
      
      setState(() {
        _smartScheduling = value;
      });
      
      if (value) {
        await _notificationService.scheduleSmartReminders(widget.nickname);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Smart scheduling enabled' : 'Smart scheduling disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling smart scheduling: $e');
    }
  }

  Future<void> _toggleReviewNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.nickname}_review_notifications', value);
      
      setState(() {
        _reviewNotifications = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Review notifications enabled' : 'Review notifications disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      print('Error toggling review notifications: $e');
    }
  }

  Future<void> _updateReviewFrequency(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${widget.nickname}_review_frequency', value);
      
      setState(() {
        _reviewFrequency = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review frequency updated to ${value.round()} days'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Error updating review frequency: $e');
    }
  }

  Future<void> _updateSessionDuration(double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('${widget.nickname}_session_duration', value);
      
      setState(() {
        _sessionDuration = value;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session duration updated to ${value.round()} minutes'),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      print('Error updating session duration: $e');
    }
  }

  void _exportProgressData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting progress data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _resetProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text('Are you sure you want to reset all progress? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress reset successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}