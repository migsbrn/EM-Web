import 'package:flutter/material.dart';
import 'shapes_activity_page.dart';
import 'daily_tasks_module.dart';
import 'package:flutter_tts/flutter_tts.dart';

class PreVocationalSkillsPage extends StatefulWidget {
  final String nickname;
  const PreVocationalSkillsPage({super.key, required this.nickname});

  @override
  _PreVocationalSkillsPageState createState() =>
      _PreVocationalSkillsPageState();
}

class _PreVocationalSkillsPageState extends State<PreVocationalSkillsPage> {
  final FlutterTts flutterTts = FlutterTts();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _setupTTS();
  }

  Future<void> _setupTTS() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
    } catch (e) {
      print("TTS setup error: $e");
    }
  }

  Future<void> _speakIntro(String module) async {
    if (_isDisposed) return;
    try {
      await flutterTts.stop();
      await flutterTts.speak("Let's learn the $module");
      await flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      print("TTS speak error: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Go Back Button
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 50,
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Let's Start Learning",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard(
                      context,
                      'assets/lrn_activity.png',
                      ShapesActivityPage(nickname: widget.nickname),
                      "shapes activity",
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_daily.png',
                      DailyTasksModulePage(nickname: widget.nickname),
                      "daily tasks",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    String imagePath,
    Widget destination,
    String moduleName,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () async {
          if (!_isDisposed) {
            try {
              await _speakIntro(moduleName);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            } catch (e) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => destination),
              );
            }
          }
        },
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
