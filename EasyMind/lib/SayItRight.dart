import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:string_similarity/string_similarity.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';

class SayItRight extends StatefulWidget {
  final String targetWord;
  final String emoji;
  final String videoPath;

  const SayItRight({
    super.key,
    required this.targetWord,
    required this.emoji,
    required this.videoPath,
    required String nickname,
  });

  @override
  _SayItRightState createState() => _SayItRightState();
}

class _SayItRightState extends State<SayItRight> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  late VideoPlayerController _videoController;

  String recognizedWord = "";
  int accuracy = 0;
  String feedbackMessage = "";
  bool isListening = false;
  bool isCountingDown = false;
  bool _isVideoReady = false;
  bool isDialogOpen = false;
  bool _buttonPressed = false;

  final List<Map<String, String>> animals = [
    {"word": "dog", "emoji": "🐶", "video": "assets/videos/dog.mp4"},
    {"word": "cat", "emoji": "🐱", "video": "assets/videos/cat.mp4"},
    {"word": "bird", "emoji": "🐦", "video": "assets/videos/bird.mp4"},
    {"word": "horse", "emoji": "🐴", "video": "assets/videos/horse1.mp4"},
  ];

  int currentIndex = 0;
  late String targetWord;
  late String emoji;
  late String videoPath;

  @override
  void initState() {
    super.initState();
    targetWord = widget.targetWord;
    emoji = widget.emoji;
    videoPath = widget.videoPath;

    currentIndex = animals.indexWhere(
      (a) => a["word"] == targetWord.toLowerCase(),
    );

    _setupTTS();
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakWord());
  }

  void _setupTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1.1);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVoice({
      "name": "en-us-x-sfg#female",
      "locale": "en-US",
    });
  }

  void _initializeVideo() async {
    try {
      // Subukan muna i-load yung video. Kung hindi ma-load, magfa-fallback.
      bool assetExists = true;

      try {
        await DefaultAssetBundle.of(context).load(videoPath);
      } catch (_) {
        assetExists = false;
        debugPrint("⚠ Missing video: $videoPath — using fallback.");
      }

      // Gumamit ng fallback video na existing (dog.mp4)
      final safePath = assetExists ? videoPath : "assets/videos/dog.mp4";

      _videoController = VideoPlayerController.asset(safePath);

      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.play();

      if (mounted) setState(() => _isVideoReady = true);
    } catch (e) {
      debugPrint("❌ Error loading video: $e");
    }
  }

  void _speakWord() async {
    await flutterTts.speak("Can you say the word $targetWord?");
  }

  void _playFeedbackSound(int accuracy) async {
    await flutterTts.stop();
    if (accuracy >= 80) {
      await flutterTts.speak(
        "Great job! You pronounced the word correctly, but you could improve a little.",
      );
    } else if (accuracy >= 41) {
      await flutterTts.speak("Ding! Good try!");
    } else {
      await flutterTts.speak("Bzz! Try again!");
    }
  }

  Future<void> _showFeedbackDialog(
    String message,
    String emoji,
    Color color,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 70)),
                const SizedBox(height: 15),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A4C93),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Okay!",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCountdownDialog(
    BuildContext context,
    VoidCallback _startSpeechRecognition,
  ) async {
    int countdown = 3;

    await flutterTts.awaitSpeakCompletion(true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        final boxWidth = size.width > 600 ? 380.0 : 280.0;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(seconds: 1), () async {
              if (!context.mounted) return;
              setDialogState(() => countdown--);

              if (countdown == 2) {
                await flutterTts.speak("Ready?");
              } else if (countdown == 1) {
                await flutterTts.speak("Set...");
              } else if (countdown == 0) {
                await flutterTts.speak("Speak!");
              } else if (countdown < 0) {
                Navigator.pop(context);
                _startSpeechRecognition();
              }
            });

            String message;
            String emoji;
            Color boxColor;

            switch (countdown) {
              case 3:
              case 2:
                message = "🟢 READY?";
                emoji = "😀";
                boxColor = Colors.greenAccent.shade100;
                break;
              case 1:
                message = "🟡 SET...";
                emoji = "😯";
                boxColor = Colors.yellowAccent.shade100;
                break;
              default:
                message = "🔴 SPEAK!";
                emoji = "😃";
                boxColor = Colors.redAccent.shade100;
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: size.width * 0.15,
                vertical: size.height * 0.25,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 700),
                width: boxWidth,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 60)),
                    const SizedBox(height: 15),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _startListening() async {
    if (isListening || isDialogOpen || isCountingDown) return;

    setState(() {
      isCountingDown = true;
    });

    _showCountdownDialog(context, _startSpeechRecognition);
  }

  void _startSpeechRecognition() async {
    setState(() {
      isListening = true;
      recognizedWord = "";
      isCountingDown = false;
    });

    bool available = await speech.initialize();
    if (available) {
      speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            recognizedWord = result.recognizedWords.toLowerCase().trim();

            double similarity = targetWord.similarityTo(recognizedWord) * 100;
            double confidence = result.confidence * 100;

            int finalScore;
            finalScore =
                confidence > 0
                    ? ((similarity + confidence) / 2).round()
                    : similarity.round();

            setState(() {
              accuracy = finalScore.clamp(0, 100);
              isListening = false;
            });

            speech.stop();
            _playFeedbackSound(accuracy);
            _showAccuracyDialog();
          }
        },
        listenFor: const Duration(seconds: 3),
        pauseFor: const Duration(seconds: 2),
        localeId: "en_US",
      );
    } else {
      setState(() {
        isListening = false;
        isCountingDown = false;
      });
    }
  }

  void _showAccuracyDialog() {
    if (isDialogOpen) return;

    isDialogOpen = true;

    String feedbackMessage;
    if (accuracy >= 80) {
      feedbackMessage =
          "Great job! You pronounced the word correctly, but there’s a little room for improvement.";
    } else if (accuracy >= 41) {
      feedbackMessage =
          "Good effort! Try to articulate the sounds a bit more clearly.";
    } else {
      feedbackMessage =
          "Please try again. Speak slowly and clearly for better accuracy.";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFBEED9),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 500,
                  maxWidth: 400,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FontAwesomeIcons.microphone,
                        size: 50,
                        color: Color(0xFF4A4E69),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Your Score",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF22223B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 0,
                          end: accuracy.toDouble(),
                        ),
                        duration: const Duration(seconds: 1),
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: value / 100,
                                  strokeWidth: 10,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    value >= 80
                                        ? Colors.green
                                        : value >= 41
                                        ? Colors.orange
                                        : Colors.red,
                                  ),
                                  backgroundColor: Colors.grey.shade300,
                                ),
                              ),
                              Text(
                                "${value.toInt()}%",
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "You said: \"$recognizedWord\"",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: Text(
                          feedbackMessage,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  isDialogOpen = false;
                                  recognizedWord = "";
                                  accuracy = 0;
                                });
                                _speakWord();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5DB2FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.replay, size: 24),
                                  SizedBox(width: 8),
                                  Text("Retry"),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                isDialogOpen = false;
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF648BA2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: const Text("Back to Games"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Navigation with slide animation
  void _goToAnimal(int newIndex) {
    if (newIndex < 0 || newIndex >= animals.length) return;

    final isNext = newIndex > currentIndex;
    final beginOffset =
        isNext ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) => SayItRight(
              targetWord: animals[newIndex]["word"]!,
              emoji: animals[newIndex]["emoji"]!,
              videoPath: animals[newIndex]["video"]!,
              nickname: '',
            ),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: beginOffset,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF648BA2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "🎤 Say It Right!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF22223B),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // VIDEO DISPLAY
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8),
                ],
              ),
              child:
                  _isVideoReady
                      ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: VideoPlayer(_videoController),
                        ),
                      )
                      : const SizedBox(
                        height: 400,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4A4E69),
                          ),
                        ),
                      ),
            ),

            const SizedBox(height: 20),

            Text(
              "${targetWord.toUpperCase()} $emoji",
              style: const TextStyle(
                fontSize: 45,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 25),

            // NAV BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // PREVIOUS
                GestureDetector(
                  onTapDown: (_) {
                    if (currentIndex > 0) {
                      setState(() {
                        _buttonPressed = true;
                      });
                    }
                  },
                  onTapUp: (_) {
                    if (currentIndex > 0) {
                      setState(() {
                        _buttonPressed = false;
                      });
                      _goToAnimal(currentIndex - 1);
                    }
                  },
                  child: AnimatedScale(
                    scale: _buttonPressed ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: ElevatedButton.icon(
                      onPressed:
                          currentIndex > 0
                              ? () => _goToAnimal(currentIndex - 1)
                              : null,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 32,
                      ),
                      label: const Text(
                        "Previous",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentIndex > 0
                                ? const Color(0xFF648BA2)
                                : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                          horizontal: 40,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 30),

                // NEXT
                GestureDetector(
                  onTapDown: (_) {
                    if (currentIndex < animals.length - 1) {
                      setState(() {
                        _buttonPressed = true;
                      });
                    }
                  },
                  onTapUp: (_) {
                    if (currentIndex < animals.length - 1) {
                      setState(() {
                        _buttonPressed = false;
                      });
                      _goToAnimal(currentIndex + 1);
                    }
                  },
                  child: AnimatedScale(
                    scale: _buttonPressed ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    child: ElevatedButton.icon(
                      onPressed:
                          currentIndex < animals.length - 1
                              ? () => _goToAnimal(currentIndex + 1)
                              : null,
                      label: const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 32,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            currentIndex < animals.length - 1
                                ? const Color(0xFF648BA2)
                                : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(
                          vertical: 22,
                          horizontal: 40,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 35),

            // MIC BUTTON
            GestureDetector(
              onTap: isCountingDown ? null : _startListening,
              child: CircleAvatar(
                radius: 60,
                backgroundColor:
                    isListening || isCountingDown
                        ? Colors.red[300]
                        : const Color(0xFF4A4E69),
                child: const FaIcon(
                  FontAwesomeIcons.microphone,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              isCountingDown
                  ? "Get ready..."
                  : isListening
                  ? "Listening..."
                  : "Tap the mic to start 🎧",
              style: const TextStyle(fontSize: 25, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
