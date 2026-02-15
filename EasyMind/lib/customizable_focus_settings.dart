import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attention_focus_system.dart';

/// Customizable Focus Settings System
class CustomizableFocusSettings {
  static final CustomizableFocusSettings _instance = CustomizableFocusSettings._internal();
  factory CustomizableFocusSettings() => _instance;
  CustomizableFocusSettings._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Default focus settings
  static const Map<String, dynamic> _defaultSettings = {
    'sessionDuration': 15, // minutes
    'breakDuration': 5, // minutes
    'maxConsecutiveSessions': 3,
    'encouragementInterval': 3, // minutes
    'focusMode': 'standard', // standard, intensive, relaxed
    'breakReminders': true,
    'soundEffects': true,
    'visualEffects': true,
    'adaptiveTiming': true,
    'personalizedEncouragement': true,
  };

  /// Get focus settings for a user
  Future<FocusSettings> getUserFocusSettings(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsKey = '${nickname}_focus_settings';
      
      // Try to get from SharedPreferences first
      final settingsJson = prefs.getString(settingsKey);
      if (settingsJson != null) {
        return FocusSettings.fromJson(settingsJson);
      }
      
      // Try to get from Firebase
      final doc = await _firestore.collection('userFocusSettings').doc(nickname).get();
      if (doc.exists) {
        final data = doc.data()!;
        final settings = FocusSettings.fromMap(data);
        await _saveSettingsToPrefs(nickname, settings);
        return settings;
      }
      
      // Return default settings
      final defaultSettings = FocusSettings.fromMap(_defaultSettings);
      await _saveSettingsToPrefs(nickname, defaultSettings);
      return defaultSettings;
    } catch (e) {
      print('Error getting focus settings: $e');
      return FocusSettings.fromMap(_defaultSettings);
    }
  }

  /// Update focus settings for a user
  Future<void> updateUserFocusSettings(String nickname, FocusSettings settings) async {
    try {
      // Save to SharedPreferences
      await _saveSettingsToPrefs(nickname, settings);
      
      // Save to Firebase
      await _firestore.collection('userFocusSettings').doc(nickname).set({
        'nickname': nickname,
        'settings': settings.toMap(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('Focus settings updated for $nickname');
    } catch (e) {
      print('Error updating focus settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettingsToPrefs(String nickname, FocusSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsKey = '${nickname}_focus_settings';
      await prefs.setString(settingsKey, settings.toJson());
    } catch (e) {
      print('Error saving settings to prefs: $e');
    }
  }

  /// Get session duration based on user preferences and performance
  Future<Duration> getSessionDuration(String nickname) async {
    try {
      final settings = await getUserFocusSettings(nickname);
      final focusSystem = AttentionFocusSystem();
      final stats = await focusSystem.getUserFocusStats(nickname);
      
      Duration baseDuration = Duration(minutes: settings.sessionDuration);
      
      // Adaptive timing based on performance
      if (settings.adaptiveTiming) {
        if (stats.focusScore >= 80) {
          // High performer - can handle longer sessions
          baseDuration = Duration(minutes: settings.sessionDuration + 5);
        } else if (stats.focusScore < 50) {
          // Low performer - shorter sessions
          baseDuration = Duration(minutes: settings.sessionDuration - 5);
        }
      }
      
      // Adjust based on focus mode
      switch (settings.focusMode) {
        case 'intensive':
          baseDuration = Duration(minutes: settings.sessionDuration + 10);
          break;
        case 'relaxed':
          baseDuration = Duration(minutes: settings.sessionDuration - 5);
          break;
        case 'standard':
        default:
          break;
      }
      
      // Ensure minimum duration
      if (baseDuration.inMinutes < 5) {
        baseDuration = const Duration(minutes: 5);
      }
      
      return baseDuration;
    } catch (e) {
      print('Error getting session duration: $e');
      return const Duration(minutes: 15);
    }
  }

  /// Get break duration based on user preferences
  Future<Duration> getBreakDuration(String nickname) async {
    try {
      final settings = await getUserFocusSettings(nickname);
      
      Duration baseDuration = Duration(minutes: settings.breakDuration);
      
      // Adjust based on focus mode
      switch (settings.focusMode) {
        case 'intensive':
          baseDuration = Duration(minutes: settings.breakDuration - 2);
          break;
        case 'relaxed':
          baseDuration = Duration(minutes: settings.breakDuration + 3);
          break;
        case 'standard':
        default:
          break;
      }
      
      // Ensure minimum duration
      if (baseDuration.inMinutes < 1) {
        baseDuration = const Duration(minutes: 1);
      }
      
      return baseDuration;
    } catch (e) {
      print('Error getting break duration: $e');
      return const Duration(minutes: 5);
    }
  }

  /// Get encouragement interval based on user preferences
  Future<Duration> getEncouragementInterval(String nickname) async {
    try {
      final settings = await getUserFocusSettings(nickname);
      return Duration(minutes: settings.encouragementInterval);
    } catch (e) {
      print('Error getting encouragement interval: $e');
      return const Duration(minutes: 3);
    }
  }

  /// Get personalized encouragement message
  Future<String> getPersonalizedEncouragement(String nickname) async {
    try {
      final settings = await getUserFocusSettings(nickname);
      
      if (!settings.personalizedEncouragement) {
        return _getRandomEncouragement();
      }
      
      // Get user's learning patterns
      final focusSystem = AttentionFocusSystem();
      final stats = await focusSystem.getUserFocusStats(nickname);
      
      // Personalized messages based on performance
      if (stats.focusScore >= 80) {
        return "You're a focus champion! 🌟 Keep up the amazing work!";
      } else if (stats.focusScore >= 60) {
        return "You're doing great! 💪 Your focus is getting stronger!";
      } else if (stats.focusScore >= 40) {
        return "Keep practicing! 🌱 You're improving every day!";
      } else {
        return "Don't give up! 💙 Every step forward counts!";
      }
    } catch (e) {
      print('Error getting personalized encouragement: $e');
      return _getRandomEncouragement();
    }
  }

  String _getRandomEncouragement() {
    final encouragements = [
      "You're doing amazing! 🌟",
      "Keep up the great work! 💪",
      "You're learning so well! 🎉",
      "Fantastic progress! ⭐",
      "You're unstoppable! 🚀",
      "Brilliant work! 🌈",
      "You're a superstar! 🏆",
      "Keep going! You're awesome! 💫",
    ];
    return encouragements[DateTime.now().millisecond % encouragements.length];
  }

  /// Reset settings to default
  Future<void> resetToDefault(String nickname) async {
    try {
      final defaultSettings = FocusSettings.fromMap(_defaultSettings);
      await updateUserFocusSettings(nickname, defaultSettings);
    } catch (e) {
      print('Error resetting settings: $e');
    }
  }
}

/// Focus Settings data model
class FocusSettings {
  final int sessionDuration;
  final int breakDuration;
  final int maxConsecutiveSessions;
  final int encouragementInterval;
  final String focusMode;
  final bool breakReminders;
  final bool soundEffects;
  final bool visualEffects;
  final bool adaptiveTiming;
  final bool personalizedEncouragement;

  FocusSettings({
    required this.sessionDuration,
    required this.breakDuration,
    required this.maxConsecutiveSessions,
    required this.encouragementInterval,
    required this.focusMode,
    required this.breakReminders,
    required this.soundEffects,
    required this.visualEffects,
    required this.adaptiveTiming,
    required this.personalizedEncouragement,
  });

  factory FocusSettings.fromMap(Map<String, dynamic> map) {
    return FocusSettings(
      sessionDuration: map['sessionDuration'] ?? 15,
      breakDuration: map['breakDuration'] ?? 5,
      maxConsecutiveSessions: map['maxConsecutiveSessions'] ?? 3,
      encouragementInterval: map['encouragementInterval'] ?? 3,
      focusMode: map['focusMode'] ?? 'standard',
      breakReminders: map['breakReminders'] ?? true,
      soundEffects: map['soundEffects'] ?? true,
      visualEffects: map['visualEffects'] ?? true,
      adaptiveTiming: map['adaptiveTiming'] ?? true,
      personalizedEncouragement: map['personalizedEncouragement'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionDuration': sessionDuration,
      'breakDuration': breakDuration,
      'maxConsecutiveSessions': maxConsecutiveSessions,
      'encouragementInterval': encouragementInterval,
      'focusMode': focusMode,
      'breakReminders': breakReminders,
      'soundEffects': soundEffects,
      'visualEffects': visualEffects,
      'adaptiveTiming': adaptiveTiming,
      'personalizedEncouragement': personalizedEncouragement,
    };
  }

  String toJson() {
    return '${sessionDuration}|${breakDuration}|${maxConsecutiveSessions}|${encouragementInterval}|${focusMode}|${breakReminders}|${soundEffects}|${visualEffects}|${adaptiveTiming}|${personalizedEncouragement}';
  }

  factory FocusSettings.fromJson(String json) {
    final parts = json.split('|');
    return FocusSettings(
      sessionDuration: int.parse(parts[0]),
      breakDuration: int.parse(parts[1]),
      maxConsecutiveSessions: int.parse(parts[2]),
      encouragementInterval: int.parse(parts[3]),
      focusMode: parts[4],
      breakReminders: parts[5] == 'true',
      soundEffects: parts[6] == 'true',
      visualEffects: parts[7] == 'true',
      adaptiveTiming: parts[8] == 'true',
      personalizedEncouragement: parts[9] == 'true',
    );
  }

  FocusSettings copyWith({
    int? sessionDuration,
    int? breakDuration,
    int? maxConsecutiveSessions,
    int? encouragementInterval,
    String? focusMode,
    bool? breakReminders,
    bool? soundEffects,
    bool? visualEffects,
    bool? adaptiveTiming,
    bool? personalizedEncouragement,
  }) {
    return FocusSettings(
      sessionDuration: sessionDuration ?? this.sessionDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      maxConsecutiveSessions: maxConsecutiveSessions ?? this.maxConsecutiveSessions,
      encouragementInterval: encouragementInterval ?? this.encouragementInterval,
      focusMode: focusMode ?? this.focusMode,
      breakReminders: breakReminders ?? this.breakReminders,
      soundEffects: soundEffects ?? this.soundEffects,
      visualEffects: visualEffects ?? this.visualEffects,
      adaptiveTiming: adaptiveTiming ?? this.adaptiveTiming,
      personalizedEncouragement: personalizedEncouragement ?? this.personalizedEncouragement,
    );
  }
}

/// Focus Settings UI Widget
class FocusSettingsWidget extends StatefulWidget {
  final String nickname;
  final Function(FocusSettings)? onSettingsChanged;
  
  const FocusSettingsWidget({
    super.key,
    required this.nickname,
    this.onSettingsChanged,
  });

  @override
  State<FocusSettingsWidget> createState() => _FocusSettingsWidgetState();
}

class _FocusSettingsWidgetState extends State<FocusSettingsWidget> {
  final CustomizableFocusSettings _settingsManager = CustomizableFocusSettings();
  FocusSettings _currentSettings = FocusSettings.fromMap({});
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsManager.getUserFocusSettings(widget.nickname);
      setState(() {
        _currentSettings = settings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings(FocusSettings newSettings) async {
    try {
      await _settingsManager.updateUserFocusSettings(widget.nickname, newSettings);
      setState(() {
        _currentSettings = newSettings;
      });
      widget.onSettingsChanged?.call(newSettings);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Focus settings updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
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
                  const Color(0xFF648BA2),
                  const Color(0xFF648BA2).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.tune,
                  size: 40,
                  color: Colors.white,
                ),
                SizedBox(height: 10),
                Text(
                  'Focus Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Customize your learning experience',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Session Duration
          _buildSliderSetting(
            'Session Duration',
            'How long each focus session lasts',
            Icons.timer,
            _currentSettings.sessionDuration.toDouble(),
            5.0,
            30.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              sessionDuration: value.round(),
            )),
          ),
          
          const SizedBox(height: 20),
          
          // Break Duration
          _buildSliderSetting(
            'Break Duration',
            'How long breaks between sessions last',
            Icons.coffee,
            _currentSettings.breakDuration.toDouble(),
            1.0,
            15.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              breakDuration: value.round(),
            )),
          ),
          
          const SizedBox(height: 20),
          
          // Focus Mode
          _buildDropdownSetting(
            'Focus Mode',
            'Choose your learning intensity',
            Icons.speed,
            _currentSettings.focusMode,
            ['standard', 'intensive', 'relaxed'],
            (value) => _updateSettings(_currentSettings.copyWith(
              focusMode: value,
            )),
          ),
          
          const SizedBox(height: 20),
          
          // Encouragement Interval
          _buildSliderSetting(
            'Encouragement Interval',
            'How often to show encouragement messages',
            Icons.favorite,
            _currentSettings.encouragementInterval.toDouble(),
            1.0,
            10.0,
            (value) => _updateSettings(_currentSettings.copyWith(
              encouragementInterval: value.round(),
            )),
          ),
          
          const SizedBox(height: 20),
          
          // Toggle Settings
          _buildToggleSetting(
            'Break Reminders',
            'Get reminded to take breaks',
            Icons.notifications,
            _currentSettings.breakReminders,
            (value) => _updateSettings(_currentSettings.copyWith(
              breakReminders: value,
            )),
          ),
          
          const SizedBox(height: 15),
          
          _buildToggleSetting(
            'Sound Effects',
            'Play sounds during learning',
            Icons.volume_up,
            _currentSettings.soundEffects,
            (value) => _updateSettings(_currentSettings.copyWith(
              soundEffects: value,
            )),
          ),
          
          const SizedBox(height: 15),
          
          _buildToggleSetting(
            'Visual Effects',
            'Show animations and effects',
            Icons.visibility,
            _currentSettings.visualEffects,
            (value) => _updateSettings(_currentSettings.copyWith(
              visualEffects: value,
            )),
          ),
          
          const SizedBox(height: 15),
          
          _buildToggleSetting(
            'Adaptive Timing',
            'Automatically adjust timing based on performance',
            Icons.auto_awesome,
            _currentSettings.adaptiveTiming,
            (value) => _updateSettings(_currentSettings.copyWith(
              adaptiveTiming: value,
            )),
          ),
          
          const SizedBox(height: 15),
          
          _buildToggleSetting(
            'Personalized Encouragement',
            'Get customized encouragement messages',
            Icons.person,
            _currentSettings.personalizedEncouragement,
            (value) => _updateSettings(_currentSettings.copyWith(
              personalizedEncouragement: value,
            )),
          ),
          
          const SizedBox(height: 30),
          
          // Reset Button
          Center(
            child: ElevatedButton.icon(
              onPressed: () async {
                await _settingsManager.resetToDefault(widget.nickname);
                await _loadSettings();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    IconData icon,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                icon,
                color: const Color(0xFF648BA2),
                size: 24,
              ),
              const SizedBox(width: 12),
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
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()} min',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF648BA2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
            activeColor: const Color(0xFF648BA2),
            inactiveColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                icon,
                color: const Color(0xFF648BA2),
                size: 24,
              ),
              const SizedBox(width: 12),
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
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: value,
            onChanged: (newValue) => onChanged(newValue!),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
            ),
            items: options.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF648BA2),
            size: 24,
          ),
          const SizedBox(width: 12),
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
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF648BA2),
          ),
        ],
      ),
    );
  }
}
