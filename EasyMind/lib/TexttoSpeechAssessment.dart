import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'TexttoSpeech.dart';

class TexttoSpeechAssessment extends StatefulWidget {
  final String nickname;
  const TexttoSpeechAssessment({super.key, required this.nickname});

  @override
  _TexttoSpeechAssessmentState createState() => _TexttoSpeechAssessmentState();
}

class _TexttoSpeechAssessmentState extends State<TexttoSpeechAssessment>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _spokenText = "";
  bool _isSpeaking = false;
  bool _questionRead = false;
  bool _isOptionDisabled = false;
  
  // Timeout handling
  Timer? _timeoutTimer;
  
  // Retry limit handling
  int _failedAttempts = 0;
  static const int _maxFailedAttempts = 5;
  
  // Assessment data
  int _currentQuestion = 0;
  int _score = 0;
  final List<Map<String, String>> _reflection = [];
  
  // Animation controllers
  late AnimationController _shakeController;
  late ConfettiController _confettiController;
  
  // Assessment questions
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Listen carefully and repeat the word:',
      'targetWord': 'Apple',
      'category': 'Alphabet',
      'instruction': 'Say "Apple"'
    },
    {
      'question': 'Listen carefully and repeat the word:',
      'targetWord': 'Ball',
      'category': 'Alphabet', 
      'instruction': 'Say "Ball"'
    },
    {
      'question': 'Listen carefully and repeat the word:',
      'targetWord': 'Cat',
      'category': 'Alphabet',
      'instruction': 'Say "Cat"'
    },
    {
      'question': 'Listen carefully and repeat the word:',
      'targetWord': 'Dog',
      'category': 'Alphabet',
      'instruction': 'Say "Dog"'
    },
    {
      'question': 'Listen carefully and repeat the number:',
      'targetWord': 'One',
      'category': 'Numbers',
      'instruction': 'Say "One"'
    },
    {
      'question': 'Listen carefully and repeat the number:',
      'targetWord': 'Two',
      'category': 'Numbers',
      'instruction': 'Say "Two"'
    },
    {
      'question': 'Listen carefully and repeat the color:',
      'targetWord': 'Red',
      'category': 'Colors',
      'instruction': 'Say "Red"'
    },
    {
      'question': 'Listen carefully and repeat the color:',
      'targetWord': 'Blue',
      'category': 'Colors',
      'instruction': 'Say "Blue"'
    },
    {
      'question': 'Listen carefully and repeat the shape:',
      'targetWord': 'Circle',
      'category': 'Shapes',
      'instruction': 'Say "Circle"'
    },
    {
      'question': 'Listen carefully and repeat the animal:',
      'targetWord': 'Dog',
      'category': 'Animals',
      'instruction': 'Say "Dog"'
    },
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _requestMicPermission();
    _configureTts();
    _speakQuestion();
    
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _flutterTts.stop();
    _speech.stop();
    _shakeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// Request microphone permission
  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  /// Configure TTS settings
  Future<void> _configureTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  /// Speak the current question
  Future<void> _speakQuestion() async {
    if (_isSpeaking) return;
    
    setState(() {
      _isSpeaking = true;
      _questionRead = false;
    });

    final question = _questions[_currentQuestion];
    await _flutterTts.stop();
    await _flutterTts.speak(question['instruction']);
    
    await Future.delayed(const Duration(milliseconds: 1000));
    await _flutterTts.speak(question['targetWord']);
    
    setState(() {
      _isSpeaking = false;
      _questionRead = true;
    });
  }

  /// Start/Stop listening (STT) with timeout handling
  void _listen() async {
    if (!_isListening) {
      await _startListening();
    } else {
      await _stopListening();
    }
  }

  /// Start listening with robust timeout handling
  Future<void> _startListening() async {
    print('Starting speech recognition...');
    
    try {
      // Cancel any existing timeout timer
      _timeoutTimer?.cancel();
      
      // Force stop and reset speech recognition completely
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check permissions
      PermissionStatus status = await Permission.microphone.status;
      if (status.isDenied) {
        status = await Permission.microphone.request();
      }
      
      if (!status.isGranted) {
        await _speak("Microphone permission is required for speech recognition.");
        return;
      }

      // Re-initialize speech recognition with patient timeout handling
      bool available = await _speech.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          print('Error type: ${error.errorMsg}');
          
          // Don't immediately stop on timeout or no match - be more patient
          if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
            print('Speech ${error.errorMsg} detected - but continuing to listen patiently');
            // Don't stop listening immediately, let the timer handle it
            return;
          }
          
          setState(() {
            _isListening = false;
          });
          
          _showErrorDialog("Speech recognition error: ${error.errorMsg}");
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
      );

      if (available) {
        print('Speech recognition available, starting to listen...');
        
        setState(() {
          _isListening = true;
          _spokenText = "";
        });
        
        // Wait a moment before starting to listen
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Start listening with longer periods for students
        await _speech.listen(
          onResult: (result) {
            print('Speech result: "${result.recognizedWords}"');
            setState(() {
              _spokenText = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 20), // Longer listening time for students
          pauseFor: const Duration(seconds: 5),  // Longer pause
          localeId: "en_US",
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        );
        
        print('Speech recognition started successfully');
        
        // Set a timeout to automatically retry if no result
        _timeoutTimer = Timer(const Duration(seconds: 25), () {
          if (_isListening && _spokenText.isEmpty) {
            print('Auto-timeout reached, trying alternative approach');
            _tryAlternativeListening();
          }
        });
        
      } else {
        print('Speech recognition not available');
        setState(() {
          _isListening = false;
        });
        await _speak("Speech recognition is not available on this device.");
      }
    } catch (e) {
      print('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Stop listening and check answer
  Future<void> _stopListening() async {
    print('Stopping speech recognition...');
    
    _timeoutTimer?.cancel();
    
    setState(() {
      _isListening = false;
    });
    
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 200));
    
    _checkAnswer();
  }

  /// Alternative listening approach for timeout cases
  Future<void> _tryAlternativeListening() async {
    print('Trying alternative listening approach...');
    
    try {
      await _speech.stop();
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Try with different settings - be patient with timeouts
      bool available = await _speech.initialize(
        onError: (error) {
          print('Alternative listening error: $error');
          
          // Don't immediately stop on timeout or no match - be more patient
          if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
            print('Alternative ${error.errorMsg} detected - but continuing to listen patiently');
            return;
          }
          
          setState(() {
            _isListening = false;
          });
          _showErrorDialog("Speech recognition is having issues. Please try again or check your microphone.");
        },
        onStatus: (status) {
          print('Alternative listening status: $status');
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _spokenText = "";
        });
        
        await _speech.listen(
          onResult: (result) {
            print('Alternative result: "${result.recognizedWords}"');
            setState(() {
              _spokenText = result.recognizedWords;
            });
          },
          listenFor: const Duration(seconds: 15), // Longer for alternative approach
          pauseFor: const Duration(seconds: 4),
          localeId: "en_US",
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.dictation,
        );
        
        print('Alternative listening started');
        
        // Set longer timeout for alternative approach
        _timeoutTimer = Timer(const Duration(seconds: 18), () {
          if (_isListening && _spokenText.isEmpty) {
            print('Alternative timeout reached - no speech detected');
            setState(() {
              _isListening = false;
            });
            _showNoSpeechDialog();
          }
        });
      }
    } catch (e) {
      print('Error in alternative listening: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Speech Recognition Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Show no speech detected dialog
  void _showNoSpeechDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic_off, color: Colors.blue),
            SizedBox(width: 8),
            Text("No Speech Detected"),
          ],
        ),
        content: Text(
          "Please speak clearly into the microphone. Make sure you're in a quiet environment.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startListening(); // Try again
            },
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }

  /// Show limit exceeded dialog
  void _showLimitExceededDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange),
            SizedBox(width: 8),
            Text("Exceeds Limit"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Try again later! (1hr)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "You've tried 5 times. Take a break and come back later!",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate back to learning materials
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LearningMaterialsPage(nickname: widget.nickname)),
                (Route<dynamic> route) => false);
            },
            child: const Text("Back to Learning"),
          ),
        ],
      ),
    );
  }

  /// Check the spoken answer
  void _checkAnswer() async {
    if (_spokenText.isEmpty) {
      await _speak("Please try again. Say the word clearly.");
      return;
    }

    setState(() {
      _isOptionDisabled = true;
    });

    final currentQuestion = _questions[_currentQuestion];
    final bool isCorrect = _spokenText.toLowerCase().trim() == 
                           currentQuestion['targetWord'].toLowerCase();

    // Track failed attempts
    if (!isCorrect) {
      _failedAttempts++;
      print('Failed attempt $_failedAttempts/$_maxFailedAttempts');
    } else {
      _failedAttempts = 0; // Reset on success
    }

    // Check if exceeded limit
    if (_failedAttempts >= _maxFailedAttempts) {
      _showLimitExceededDialog();
      return;
    }

    // Save to reflection for summary
    _reflection.add({
      "question": currentQuestion['question'],
      "userAnswer": _spokenText,
      "correctAnswer": currentQuestion['targetWord'],
    });

    await _flutterTts.stop();
    
    if (isCorrect) {
      await _flutterTts.speak("Correct! Well done!");
      _score++;
      _confettiController.play();
    } else {
      await _flutterTts.speak("Not quite right. The correct word is ${currentQuestion['targetWord']}");
      _shakeController.forward(from: 0.0);
    }

    // Wait a bit then go to next question
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    
    setState(() {
      _isOptionDisabled = false;
      _spokenText = "";
    });
    
    _goToNext();
  }

  /// Go to next question or show results
  void _goToNext() async {
    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _questionRead = false;
      });
      _speakQuestion();
    } else {
      await _saveToMemoryRetention();
      _showCompletionDialog();
    }
  }

  /// Save to memory retention system
  Future<void> _saveToMemoryRetention() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tts_assessment_score', _score);
      await prefs.setInt('tts_assessment_total', _questions.length);
      await prefs.setString('tts_assessment_date', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }

  /// Show completion dialog
  void _showCompletionDialog() {
    final double percentage = (_score / _questions.length) * 100;
    String title, message, emoji;
    Color titleColor;

    if (percentage >= 80) {
      title = "EXCELLENT WORK! 🌟";
      message = "You did amazing! Your speech recognition skills are fantastic!";
      emoji = "🎉🏆";
      titleColor = const Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      title = "GOOD JOB! 👏";
      message = "You did well! Keep practicing and you'll get even better!";
      emoji = "🎯🎪";
      titleColor = const Color(0xFF2196F3);
    } else {
      title = "KEEP LEARNING! 🌱";
      message = "Speech recognition takes practice! Try again and you'll improve!";
      emoji = "🌻🎪";
      titleColor = const Color(0xFFFF9800);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog.fullscreen(
          backgroundColor: const Color(0xFFF7F9FC),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple],
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height < 600 ? 16.0 : 24.0,
                        horizontal: MediaQuery.of(context).size.width < 400 ? 12.0 : 20.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animated celebration emojis
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              emoji,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 48 : MediaQuery.of(context).size.width < 600 ? 64 : 80,
                              ),
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                          
                          // Main emoji with animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Text(
                                  emoji,
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width < 400 ? 72 : MediaQuery.of(context).size.width < 600 ? 96 : 120,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                          
                          // Title with enhanced styling and animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                                    vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        titleColor.withOpacity(0.8),
                                        titleColor.withOpacity(0.6),
                                        Colors.white.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 25 : MediaQuery.of(context).size.width < 600 ? 35 : 45),
                                    boxShadow: [
                                      BoxShadow(
                                        color: titleColor.withOpacity(0.4),
                                        blurRadius: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width < 600 ? 16 : 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 24 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: MediaQuery.of(context).size.width < 400 ? 1.0 : MediaQuery.of(context).size.width < 600 ? 1.5 : 2.0,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 12 : 16),
                          
                          // Kid-friendly message
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width < 400 ? 12 : MediaQuery.of(context).size.width < 600 ? 20 : 28,
                            ),
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 20 : 24,
                                color: const Color(0xFF4A4E69),
                                fontFamily: 'Poppins',
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 12 : 16),
                          
                          // Enhanced score display with animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 700),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 24 : 32,
                                    vertical: MediaQuery.of(context).size.height < 600 ? 12 : 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4A90E2),
                                        Color(0xFF357ABD),
                                        Color(0xFF2E5BBA),
                                        Colors.white,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36),
                                    border: Border.all(
                                      color: Colors.blue.shade300,
                                      width: MediaQuery.of(context).size.width < 400 ? 2 : MediaQuery.of(context).size.width < 600 ? 3 : 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: MediaQuery.of(context).size.width < 400 ? 8 : MediaQuery.of(context).size.width < 600 ? 12 : 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "🎯",
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36,
                                        ),
                                      ),
                                      SizedBox(width: MediaQuery.of(context).size.width < 400 ? 8 : MediaQuery.of(context).size.width < 600 ? 12 : 16),
                                      Text(
                                        "Your Score: $_score/${_questions.length}",
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.width < 400 ? 18 : MediaQuery.of(context).size.width < 600 ? 24 : 30,
                                          color: Colors.blue.shade800,
                                          fontWeight: FontWeight.bold,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.white70,
                                              offset: Offset(1, 1),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                          
                          // View My Answers button with animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showAnswerSummaryModal();
                                  },
                                  icon: Icon(
                                    Icons.quiz,
                                    color: Colors.white,
                                    size: MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 26 : 32,
                                  ),
                                  label: Text(
                                    "View My Answers",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 16 : MediaQuery.of(context).size.width < 600 ? 20 : 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A4C93),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.width < 400 ? 24 : MediaQuery.of(context).size.width < 600 ? 32 : 40,
                                      vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36),
                                    ),
                                    elevation: 8,
                                    shadowColor: Colors.purple.withOpacity(0.4),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height < 600 ? 16 : 24),
                          
                          // Back to Learning button with animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 900),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => LearningMaterialsPage(nickname: widget.nickname)),
                                        (Route<dynamic> route) => false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00C9FF),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: MediaQuery.of(context).size.width < 400 ? 32 : MediaQuery.of(context).size.width < 600 ? 40 : 48,
                                      vertical: MediaQuery.of(context).size.height < 600 ? 16 : 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width < 400 ? 20 : MediaQuery.of(context).size.width < 600 ? 28 : 36),
                                    ),
                                    elevation: 10,
                                    shadowColor: Colors.cyan.withOpacity(0.5),
                                  ),
                                  child: Text(
                                    "Back to Learning",
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.width < 400 ? 18 : MediaQuery.of(context).size.width < 600 ? 24 : 30,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show answer summary modal
  void _showAnswerSummaryModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("📝", style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Your Answers",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _reflection.length,
                  itemBuilder: (context, index) {
                    final item = _reflection[index];
                    final isCorrect = item['userAnswer']?.toLowerCase().trim() == 
                                     item['correctAnswer']?.toLowerCase();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        title: Text(
                          item['question'] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Your answer: ${item['userAnswer']}"),
                            Text("Correct answer: ${item['correctAnswer']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A9D8F),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("Close", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestion];
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F0DC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
              // Header with progress
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentQuestion + 1) / _questions.length,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2A9D8F),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "${_currentQuestion + 1}/${_questions.length}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2A9D8F),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                      child: Text(
                        currentQuestion['category'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A9D8F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Question text - simplified
                    Text(
                      "Repeat the word:",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width < 400 ? 16 : 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // Target word
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A9D8F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2A9D8F).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        currentQuestion['targetWord'],
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width < 400 ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A9D8F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Speech recognition area
              Container(
                width: double.infinity,
                height: 100,
                padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 6),
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
              
              const SizedBox(height: 20),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _questionRead ? _speakQuestion : null,
                      icon: const Icon(Icons.volume_up, color: Colors.white),
                      label: const Text("Listen Again"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0077B6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                      onPressed: _questionRead && !_isOptionDisabled ? _listen : null,
                      icon: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                      ),
                      label: Text(_isListening ? "Stop & Check" : "Speak Now"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening
                            ? Colors.redAccent
                            : const Color(0xFF2A9D8F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
              
              // Manual retry button for timeout cases
              if (!_isListening && !_isOptionDisabled)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton(
                    onPressed: () async {
                      print('Manual retry button pressed');
                      await _startListening();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5DB2FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Retry Speech Recognition",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      )
    );
  }
}
