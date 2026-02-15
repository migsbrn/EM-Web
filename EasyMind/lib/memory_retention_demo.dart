import 'package:flutter/material.dart';
import 'memory_retention_system.dart';
import 'unified_analytics_dashboard.dart';

/// Demo page to test and showcase the Memory Retention System
class MemoryRetentionDemo extends StatefulWidget {
  const MemoryRetentionDemo({super.key});

  @override
  State<MemoryRetentionDemo> createState() => _MemoryRetentionDemoState();
}

class _MemoryRetentionDemoState extends State<MemoryRetentionDemo> {
  final MemoryRetentionSystem _retentionSystem = MemoryRetentionSystem();
  final String _testNickname = "DemoStudent";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: const Text('🧠 Memory Retention Demo'),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    'Memory Retention System Demo',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'This demo shows how the memory retention system helps students remember their lessons better through spaced repetition.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4A4E69),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Demo Buttons
            _buildDemoSection(
              "📚 Test Lesson Completion",
              "Simulate completing different lessons to see how the system tracks progress",
              [
                _buildDemoButton(
                  "Complete Alphabet Assessment",
                  () => _simulateLessonCompletion("Functional Academics", "Alphabet Assessment", 4, 5),
                ),
                _buildDemoButton(
                  "Complete Colors Assessment", 
                  () => _simulateLessonCompletion("Functional Academics", "Colors Assessment", 3, 5),
                ),
                _buildDemoButton(
                  "Complete Shapes Assessment",
                  () => _simulateLessonCompletion("Functional Academics", "Shapes Assessment", 5, 5),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Removed Review Reminder Widget Section
            
            // Progress Dashboard Demo
            _buildDemoSection(
              "📊 Progress Dashboard",
              "View comprehensive learning statistics and progress charts",
              [
                _buildDemoButton(
                  "Open Progress Dashboard",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UnifiedAnalyticsDashboard(
                        nickname: _testNickname,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // How It Works
            _buildDemoSection(
              "ℹ️ How It Works",
              "Understanding the memory retention system",
              [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem("1️⃣", "Complete Assessment", "System saves your score and sets first review date"),
                      _buildInfoItem("2️⃣", "Spaced Repetition", "Review intervals: 1, 3, 7, 14, 30, 60, 120 days"),
                      _buildInfoItem("3️⃣", "Review Reminders", "System shows lessons due for review"),
                      _buildInfoItem("4️⃣", "Progress Tracking", "Track mastery levels and retention scores"),
                      _buildInfoItem("5️⃣", "Adaptive Learning", "System adjusts based on your performance"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection(String title, String description, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4E69),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4A4E69),
          ),
        ),
        const SizedBox(height: 15),
        ...children,
      ],
    );
  }

  Widget _buildDemoButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF648BA2),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4A4E69),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateLessonCompletion(String moduleName, String lessonType, int score, int totalQuestions) async {
    try {
      await _retentionSystem.saveLessonCompletion(
        nickname: _testNickname,
        moduleName: moduleName,
        lessonType: lessonType,
        score: score,
        totalQuestions: totalQuestions,
        passed: score >= totalQuestions / 2,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $lessonType completed! Score: $score/$totalQuestions'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'View Progress',
            textColor: Colors.white,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnifiedAnalyticsDashboard(
                  nickname: _testNickname,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
