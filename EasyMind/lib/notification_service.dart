import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'memory_retention_system.dart';

/// Notification Service for Memory Retention Reminders
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Check if notifications are available
      final bool? isAvailable = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      
      if (isAvailable == false) {
        print('⚠️ Notifications not available on this device');
        return;
      }

      // Initialize timezone
      tz.initializeTimeZones();
      
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      
      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions
      await _requestPermissions();
      
      _isInitialized = true;
      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
      print('📱 App will continue without push notifications');
      _isInitialized = false;
      // Don't throw error - app should still work without notifications
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to review dashboard when notification is tapped
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule daily review reminders
  Future<void> scheduleDailyReminders(String nickname) async {
    try {
      // Check if service is initialized
      if (!_isInitialized) {
        print('⚠️ Notification service not initialized, skipping daily reminders');
        return;
      }
      
      // Cancel existing notifications
      await cancelAllNotifications();

      // Schedule morning reminder (9:00 AM)
      await _scheduleNotification(
        id: 1,
        title: "🌟 Time to Learn!",
        body: "Good morning! Ready for some fun learning? Let's review your lessons!",
        scheduledDate: _getNextScheduledTime(9, 0),
        payload: 'daily_review',
      );

      // Schedule afternoon reminder (3:00 PM)
      await _scheduleNotification(
        id: 2,
        title: "🎮 Learning Time!",
        body: "Afternoon learning session! You're doing amazing! 🌟",
        scheduledDate: _getNextScheduledTime(15, 0),
        payload: 'afternoon_review',
      );

      // Schedule evening reminder (7:00 PM)
      await _scheduleNotification(
        id: 3,
        title: "✨ Evening Practice!",
        body: "Let's end the day with some fun learning! You're so smart! 🎉",
        scheduledDate: _getNextScheduledTime(19, 0),
        payload: 'evening_review',
      );

      // Schedule weekly progress reminder (Sunday 10:00 AM)
      await _scheduleWeeklyProgressReminder();

      print('✅ Daily reminders scheduled successfully');
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
      // Fallback: Save reminder times to SharedPreferences for in-app reminders
      await _saveReminderTimes(nickname);
    }
  }

  /// Fallback: Save reminder times to SharedPreferences
  Future<void> _saveReminderTimes(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save next reminder times
      await prefs.setString('${nickname}_next_morning_reminder', 
          _getNextScheduledTime(9, 0).toIso8601String());
      await prefs.setString('${nickname}_next_afternoon_reminder', 
          _getNextScheduledTime(15, 0).toIso8601String());
      await prefs.setString('${nickname}_next_evening_reminder', 
          _getNextScheduledTime(19, 0).toIso8601String());
      
      print('📱 Reminder times saved for in-app notifications');
    } catch (e) {
      print('Error saving reminder times: $e');
    }
  }

  /// Schedule a specific notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'memory_retention',
          'Memory Retention Reminders',
          channelDescription: 'Notifications for lesson reviews and learning reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF648BA2),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Get next scheduled time for a given hour and minute
  DateTime _getNextScheduledTime(int hour, int minute) {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If the time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// Schedule weekly progress reminder
  Future<void> _scheduleWeeklyProgressReminder() async {
    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: (7 - now.weekday) % 7));
    final scheduledDate = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 10, 0);

    await _scheduleNotification(
      id: 4,
      title: "📊 Weekly Progress!",
      body: "Check out your amazing learning progress this week! You're becoming so smart! 🌟",
      scheduledDate: scheduledDate,
      payload: 'weekly_progress',
    );
  }

  /// Schedule lesson-specific review reminders
  Future<void> scheduleLessonReviewReminder(String nickname, String moduleName, String lessonType, DateTime reviewDate) async {
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _scheduleNotification(
        id: notificationId,
        title: "🎯 Review Time!",
        body: "Time to review $moduleName - $lessonType! You're doing great! 🌟",
        scheduledDate: reviewDate,
        payload: 'lesson_review_$moduleName',
      );
    } catch (e) {
      print('Error scheduling lesson review reminder: $e');
    }
  }

  /// Schedule smart reminders based on user patterns
  Future<void> scheduleSmartReminders(String nickname) async {
    try {
      // Check if service is initialized
      if (!_isInitialized) {
        print('⚠️ Notification service not initialized, skipping smart reminders');
        return;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final lastActiveTime = prefs.getString('${nickname}_last_active_time');
      
      if (lastActiveTime != null) {
        final lastActive = DateTime.parse(lastActiveTime);
        final hour = lastActive.hour;
        
        // Schedule reminders based on user's active hours
        List<int> reminderHours = [];
        
        if (hour >= 6 && hour <= 10) {
          // Morning learner
          reminderHours = [9, 15, 19];
        } else if (hour >= 11 && hour <= 15) {
          // Afternoon learner
          reminderHours = [12, 16, 20];
        } else if (hour >= 16 && hour <= 22) {
          // Evening learner
          reminderHours = [10, 18, 21];
        } else {
          // Default schedule
          reminderHours = [9, 15, 19];
        }
        
        // Cancel existing notifications
        await cancelAllNotifications();
        
        // Schedule personalized reminders
        for (int i = 0; i < reminderHours.length; i++) {
          await _scheduleNotification(
            id: i + 1,
            title: _getPersonalizedTitle(i),
            body: _getPersonalizedBody(i),
            scheduledDate: _getNextScheduledTime(reminderHours[i], 0),
            payload: 'smart_reminder_$i',
          );
        }
        
        print('Smart reminders scheduled for user: $nickname');
      }
    } catch (e) {
      print('Error scheduling smart reminders: $e');
    }
  }

  /// Get personalized notification title
  String _getPersonalizedTitle(int index) {
    final titles = [
      "🌟 Good Morning, Super Learner!",
      "🎮 Afternoon Learning Adventure!",
      "✨ Evening Learning Magic!",
    ];
    return titles[index % titles.length];
  }

  /// Get personalized notification body
  String _getPersonalizedBody(int index) {
    final bodies = [
      "Ready to start your learning journey? You're going to do amazing today! 🌟",
      "Time for some fun learning! You're becoming so smart! 🎉",
      "Let's end the day with some awesome learning! You're incredible! ✨",
    ];
    return bodies[index % bodies.length];
  }

  /// Update user's last active time
  Future<void> updateLastActiveTime(String nickname) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${nickname}_last_active_time', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error updating last active time: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      print('Error canceling notifications: $e');
      // Continue without throwing - this is not critical
    }
  }

  /// Show immediate notification for lessons due
  Future<void> showLessonsDueNotification(String nickname) async {
    try {
      final lessonsDue = await _retentionSystem.getLessonsDueForReview(nickname);
      
      if (lessonsDue.isNotEmpty) {
        await _notifications.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          "🎯 Lessons Ready for Review!",
          "You have ${lessonsDue.length} lesson${lessonsDue.length > 1 ? 's' : ''} ready for review! Let's keep learning! 🌟",
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lessons_due',
              'Lessons Due for Review',
              channelDescription: 'Notifications for lessons ready for review',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              color: const Color(0xFF648BA2),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: 'lessons_due',
        );
      }
    } catch (e) {
      print('Error showing lessons due notification: $e');
    }
  }
}
