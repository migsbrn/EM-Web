import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'TexttoSpeechAssessment.dart';

class LearningMaterialsPage extends StatefulWidget {
  final String nickname;
  const LearningMaterialsPage({super.key, required this.nickname});

  @override
  _LearningMaterialsPageState createState() => _LearningMaterialsPageState();
}

class _LearningMaterialsPageState extends State<LearningMaterialsPage> {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = "";

  // Lessons per category
  final Map<String, List<String>> lessons = {
    "Alphabet": [
      "A is for Apple",
      "B is for Ball",
      "C is for Cat",
      "D is for Dog",
    ],
    "Numbers": ["1 is One", "2 is Two", "3 is Three", "4 is Four"],
    "Colors": ["Red", "Blue", "Yellow", "Green"],
    "Shapes": ["Circle", "Square", "Triangle", "Rectangle"],
    "Animals": ["Dog", "Cat", "Elephant", "Lion"],
  };

  String selectedCategory = "Alphabet";
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _requestMicPermission();
  }

  /// Request microphone permission
  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  /// Speak lesson (TTS)
  Future _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  /// Start/Stop listening (STT)
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print("Status: $val"),
        onError: (val) => print("Error: $val"),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult:
              (val) => setState(() {
                _spokenText = val.recognizedWords;
              }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  /// Get current lesson text
  String get currentLesson => lessons[selectedCategory]![currentIndex];

  /// Get emoji for category
  String _getCategoryEmoji(String category) {
    switch (category) {
      case "Alphabet":
        return "🔤";
      case "Numbers":
        return "🔢";
      case "Colors":
        return "🎨";
      case "Shapes":
        return "🔷";
      case "Animals":
        return "🐾";
      default:
        return "📚";
    }
  }

  /// Show assessment dialog
  void _showAssessmentDialog() async {
    await _flutterTts.stop();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text("🎯", style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Ready for Assessment?",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("🎤", style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              "Test your speech recognition skills!",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                color: const Color(0xFF4A4E69),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "You'll listen to words and repeat them.",
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                color: const Color(0xFF7F8C8D),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Not Yet", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TexttoSpeechAssessment(nickname: widget.nickname),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Take Assessment",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0DC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
              // Go Back Button
              Align(
                alignment: Alignment.topLeft,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF648BA2),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Enhanced Title with emojis
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "🎤",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Text to Speech Learning",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "🗣️",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Enhanced Category Selector with emojis
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: lessons.keys.map((category) {
                    // Get emoji for each category
                    String categoryEmoji = _getCategoryEmoji(category);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = category;
                            currentIndex = 0;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedCategory == category
                              ? const Color(0xFF2A9D8F)
                              : const Color(0xFFB0BEC5),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: selectedCategory == category ? 6 : 2,
                          shadowColor: selectedCategory == category 
                              ? const Color(0xFF2A9D8F).withOpacity(0.4)
                              : Colors.grey.withOpacity(0.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              categoryEmoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              // Enhanced Lesson Card with better styling
              Container(
                height: MediaQuery.of(context).size.height * 0.28, // Slightly larger
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF2A9D8F).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Category indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCategoryEmoji(selectedCategory),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            selectedCategory,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2A9D8F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lesson text
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            currentLesson,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width < 400 ? 28 : 36,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: null,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    ),
                    // Progress indicator
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${currentIndex + 1}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A9D8F),
                          ),
                        ),
                        const Text(
                          " / ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                          ),
                        ),
                        Text(
                          "${lessons[selectedCategory]!.length}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2A9D8F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Enhanced Navigation Buttons with icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentIndex > 0
                        ? () {
                            setState(() {
                              currentIndex--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    label: const Text("Previous"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A9D8F),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF2A9D8F).withOpacity(0.4),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: currentIndex < lessons[selectedCategory]!.length - 1
                        ? () {
                            setState(() {
                              currentIndex++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    label: const Text("Next"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF0077B6).withOpacity(0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Enhanced Speech-to-Text Output with visual feedback
              Container(
                width: double.infinity,
                height: 100, // Slightly larger
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isListening 
                        ? [const Color(0xFFFFE0E0), const Color(0xFFFFF0F0)]
                        : [const Color(0xFFE8F5E8), const Color(0xFFF0F8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isListening 
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFF2A9D8F).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isListening 
                          ? Colors.red.withOpacity(0.2)
                          : const Color(0xFF2A9D8F).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.mic : Icons.mic_off,
                          color: _isListening ? Colors.red : const Color(0xFF2A9D8F),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isListening ? "Listening..." : "Ready to speak",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _isListening ? Colors.red : const Color(0xFF2A9D8F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Speech text
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _spokenText.isEmpty
                              ? "Your speech will appear here... 🎤"
                              : _spokenText,
                          style: TextStyle(
                            fontSize: 18,
                            color: _spokenText.isEmpty 
                                ? const Color(0xFF7F8C8D)
                                : const Color(0xFF2C3E50),
                            height: 1.3,
                            fontWeight: _spokenText.isEmpty ? FontWeight.normal : FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: null,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Enhanced Action Buttons with icons and animations
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _speak(currentLesson),
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: const Text("Listen Lesson"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                        shadowColor: const Color(0xFF0077B6).withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _listen,
                      icon: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                      label: Text(_isListening ? "Stop" : "Speak Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.redAccent
                            : const Color(0xFF2A9D8F),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                        shadowColor: (_isListening
                                ? Colors.redAccent
                                : const Color(0xFF2A9D8F))
                            .withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Assessment Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAssessmentDialog,
                  icon: const Icon(Icons.quiz, color: Colors.white),
                  label: const Text(
                    "Take Assessment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4C93),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: Colors.purple.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      )
    );
  }
}
