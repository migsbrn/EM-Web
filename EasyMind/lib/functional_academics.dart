import 'package:flutter/material.dart';
import 'LearnTheAlphabets.dart';
import 'RhymeAndRead.dart';
import 'LearnColors.dart';
import 'LearnShapes.dart';
import 'LearnMyFamily.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FunctionalAcademicsPage extends StatefulWidget {
  final String nickname;

  const FunctionalAcademicsPage({super.key, required this.nickname});

  @override
  _FunctionalAcademicsPageState createState() =>
      _FunctionalAcademicsPageState();
}

class _FunctionalAcademicsPageState extends State<FunctionalAcademicsPage> {
  final FlutterTts flutterTts = FlutterTts();
  final bool _isDisposed = false;

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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
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
                      'assets/lrn_alphabets.png',  // use wide banners
                      LearnTheAlphabets(nickname: widget.nickname),
                      "alphabet",
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_read.png',
                      RhymeAndRead(nickname: widget.nickname),
                      "rhyme and read",
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_colors.png',
                      LearnColors(nickname: widget.nickname),
                      "colors",
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_shape.png',
                      LearnShapes(nickname: widget.nickname),
                      "shapes",
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_family.png',
                      LearnMyFamily(nickname: widget.nickname),
                      "my family",
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

  // FULL-WIDTH BANNER CARD IMAGE ONLY
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
          height: 120, // perfect banner height
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover, // 🔥 EXACTLY like your sample banner
          ),
        ),
      ),
    );
  }
}
