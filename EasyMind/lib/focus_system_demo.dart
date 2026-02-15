import 'package:flutter/material.dart';
// interactive_focus_widget removed - using inline or simplified UI to avoid dependency
import 'attention_focus_system.dart';
import 'responsive_utils.dart';

/// Demo page to showcase the Focus/Attention System
class FocusSystemDemo extends StatefulWidget {
  final String nickname;

  const FocusSystemDemo({
    super.key,
    required this.nickname,
  });

  @override
  State<FocusSystemDemo> createState() => _FocusSystemDemoState();
}

class _FocusSystemDemoState extends State<FocusSystemDemo> {
  final AttentionFocusSystem _focusSystem = AttentionFocusSystem();
  FocusStatus _currentStatus = FocusStatus.idle;
  Duration? _sessionDuration;
  Duration? _breakDuration;

  @override
  void initState() {
    super.initState();
    _initializeFocusSystem();
  }

  Future<void> _initializeFocusSystem() async {
    await _focusSystem.initialize();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      _currentStatus = _focusSystem.getCurrentStatus();
      _sessionDuration = _focusSystem.getSessionDuration();
      _breakDuration = _focusSystem.getBreakDuration();
    });
  }

  Future<void> _startSession() async {
    await _focusSystem.startFocusSession(
      nickname: widget.nickname,
      moduleName: "Focus Demo",
      lessonType: "System Test",
    );
    _updateStatus();
  }

  Future<void> _endSession() async {
    await _focusSystem.endFocusSession(
      nickname: widget.nickname,
      moduleName: "Focus Demo",
      lessonType: "System Test",
      completed: true,
    );
    _updateStatus();
  }

  Future<void> _endBreak() async {
    await _focusSystem.endBreak(widget.nickname);
    _updateStatus();
  }

  void _showBreakDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Take a short break?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Would you like to take a short break now or continue?',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Break time! Take a rest! 🎉'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Take Break', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Keep going! You\'re doing great! 💪'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: ResponsiveText(
          "Focus System Demo 🧠",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          mobileFontSize: 18,
          tabletFontSize: 20,
          desktopFontSize: 22,
          largeDesktopFontSize: 24,
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: ResponsiveUtils.getResponsivePadding(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ResponsiveIcon(
                    Icons.psychology,
                    color: Colors.white,
                    mobileSize: 40,
                    tabletSize: 44,
                    desktopSize: 48,
                    largeDesktopSize: 52,
                  ),
                  ResponsiveSpacing(mobileSpacing: 10),
                  ResponsiveText(
                    "Focus/Attention System",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    mobileFontSize: 20,
                    tabletFontSize: 22,
                    desktopFontSize: 24,
                    largeDesktopFontSize: 26,
                  ),
                  ResponsiveSpacing(mobileSpacing: 5),
                  ResponsiveText(
                    "Test the interactive focus features!",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    mobileFontSize: 14,
                    tabletFontSize: 16,
                    desktopFontSize: 18,
                    largeDesktopFontSize: 20,
                  ),
                ],
              ),
            ),

            ResponsiveSpacing(mobileSpacing: 30),

            // Interactive Focus Widget
            ResponsiveText(
              "🎯 Interactive Focus Widget",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "This widget shows focus progress, timers, and encouragement messages:",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 15),

            // Interactive focus widget removed; keep spacing for layout
            const SizedBox(height: 10),
            const SizedBox(height: 30),

            // Manual Controls
            const Text(
              "🎮 Manual Controls",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Test the focus system manually:",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStatus == FocusStatus.idle ? _startSession : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStatus == FocusStatus.focused ? _endSession : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('End Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _currentStatus == FocusStatus.onBreak ? _endBreak : null,
                    icon: const Icon(Icons.coffee),
                    label: const Text('End Break'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showBreakDialog,
                    icon: const Icon(Icons.timer),
                    label: const Text('Test Break'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Status Display
            const Text(
              "📊 Current Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
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
                  _buildStatusRow("Status", _getStatusText(_currentStatus)),
                  const SizedBox(height: 10),
                  if (_sessionDuration != null)
                    _buildStatusRow("Session Duration", _formatDuration(_sessionDuration!)),
                  if (_breakDuration != null)
                    _buildStatusRow("Break Duration", _formatDuration(_breakDuration!)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Features List
            const Text(
              "✨ Focus System Features",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
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
                  _buildFeatureItem("⏰ 15-minute focus sessions"),
                  _buildFeatureItem("🎯 Automatic break suggestions after 3 sessions"),
                  _buildFeatureItem("💬 Encouragement messages every 3 minutes"),
                  _buildFeatureItem("📊 Progress tracking and statistics"),
                  _buildFeatureItem("🎮 Interactive animations and timers"),
                  _buildFeatureItem("☕ Break reminder with countdown"),
                  _buildFeatureItem("📈 Focus analytics dashboard"),
                  _buildFeatureItem("🔊 Voice announcements (TTS)"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📋 How to Test:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "1. Tap 'Start Session' to begin a focus session\n"
                    "2. Watch the Interactive Focus Widget show progress\n"
                    "3. Wait for encouragement messages (every 3 minutes)\n"
                    "4. Complete 3 sessions to trigger break suggestion\n"
                    "5. Test the break reminder dialog\n"
                    "6. Check Focus Analytics Dashboard for statistics",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  String _getStatusText(FocusStatus status) {
    switch (status) {
      case FocusStatus.idle:
        return "Idle";
      case FocusStatus.focused:
        return "Focused";
      case FocusStatus.onBreak:
        return "On Break";
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${minutes}m ${seconds}s";
  }
}
