import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gamification_system.dart';
import 'notification_service.dart';
import 'mindfulness_exercises.dart';
import 'responsive_utils.dart';

/// Student Profile Page - Shows student information and stats
class StudentProfile extends StatefulWidget {
  final String nickname;

  const StudentProfile({
    super.key,
    required this.nickname,
  });

  @override
  State<StudentProfile> createState() => _StudentProfileState();
}

class _StudentProfileState extends State<StudentProfile> with TickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  
  late TabController _tabController;
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  
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
    _setupAnimations();
    _loadSettings();
  }

  void _setupAnimations() {
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _bounceController.forward();
    _pulseController.repeat(reverse: true);
    
    // Add a periodic refresh to ensure data is up-to-date
    _startPeriodicRefresh();
  }
  
  void _startPeriodicRefresh() {
    // Refresh data every 5 seconds to ensure real-time updates
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        print('DEBUG: Profile Screen - Periodic refresh triggered');
        setState(() {}); // Trigger rebuild to refresh StreamBuilders
        _startPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: ResponsiveText(
                    '🌟',
                    mobileFontSize: 24,
                    tabletFontSize: 26,
                    desktopFontSize: 28,
                    largeDesktopFontSize: 30,
                  ),
                );
              },
            ),
            ResponsiveSpacing(mobileSpacing: 8, isVertical: false),
            ResponsiveText(
              'My Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              mobileFontSize: 20,
              tabletFontSize: 22,
              desktopFontSize: 24,
              largeDesktopFontSize: 26,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobile: 12,
              tablet: 14,
              desktop: 16,
              largeDesktop: 18,
            ),
            fontWeight: FontWeight.bold,
          ),
          isScrollable: true,
          tabs: const [
            Tab(text: '👤 My Info', icon: Icon(Icons.person_outline)),
            Tab(text: '⚙️ Settings', icon: Icon(Icons.settings_outlined)),
            Tab(text: '🧘 Mindfulness', icon: Icon(Icons.spa)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildSettingsTab(),
          _buildMindfulnessTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('userStats')
          .doc(widget.nickname)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(
            child: Text('No student data found'),
          );
        }

        final userStatsData = snapshot.data!.data() as Map<String, dynamic>;
        print('DEBUG: Profile Screen - User stats data: ${userStatsData}');
        
        return SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              // Profile Header with Animation
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildProfileHeader(userStatsData),
                  );
                },
              ),
              
              ResponsiveSpacing(mobileSpacing: 20),
              
              // Fun Achievement Cards
              _buildAchievementCards(userStatsData),
              
              ResponsiveSpacing(mobileSpacing: 20),
              
              // Learning Progress
              _buildLearningProgress(userStatsData),
              
              ResponsiveSpacing(mobileSpacing: 20),
              
              // Fun Facts Section
              _buildFunFacts(userStatsData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Settings Header with Fun Design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981),
                  const Color(0xFF059669),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '⚙️',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'My Settings',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Make learning even more fun!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Fun Settings Cards
          _buildFunSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildFunSettingsCard() {
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
            '🔔 Notification Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildFunSwitchTile(
            'Daily Reminders',
            'Get fun reminders to learn!',
            '🔔',
            _dailyReminders,
            (value) => _toggleDailyReminders(value),
          ),
          const SizedBox(height: 16),
          _buildFunSwitchTile(
            'Smart Scheduling',
            'Learn at the best times for you!',
            '🧠',
            _smartScheduling,
            (value) => _toggleSmartScheduling(value),
          ),
          const SizedBox(height: 16),
          _buildFunSwitchTile(
            'Review Notifications',
            'Don\'t forget to review lessons!',
            '📚',
            _reviewNotifications,
            (value) => _toggleReviewNotifications(value),
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            '🎯 Learning Preferences',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          
          _buildFunSliderTile(
            'Review Frequency',
            'How often to review lessons',
            '📅',
            _reviewFrequency,
            1.0,
            7.0,
            (value) => _updateReviewFrequency(value),
          ),
          const SizedBox(height: 20),
          _buildFunSliderTile(
            'Session Duration',
            'How long to learn each time',
            '⏰',
            _sessionDuration,
            5.0,
            30.0,
            (value) => _updateSessionDuration(value),
          ),
        ],
      ),
    );
  }

  Widget _buildFunSwitchTile(String title, String subtitle, String emoji, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: value ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildFunSliderTile(String title, String subtitle, String emoji, double value, double min, double max, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            label: value.round().toString(),
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text('${value.round()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              Text('${max.round()}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userStatsData) {
    final totalXP = userStatsData['totalXP'] ?? 0;
    final level = userStatsData['currentLevel'] ?? 1;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF),
            const Color(0xFF9C88FF),
            const Color(0xFFB19CD9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animated Avatar
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.child_care,
                  color: Color(0xFF6C63FF),
                  size: 60,
                ),
              ),
              // Level Badge with Dynamic Color
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GamificationSystem.getLevelColor(level),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: GamificationSystem.getLevelColor(level).withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Name with Fun Typography
          Text(
            widget.nickname,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // XP Progress Bar
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _calculateXPProgress(totalXP, level),
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.yellow.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // XP Text with Level Title
          Column(
            children: [
              Text(
                '$totalXP XP • Level $level',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                GamificationSystem.getLevelTitle(level),
                style: TextStyle(
                  fontSize: 18,
                  color: GamificationSystem.getLevelColor(level),
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              Text(
                GamificationSystem.getLevelDescription(level),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          
          const SizedBox(height: 15),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: GamificationSystem.getLevelColor(level),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: GamificationSystem.getLevelColor(level).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getLevelIcon(level),
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  GamificationSystem.getLevelTitle(level).split(' ').skip(1).join(' ').toUpperCase() + '!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for XP progress calculation

  /// Get level icon based on level number
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

  double _calculateXPProgress(int totalXP, int level) {
    // Use the same level requirements as gamification system
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
    
    if (level >= levelRequirements.length) return 1.0;
    
    final currentLevelXP = levelRequirements[level] ?? 0;
    final nextLevel = level + 1;
    final nextLevelXP = levelRequirements[nextLevel] ?? (currentLevelXP + 500);
    final progressXP = totalXP - currentLevelXP;
    final requiredXP = nextLevelXP - currentLevelXP;
    
    return (progressXP / requiredXP).clamp(0.0, 1.0);
  }

  Widget _buildAchievementCards(Map<String, dynamic> userStatsData) {
    // Get additional data from students collection for fields not in userStats
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('nickname', isEqualTo: widget.nickname)
          .snapshots(),
      builder: (context, snapshot) {
        int lessonsCompleted = 0;
        int currentStreak = userStatsData['streakDays'] ?? 0;
        int longestStreak = 0;
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final studentData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          lessonsCompleted = studentData['totalLessonsCompleted'] ?? 0;
          longestStreak = studentData['longestStreak'] ?? 0;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🏆 My Achievements',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    '📚',
                    'Lessons',
                    '$lessonsCompleted',
                    'Completed',
                    const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    '🔥',
                    'Streak',
                    '$currentStreak',
                    'Days',
                    const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAchievementCard(
                    '⭐',
                    'Best Streak',
                    '$longestStreak',
                    'Days',
                    const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAchievementCard(
                    '🎯',
                    'Level',
                    '${userStatsData['currentLevel'] ?? 1}',
                    'Learner',
                    const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementCard(String emoji, String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgress(Map<String, dynamic> userStatsData) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessonRetention')
          .where('nickname', isEqualTo: widget.nickname)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, double> subjectProgress = {};
        
        if (snapshot.hasData) {
          // Calculate real progress for each subject
          final lessons = snapshot.data!.docs;
          print('DEBUG: Profile Screen - Found ${lessons.length} lesson retention records');
          final Map<String, List<Map<String, dynamic>>> subjectLessons = {};
          
          for (var doc in lessons) {
            final data = doc.data() as Map<String, dynamic>;
            final moduleName = data['moduleName'] ?? 'Unknown';
            print('DEBUG: Profile Screen - Lesson data: ${data}');
            
            if (!subjectLessons.containsKey(moduleName)) {
              subjectLessons[moduleName] = [];
            }
            subjectLessons[moduleName]!.add(data);
          }
          
          // Calculate progress for each subject
          subjectLessons.forEach((subject, lessons) {
            if (lessons.isNotEmpty) {
              final passedLessons = lessons.where((lesson) => lesson['passed'] == true).length;
              subjectProgress[subject] = (passedLessons / lessons.length).clamp(0.0, 1.0);
              print('DEBUG: Profile Screen - Subject $subject: $passedLessons/${lessons.length} passed (${subjectProgress[subject]})');
            }
          });
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
                '📈 Learning Progress',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 20),
              
              // Dynamic progress items based on real data
              if (subjectProgress.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Start learning to see your progress! 🌟',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...subjectProgress.entries.map((entry) {
                  final subject = entry.key;
                  final progress = entry.value;
                  
                  return Column(
                    children: [
                      _buildProgressItem(
                        _getSubjectEmoji(subject),
                        _getSubjectTitle(subject),
                        _getSubjectDescription(subject),
                        progress,
                        _getSubjectColor(subject),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  String _getSubjectEmoji(String subject) {
    if (subject.toLowerCase().contains('color') || subject.toLowerCase().contains('shape')) {
      return '🎨';
    } else if (subject.toLowerCase().contains('alphabet') || subject.toLowerCase().contains('letter')) {
      return '🔤';
    } else if (subject.toLowerCase().contains('number') || subject.toLowerCase().contains('count')) {
      return '🔢';
    } else if (subject.toLowerCase().contains('family')) {
      return '👨‍👩‍👧‍👦';
    } else if (subject.toLowerCase().contains('sound') || subject.toLowerCase().contains('speech')) {
      return '🎵';
    } else if (subject.toLowerCase().contains('word') || subject.toLowerCase().contains('formation')) {
      return '📝';
    } else if (subject.toLowerCase().contains('tracing')) {
      return '✏️';
    } else if (subject.toLowerCase().contains('categorization') || subject.toLowerCase().contains('belong')) {
      return '🗂️';
    } else {
      return '📚';
    }
  }

  String _getSubjectTitle(String subject) {
    if (subject.toLowerCase().contains('color') || subject.toLowerCase().contains('shape')) {
      return 'Colors & Shapes';
    } else if (subject.toLowerCase().contains('alphabet') || subject.toLowerCase().contains('letter')) {
      return 'Alphabet';
    } else if (subject.toLowerCase().contains('number') || subject.toLowerCase().contains('count')) {
      return 'Numbers';
    } else if (subject.toLowerCase().contains('family')) {
      return 'Family';
    } else if (subject.toLowerCase().contains('sound') || subject.toLowerCase().contains('speech')) {
      return 'Sounds & Speech';
    } else if (subject.toLowerCase().contains('word') || subject.toLowerCase().contains('formation')) {
      return 'Word Formation';
    } else if (subject.toLowerCase().contains('tracing')) {
      return 'Letter Tracing';
    } else if (subject.toLowerCase().contains('categorization') || subject.toLowerCase().contains('belong')) {
      return 'Categorization';
    } else {
      return subject;
    }
  }

  String _getSubjectDescription(String subject) {
    if (subject.toLowerCase().contains('color') || subject.toLowerCase().contains('shape')) {
      return 'Learn about colors and shapes';
    } else if (subject.toLowerCase().contains('alphabet') || subject.toLowerCase().contains('letter')) {
      return 'Master the ABCs';
    } else if (subject.toLowerCase().contains('number') || subject.toLowerCase().contains('count')) {
      return 'Count and calculate';
    } else if (subject.toLowerCase().contains('family')) {
      return 'Learn about family';
    } else if (subject.toLowerCase().contains('sound') || subject.toLowerCase().contains('speech')) {
      return 'Practice sounds and speech';
    } else if (subject.toLowerCase().contains('word') || subject.toLowerCase().contains('formation')) {
      return 'Form words from letters';
    } else if (subject.toLowerCase().contains('tracing')) {
      return 'Trace letters and shapes';
    } else if (subject.toLowerCase().contains('categorization') || subject.toLowerCase().contains('belong')) {
      return 'Sort and categorize items';
    } else {
      return 'Keep learning!';
    }
  }

  Color _getSubjectColor(String subject) {
    if (subject.toLowerCase().contains('color') || subject.toLowerCase().contains('shape')) {
      return const Color(0xFF8B5CF6);
    } else if (subject.toLowerCase().contains('alphabet') || subject.toLowerCase().contains('letter')) {
      return const Color(0xFF06B6D4);
    } else if (subject.toLowerCase().contains('number') || subject.toLowerCase().contains('count')) {
      return const Color(0xFF10B981);
    } else if (subject.toLowerCase().contains('family')) {
      return const Color(0xFFF59E0B);
    } else if (subject.toLowerCase().contains('sound') || subject.toLowerCase().contains('speech')) {
      return const Color(0xFFEF4444);
    } else if (subject.toLowerCase().contains('word') || subject.toLowerCase().contains('formation')) {
      return const Color(0xFF8B5CF6);
    } else if (subject.toLowerCase().contains('tracing')) {
      return const Color(0xFF06B6D4);
    } else if (subject.toLowerCase().contains('categorization') || subject.toLowerCase().contains('belong')) {
      return const Color(0xFF10B981);
    } else {
      return const Color(0xFF6C63FF);
    }
  }

  Widget _buildProgressItem(String emoji, String title, String subtitle, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          subtitle,
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
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFunFacts(Map<String, dynamic> userStatsData) {
    final totalXP = userStatsData['totalXP'] ?? 0;
    final currentStreak = userStatsData['streakDays'] ?? 0;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('nickname', isEqualTo: widget.nickname)
          .snapshots(),
      builder: (context, snapshot) {
        int lessonsCompleted = 0;
        
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final studentData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          lessonsCompleted = studentData['totalLessonsCompleted'] ?? 0;
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🌟 Fun Facts About Me',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              _buildFunFactItem(
                '🎯',
                'I\'ve earned $totalXP XP points!',
                'That\'s like collecting $totalXP stars!',
              ),
              const SizedBox(height: 16),
              _buildFunFactItem(
                '📚',
                'I\'ve completed $lessonsCompleted lessons!',
                'I\'m becoming super smart!',
              ),
              const SizedBox(height: 16),
              _buildFunFactItem(
                '🔥',
                'My current streak is $currentStreak days!',
                'I\'m on fire with learning!',
              ),
              const SizedBox(height: 16),
              _buildFunFactItem(
                '🏆',
                'I\'m a Level ${userStatsData['currentLevel'] ?? 1} learner!',
                'Keep going to reach the next level!',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunFactItem(String emoji, String title, String subtitle) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
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

  Widget _buildMindfulnessTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mindfulness Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEC4899),
                  const Color(0xFFDB2777),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '🧘',
                  style: TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mindfulness',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Relax, focus, and feel calm with guided exercises!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Mindfulness Exercises
          _buildFeatureCard(
            'Breathing Exercise',
            'Calm your mind with guided breathing',
            Icons.air,
            const Color(0xFFEC4899),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MindfulnessExerciseWidget(
                    nickname: widget.nickname,
                    exerciseType: 'breathing',
                    duration: 60,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            'Body Scan',
            'Relax your body from head to toe',
            Icons.accessibility,
            const Color(0xFFDB2777),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MindfulnessExerciseWidget(
                    nickname: widget.nickname,
                    exerciseType: 'body_scan',
                    duration: 300,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            'Gratitude Practice',
            'Practice being thankful and happy',
            Icons.favorite,
            const Color(0xFFBE185D),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MindfulnessExerciseWidget(
                    nickname: widget.nickname,
                    exerciseType: 'gratitude',
                    duration: 180,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            'Mindful Listening',
            'Focus on the sounds around you',
            Icons.hearing,
            const Color(0xFF9D174D),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MindfulnessExerciseWidget(
                    nickname: widget.nickname,
                    exerciseType: 'listening',
                    duration: 120,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            'Visualization',
            'Imagine a peaceful, beautiful place',
            Icons.visibility,
            const Color(0xFF831843),
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MindfulnessExerciseWidget(
                    nickname: widget.nickname,
                    exerciseType: 'visualization',
                    duration: 240,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
