import 'package:flutter/material.dart';
import 'dart:async';
import 'gamification_system.dart';

/// Gamified Level Display Widget - Shows current level and XP progress
class GamifiedLevelWidget extends StatefulWidget {
  final String nickname;
  final VoidCallback? onLevelUp;

  const GamifiedLevelWidget({
    super.key,
    required this.nickname,
    this.onLevelUp,
  });

  @override
  State<GamifiedLevelWidget> createState() => _GamifiedLevelWidgetState();
}

class _GamifiedLevelWidgetState extends State<GamifiedLevelWidget>
    with TickerProviderStateMixin {
  final GamificationSystem _gamificationSystem = GamificationSystem();
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  UserGamificationStats? _userStats;
  LevelProgress? _levelProgress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserStats();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _loadUserStats() async {
    try {
      final stats = await _gamificationSystem.getUserStats(widget.nickname);
      final progress = _gamificationSystem.getLevelProgress(stats.totalXP);
      
      setState(() {
        _userStats = stats;
        _levelProgress = progress;
        _isLoading = false;
      });
      
      _progressController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    if (_isLoading) {
      return Container(
        height: isSmallScreen ? 80 : 100,
        margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF5DB2FF)),
        ),
      );
    }

    if (_userStats == null || _levelProgress == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getLevelColors(_levelProgress!.currentLevel).first.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildLevelDisplay(isSmallScreen),
          SizedBox(height: isSmallScreen ? 12 : 16),
          _buildXPProgress(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                decoration: BoxDecoration(
                  color: _getLevelColors(_levelProgress!.currentLevel).first.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _getLevelEmoji(_levelProgress!.currentLevel),
                  style: TextStyle(fontSize: isSmallScreen ? 24 : 32),
                ),
              ),
            );
          },
        ),
        SizedBox(width: isSmallScreen ? 10 : 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Level ${_levelProgress!.currentLevel} ${_getLevelTitle(_levelProgress!.currentLevel)}",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF22223B),
                ),
              ),
              SizedBox(height: isSmallScreen ? 3 : 5),
              Text(
                "${_userStats!.totalXP} Total XP • ${_userStats!.badgeCount} Badges",
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: const Color(0xFF4A4E69),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelDisplay(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getLevelColors(_levelProgress!.currentLevel).first.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Level", _levelProgress!.currentLevel.toString(), Icons.star, isSmallScreen),
          _buildStatItem("XP", _userStats!.totalXP.toString(), Icons.bolt, isSmallScreen),
          _buildStatItem("Badges", _userStats!.badgeCount.toString(), Icons.emoji_events, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isSmallScreen) {
    return Column(
      children: [
        Icon(
          icon, 
          color: _getLevelColors(_levelProgress!.currentLevel).first, 
          size: isSmallScreen ? 20 : 24
        ),
        SizedBox(height: isSmallScreen ? 3 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF22223B),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: const Color(0xFF4A4E69),
          ),
        ),
      ],
    );
  }

  Widget _buildXPProgress(bool isSmallScreen) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Progress to Level ${_levelProgress!.nextLevel}",
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4E69),
              ),
            ),
            Text(
              "${_levelProgress!.currentXP}/${_levelProgress!.requiredXP} XP",
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22223B),
              ),
            ),
          ],
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _levelProgress!.progressPercentage * _progressAnimation.value,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(_getLevelColors(_levelProgress!.currentLevel).first),
              minHeight: isSmallScreen ? 6 : 8,
            );
          },
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          "${(_levelProgress!.progressPercentage * 100).toStringAsFixed(0)}% Complete",
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: const Color(0xFF4A4E69),
          ),
        ),
      ],
    );
  }

  List<Color> _getLevelColors(int level) {
    if (level >= 8) return [const Color(0xFF5DB2FF), const Color(0xFF4A4E69)]; // Legendary
    if (level >= 6) return [const Color(0xFF3C7E71), const Color(0xFF5DB2FF)]; // Epic
    if (level >= 4) return [const Color(0xFF648BA2), const Color(0xFF4A4E69)]; // Rare
    return [const Color(0xFF5DB2FF), const Color(0xFF3C7E71)]; // Common
  }

  String _getLevelEmoji(int level) {
    if (level >= 10) return "👑";
    if (level >= 8) return "🌟";
    if (level >= 6) return "⭐";
    if (level >= 4) return "🎯";
    if (level >= 2) return "🌱";
    return "🌰";
  }

  String _getLevelTitle(int level) {
    if (level >= 10) return "Supreme Master";
    if (level >= 8) return "Legendary";
    if (level >= 6) return "Epic";
    if (level >= 4) return "Advanced";
    if (level >= 2) return "Growing";
    return "Beginner";
  }
}

/// Reward Animation Widget - Shows XP gains and level ups
class RewardAnimationWidget extends StatefulWidget {
  final GamificationResult result;
  final VoidCallback? onAnimationComplete;

  const RewardAnimationWidget({
    super.key,
    required this.result,
    this.onAnimationComplete,
  });

  @override
  State<RewardAnimationWidget> createState() => _RewardAnimationWidgetState();
}

class _RewardAnimationWidgetState extends State<RewardAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
  }

  void _startAnimation() async {
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _slideController, _fadeController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.result.leveledUp 
                      ? const Color(0xFF5DB2FF)
                      : const Color(0xFF3C7E71),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.result.leveledUp ? Icons.star : Icons.bolt,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.result.message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Badge Collection Widget - Shows earned badges
class BadgeCollectionWidget extends StatefulWidget {
  final String nickname;

  const BadgeCollectionWidget({
    super.key,
    required this.nickname,
  });

  @override
  State<BadgeCollectionWidget> createState() => _BadgeCollectionWidgetState();
}

class _BadgeCollectionWidgetState extends State<BadgeCollectionWidget> {
  final GamificationSystem _gamificationSystem = GamificationSystem();
  List<UserBadge> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await _gamificationSystem.getUserBadges(widget.nickname);
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              "No Badges Yet! 🏆",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Complete lessons to earn your first badge!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];
        return _buildBadgeCard(badge);
      },
    );
  }

  Widget _buildBadgeCard(UserBadge badge) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: _getBadgeColors(badge.badgeDefinition.rarity).first,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.badgeDefinition.icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            badge.badgeDefinition.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getBadgeColors(badge.badgeDefinition.rarity).first,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<Color> _getBadgeColors(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.legendary:
        return [const Color(0xFF5DB2FF), const Color(0xFF4A4E69)];
      case BadgeRarity.epic:
        return [const Color(0xFF3C7E71), const Color(0xFF5DB2FF)];
      case BadgeRarity.rare:
        return [const Color(0xFF648BA2), const Color(0xFF4A4E69)];
      case BadgeRarity.common:
        return [const Color(0xFF5DB2FF), const Color(0xFF3C7E71)];
    }
  }
}
