import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gamification_system.dart';
import 'gamified_ui_components.dart';

/// Gamification Dashboard - Shows all gamified elements
class GamificationDashboard extends StatefulWidget {
  final String nickname;

  const GamificationDashboard({
    super.key,
    required this.nickname,
  });

  @override
  State<GamificationDashboard> createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard> {
  final GamificationSystem _gamificationSystem = GamificationSystem();
  
  UserGamificationStats? _userStats;
  List<UserBadge> _badges = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _gamificationSystem.getUserStats(widget.nickname);
      final badges = await _gamificationSystem.getUserBadges(widget.nickname);
      final leaderboard = await _gamificationSystem.getLeaderboard(limit: 5);
      
      setState(() {
        _userStats = stats;
        _badges = badges;
        _leaderboard = leaderboard;
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
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: const Text(
          "Game Center 🎮",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF5DB2FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userStats == null
              ? _buildEmptyState()
              : _buildDashboard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.games_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            "Welcome to Game Center! 🎮",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Start learning to unlock achievements! 🌟",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text("Go Back"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GamifiedLevelWidget(
            nickname: widget.nickname,
            onLevelUp: () {
              _loadData(); // Refresh data after level up
            },
          ),
          const SizedBox(height: 20),
          _buildStatsCards(),
          const SizedBox(height: 20),
          _buildBadgesSection(),
          const SizedBox(height: 20),
          _buildLeaderboardSection(),
          const SizedBox(height: 20),
          _buildAchievementsChart(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Total XP",
              _userStats!.totalXP.toString(),
              const Color(0xFF5DB2FF),
              Icons.bolt,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Badges",
              _userStats!.badgeCount.toString(),
              const Color(0xFF3C7E71),
              Icons.emoji_events,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              "Streak",
              "${_userStats!.streakDays} days",
              const Color(0xFF648BA2),
              Icons.local_fire_department,
            ),
          ),
        ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 2),
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
          Icon(
            icon,
            color: color,
            size: 32,
          ),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF4A4E69),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Badge Collection 🏆",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "${_badges.length} earned",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BadgeCollectionWidget(nickname: widget.nickname),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.leaderboard,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Top Players 🏆",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_leaderboard.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  "No leaderboard data yet!",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ..._leaderboard.map((entry) => _buildLeaderboardEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry) {
    final isCurrentUser = entry.nickname == widget.nickname;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.purple.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser ? Border.all(color: Colors.purple.shade200) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(entry.rank),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                entry.rank.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.nickname,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser ? Colors.purple.shade700 : Colors.black87,
                  ),
                ),
                Text(
                  "Level ${entry.level} • ${entry.totalXP} XP • ${entry.badgeCount} badges",
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

  Widget _buildAchievementsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Progress Overview 📊",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    color: Colors.blue.shade400,
                    value: _userStats!.totalXP.toDouble(),
                    title: "Total XP\n${_userStats!.totalXP}",
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.orange.shade400,
                    value: _userStats!.badgeCount.toDouble() * 50,
                    title: "Badges\n${_userStats!.badgeCount}",
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.green.shade400,
                    value: _userStats!.streakDays.toDouble() * 20,
                    title: "Streak\n${_userStats!.streakDays} days",
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

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade600; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.orange.shade600; // Bronze
      default:
        return Colors.blue.shade400;
    }
  }
}
