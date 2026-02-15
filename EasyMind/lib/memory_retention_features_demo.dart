import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'memory_retention_system.dart';
import 'review_dashboard.dart';
import 'app_initialization_service.dart';

/// Demo page showcasing all memory retention features
class MemoryRetentionFeaturesDemo extends StatefulWidget {
  final String nickname;
  
  const MemoryRetentionFeaturesDemo({
    super.key,
    required this.nickname,
  });

  @override
  State<MemoryRetentionFeaturesDemo> createState() => _MemoryRetentionFeaturesDemoState();
}

class _MemoryRetentionFeaturesDemoState extends State<MemoryRetentionFeaturesDemo> {
  final NotificationService _notificationService = NotificationService();
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  final AppInitializationService _initService = AppInitializationService();
  
  Map<String, dynamic> _learningPatterns = {};
  Map<String, dynamic> _analytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final results = await Future.wait([
        _retentionSystem.getUserLearningPatterns(widget.nickname),
        _retentionSystem.getRetentionAnalytics(widget.nickname),
      ]);
      
      setState(() {
        _learningPatterns = results[0] as Map<String, dynamic>;
        _analytics = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: const Text(
          '🧠 Memory Retention Features',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF648BA2)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF648BA2).withOpacity(0.1),
                          const Color(0xFF648BA2).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF648BA2).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Memory Retention System',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Advanced features to help students retain their lessons through spaced repetition, smart scheduling, and comprehensive analytics.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Feature Cards
                  _buildFeatureCard(
                    '🔔 Push Notifications',
                    'Daily reminders and smart scheduling',
                    'Schedule personalized reminders based on your learning patterns',
                    Icons.notifications,
                    Colors.orange,
                    () => _testNotifications(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildFeatureCard(
                    '📊 Review Dashboard',
                    'Comprehensive learning analytics',
                    'Track progress, view charts, and manage settings',
                    Icons.dashboard,
                    Colors.blue,
                    () => _openReviewDashboard(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildFeatureCard(
                    '🧠 Smart Scheduling',
                    'AI-powered optimal timing',
                    'Learn when you perform best',
                    Icons.schedule,
                    Colors.purple,
                    () => _showSmartScheduling(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildFeatureCard(
                    '📈 Retention Analytics',
                    'Detailed performance insights',
                    'Mastery levels, trends, and patterns',
                    Icons.analytics,
                    Colors.green,
                    () => _showAnalytics(),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Learning Patterns Summary
                  _buildLearningPatternsCard(),
                  
                  const SizedBox(height: 20),
                  
                  // Quick Actions
                  _buildQuickActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPatternsCard() {
    final preferredHours = _learningPatterns['preferredHours'] as List<int>? ?? [9, 15, 19];
    final bestPerformanceHour = _learningPatterns['bestPerformanceHour'] as int? ?? 10;
    final learningStreak = _learningPatterns['learningStreak'] as int? ?? 0;
    final totalSessions = _learningPatterns['totalSessions'] as int? ?? 0;
    
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
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigo.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.indigo.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Your Learning Patterns',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildPatternItem(
                  'Preferred Hours',
                  preferredHours.map((h) => '${h}:00').join(', '),
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPatternItem(
                  'Best Performance',
                  '${bestPerformanceHour}:00',
                  Icons.star,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildPatternItem(
                  'Learning Streak',
                  '$learningStreak days',
                  Icons.local_fire_department,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPatternItem(
                  'Total Sessions',
                  '$totalSessions',
                  Icons.school,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade100,
            Colors.teal.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: Colors.teal.shade700, size: 28),
              const SizedBox(width: 10),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _initService.initializeUser(widget.nickname),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh Data',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text(
                    'Export Data',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade500,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Action Methods
  void _testNotifications() async {
    await _notificationService.showLessonsDueNotification(widget.nickname);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent! Check your notifications.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openReviewDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDashboard(
          nickname: widget.nickname,
        ),
      ),
    );
  }

  void _showSmartScheduling() {
    final preferredHours = _learningPatterns['preferredHours'] as List<int>? ?? [9, 15, 19];
    final bestPerformanceHour = _learningPatterns['bestPerformanceHour'] as int? ?? 10;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧠 Smart Scheduling'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Based on your learning patterns:'),
            const SizedBox(height: 10),
            Text('• Preferred learning hours: ${preferredHours.map((h) => '${h}:00').join(', ')}'),
            Text('• Best performance hour: ${bestPerformanceHour}:00'),
            const SizedBox(height: 10),
            const Text('The system will schedule your reviews at these optimal times!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showAnalytics() {
    final retentionRate = _analytics['retentionRate'] as double? ?? 0.0;
    final totalSessions = _analytics['totalSessions'] as int? ?? 0;
    final masteredSessions = _analytics['masteredSessions'] as int? ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📈 Retention Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Retention Rate: ${retentionRate.toStringAsFixed(1)}%'),
            Text('• Total Sessions: $totalSessions'),
            Text('• Mastered Sessions: $masteredSessions'),
            const SizedBox(height: 10),
            const Text('View detailed charts in the Review Dashboard!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openReviewDashboard();
            },
            child: const Text('Open Dashboard'),
          ),
        ],
      ),
    );
  }
}
