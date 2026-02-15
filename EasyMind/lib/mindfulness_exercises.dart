import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:math';

/// Mindfulness Exercises System for Focus and Relaxation
class MindfulnessExercises {
  static final MindfulnessExercises _instance = MindfulnessExercises._internal();
  factory MindfulnessExercises() => _instance;
  MindfulnessExercises._internal();

  final FlutterTts _flutterTts = FlutterTts();

  /// Initialize the mindfulness system
  Future<void> initialize() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.4); // Slower for relaxation
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print('Error initializing mindfulness exercises: $e');
    }
  }

  /// Start breathing exercise
  Future<void> startBreathingExercise({
    required Function(String) onInstruction,
    required Function(int) onCountdown,
    required VoidCallback onComplete,
    int duration = 60, // seconds
  }) async {
    try {
      await _flutterTts.speak("Let's start a calming breathing exercise. Find a comfortable position.");
      
      // Breathing phases
      final phases = [
        {'name': 'Inhale', 'duration': 4, 'instruction': 'Breathe in slowly through your nose'},
        {'name': 'Hold', 'duration': 2, 'instruction': 'Hold your breath gently'},
        {'name': 'Exhale', 'duration': 6, 'instruction': 'Breathe out slowly through your mouth'},
        {'name': 'Rest', 'duration': 2, 'instruction': 'Rest and feel calm'},
      ];

      int totalTime = 0;

      while (totalTime < duration) {
        for (final phase in phases) {
          if (totalTime >= duration) break;
          
          final phaseDuration = phase['duration'] as int;
          final instruction = phase['instruction'] as String;
          
          onInstruction(instruction);
          await _flutterTts.speak(instruction);
          
          // Countdown for this phase
          for (int i = phaseDuration; i > 0; i--) {
            if (totalTime >= duration) break;
            onCountdown(i);
            await Future.delayed(const Duration(seconds: 1));
            totalTime++;
          }
        }
      }
      
      await _flutterTts.speak("Great job! You've completed the breathing exercise. Feel the calmness.");
      onComplete();
    } catch (e) {
      print('Error during breathing exercise: $e');
    }
  }

  /// Start body scan meditation
  Future<void> startBodyScanMeditation({
    required Function(String) onInstruction,
    required VoidCallback onComplete,
    int duration = 300, // 5 minutes
  }) async {
    try {
      await _flutterTts.speak("Let's begin a body scan meditation. Lie down comfortably and close your eyes.");
      
      final bodyParts = [
        {'part': 'toes', 'instruction': 'Focus on your toes. Feel any tension and let it go.'},
        {'part': 'feet', 'instruction': 'Move your attention to your feet. Feel them relax completely.'},
        {'part': 'legs', 'instruction': 'Notice your legs. Feel them becoming heavy and relaxed.'},
        {'part': 'stomach', 'instruction': 'Focus on your stomach. Feel it rise and fall with each breath.'},
        {'part': 'chest', 'instruction': 'Notice your chest. Feel it expand and relax with each breath.'},
        {'part': 'arms', 'instruction': 'Move to your arms. Feel them becoming warm and relaxed.'},
        {'part': 'hands', 'instruction': 'Focus on your hands. Feel any tension melting away.'},
        {'part': 'neck', 'instruction': 'Notice your neck. Let any tightness release completely.'},
        {'part': 'head', 'instruction': 'Focus on your head. Feel your mind becoming calm and peaceful.'},
      ];

      final timePerPart = duration ~/ bodyParts.length;
      
      for (final part in bodyParts) {
        final instruction = part['instruction'] as String;
        onInstruction(instruction);
        await _flutterTts.speak(instruction);
        await Future.delayed(Duration(seconds: timePerPart));
      }
      
      await _flutterTts.speak("Excellent! You've completed the body scan. Feel how relaxed and peaceful you are.");
      onComplete();
    } catch (e) {
      print('Error during body scan meditation: $e');
    }
  }

  /// Start gratitude practice
  Future<void> startGratitudePractice({
    required Function(String) onInstruction,
    required VoidCallback onComplete,
    int duration = 180, // 3 minutes
  }) async {
    try {
      await _flutterTts.speak("Let's practice gratitude. Think about things that make you happy and thankful.");
      
      final gratitudePrompts = [
        "Think of someone who loves you. How does that make you feel?",
        "Remember a time when you felt proud of yourself. What did you accomplish?",
        "Think of something beautiful you saw today. What made it special?",
        "Remember a time when someone helped you. How did that feel?",
        "Think of something you're good at. What do you like about it?",
        "Remember a fun time you had recently. What made it enjoyable?",
        "Think of your favorite place. Why do you love it there?",
        "Remember a time when you felt happy. What was happening?",
      ];

      final timePerPrompt = duration ~/ gratitudePrompts.length;
      
      for (final prompt in gratitudePrompts) {
        onInstruction(prompt);
        await _flutterTts.speak(prompt);
        await Future.delayed(Duration(seconds: timePerPrompt));
      }
      
      await _flutterTts.speak("Wonderful! You've practiced gratitude. Notice how thankful and happy you feel.");
      onComplete();
    } catch (e) {
      print('Error during gratitude practice: $e');
    }
  }

  /// Start mindful listening
  Future<void> startMindfulListening({
    required Function(String) onInstruction,
    required VoidCallback onComplete,
    int duration = 120, // 2 minutes
  }) async {
    try {
      await _flutterTts.speak("Let's practice mindful listening. Close your eyes and listen carefully to the sounds around you.");
      
      final listeningPrompts = [
        "Listen to the sounds in the room. What do you hear?",
        "Focus on sounds that are far away. What can you hear?",
        "Listen for sounds that are close to you. What do you notice?",
        "Pay attention to your own breathing. How does it sound?",
        "Listen for any sounds outside. What can you hear?",
        "Focus on the quietest sound you can hear. What is it?",
        "Listen to the rhythm of sounds around you. What patterns do you notice?",
        "Take a moment to appreciate all the sounds you can hear.",
      ];

      final timePerPrompt = duration ~/ listeningPrompts.length;
      
      for (final prompt in listeningPrompts) {
        onInstruction(prompt);
        await _flutterTts.speak(prompt);
        await Future.delayed(Duration(seconds: timePerPrompt));
      }
      
      await _flutterTts.speak("Great listening practice! You've become more aware of the world around you.");
      onComplete();
    } catch (e) {
      print('Error during mindful listening: $e');
    }
  }

  /// Start visualization exercise
  Future<void> startVisualizationExercise({
    required Function(String) onInstruction,
    required VoidCallback onComplete,
    int duration = 240, // 4 minutes
  }) async {
    try {
      await _flutterTts.speak("Let's do a peaceful visualization. Close your eyes and imagine a beautiful, calm place.");
      
      final visualizationScript = [
        "Imagine you're walking through a peaceful forest. The trees are tall and green.",
        "You can hear birds singing softly in the distance. The air feels fresh and clean.",
        "You come to a beautiful, calm lake. The water is crystal clear and still.",
        "You sit by the lake and watch the gentle ripples on the water. You feel completely peaceful.",
        "The sun is warm on your face, and you feel safe and happy in this beautiful place.",
        "You take a deep breath and feel all your worries floating away like clouds.",
        "In this peaceful place, you feel strong, calm, and ready for anything.",
        "When you're ready, slowly open your eyes and bring this peaceful feeling with you.",
      ];

      final timePerScript = duration ~/ visualizationScript.length;
      
      for (final script in visualizationScript) {
        onInstruction(script);
        await _flutterTts.speak(script);
        await Future.delayed(Duration(seconds: timePerScript));
      }
      
      await _flutterTts.speak("Beautiful! You've created a peaceful place in your mind. Remember, you can visit this place anytime.");
      onComplete();
    } catch (e) {
      print('Error during visualization exercise: $e');
    }
  }

  /// Get random mindfulness tip
  String getRandomMindfulnessTip() {
    final tips = [
      "Take three deep breaths when you feel stressed.",
      "Notice five things you can see around you right now.",
      "Think of three things you're grateful for today.",
      "Take a moment to feel your feet on the ground.",
      "Listen to the sounds around you without judging them.",
      "Notice how your body feels right now.",
      "Take a break and look at something beautiful.",
      "Remember that it's okay to feel your emotions.",
      "Practice being kind to yourself today.",
      "Take one moment to appreciate something small.",
    ];
    
    return tips[Random().nextInt(tips.length)];
  }

  /// Stop all exercises
  Future<void> stopAllExercises() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Error stopping exercises: $e');
    }
  }
}

/// Mindfulness Exercise Widget
class MindfulnessExerciseWidget extends StatefulWidget {
  final String nickname;
  final String exerciseType;
  final int duration;
  
  const MindfulnessExerciseWidget({
    super.key,
    required this.nickname,
    required this.exerciseType,
    this.duration = 60,
  });

  @override
  State<MindfulnessExerciseWidget> createState() => _MindfulnessExerciseWidgetState();
}

class _MindfulnessExerciseWidgetState extends State<MindfulnessExerciseWidget>
    with TickerProviderStateMixin {
  final MindfulnessExercises _mindfulness = MindfulnessExercises();
  
  late AnimationController _breathController;
  late AnimationController _pulseController;
  late Animation<double> _breathAnimation;
  late Animation<double> _pulseAnimation;
  
  String _currentInstruction = '';
  int _currentCountdown = 0;
  bool _isExerciseActive = false;
  bool _isExerciseComplete = false;
  Timer? _exerciseTimer;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMindfulness();
    _remainingTime = widget.duration;
  }

  void _initializeAnimations() {
    _breathController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _breathAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeMindfulness() async {
    await _mindfulness.initialize();
  }

  Future<void> _startExercise() async {
    setState(() {
      _isExerciseActive = true;
      _isExerciseComplete = false;
    });

    _pulseController.repeat(reverse: true);

    // Start countdown timer
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
      }
    });

    // Start the specific exercise
    switch (widget.exerciseType) {
      case 'breathing':
        await _startBreathingExercise();
        break;
      case 'body_scan':
        await _startBodyScanMeditation();
        break;
      case 'gratitude':
        await _startGratitudePractice();
        break;
      case 'listening':
        await _startMindfulListening();
        break;
      case 'visualization':
        await _startVisualizationExercise();
        break;
      default:
        await _startBreathingExercise();
    }
  }

  Future<void> _startBreathingExercise() async {
    await _mindfulness.startBreathingExercise(
      onInstruction: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onCountdown: (count) {
        setState(() {
          _currentCountdown = count;
        });
        _breathController.forward().then((_) {
          _breathController.reverse();
        });
      },
      onComplete: _onExerciseComplete,
      duration: widget.duration,
    );
  }

  Future<void> _startBodyScanMeditation() async {
    await _mindfulness.startBodyScanMeditation(
      onInstruction: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onComplete: _onExerciseComplete,
      duration: widget.duration,
    );
  }

  Future<void> _startGratitudePractice() async {
    await _mindfulness.startGratitudePractice(
      onInstruction: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onComplete: _onExerciseComplete,
      duration: widget.duration,
    );
  }

  Future<void> _startMindfulListening() async {
    await _mindfulness.startMindfulListening(
      onInstruction: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onComplete: _onExerciseComplete,
      duration: widget.duration,
    );
  }

  Future<void> _startVisualizationExercise() async {
    await _mindfulness.startVisualizationExercise(
      onInstruction: (instruction) {
        setState(() {
          _currentInstruction = instruction;
        });
      },
      onComplete: _onExerciseComplete,
      duration: widget.duration,
    );
  }

  void _onExerciseComplete() {
    setState(() {
      _isExerciseActive = false;
      _isExerciseComplete = true;
    });
    _pulseController.stop();
    _exerciseTimer?.cancel();
  }

  void _stopExercise() {
    setState(() {
      _isExerciseActive = false;
    });
    _pulseController.stop();
    _exerciseTimer?.cancel();
    _mindfulness.stopAllExercises();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _pulseController.dispose();
    _exerciseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: Text(_getExerciseTitle()),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
        actions: [
          if (_isExerciseActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopExercise,
            ),
        ],
      ),
      body: Column(
        children: [
          // Exercise Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF648BA2),
                  const Color(0xFF648BA2).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _getExerciseIcon(),
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  _getExerciseTitle(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _getExerciseDescription(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Exercise Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isExerciseActive && !_isExerciseComplete) ...[
                    // Start Exercise
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFF648BA2).withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF648BA2),
                                width: 3,
                              ),
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 80,
                              color: Color(0xFF648BA2),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _startExercise,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Exercise'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ] else if (_isExerciseActive) ...[
                    // Exercise in Progress
                    AnimatedBuilder(
                      animation: _breathAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _breathAnimation.value,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF648BA2).withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF648BA2),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              size: 60,
                              color: Color(0xFF648BA2),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _currentInstruction,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_currentCountdown > 0) ...[
                      const SizedBox(height: 20),
                      Text(
                        '$_currentCountdown',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF648BA2),
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Text(
                      'Time remaining: ${_remainingTime}s',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  ] else if (_isExerciseComplete) ...[
                    // Exercise Complete
                    const Icon(
                      Icons.check_circle,
                      size: 100,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Exercise Complete!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Great job! You\'ve completed your mindfulness exercise.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7F8C8D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isExerciseComplete = false;
                              _remainingTime = widget.duration;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF648BA2),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getExerciseTitle() {
    switch (widget.exerciseType) {
      case 'breathing': return 'Breathing Exercise';
      case 'body_scan': return 'Body Scan Meditation';
      case 'gratitude': return 'Gratitude Practice';
      case 'listening': return 'Mindful Listening';
      case 'visualization': return 'Visualization Exercise';
      default: return 'Mindfulness Exercise';
    }
  }

  String _getExerciseDescription() {
    switch (widget.exerciseType) {
      case 'breathing': return 'Calm your mind with guided breathing';
      case 'body_scan': return 'Relax your body from head to toe';
      case 'gratitude': return 'Practice being thankful and happy';
      case 'listening': return 'Focus on the sounds around you';
      case 'visualization': return 'Imagine a peaceful, beautiful place';
      default: return 'Take a moment to relax and focus';
    }
  }

  IconData _getExerciseIcon() {
    switch (widget.exerciseType) {
      case 'breathing': return Icons.air;
      case 'body_scan': return Icons.accessibility;
      case 'gratitude': return Icons.favorite;
      case 'listening': return Icons.hearing;
      case 'visualization': return Icons.visibility;
      default: return Icons.spa;
    }
  }
}
