import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:math';

/// Intelligent NLP System for Kids - Understands speech and provides smart feedback
class IntelligentNLPSystem {
  static final SpeechToText _speechToText = SpeechToText();
  static final FlutterTts _flutterTts = FlutterTts();
  
  // NLP Keywords and Patterns for Kids
  static final Map<String, List<String>> _positiveKeywords = {
    'excitement': ['wow', 'awesome', 'amazing', 'cool', 'great', 'fantastic', 'super', 'wonderful'],
    'understanding': ['yes', 'okay', 'got it', 'understand', 'clear', 'sure', 'right'],
    'help': ['help', 'confused', 'don\'t know', 'hard', 'difficult', 'stuck'],
    'completion': ['done', 'finished', 'complete', 'all done', 'finished'],
    'encouragement': ['try again', 'one more', 'again', 'more', 'keep going'],
  };
  
  static final Map<String, List<String>> _negativeKeywords = {
    'frustration': ['no', 'wrong', 'bad', 'hate', 'boring', 'stupid', 'hard'],
    'confusion': ['what', 'how', 'why', 'confused', 'don\'t understand'],
    'tired': ['tired', 'sleepy', 'rest', 'break', 'stop'],
  };
  
  static final Map<String, List<String>> _learningKeywords = {
    'colors': ['red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'black', 'white'],
    'shapes': ['circle', 'square', 'triangle', 'rectangle', 'star', 'heart', 'diamond'],
    'numbers': ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'],
    'letters': ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'],
    'family': ['mom', 'dad', 'brother', 'sister', 'family', 'parent', 'grandma', 'grandpa'],
  };
  
  // Smart Response Templates
  static final Map<String, List<String>> _responseTemplates = {
    'excitement': [
      "I love your enthusiasm! 🌟",
      "You're so excited! That's wonderful! 🎉",
      "Your energy is amazing! Keep it up! ⭐",
      "Wow! You're really enjoying this! 🚀",
    ],
    'understanding': [
      "Great! You're getting it! 🎯",
      "Perfect! You understand! 🌟",
      "Excellent! You're learning so well! ✨",
      "Wonderful! You're doing great! 🏆",
    ],
    'help': [
      "Don't worry! I'm here to help! 🤗",
      "Let me help you understand! 📚",
      "It's okay to ask for help! 💪",
      "I'll make it easier for you! 🌈",
    ],
    'completion': [
      "Fantastic! You finished it! 🎊",
      "Amazing work! You're done! 🌟",
      "Great job completing that! 🏆",
      "You did it! So proud! ⭐",
    ],
    'encouragement': [
      "Let's try again! You can do it! 💪",
      "One more time! You're getting better! 🌟",
      "Keep going! You're doing great! 🚀",
      "Don't give up! You're learning! 📚",
    ],
    'frustration': [
      "It's okay to feel frustrated! Let's take a break! 🌱",
      "Don't worry! Learning takes time! 💙",
      "You're doing your best! That's what matters! 🌟",
      "Let's try something easier! 📚",
    ],
    'confusion': [
      "Let me explain that better! 📖",
      "I'll help you understand! 🤗",
      "That's a great question! Let me show you! ✨",
      "Don't worry! We'll figure it out together! 🌈",
    ],
    'tired': [
      "You're working so hard! Take a rest! 😴",
      "Great effort! Time for a break! ☕",
      "You've been learning a lot! Rest up! 🌙",
      "Amazing work! You deserve a break! 🌟",
    ],
  };
  
  /// Initialize the NLP system
  static Future<void> initialize() async {
    try {
      // Initialize Speech-to-Text
      await _speechToText.initialize();
      
      // Initialize Text-to-Speech
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setPitch(1.2);
      await _flutterTts.setSpeechRate(0.7);
      
      // Set up TTS voice for kids
      List<dynamic> voices = await _flutterTts.getVoices;
      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman") || name.contains("natural")) &&
            locale.contains("en")) {
          await _flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          break;
        }
      }
    } catch (e) {
      print('Error initializing NLP system: $e');
    }
  }
  
  /// Start listening for speech input
  static Future<void> startListening({
    required Function(String) onResult,
    required Function(String) onError,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!await _speechToText.hasPermission) {
        onError("Speech permission not granted");
        return;
      }
      
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            final recognizedText = result.recognizedWords.toLowerCase();
            onResult(recognizedText);
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: "en_US",
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes
        },
      );
    } catch (e) {
      onError("Error starting speech recognition: $e");
    }
  }
  
  /// Stop listening
  static Future<void> stopListening() async {
    await _speechToText.stop();
  }
  
  /// Analyze speech input and determine intent
  static NLPAnalysis analyzeSpeech(String speechInput) {
    final input = speechInput.toLowerCase().trim();
    
    // Check for positive emotions
    for (final category in _positiveKeywords.keys) {
      for (final keyword in _positiveKeywords[category]!) {
        if (input.contains(keyword)) {
          return NLPAnalysis(
            intent: category,
            confidence: _calculateConfidence(input, keyword),
            response: _getRandomResponse(category),
            emotion: 'positive',
            learningContent: _extractLearningContent(input),
          );
        }
      }
    }
    
    // Check for negative emotions
    for (final category in _negativeKeywords.keys) {
      for (final keyword in _negativeKeywords[category]!) {
        if (input.contains(keyword)) {
          return NLPAnalysis(
            intent: category,
            confidence: _calculateConfidence(input, keyword),
            response: _getRandomResponse(category),
            emotion: 'negative',
            learningContent: _extractLearningContent(input),
          );
        }
      }
    }
    
    // Check for learning content
    final learningContent = _extractLearningContent(input);
    if (learningContent.isNotEmpty) {
      return NLPAnalysis(
        intent: 'learning',
        confidence: 0.8,
        response: "Great! You're learning about $learningContent! 🌟",
        emotion: 'neutral',
        learningContent: learningContent,
      );
    }
    
    // Default response for unrecognized input
    return NLPAnalysis(
      intent: 'unknown',
      confidence: 0.3,
      response: "I heard you! Can you tell me more? 🤔",
      emotion: 'neutral',
      learningContent: '',
    );
  }
  
  /// Calculate confidence score for keyword matching
  static double _calculateConfidence(String input, String keyword) {
    final inputWords = input.split(' ');
    final keywordWords = keyword.split(' ');
    
    int matches = 0;
    for (final word in keywordWords) {
      if (inputWords.contains(word)) {
        matches++;
      }
    }
    
    return matches / keywordWords.length;
  }
  
  /// Get random response for a category
  static String _getRandomResponse(String category) {
    final responses = _responseTemplates[category] ?? ["Great! 🌟"];
    return responses[Random().nextInt(responses.length)];
  }
  
  /// Extract learning content from speech
  static String _extractLearningContent(String input) {
    for (final category in _learningKeywords.keys) {
      for (final keyword in _learningKeywords[category]!) {
        if (input.contains(keyword)) {
          return category;
        }
      }
    }
    return '';
  }
  
  /// Speak response with TTS
  static Future<void> speakResponse(String response) async {
    try {
      await _flutterTts.speak(response);
    } catch (e) {
      print('Error speaking response: $e');
    }
  }
  
  /// Get intelligent feedback based on assessment performance
  static String getIntelligentFeedback({
    required double performance,
    required String assessmentType,
    required String userSpeech,
  }) {
    final analysis = analyzeSpeech(userSpeech);
    
    String baseFeedback = '';
    
    if (performance >= 0.9) {
      baseFeedback = "Incredible! You're a superstar! 🌟";
    } else if (performance >= 0.7) {
      baseFeedback = "Great job! You're doing amazing! 🎉";
    } else if (performance >= 0.5) {
      baseFeedback = "Good work! You're learning! 💪";
    } else {
      baseFeedback = "Keep trying! You're getting better! 🌱";
    }
    
    // Combine with NLP analysis
    if (analysis.emotion == 'positive') {
      return "$baseFeedback ${analysis.response}";
    } else if (analysis.emotion == 'negative') {
      return "Don't worry! ${analysis.response} $baseFeedback";
    } else {
      return baseFeedback;
    }
  }
  
  /// Generate contextual help based on speech input
  static String getContextualHelp(String speechInput, String currentModule) {
    final analysis = analyzeSpeech(speechInput);
    
    if (analysis.intent == 'help' || analysis.intent == 'confusion') {
      switch (currentModule) {
        case 'alphabet':
          return "Let me help you with letters! Try saying the letter out loud! 📚";
        case 'colors':
          return "Colors are fun! Look around and tell me what colors you see! 🌈";
        case 'shapes':
          return "Shapes are everywhere! Can you find a circle or square? 🔷";
        case 'numbers':
          return "Numbers help us count! Let's count together! 🔢";
        case 'family':
          return "Families are special! Tell me about your family! 👨‍👩‍👧‍👦";
        default:
          return "I'm here to help! What would you like to learn? 🤗";
      }
    }
    
    return analysis.response;
  }
  
  /// Check if speech input indicates completion
  static bool isCompletionIndicated(String speechInput) {
    final analysis = analyzeSpeech(speechInput);
    return analysis.intent == 'completion' || 
           speechInput.contains('done') || 
           speechInput.contains('finished') ||
           speechInput.contains('all done');
  }
  
  /// Check if speech input indicates need for help
  static bool isHelpNeeded(String speechInput) {
    final analysis = analyzeSpeech(speechInput);
    return analysis.intent == 'help' || 
           analysis.intent == 'confusion' ||
           speechInput.contains('help') ||
           speechInput.contains('don\'t know');
  }
  
  /// Get encouragement based on speech input
  static String getEncouragement(String speechInput) {
    final analysis = analyzeSpeech(speechInput);
    
    if (analysis.emotion == 'negative') {
      return "You're doing great! Don't give up! 🌟";
    } else if (analysis.intent == 'encouragement') {
      return analysis.response;
    } else {
      return "Keep going! You're amazing! ⭐";
    }
  }
}

/// NLP Analysis Result
class NLPAnalysis {
  final String intent;
  final double confidence;
  final String response;
  final String emotion;
  final String learningContent;
  
  NLPAnalysis({
    required this.intent,
    required this.confidence,
    required this.response,
    required this.emotion,
    required this.learningContent,
  });
  
  @override
  String toString() {
    return 'NLPAnalysis(intent: $intent, confidence: $confidence, emotion: $emotion, content: $learningContent)';
  }
}

/// Voice Interaction Widget for Kids
class VoiceInteractionWidget extends StatefulWidget {
  final String nickname;
  final String currentModule;
  final Function(String) onSpeechResult;
  final Function(String) onIntelligentFeedback;
  
  const VoiceInteractionWidget({
    super.key,
    required this.nickname,
    required this.currentModule,
    required this.onSpeechResult,
    required this.onIntelligentFeedback,
  });
  
  @override
  State<VoiceInteractionWidget> createState() => _VoiceInteractionWidgetState();
}

class _VoiceInteractionWidgetState extends State<VoiceInteractionWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastSpeechResult = '';
  String _currentFeedback = '';
  
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeNLP();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  Future<void> _initializeNLP() async {
    await IntelligentNLPSystem.initialize();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
  
  Future<void> _startListening() async {
    if (_isListening) return;
    
    setState(() {
      _isListening = true;
      _isProcessing = false;
    });
    
    _pulseController.repeat(reverse: true);
    
    await IntelligentNLPSystem.startListening(
      onResult: _handleSpeechResult,
      onError: _handleSpeechError,
    );
  }
  
  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    await IntelligentNLPSystem.stopListening();
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });
    
    _pulseController.stop();
    
    // Process the speech result
    if (_lastSpeechResult.isNotEmpty) {
      await _processSpeechResult(_lastSpeechResult);
    }
  }
  
  void _handleSpeechResult(String result) {
    setState(() {
      _lastSpeechResult = result;
    });
  }
  
  void _handleSpeechError(String error) {
    setState(() {
      _isListening = false;
      _isProcessing = false;
    });
    
    _pulseController.stop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Oops! I didn't hear that. Try again! 🎤"),
        backgroundColor: Colors.orange,
      ),
    );
  }
  
  Future<void> _processSpeechResult(String speechInput) async {
    final analysis = IntelligentNLPSystem.analyzeSpeech(speechInput);
    
    setState(() {
      _currentFeedback = analysis.response;
      _isProcessing = false;
    });
    
    // Provide intelligent feedback
    widget.onIntelligentFeedback(analysis.response);
    
    // Speak the response
    await IntelligentNLPSystem.speakResponse(analysis.response);
    
    // Pass result to parent
    widget.onSpeechResult(speechInput);
    
    // Show contextual help if needed
    if (IntelligentNLPSystem.isHelpNeeded(speechInput)) {
      final helpMessage = IntelligentNLPSystem.getContextualHelp(
        speechInput, 
        widget.currentModule,
      );
      
      Future.delayed(const Duration(seconds: 2), () {
        IntelligentNLPSystem.speakResponse(helpMessage);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isListening 
              ? [const Color(0xFF4ECDC4), const Color(0xFF44A08D)]
              : [const Color(0xFF6BCF7F), const Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: (_isListening 
                ? const Color(0xFF4ECDC4) 
                : const Color(0xFF6BCF7F)).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Talk to Me! 🎤",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          // Voice Button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 40,
                      color: _isListening 
                          ? const Color(0xFF4ECDC4)
                          : const Color(0xFF6BCF7F),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status Text
          Text(
            _isListening 
                ? "I'm listening... 👂"
                : _isProcessing
                    ? "Thinking... 🤔"
                    : "Tap to talk! 🗣️",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          
          // Speech Result
          if (_lastSpeechResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "You said: \"$_lastSpeechResult\"",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          // Feedback
          if (_currentFeedback.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _currentFeedback,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
