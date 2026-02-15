import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'gamification_system.dart';

class MatchSoundPage extends StatefulWidget {
  final String nickname;
  const MatchSoundPage({super.key, required this.nickname});

  @override
  State<MatchSoundPage> createState() => _MatchSoundPageState();
}

class _MatchSoundPageState extends State<MatchSoundPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _mainPlayer = AudioPlayer();
  final List<AudioPlayer> _optionPlayers = List.generate(
    4,
    (_) => AudioPlayer(),
  );
  final FlutterTts _flutterTts = FlutterTts();

  // --- EXPANDED DATA STRUCTURE ---
  final List<Map<String, dynamic>> _questions = [
    {
      'mainSound': 'sound/dog_bark.mp3',
      'options': [
        'sound/bark1.mp3',
        'sound/bark2.mp3',
        'sound/dog_bark.mp3', // Correct
        'sound/bark3.mp3',
      ],
      'images': [
        'assets/bird.jpg',
        'assets/cow.jpg',
        'assets/dogg.jpg',
        'assets/chicken.jpg',
      ],
      'correctIndex': 2,
    },
    {
      'mainSound': 'sound/meowing-cat.mp3',
      'options': [
        'sound/bark1.mp3', // Correct
        'sound/meowing-cat.mp3',
        'sound/dog_bark.mp3',
        'sound/bark2.mp3',
      ],
      'images': [
        'assets/bird.jpg',
        'assets/cat.jpg',
        'assets/dogg.jpg',
        'assets/cow.jpg',
      ],
      'correctIndex': 1,
    },
    {
      'mainSound': 'sound/car-horn.mp3',
      'options': [
        'sound/car-horn.mp3', // Correct
        'sound/bike-bell.mp3',
        'sound/phone-ring.mp3',
        'sound/siren.mp3',
      ],
      'images': [
        'assets/car.jpg',
        'assets/bike.jpg',
        'assets/phone.jpg',
        'assets/siren.jpg',
      ],
      'correctIndex': 0,
    },
    {
      'mainSound': 'sound/bike-bell.mp3',
      'options': [
        'sound/siren.mp3',
        'sound/meowing-cat.mp3',
        'sound/bike-bell.mp3', // Correct
        'sound/dog_bark.mp3',
      ],
      'images': [
        'assets/siren.jpg',
        'assets/cat.jpg',
        'assets/bike.jpg',
        'assets/dogg.jpg',
      ],
      'correctIndex': 2,
    },
  ];

  Map<String, dynamic> get _currentQuestion => _questions[_currentIndex];
  // --- END EXPANDED DATA STRUCTURE ---

  late AnimationController _animationController;
  late Animation<double> _waveAnimation;
  int _currentIndex = 0; // New: Tracks current question index
  int? _selectedOption;
  int _score = 0;
  bool _isDialogOpen = false;

  // Adaptive Assessment System
  bool _useAdaptiveMode = true;
  String _currentDifficulty = 'beginner';
  final GamificationSystem _gamificationSystem = GamificationSystem();
  GamificationResult? _lastReward;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _waveAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _setupTTS();
    _initializeAudioPlayers();
    _initializeAdaptiveMode();
  }

  void _initializeAudioPlayers() async {
    try {
      print('Initializing audio players...');
      // Note: Only checking the assets for the FIRST question to avoid excessive I/O
      // during initialization. Playback will use the current question's assets.
      print('Audio players initialization completed');
    } catch (e) {
      print('Error initializing audio players: $e');
    }
  }

  void _setupTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.1);
    await _flutterTts.setSpeechRate(0.5);

    try {
      List<dynamic> voices = await _flutterTts.getVoices;
      bool voiceSet = false;

      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman")) &&
            locale.contains("en")) {
          await _flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          voiceSet = true;
          break;
        }
      }

      if (!voiceSet) {
        print("No suitable female voice found, using default");
      }
    } catch (e) {
      print("TTS voice configuration failed, using default: $e");
    }
  }

  void _speakInstructions() async {
    await _flutterTts.stop();
    await _flutterTts.speak(
      "Listen to the sound and select the matching one below.",
    );
  }

  void _stopAllAudio() async {
    try {
      await _mainPlayer.stop();
      for (var player in _optionPlayers) {
        await player.stop();
      }
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  void dispose() {
    _stopAllAudio();
    _animationController.dispose();
    _mainPlayer.dispose();
    for (var player in _optionPlayers) {
      player.dispose();
    }
    _flutterTts.stop();
    super.dispose();
  }

  void _playMainSound() async {
    try {
      _stopAllAudio();
      await _mainPlayer.play(AssetSource(_currentQuestion['mainSound']));
      _animationController.repeat(reverse: true);
      await Future.delayed(const Duration(seconds: 2));
      _animationController.stop();
      _animationController.reset();
    } catch (e) {
      print('Error playing main sound: $e');
    }
  }

  void _playOptionSound(int index) async {
    try {
      print('Playing option sound at index: $index');
      final soundPath = _currentQuestion['options'][index];
      print('Sound path: $soundPath');

      _stopAllAudio();
      await Future.delayed(const Duration(milliseconds: 100));
      await _optionPlayers[index].play(AssetSource(soundPath));

      print('Successfully started playing option sound');

      setState(() {
        _selectedOption = index;
      });
    } catch (e) {
      print('Error playing option sound: $e');
    }
  }

  void _confirmSelection() async {
    if (_isDialogOpen || _selectedOption == null) {
      if (_selectedOption == null) {
        await _flutterTts.speak("Please select an option first!");
      }
      return;
    }

    _isDialogOpen = true;
    final bool isCorrect = _selectedOption == _currentQuestion['correctIndex'];

    if (isCorrect) {
      setState(() {
        _score++;
      });
      await _flutterTts.speak("Correct!");
      _showFeedbackDialog(
        "Great job! You matched the sound correctly!",
        isCorrect,
      );
      // Save result immediately for the current correct answer
      _saveToAdaptiveAssessment(isCorrect: true);
      _saveToMemoryRetention(isCorrect: true);
    } else {
      await _flutterTts.speak("Try again!");
      _showFeedbackDialog(
        "Oops! That wasn't the right match. Try again.",
        isCorrect,
      );
      _saveToAdaptiveAssessment(isCorrect: false);
    }
  }

  // New function to handle moving to the next question or finishing the game
  void _moveToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
      });
      _playMainSound(); // Play the sound for the new question
    } else {
      // Game finished
      _showCompletionDialog();
    }
  }

  // Updated _showFeedbackDialog to handle next/retry logic
  void _showFeedbackDialog(String feedbackMessage, bool isCorrect) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.7,
                  maxWidth: screenWidth * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.error,
                        size: screenWidth * 0.12,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Text(
                        isCorrect ? "Correct!" : "Incorrect",
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF22223B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.018,
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
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            color: Colors.black87,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _isDialogOpen = false;
                            _selectedOption = null;
                          });

                          if (isCorrect) {
                            _moveToNextQuestion();
                          } else {
                            // Retry current question by replaying the main sound
                            _playMainSound();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isCorrect
                                  ? const Color(0xFF5DB2FF)
                                  : const Color(0xFFE94F37),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.022,
                            horizontal: screenWidth * 0.05,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.arrow_forward : Icons.replay,
                              size: screenWidth * 0.06,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              isCorrect
                                  ? (_currentIndex < _questions.length - 1
                                      ? "Next Question"
                                      : "Finish Game")
                                  : "Try Again",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    ).then((_) {
      setState(() {
        _isDialogOpen = false;
      });
    });
  }

  // New function to show the final game completion state
  void _showCompletionDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final totalQuestions = _questions.length;
    final String feedback =
        "You answered $_score out of $totalQuestions sounds correctly!";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: screenWidth * 0.15,
                    color: Colors.amber,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    "Game Completed!",
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Text(
                    feedback,
                    style: TextStyle(fontSize: screenWidth * 0.05),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      _stopAllAudio();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                        horizontal: screenWidth * 0.08,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Back to Games",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isIpad = screenWidth >= 600;
    final double boxSize = isIpad ? screenWidth * 0.25 : screenWidth * 0.35;
    final double imageSize = isIpad ? screenWidth * 0.22 : screenWidth * 0.3;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBD8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  'Score: $_score/${_questions.length}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A6C82),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: screenHeight * 0.08,
                  width: screenWidth * 0.4,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        _stopAllAudio();
                        Navigator.pop(context);
                      } catch (e) {
                        print('Error navigating back: $e');
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.05,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A6C82),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Match The Sound',
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A6C82),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: screenHeight * 0.015),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Listen to the sound and select the matching one below.',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        color: const Color.fromARGB(255, 0, 0, 0),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      size: screenWidth * 0.08,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                    onPressed: _speakInstructions,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        width: screenWidth * 0.2 * _waveAnimation.value,
                        height: screenWidth * 0.2 * _waveAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        width: screenWidth * 0.15 * _waveAnimation.value,
                        height: screenWidth * 0.15 * _waveAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withOpacity(0.3),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    iconSize: screenWidth * 0.15,
                    icon: const Icon(Icons.play_circle_filled_rounded),
                    color: const Color(0xFF4A6C82),
                    onPressed: _playMainSound,
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.04),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) => _buildImageButton(index, boxSize, imageSize),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      2,
                      (index) =>
                          _buildImageButton(index + 2, boxSize, imageSize),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  SizedBox(
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      onPressed: _confirmSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A6C82),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.02,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Selection',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageButton(int index, double boxSize, double imageSize) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
      ),
      child: GestureDetector(
        onTap: () => _playOptionSound(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: boxSize,
          width: boxSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                _selectedOption == index
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  _selectedOption == index
                      ? Colors.blue.shade400
                      : Colors.grey.shade200,
              width: _selectedOption == index ? 3.0 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _currentQuestion['images'][index],
                    height: imageSize,
                    width: imageSize,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: imageSize,
                        width: imageSize,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.volume_up_rounded,
                  size: MediaQuery.of(context).size.width * 0.08,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Adaptive Assessment Methods
  Future<void> _initializeAdaptiveMode() async {
    if (_useAdaptiveMode) {
      try {
        await _gamificationSystem.initialize();
        _currentDifficulty = await AdaptiveAssessmentSystem.getCurrentLevel(
          widget.nickname,
          AssessmentType.sounds.value,
        );
        setState(() {});
      } catch (e) {
        print('Error initializing adaptive mode: $e');
      }
    }
  }

  // Refactored to save results per question
  Future<void> _saveToAdaptiveAssessment({required bool isCorrect}) async {
    if (!_useAdaptiveMode) return;

    try {
      final totalQuestions = 1; // Treat each round as 1 question attempt
      final correctAnswers = isCorrect ? 1 : 0;
      final currentSound = _currentQuestion['mainSound'];

      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: AssessmentType.sounds.value,
        moduleName: "Sound Matching Game",
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        // Using a placeholder time, as time spent per question is complex to track
        timeSpent: const Duration(seconds: 30),
        attemptedQuestions: [currentSound],
        correctQuestions: isCorrect ? [currentSound] : [],
      );

      // Award XP based on current question performance
      _lastReward = await _gamificationSystem.awardXP(
        nickname: widget.nickname,
        activity: isCorrect ? 'correct_sound_match' : 'sound_match_re_attempt',
        metadata: {
          'module': 'matchTheSound',
          'question': currentSound,
          'correct': isCorrect,
        },
      );

      print(
        'Adaptive assessment saved for question $_currentIndex. Correct: $isCorrect',
      );
    } catch (e) {
      print('Error saving adaptive assessment: $e');
    }
  }

  // Refactored to save results per question
  Future<void> _saveToMemoryRetention({required bool isCorrect}) async {
    try {
      final retentionSystem = MemoryRetentionSystem();
      await retentionSystem.saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: "Sound Recognition",
        lessonType: "MatchTheSound Game",
        score: isCorrect ? 1 : 0,
        totalQuestions: 1,
        passed: isCorrect,
      );
    } catch (e) {
      print('Error saving to memory retention: $e');
    }
  }
}
