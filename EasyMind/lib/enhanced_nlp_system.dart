import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:math';

/// Enhanced NLP System with Pronunciation Assessment
class EnhancedNLPSystem {
  static final SpeechToText _speechToText = SpeechToText();
  static final FlutterTts _flutterTts = FlutterTts();
  
  // Pronunciation assessment patterns
  static final Map<String, List<String>> _pronunciationPatterns = {
    'th': ['th', 'f', 'd', 't'],
    'r': ['r', 'w', 'l'],
    'l': ['l', 'r', 'w'],
    'v': ['v', 'b', 'f'],
    'w': ['w', 'r', 'v'],
    's': ['s', 'sh', 'th'],
    'sh': ['sh', 's', 'ch'],
    'ch': ['ch', 'sh', 't'],
    'j': ['j', 'g', 'y'],
    'g': ['g', 'j', 'k'],
  };
  
  // Phonetic alphabet mapping
  static final Map<String, String> _phoneticMap = {
    'a': 'ay', 'b': 'bee', 'c': 'see', 'd': 'dee', 'e': 'ee',
    'f': 'eff', 'g': 'gee', 'h': 'aitch', 'i': 'eye', 'j': 'jay',
    'k': 'kay', 'l': 'ell', 'm': 'em', 'n': 'en', 'o': 'oh',
    'p': 'pee', 'q': 'cue', 'r': 'ar', 's': 'ess', 't': 'tee',
    'u': 'you', 'v': 'vee', 'w': 'double-you', 'x': 'ex', 'y': 'why', 'z': 'zee'
  };
  
  // Multi-language support
  static final Map<String, Map<String, List<String>>> _languageKeywords = {
    'en': {
      'greetings': ['hello', 'hi', 'good morning', 'good afternoon', 'good evening'],
      'colors': ['red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'black', 'white'],
      'numbers': ['one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten'],
      'family': ['mom', 'dad', 'brother', 'sister', 'family', 'parent', 'grandma', 'grandpa'],
      'animals': ['cat', 'dog', 'bird', 'fish', 'lion', 'elephant', 'tiger', 'bear'],
      'food': ['apple', 'banana', 'pizza', 'cake', 'milk', 'water', 'bread', 'cheese'],
    },
    'es': {
      'greetings': ['hola', 'buenos días', 'buenas tardes', 'buenas noches'],
      'colors': ['rojo', 'azul', 'verde', 'amarillo', 'naranja', 'morado', 'rosa', 'negro', 'blanco'],
      'numbers': ['uno', 'dos', 'tres', 'cuatro', 'cinco', 'seis', 'siete', 'ocho', 'nueve', 'diez'],
      'family': ['mamá', 'papá', 'hermano', 'hermana', 'familia', 'abuela', 'abuelo'],
      'animals': ['gato', 'perro', 'pájaro', 'pez', 'león', 'elefante', 'tigre', 'oso'],
      'food': ['manzana', 'plátano', 'pizza', 'pastel', 'leche', 'agua', 'pan', 'queso'],
    },
  };
  
  /// Initialize the enhanced NLP system
  static Future<void> initialize({String language = 'en'}) async {
    try {
      // Initialize Speech-to-Text
      await _speechToText.initialize();
      
      // Initialize Text-to-Speech
      await _flutterTts.setLanguage(language == 'en' ? "en-US" : "es-ES");
      await _flutterTts.setPitch(1.2);
      await _flutterTts.setSpeechRate(0.7);
      
      // Set up TTS voice for kids
      List<dynamic> voices = await _flutterTts.getVoices;
      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman") || name.contains("natural")) &&
            locale.contains(language)) {
          await _flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          break;
        }
      }
    } catch (e) {
      print('Error initializing enhanced NLP system: $e');
    }
  }
  
  /// Assess pronunciation accuracy
  static Future<PronunciationAssessment> assessPronunciation({
    required String targetWord,
    required String spokenWord,
    required String language,
  }) async {
    try {
      // Normalize words
      final normalizedTarget = targetWord.toLowerCase().trim();
      final normalizedSpoken = spokenWord.toLowerCase().trim();
      
      // Calculate basic similarity
      final similarity = _calculateStringSimilarity(normalizedTarget, normalizedSpoken);
      
      // Analyze phonetic patterns
      final phoneticAnalysis = _analyzePhoneticPatterns(normalizedTarget, normalizedSpoken);
      
      // Calculate pronunciation score
      final pronunciationScore = _calculatePronunciationScore(
        similarity,
        phoneticAnalysis,
        normalizedTarget,
        normalizedSpoken,
      );
      
      // Generate feedback
      final feedback = _generatePronunciationFeedback(
        pronunciationScore,
        phoneticAnalysis,
        normalizedTarget,
        normalizedSpoken,
      );
      
      // Suggest improvements
      final suggestions = _generateImprovementSuggestions(
        phoneticAnalysis,
        normalizedTarget,
        normalizedSpoken,
      );
      
      return PronunciationAssessment(
        targetWord: targetWord,
        spokenWord: spokenWord,
        accuracy: pronunciationScore,
        similarity: similarity,
        phoneticAnalysis: phoneticAnalysis,
        feedback: feedback,
        suggestions: suggestions,
        isCorrect: pronunciationScore >= 0.8,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error assessing pronunciation: $e');
      return PronunciationAssessment(
        targetWord: targetWord,
        spokenWord: spokenWord,
        accuracy: 0.0,
        similarity: 0.0,
        phoneticAnalysis: {},
        feedback: 'Unable to assess pronunciation',
        suggestions: ['Try speaking more clearly'],
        isCorrect: false,
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Calculate string similarity
  static double _calculateStringSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    final longer = str1.length > str2.length ? str1 : str2;
    final shorter = str1.length > str2.length ? str2 : str1;
    
    if (longer.length == 0) return 1.0;
    
    final editDistance = _levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }
  
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String str1, String str2) {
    final matrix = List.generate(
      str1.length + 1,
      (i) => List.generate(str2.length + 1, (j) => 0),
    );
    
    for (int i = 0; i <= str1.length; i++) {
      matrix[i][0] = i;
    }
    
    for (int j = 0; j <= str2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= str1.length; i++) {
      for (int j = 1; j <= str2.length; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[str1.length][str2.length];
  }

  /// Analyze phonetic patterns in speech
  static Map<String, dynamic> _analyzePhoneticPatterns(String target, String spoken) {
    final analysis = <String, dynamic>{};
    
    // Check for common pronunciation issues
    for (final pattern in _pronunciationPatterns.keys) {
      final targetCount = target.split(pattern).length - 1;
      final spokenCount = spoken.split(pattern).length - 1;
      
      if (targetCount > 0) {
        analysis[pattern] = {
          'targetCount': targetCount,
          'spokenCount': spokenCount,
          'accuracy': spokenCount / targetCount,
          'issue': spokenCount < targetCount ? 'missing' : 
                   spokenCount > targetCount ? 'extra' : 'correct',
        };
      }
    }
    
    // Check for letter substitutions
    final substitutions = <String, String>{};
    for (int i = 0; i < min(target.length, spoken.length); i++) {
      if (target[i] != spoken[i]) {
        substitutions[target[i]] = spoken[i];
      }
    }
    analysis['substitutions'] = substitutions;
    
    // Check for missing or extra letters
    analysis['missingLetters'] = _findMissingLetters(target, spoken);
    analysis['extraLetters'] = _findExtraLetters(target, spoken);
    
    return analysis;
  }
  
  /// Calculate pronunciation score
  static double _calculatePronunciationScore(
    double similarity,
    Map<String, dynamic> phoneticAnalysis,
    String target,
    String spoken,
  ) {
    double score = similarity;
    
    // Adjust for phonetic patterns
    for (final pattern in phoneticAnalysis.keys) {
      if (pattern != 'substitutions' && pattern != 'missingLetters' && pattern != 'extraLetters') {
        final patternData = phoneticAnalysis[pattern] as Map<String, dynamic>;
        final accuracy = patternData['accuracy'] as double;
        score = (score + accuracy) / 2;
      }
    }
    
    // Penalize missing or extra letters
    final missingLetters = phoneticAnalysis['missingLetters'] as List<String>;
    final extraLetters = phoneticAnalysis['extraLetters'] as List<String>;
    
    if (missingLetters.isNotEmpty) {
      score -= missingLetters.length * 0.1;
    }
    
    if (extraLetters.isNotEmpty) {
      score -= extraLetters.length * 0.05;
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  /// Generate pronunciation feedback
  static String _generatePronunciationFeedback(
    double score,
    Map<String, dynamic> phoneticAnalysis,
    String target,
    String spoken,
  ) {
    if (score >= 0.9) {
      return "Perfect pronunciation! 🌟 You said '$target' beautifully!";
    } else if (score >= 0.8) {
      return "Great job! 🎉 You're very close to perfect pronunciation!";
    } else if (score >= 0.6) {
      return "Good effort! 💪 You're getting better at pronouncing '$target'!";
    } else if (score >= 0.4) {
      return "Keep practicing! 🌱 Try to focus on each sound in '$target'!";
    } else {
      return "Don't give up! 💙 Let's practice '$target' together!";
    }
  }
  
  /// Generate improvement suggestions
  static List<String> _generateImprovementSuggestions(
    Map<String, dynamic> phoneticAnalysis,
    String target,
    String spoken,
  ) {
    final suggestions = <String>[];
    
    // Check for specific phonetic issues
    for (final pattern in phoneticAnalysis.keys) {
      if (pattern != 'substitutions' && pattern != 'missingLetters' && pattern != 'extraLetters') {
        final patternData = phoneticAnalysis[pattern] as Map<String, dynamic>;
        final issue = patternData['issue'] as String;
        
        if (issue == 'missing') {
          suggestions.add("Try to pronounce the '$pattern' sound more clearly");
        } else if (issue == 'extra') {
          suggestions.add("Be careful not to add extra '$pattern' sounds");
        }
      }
    }
    
    // Check for missing letters
    final missingLetters = phoneticAnalysis['missingLetters'] as List<String>;
    if (missingLetters.isNotEmpty) {
      suggestions.add("Don't forget to pronounce: ${missingLetters.join(', ')}");
    }
    
    // Check for substitutions
    final substitutions = phoneticAnalysis['substitutions'] as Map<String, String>;
    if (substitutions.isNotEmpty) {
      for (final entry in substitutions.entries) {
        suggestions.add("Try saying '$entry.key' instead of '$entry.value'");
      }
    }
    
    // Add general suggestions if no specific issues found
    if (suggestions.isEmpty) {
      suggestions.add("Speak slowly and clearly");
      suggestions.add("Listen to the word and repeat it");
      suggestions.add("Practice each sound separately");
    }
    
    return suggestions;
  }
  
  /// Find missing letters
  static List<String> _findMissingLetters(String target, String spoken) {
    final missing = <String>[];
    final spokenChars = spoken.split('');
    
    for (final char in target.split('')) {
      if (!spokenChars.contains(char)) {
        missing.add(char);
      }
    }
    
    return missing;
  }
  
  /// Find extra letters
  static List<String> _findExtraLetters(String target, String spoken) {
    final extra = <String>[];
    final targetChars = target.split('');
    
    for (final char in spoken.split('')) {
      if (!targetChars.contains(char)) {
        extra.add(char);
      }
    }
    
    return extra;
  }
  
  /// Multi-language speech analysis
  static Future<MultiLanguageAnalysis> analyzeMultiLanguageSpeech({
    required String speechInput,
    required String currentLanguage,
    required List<String> supportedLanguages,
  }) async {
    try {
      String detectedLanguage = currentLanguage;
      double confidence = 0.8;
      final translations = <String, Map<String, dynamic>>{};
      final suggestions = <String>[];
      
      // Analyze speech in current language
      final currentAnalysis = _analyzeSpeechInLanguage(speechInput, currentLanguage);
      translations[currentLanguage] = currentAnalysis;
      
      // Try to detect if user switched languages
      for (final lang in supportedLanguages) {
        if (lang != currentLanguage) {
          final langAnalysis = _analyzeSpeechInLanguage(speechInput, lang);
          if (langAnalysis['confidence'] > 0.6) {
            detectedLanguage = lang;
            confidence = langAnalysis['confidence'];
            translations[lang] = langAnalysis;
          }
        }
      }
      
      // Generate suggestions
      final finalSuggestions = _generateLanguageSuggestions(
        MultiLanguageAnalysis(
          detectedLanguage: detectedLanguage,
          confidence: confidence,
          translations: translations,
          suggestions: suggestions,
          timestamp: DateTime.now(),
        ),
      );
      
      final analysis = MultiLanguageAnalysis(
        detectedLanguage: detectedLanguage,
        confidence: confidence,
        translations: translations,
        suggestions: finalSuggestions,
        timestamp: DateTime.now(),
      );
      
      return analysis;
    } catch (e) {
      print('Error analyzing multi-language speech: $e');
      return MultiLanguageAnalysis(
        detectedLanguage: currentLanguage,
        confidence: 0.0,
        translations: {},
        suggestions: ['Unable to analyze speech'],
        timestamp: DateTime.now(),
      );
    }
  }
  
  /// Analyze speech in specific language
  static Map<String, dynamic> _analyzeSpeechInLanguage(String speech, String language) {
    final keywords = _languageKeywords[language] ?? {};
    final speechLower = speech.toLowerCase();
    
    double confidence = 0.0;
    final detectedCategories = <String>[];
    
    for (final category in keywords.keys) {
      for (final keyword in keywords[category]!) {
        if (speechLower.contains(keyword)) {
          detectedCategories.add(category);
          confidence += 0.1;
        }
      }
    }
    
    return {
      'confidence': confidence.clamp(0.0, 1.0),
      'categories': detectedCategories,
      'keywords': keywords,
    };
  }
  
  /// Generate language suggestions
  static List<String> _generateLanguageSuggestions(MultiLanguageAnalysis analysis) {
    final suggestions = <String>[];
    
    if (analysis.confidence < 0.5) {
      suggestions.add("Try speaking more clearly");
      suggestions.add("Use simple words");
    }
    
    if (analysis.translations.length > 1) {
      suggestions.add("Great! You're using multiple languages!");
    }
    
    return suggestions;
  }
  
  /// Get phonetic representation of word
  static String getPhoneticRepresentation(String word) {
    return word.split('').map((char) => _phoneticMap[char.toLowerCase()] ?? char).join(' ');
  }
  
  /// Speak with pronunciation guidance
  static Future<void> speakWithGuidance(String text, {String language = 'en'}) async {
    try {
      await _flutterTts.setLanguage(language == 'en' ? "en-US" : "es-ES");
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking with guidance: $e');
    }
  }
  
  /// Start pronunciation practice session
  static Future<void> startPronunciationPractice({
    required String targetWord,
    required Function(PronunciationAssessment) onAssessment,
    required Function(String) onError,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      if (!await _speechToText.hasPermission) {
        onError("Speech permission not granted");
        return;
      }
      
      await _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            final spokenWord = result.recognizedWords;
            final assessment = await assessPronunciation(
              targetWord: targetWord,
              spokenWord: spokenWord,
              language: 'en',
            );
            onAssessment(assessment);
          }
        },
        listenFor: timeout,
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: "en_US",
        onSoundLevelChange: (level) {
          // Optional: Handle sound level changes
        },
      );
    } catch (e) {
      onError("Error starting pronunciation practice: $e");
    }
  }
  
  /// Stop pronunciation practice
  static Future<void> stopPronunciationPractice() async {
    await _speechToText.stop();
  }
}

/// Pronunciation Assessment Result
class PronunciationAssessment {
  final String targetWord;
  final String spokenWord;
  final double accuracy;
  final double similarity;
  final Map<String, dynamic> phoneticAnalysis;
  final String feedback;
  final List<String> suggestions;
  final bool isCorrect;
  final DateTime timestamp;

  PronunciationAssessment({
    required this.targetWord,
    required this.spokenWord,
    required this.accuracy,
    required this.similarity,
    required this.phoneticAnalysis,
    required this.feedback,
    required this.suggestions,
    required this.isCorrect,
    required this.timestamp,
  });
}

/// Multi-Language Analysis Result
class MultiLanguageAnalysis {
  final String detectedLanguage;
  final double confidence;
  final Map<String, Map<String, dynamic>> translations;
  final List<String> suggestions;
  final DateTime timestamp;

  MultiLanguageAnalysis({
    required this.detectedLanguage,
    required this.confidence,
    required this.translations,
    required this.suggestions,
    required this.timestamp,
  });
}

/// Pronunciation Practice Widget
class PronunciationPracticeWidget extends StatefulWidget {
  final String targetWord;
  final Function(PronunciationAssessment) onAssessment;
  final Function(String) onError;
  
  const PronunciationPracticeWidget({
    super.key,
    required this.targetWord,
    required this.onAssessment,
    required this.onError,
  });

  @override
  State<PronunciationPracticeWidget> createState() => _PronunciationPracticeWidgetState();
}

class _PronunciationPracticeWidgetState extends State<PronunciationPracticeWidget>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  PronunciationAssessment? _lastAssessment;
  
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
    await EnhancedNLPSystem.initialize();
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
    
    await EnhancedNLPSystem.startPronunciationPractice(
      targetWord: widget.targetWord,
      onAssessment: _handleAssessment,
      onError: _handleError,
    );
  }
  
  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    await EnhancedNLPSystem.stopPronunciationPractice();
    
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });
    
    _pulseController.stop();
  }
  
  void _handleAssessment(PronunciationAssessment assessment) {
    setState(() {
      _lastAssessment = assessment;
      _isProcessing = false;
    });
    
    widget.onAssessment(assessment);
  }
  
  void _handleError(String error) {
    setState(() {
      _isListening = false;
      _isProcessing = false;
    });
    
    _pulseController.stop();
    widget.onError(error);
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
                : const Color(0xFF6BCF7F)).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Practice: ${widget.targetWord}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          
          // Pronunciation Guide
          Text(
            "Phonetic: ${EnhancedNLPSystem.getPhoneticRepresentation(widget.targetWord)}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
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
                          color: Colors.black.withOpacity(0.2),
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
                    ? "Analyzing... 🤔"
                    : "Tap to practice! 🗣️",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
          
          // Assessment Results
          if (_lastAssessment != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    "Accuracy: ${(_lastAssessment!.accuracy * 100).round()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastAssessment!.feedback,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_lastAssessment!.suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      "Tip: ${_lastAssessment!.suggestions.first}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
