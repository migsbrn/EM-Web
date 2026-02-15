import 'package:flutter/material.dart';
import 'adaptive_assessment_system.dart';

/// Kid-friendly widget to display adaptive assessment information
class AdaptiveAssessmentWidget extends StatefulWidget {
  final String nickname;
  final String assessmentType;
  final VoidCallback? onLevelChanged;

  const AdaptiveAssessmentWidget({
    super.key,
    required this.nickname,
    required this.assessmentType,
    this.onLevelChanged,
  });

  @override
  State<AdaptiveAssessmentWidget> createState() => _AdaptiveAssessmentWidgetState();
}

class _AdaptiveAssessmentWidgetState extends State<AdaptiveAssessmentWidget>
    with TickerProviderStateMixin {
  String _currentLevel = 'beginner';
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  late AnimationController _levelController;
  late AnimationController _progressController;
  late Animation<double> _levelAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAdaptiveData();
  }

  void _initializeAnimations() {
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _levelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _levelController,
      curve: Curves.elasticOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadAdaptiveData() async {
    try {
      final level = await AdaptiveAssessmentSystem.getCurrentLevel(
        widget.nickname, 
        widget.assessmentType,
      );
      
      final stats = await AdaptiveAssessmentSystem.getUserAdaptiveStats(
        widget.nickname,
      );
      
      setState(() {
        _currentLevel = level;
        _stats = stats;
        _isLoading = false;
      });
      
      _levelController.forward();
      _progressController.forward();
    } catch (e) {
      print('Error loading adaptive data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _levelController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getLevelColors(_currentLevel),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: _getLevelColors(_currentLevel).first.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLevelDisplay(),
          const SizedBox(height: 20),
          _buildProgressInfo(),
          const SizedBox(height: 20),
          _buildEncouragementMessage(),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF6BCF7F),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              "Loading your learning level... 🎪",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _levelAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _levelAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  _getLevelIcon(_currentLevel),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLevelTitle(_currentLevel),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getLevelSubtitle(_currentLevel),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelDisplay() {
    return AnimatedBuilder(
      animation: _levelAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _levelAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Your Learning Level",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: AdaptiveAssessmentSystem.difficultyLevels.map((level) {
                    final isCurrentLevel = level == _currentLevel;
                    final isCompleted = _isLevelCompleted(level);
                    
                    return Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isCurrentLevel 
                                ? Colors.white 
                                : isCompleted 
                                    ? Colors.white.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getLevelEmoji(level),
                              style: TextStyle(
                                fontSize: 24,
                                color: isCurrentLevel 
                                    ? _getLevelColors(level).first
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getLevelShortName(level),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isCurrentLevel ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressInfo() {
    final averagePerformance = _stats['averagePerformance'] as double? ?? 0.0;
    final totalAssessments = _stats['totalAssessments'] as int? ?? 0;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                "Your Progress",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    "Games Played",
                    totalAssessments.toString(),
                    "🎮",
                  ),
                  _buildStatItem(
                    "Smart Score",
                    "${(averagePerformance * 100).toInt()}%",
                    "🧠",
                  ),
                  _buildStatItem(
                    "Improvement",
                    _getImprovementEmoji(_stats['improvementTrend'] as String? ?? 'stable'),
                    "📈",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progressAnimation.value * averagePerformance,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                "Keep learning to unlock new levels! 🌟",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildEncouragementMessage() {
    final averagePerformance = _stats['averagePerformance'] as double? ?? 0.0;
    final message = AdaptiveAssessmentSystem.getPerformanceFeedback(
      averagePerformance, 
      _currentLevel,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            "🌟 You're Amazing! 🌟",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getLevelColors(String level) {
    switch (level) {
      case 'beginner':
        return [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)]; // Green
      case 'intermediate':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]; // Teal
      case 'advanced':
        return [const Color(0xFF5DB2FF), const Color(0xFF3B82F6)]; // Blue
      case 'expert':
        return [const Color(0xFFFF6B6B), const Color(0xFFE53E3E)]; // Red
      default:
        return [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)];
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'beginner':
        return Icons.child_care;
      case 'intermediate':
        return Icons.school;
      case 'advanced':
        return Icons.star;
      case 'expert':
        return Icons.emoji_events;
      default:
        return Icons.child_care;
    }
  }

  String _getLevelTitle(String level) {
    switch (level) {
      case 'beginner':
        return "Learning Explorer! 🌱";
      case 'intermediate':
        return "Smart Learner! 🎓";
      case 'advanced':
        return "Super Star! ⭐";
      case 'expert':
        return "Genius Master! 👑";
      default:
        return "Learning Explorer! 🌱";
    }
  }

  String _getLevelSubtitle(String level) {
    switch (level) {
      case 'beginner':
        return "You're starting your amazing journey!";
      case 'intermediate':
        return "You're getting really good at this!";
      case 'advanced':
        return "You're becoming a learning champion!";
      case 'expert':
        return "You're a true learning master!";
      default:
        return "You're starting your amazing journey!";
    }
  }

  String _getLevelEmoji(String level) {
    switch (level) {
      case 'beginner':
        return "🌱";
      case 'intermediate':
        return "🎓";
      case 'advanced':
        return "⭐";
      case 'expert':
        return "👑";
      default:
        return "🌱";
    }
  }

  String _getLevelShortName(String level) {
    switch (level) {
      case 'beginner':
        return "Start";
      case 'intermediate':
        return "Good";
      case 'advanced':
        return "Great";
      case 'expert':
        return "Best";
      default:
        return "Start";
    }
  }

  bool _isLevelCompleted(String level) {
    final currentIndex = AdaptiveAssessmentSystem.difficultyLevels.indexOf(_currentLevel);
    final levelIndex = AdaptiveAssessmentSystem.difficultyLevels.indexOf(level);
    return levelIndex < currentIndex;
  }

  String _getImprovementEmoji(String trend) {
    switch (trend) {
      case 'improving':
        return "📈";
      case 'declining':
        return "📉";
      default:
        return "➡️";
    }
  }
}
