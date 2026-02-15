import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RhymeAssessment.dart';

class RhymeAndRead extends StatefulWidget {
  final String nickname;
  const RhymeAndRead({super.key, required this.nickname});

  @override
  _RhymeAndReadState createState() => _RhymeAndReadState();
}

class _RhymeAndReadState extends State<RhymeAndRead> {
  int currentIndex = 0;
  FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  final List<Map<String, String>> rhymes = [
    {
      "image": "assets/cat_mat.jpg",
      "word": "Cat – Mat",
      "sentence": "The cat sat on a mat",
    },
    {
      "image": "assets/hen_pen.jpg",
      "word": "Hen – Pen",
      "sentence": "The hen is in the pen",
    },
    {
      "image": "assets/hand_sand.jpg",
      "word": "Hand – Sand",
      "sentence": "A hand touches the sand.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _configureTts();
    _loadSavedIndex();
  }

  Future<void> _configureTts() async {
    // Configure TTS non-blocking setup and handlers
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.6); // Slower for kids
    await flutterTts.setPitch(1.3); // Higher pitch for kid-friendly voice
    await flutterTts.setVolume(1.0); // Full volume

    // Use start/completion handlers to track speaking state
    flutterTts.setStartHandler(() {
      if (mounted) setState(() => isSpeaking = true);
    });
    flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => isSpeaking = false);
    });
    flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => isSpeaking = false);
      print('TTS error: $msg');
    });

    // Try to set a kid-friendly voice (best-effort, non-fatal)
    try {
      await flutterTts.setVoice({
        "name": "en-us-x-tpf#female_1-local",
        "locale": "en-US",
      });
    } catch (e) {
      try {
        await flutterTts.setVoice({
          "name": "en-us-x-sfg#female_2-local",
          "locale": "en-US",
        });
      } catch (e) {
        // ignore - keep system default
      }
    }
  }

  Future<void> _loadSavedIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedIndex = prefs.getInt('rhymeCurrentIndex') ?? 0;
    setState(() {
      currentIndex = savedIndex;
    });
    _playRhymeSequence();
  }

  Future<void> _saveCurrentIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rhymeCurrentIndex', currentIndex);
  }

  void nextRhyme() async {
    // Stop any current speech first
    await flutterTts.stop();
    await Future.delayed(Duration(milliseconds: 200));
    
    if (currentIndex < rhymes.length - 1) {
      setState(() => currentIndex++);
      _saveCurrentIndex();
      _playRhymeSequence();
    } else {
      _showCompletionDialog();
    }
  }

  void previousRhyme() async {
    // Stop any current speech first
    await flutterTts.stop();
    await Future.delayed(Duration(milliseconds: 200));
    
    if (currentIndex > 0) {
      setState(() => currentIndex--);
      _saveCurrentIndex();
      _playRhymeSequence();
    }
  }

  Future<void> _speak(String text) async {
    try {
      // Always stop any current speech first
      await flutterTts.stop();
      
      // Wait a moment to ensure stop is processed
      await Future.delayed(Duration(milliseconds: 100));
      
      // Configure TTS settings for each speech
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.6);
      await flutterTts.setPitch(1.3);
      await flutterTts.setVolume(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      
      // Speak the text and wait for completion
      await flutterTts.speak(text);
      
      // Wait for speech to complete before returning
      await Future.delayed(Duration(milliseconds: 500));
      
    } catch (e) {
      print('TTS Error: $e');
      // Fallback: try with basic settings
      try {
        await flutterTts.stop();
        await Future.delayed(Duration(milliseconds: 100));
        await flutterTts.speak(text);
        await Future.delayed(Duration(milliseconds: 500));
      } catch (e2) {
        print('TTS Fallback Error: $e2');
      }
    }
  }

  Future<void> _playRhymeSequence() async {
    // Ensure any previous speech is completely stopped
    await flutterTts.stop();
    await Future.delayed(Duration(milliseconds: 300));
    
    String rhymeWord = rhymes[currentIndex]["word"]!;
    String sentence = rhymes[currentIndex]["sentence"]!;

    // Speak "The rhyme word is [rhymeWord]" once
    await _speak("The rhyme word is $rhymeWord");

    // Speak the rhyme word three times with short pauses
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      await _speak(rhymeWord);
    }

    // Prompt to repeat and then play the sentence
    await Future.delayed(const Duration(milliseconds: 700));
    await _speak("Can you repeat the rhyme word?");
    await Future.delayed(const Duration(milliseconds: 900));
    await _speak(sentence);
  }

  Future<void> _resetCurrentIndex() async {
    await flutterTts.stop();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('rhymeCurrentIndex', 0);
    setState(() {
      currentIndex = 0;
    });
  }

  void _showCompletionDialog() async {
    await flutterTts.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFFF6DC),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/star.png', height: 150, width: 150),
                  const SizedBox(height: 20),
                  const Text(
                    "What would you like to do next?",
                    style: TextStyle(
                      fontSize: 26,
                      color: Color(0xFF4C4F6B),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDialogButton(
                        label: "Restart Module",
                        color: const Color(0xFF4C4F6B),
                        onPressed: () async {
                          await flutterTts.stop();
                          await Future.delayed(Duration(milliseconds: 200));
                          await _resetCurrentIndex();
                          Navigator.pop(context);
                          _playRhymeSequence();
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDialogButton(
                        label: "Take Assessment",
                        color: const Color(0xFF3C7E71),
                        onPressed: () {
                          _resetCurrentIndex();
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RhymeAssessment(nickname: widget.nickname),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmall = screenWidth < 420;
    final bool isMedium = screenWidth >= 420 && screenWidth < 800;
    final double backH = isSmall ? 50 : 60;
    final double backW = isSmall ? 140 : 180;
  final double backFont = isSmall ? 20 : 25;
    final double imageSize = isSmall ? screenWidth * 0.7 : (isMedium ? screenWidth * 0.5 : screenWidth * 0.45);
    final double wordFont = isSmall ? 32 : (isMedium ? 40 : 45);
    final double sentenceFont = isSmall ? 18 : (isMedium ? 24 : 28);
    final double volIcon = isSmall ? 26 : 35;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: backH,
                    width: backW,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmall ? 12 : 15,
                          horizontal: isSmall ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: backFont,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Center the image and place navigation buttons below to avoid overflow
              Center(
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      rhymes[currentIndex]["image"]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous button
                  ElevatedButton(
                    onPressed: currentIndex > 0 ? previousRhyme : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentIndex > 0 ? const Color(0xFF648BA2) : Colors.grey.shade400,
                      minimumSize: Size(isSmall ? 110 : 150, isSmall ? 44 : 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Previous',
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  // Next button
                  ElevatedButton(
                    onPressed: nextRhyme,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C7E71),
                      minimumSize: Size(isSmall ? 110 : 150, isSmall ? 44 : 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: TextStyle(
                        fontSize: isSmall ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await flutterTts.stop();
                      await Future.delayed(const Duration(milliseconds: 200));
                      await _speak(rhymes[currentIndex]["word"]!);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FaIcon(
                        FontAwesomeIcons.volumeHigh,
                        size: volIcon,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    rhymes[currentIndex]["word"]!,
                    style: TextStyle(
                      fontSize: wordFont,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A4E69),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await flutterTts.stop();
                      await Future.delayed(const Duration(milliseconds: 200));
                      await _speak(rhymes[currentIndex]["sentence"]!);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: FaIcon(
                        FontAwesomeIcons.volumeHigh,
                        size: volIcon,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      rhymes[currentIndex]["sentence"]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: sentenceFont,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
