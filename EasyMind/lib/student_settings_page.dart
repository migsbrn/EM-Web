import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Simple Settings Page for Students
class StudentSettingsPage extends StatefulWidget {
  final String nickname;
  
  const StudentSettingsPage({
    super.key,
    required this.nickname,
  });

  @override
  State<StudentSettingsPage> createState() => _StudentSettingsPageState();
}

class _StudentSettingsPageState extends State<StudentSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  
  bool _dailyReminders = true;
  bool _smartScheduling = true;
  bool _reviewNotifications = true;
  double _reviewFrequency = 3.0;
  double _sessionDuration = 15.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading settings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: const Text(
          '⚙️ My Settings',
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
                  // Welcome Message
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
                        Text(
                          'Hello, ${widget.nickname}! 👋',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Customize your learning experience! You can adjust notifications, review frequency, and more.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Notification Settings
                  _buildSettingsCard(
                    '🔔 Notifications',
                    'Control when and how you get learning reminders',
                    [
                      _buildSwitchTile(
                        'Daily Reminders',
                        'Get reminders at 9 AM, 3 PM, and 7 PM',
                        _dailyReminders,
                        (value) => _toggleDailyReminders(value),
                        Icons.notifications,
                        Colors.orange,
                      ),
                      _buildSwitchTile(
                        'Smart Scheduling',
                        'Reminders adapt to your learning patterns',
                        _smartScheduling,
                        (value) => _toggleSmartScheduling(value),
                        Icons.psychology,
                        Colors.purple,
                      ),
                      _buildSwitchTile(
                        'Review Notifications',
                        'Get notified when lessons need review',
                        _reviewNotifications,
                        (value) => _toggleReviewNotifications(value),
                        Icons.school,
                        Colors.green,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Learning Preferences
                  _buildSettingsCard(
                    '🎯 Learning Preferences',
                    'Adjust how often you want to review lessons',
                    [
                      _buildSliderTile(
                        'Review Frequency',
                        'How many days between reviews',
                        _reviewFrequency,
                        1.0,
                        7.0,
                        (value) => _updateReviewFrequency(value),
                        Icons.schedule,
                        Colors.blue,
                      ),
                      _buildSliderTile(
                        'Session Duration',
                        'How long each learning session should be',
                        _sessionDuration,
                        5.0,
                        30.0,
                        (value) => _updateSessionDuration(value),
                        Icons.timer,
                        Colors.teal,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Quick Actions
                  _buildQuickActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingsCard(String title, String subtitle, List<Widget> children) {
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
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(height: 2),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4E69),
                      ),
                    ),
                    const SizedBox(height: 2),
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
          const SizedBox(height: 15),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            activeColor: color,
            onChanged: onChanged,
          ),
          Center(
            child: Text(
              '${value.toInt()} ${title.toLowerCase().contains('duration') ? 'minutes' : 'days'}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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
                  onPressed: () => _resetToDefaults(),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Reset to Defaults',
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
                  onPressed: () => _testNotifications(),
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  label: const Text(
                    'Test Notifications',
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
  Future<void> _toggleDailyReminders(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.nickname}_daily_reminders', value);
      
      setState(() {
        _dailyReminders = value;
      });
      
      if (value) {
        await _notificationService.scheduleDailyReminders(widget.nickname);
        _showSnackBar('Daily reminders enabled! You\'ll get notifications at 9 AM, 3 PM, and 7 PM.', Colors.green);
      } else {
        await _notificationService.cancelAllNotifications();
        _showSnackBar('Daily reminders disabled.', Colors.orange);
      }
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
        _showSnackBar('Smart scheduling enabled! Reminders will adapt to your learning patterns.', Colors.green);
      } else {
        _showSnackBar('Smart scheduling disabled. Using default reminder times.', Colors.orange);
      }
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
      
      _showSnackBar(
        value ? 'Review notifications enabled!' : 'Review notifications disabled.',
        value ? Colors.green : Colors.orange,
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
      
      _showSnackBar('Review frequency set to ${value.toInt()} days.', Colors.blue);
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
      
      _showSnackBar('Session duration set to ${value.toInt()} minutes.', Colors.blue);
    } catch (e) {
      print('Error updating session duration: $e');
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('${widget.nickname}_daily_reminders', true);
      await prefs.setBool('${widget.nickname}_smart_scheduling', true);
      await prefs.setBool('${widget.nickname}_review_notifications', true);
      await prefs.setDouble('${widget.nickname}_review_frequency', 3.0);
      await prefs.setDouble('${widget.nickname}_session_duration', 15.0);
      
      setState(() {
        _dailyReminders = true;
        _smartScheduling = true;
        _reviewNotifications = true;
        _reviewFrequency = 3.0;
        _sessionDuration = 15.0;
      });
      
      await _notificationService.scheduleDailyReminders(widget.nickname);
      _showSnackBar('Settings reset to defaults!', Colors.green);
    } catch (e) {
      print('Error resetting settings: $e');
    }
  }

  Future<void> _testNotifications() async {
    try {
      await _notificationService.showLessonsDueNotification(widget.nickname);
      _showSnackBar('Test notification sent! Check your notifications.', Colors.blue);
    } catch (e) {
      // Fallback: Create a test reminder
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${widget.nickname}_next_morning_reminder', 
          DateTime.now().add(const Duration(seconds: 5)).toIso8601String());
      _showSnackBar('Test reminder scheduled! You\'ll see it in 5 seconds.', Colors.green);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
