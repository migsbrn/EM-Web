import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'gamification_system.dart';
import 'adaptive_assessment_system.dart';
import 'memory_retention_system.dart';
import 'visit_tracking_system.dart';

/// Flashcard Game - A standalone educational game for spaced repetition learning
class FlashcardGame extends StatefulWidget {
  final String nickname;
  
  const FlashcardGame({
    super.key,
    required this.nickname,
  });

  @override
  State<FlashcardGame> createState() => _FlashcardGameState();
}

class _FlashcardGameState extends State<FlashcardGame>
    with TickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  late ConfettiController _confettiController;
  
  late AnimationController _flipController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _flipAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  
  List<Flashcard> _flashcards = [];
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isAnimating = false;
  Map<int, bool> _cardFlipStates = {}; // Track flip state for each card
  
  // Quiz variables
  bool _isQuizMode = false;
  List<QuizQuestion> _quizQuestions = [];
  int _currentQuizIndex = 0;
  int _correctAnswers = 0;
  int _totalQuizQuestions = 0;
  
  // Timer variables
  Timer? _quizTimer;
  int _timeRemaining = 0; // in seconds
  int _totalQuizTime = 300; // 5 minutes in seconds
  bool _isQuizCompleted = false;
  
  // Scoring system
  GamificationSystem? _gamificationSystem;
  GamificationResult? _lastReward;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTTS();
    _loadFlashcards();
    _initializeGamification();
    _trackVisit();
  }

  void _initializeAnimations() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.2);
  }

  Future<void> _loadFlashcards() async {
    try {
      // Create independent flashcard content
      _flashcards = _createIndependentFlashcards();
      
      // Shuffle flashcards for better learning
      _flashcards.shuffle();
      
      // Initialize flip states for all cards
      _cardFlipStates.clear();
      for (int i = 0; i < _flashcards.length; i++) {
        _cardFlipStates[i] = false;
      }
      
      if (_flashcards.isNotEmpty) {
        setState(() {
          _currentIndex = 0;
          _isFlipped = false;
        });
        _slideController.forward();
        _progressController.forward();
        _speakCard();
      }
    } catch (e) {
      print('Error loading flashcards: $e');
    }
  }

  List<Flashcard> _createIndependentFlashcards() {
    return [
      // Alphabet Flashcards - Kid Friendly
      Flashcard(
        id: 1,
        frontText: 'What letter comes after A?',
        backText: 'B',
        imagePath: 'assets/abc_blocks.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Alphabet',
        lessonData: {'moduleName': 'Alphabet'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 2,
        frontText: 'What letter comes after M?',
        backText: 'N',
        imagePath: 'assets/abc_blocks.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Alphabet',
        lessonData: {'moduleName': 'Alphabet'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 3,
        frontText: 'How many vowels are there?',
        backText: '5',
        imagePath: 'assets/abc_blocks.png',
        difficulty: FlashcardDifficulty.medium,
        category: 'Alphabet',
        lessonData: {'moduleName': 'Alphabet'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Numbers Flashcards - Kid Friendly
      Flashcard(
        id: 4,
        frontText: 'What is 2 + 3?',
        backText: '5',
        imagePath: 'assets/sta.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Numbers',
        lessonData: {'moduleName': 'Numbers'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 5,
        frontText: 'What is 7 - 4?',
        backText: '3',
        imagePath: 'assets/sta.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Numbers',
        lessonData: {'moduleName': 'Numbers'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 6,
        frontText: 'What is 2 + 2?',
        backText: '4',
        imagePath: 'assets/sta.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Numbers',
        lessonData: {'moduleName': 'Numbers'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Colors Flashcards - Kid Friendly
      Flashcard(
        id: 7,
        frontText: 'What color do you get when you mix red and blue?',
        backText: 'Purple',
        imagePath: 'assets/colors.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Colors',
        lessonData: {'moduleName': 'Colors'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 8,
        frontText: 'What color do you get when you mix yellow and blue?',
        backText: 'Green',
        imagePath: 'assets/colors.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Colors',
        lessonData: {'moduleName': 'Colors'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 9,
        frontText: 'What color do you get when you mix red and yellow?',
        backText: 'Orange',
        imagePath: 'assets/colors.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Colors',
        lessonData: {'moduleName': 'Colors'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Shapes Flashcards - Kid Friendly
      Flashcard(
        id: 10,
        frontText: 'How many sides does a triangle have?',
        backText: '3',
        imagePath: 'assets/shapes.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Shapes',
        lessonData: {'moduleName': 'Shapes'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 11,
        frontText: 'How many sides does a square have?',
        backText: '4',
        imagePath: 'assets/shapes.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Shapes',
        lessonData: {'moduleName': 'Shapes'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 12,
        frontText: 'What shape is round like a ball?',
        backText: 'Circle',
        imagePath: 'assets/shapes.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Shapes',
        lessonData: {'moduleName': 'Shapes'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Family Flashcards - Kid Friendly
      Flashcard(
        id: 13,
        frontText: 'Who is your mom\'s sister?',
        backText: 'Aunt',
        imagePath: 'assets/love_family.jpg',
        difficulty: FlashcardDifficulty.easy,
        category: 'Family',
        lessonData: {'moduleName': 'Family'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 14,
        frontText: 'Who is your dad\'s brother?',
        backText: 'Uncle',
        imagePath: 'assets/love_family.jpg',
        difficulty: FlashcardDifficulty.easy,
        category: 'Family',
        lessonData: {'moduleName': 'Family'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 15,
        frontText: 'Who are your mom\'s parents?',
        backText: 'Grandparents',
        imagePath: 'assets/love_family.jpg',
        difficulty: FlashcardDifficulty.medium,
        category: 'Family',
        lessonData: {'moduleName': 'Family'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Sounds Flashcards - Kid Friendly
      Flashcard(
        id: 16,
        frontText: 'What sound does a dog make?',
        backText: 'Woof',
        imagePath: 'assets/Sounds.webp',
        difficulty: FlashcardDifficulty.easy,
        category: 'Sounds',
        lessonData: {'moduleName': 'Sounds'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 17,
        frontText: 'What sound does a cat make?',
        backText: 'Meow',
        imagePath: 'assets/Sounds.webp',
        difficulty: FlashcardDifficulty.easy,
        category: 'Sounds',
        lessonData: {'moduleName': 'Sounds'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 18,
        frontText: 'What sound does a cow make?',
        backText: 'Moo',
        imagePath: 'assets/Sounds.webp',
        difficulty: FlashcardDifficulty.easy,
        category: 'Sounds',
        lessonData: {'moduleName': 'Sounds'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      
      // Word Formation Flashcards - Kid Friendly
      Flashcard(
        id: 19,
        frontText: 'How do you spell "___"?',
        backText: 'C-A-T',
        imagePath: 'assets/ake_words.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Word Formation',
        lessonData: {'moduleName': 'Word Formation'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 20,
        frontText: 'How do you spell "___"?',
        backText: 'D-O-G',
        imagePath: 'assets/ake_words.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Word Formation',
        lessonData: {'moduleName': 'Word Formation'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
      Flashcard(
        id: 21,
        frontText: 'How do you spell "___"?',
        backText: 'S-U-N',
        imagePath: 'assets/ake_words.png',
        difficulty: FlashcardDifficulty.easy,
        category: 'Word Formation',
        lessonData: {'moduleName': 'Word Formation'},
        lastReviewed: null,
        nextReview: DateTime.now(),
      ),
    ];
  }


  Future<void> _speakCard() async {
    if (_flashcards.isNotEmpty) {
      final card = _flashcards[_currentIndex];
      String textToSpeak;
      
      if (_isFlipped) {
        textToSpeak = card.backText;
      } else {
        // For spelling questions, speak the actual word instead of underscores
        if (card.category == 'Word Formation' && card.frontText.contains('___')) {
          // Replace underscores with the actual word for TTS
          if (card.backText == 'C-A-T') {
            textToSpeak = 'How do you spell "CAT"?';
          } else if (card.backText == 'D-O-G') {
            textToSpeak = 'How do you spell "DOG"?';
          } else if (card.backText == 'S-U-N') {
            textToSpeak = 'How do you spell "SUN"?';
          } else {
            textToSpeak = card.frontText;
          }
        } else {
          textToSpeak = card.frontText;
        }
      }
      
      await _flutterTts.speak(textToSpeak);
    }
  }

  Future<void> _flipCard() async {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
      _isFlipped = !_isFlipped;
      // Save the flip state for this card
      _cardFlipStates[_currentIndex] = _isFlipped;
    });
    
    // Play flip animation
    await _flipController.forward();
    
    // Reset animation for next flip
    _flipController.reset();
    
    await _speakCard();
    
    setState(() {
      _isAnimating = false;
    });
  }

  Future<void> _goToNextCard() async {
    if (_isAnimating) return;
    
    if (_currentIndex < _flashcards.length - 1) {
      setState(() {
        _isAnimating = true;
        _currentIndex++;
        // Restore the flip state for the new card, default to false if not set
        _isFlipped = _cardFlipStates[_currentIndex] ?? false;
      });
      
      // Reset and play slide animation
      _slideController.reset();
      await _slideController.forward();
      await _speakCard();
      
      setState(() {
        _isAnimating = false;
      });
    }
  }

  Future<void> _goToPreviousCard() async {
    if (_isAnimating) return;
    
    if (_currentIndex > 0) {
      setState(() {
        _isAnimating = true;
        _currentIndex--;
        // Restore the flip state for the previous card, default to false if not set
        _isFlipped = _cardFlipStates[_currentIndex] ?? false;
      });
      
      // Reset and play slide animation
      _slideController.reset();
      await _slideController.forward();
      await _speakCard();
      
      setState(() {
        _isAnimating = false;
      });
    }
  }


  void _showCompletionDialog() {
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF648BA2),
                const Color(0xFF648BA2).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 20),
              const Text(
                'You Did It! 🎊',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Stats Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Cards Viewed', '${_currentIndex + 1}'),
                    _buildStatRow('Total Cards', '${_flashcards.length}'),
                    _buildStatRow('XP Earned', '${_flashcards.length * 5}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Action Buttons
              Column(
                children: [
                  // Quiz Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _startQuiz();
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Ready to take a quiz? 🧠'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                  
                  // Other Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _restartSession();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Play Again! 🎮'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF648BA2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Home 🏠'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeGamification() async {
    try {
      _gamificationSystem = GamificationSystem();
      await _gamificationSystem!.initialize();
    } catch (e) {
      print('Error initializing gamification: $e');
    }
  }

  Future<void> _trackVisit() async {
    try {
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: 'game',
        itemName: 'Flashcard Game',
        moduleName: 'Games',
      );
      print('Visit tracked for Flashcard Game');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  void _startQuiz() {
    _quizQuestions = _createQuizQuestions();
    _totalQuizQuestions = _quizQuestions.length;
    _currentQuizIndex = 0;
    _correctAnswers = 0;
    _timeRemaining = _totalQuizTime;
    _isQuizCompleted = false;
    
    // Start timer
    _startQuizTimer();
    
    setState(() {
      _isQuizMode = true;
    });
  }

  void _startQuizTimer() {
    _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && !_isQuizCompleted) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _endQuiz();
      }
    });
  }

  void _endQuiz() {
    _quizTimer?.cancel();
    _isQuizCompleted = true;
    _saveQuizResults();
    setState(() {});
  }

  List<QuizQuestion> _createQuizQuestions() {
    return [
      // Alphabet Questions
      QuizQuestion(
        question: 'What letter comes after A?',
        options: ['B', 'C', 'D', 'E'],
        correctAnswer: 'B',
        category: 'Alphabet',
      ),
      QuizQuestion(
        question: 'What letter comes after M?',
        options: ['L', 'N', 'O', 'P'],
        correctAnswer: 'N',
        category: 'Alphabet',
      ),
      QuizQuestion(
        question: 'How many vowels are there?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '5',
        category: 'Alphabet',
      ),
      
      // Numbers Questions
      QuizQuestion(
        question: 'What is 2 + 3?',
        options: ['4', '5', '6', '7'],
        correctAnswer: '5',
        category: 'Numbers',
      ),
      QuizQuestion(
        question: 'What is 7 - 4?',
        options: ['2', '3', '4', '5'],
        correctAnswer: '3',
        category: 'Numbers',
      ),
      QuizQuestion(
        question: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        category: 'Numbers',
      ),
      
      // Colors Questions
      QuizQuestion(
        question: 'What color do you get when you mix red and blue?',
        options: ['Green', 'Purple', 'Orange', 'Yellow'],
        correctAnswer: 'Purple',
        category: 'Colors',
      ),
      QuizQuestion(
        question: 'What color do you get when you mix yellow and blue?',
        options: ['Red', 'Green', 'Purple', 'Orange'],
        correctAnswer: 'Green',
        category: 'Colors',
      ),
      QuizQuestion(
        question: 'What color do you get when you mix red and yellow?',
        options: ['Blue', 'Green', 'Orange', 'Purple'],
        correctAnswer: 'Orange',
        category: 'Colors',
      ),
      
      // Shapes Questions
      QuizQuestion(
        question: 'How many sides does a triangle have?',
        options: ['2', '3', '4', '5'],
        correctAnswer: '3',
        category: 'Shapes',
      ),
      QuizQuestion(
        question: 'How many sides does a square have?',
        options: ['3', '4', '5', '6'],
        correctAnswer: '4',
        category: 'Shapes',
      ),
      QuizQuestion(
        question: 'What shape is round like a ball?',
        options: ['Square', 'Triangle', 'Circle', 'Rectangle'],
        correctAnswer: 'Circle',
        category: 'Shapes',
      ),
      
      // Family Questions
      QuizQuestion(
        question: 'Who is your mom\'s sister?',
        options: ['Uncle', 'Aunt', 'Cousin', 'Grandma'],
        correctAnswer: 'Aunt',
        category: 'Family',
      ),
      QuizQuestion(
        question: 'Who is your dad\'s brother?',
        options: ['Aunt', 'Uncle', 'Cousin', 'Grandpa'],
        correctAnswer: 'Uncle',
        category: 'Family',
      ),
      QuizQuestion(
        question: 'Who are your mom\'s parents?',
        options: ['Aunts', 'Uncles', 'Grandparents', 'Cousins'],
        correctAnswer: 'Grandparents',
        category: 'Family',
      ),
      
      // Sounds Questions
      QuizQuestion(
        question: 'What sound does a dog make?',
        options: ['Meow', 'Woof', 'Moo', 'Chirp'],
        correctAnswer: 'Woof',
        category: 'Sounds',
      ),
      QuizQuestion(
        question: 'What sound does a cat make?',
        options: ['Woof', 'Meow', 'Moo', 'Quack'],
        correctAnswer: 'Meow',
        category: 'Sounds',
      ),
      QuizQuestion(
        question: 'What sound does a cow make?',
        options: ['Woof', 'Meow', 'Moo', 'Oink'],
        correctAnswer: 'Moo',
        category: 'Sounds',
      ),
      
      // Word Formation Questions
      QuizQuestion(
        question: 'How do you spell "CAT"?',
        options: ['C-A-T', 'K-A-T', 'C-E-T', 'K-E-T'],
        correctAnswer: 'C-A-T',
        category: 'Word Formation',
      ),
      QuizQuestion(
        question: 'How do you spell "DOG"?',
        options: ['D-O-G', 'B-O-G', 'D-U-G', 'B-U-G'],
        correctAnswer: 'D-O-G',
        category: 'Word Formation',
      ),
      QuizQuestion(
        question: 'How do you spell "SUN"?',
        options: ['S-U-N', 'S-O-N', 'S-A-N', 'S-E-N'],
        correctAnswer: 'S-U-N',
        category: 'Word Formation',
      ),
    ];
  }

  void _restartSession() {
    setState(() {
      _currentIndex = 0;
      _isFlipped = false;
      _isQuizMode = false;
    });
    
    // Reset all card flip states
    _cardFlipStates.clear();
    for (int i = 0; i < _flashcards.length; i++) {
      _cardFlipStates[i] = false;
    }
    
    _slideController.reset();
    _slideController.forward();
    _progressController.reset();
    _progressController.forward();
    _speakCard();
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    _flipController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _confettiController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Widget _buildQuizUI() {
    if (_currentQuizIndex >= _quizQuestions.length) {
      return _buildQuizResults();
    }
    
    final question = _quizQuestions[_currentQuizIndex];
    final progress = (_currentQuizIndex + 1) / _totalQuizQuestions;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: Text('🧠 Quiz (${_currentQuizIndex + 1}/$_totalQuizQuestions)'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Timer and Progress Bar
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Timer Display - Kid Friendly
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _timeRemaining < 60 ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: _timeRemaining < 60 ? Colors.red : Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_timeRemaining < 60 ? Colors.red : Colors.white).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _timeRemaining < 60 ? Icons.warning : Icons.timer,
                        color: _timeRemaining < 60 ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_timeRemaining),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _timeRemaining < 60 ? Colors.red : Colors.white,
                        ),
                      ),
                      if (_timeRemaining < 60) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '⏰',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // Progress Bar - Kid Friendly
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF9B59B6),
                      ),
                      minHeight: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Question
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF9B59B6),
                      const Color(0xFF8E44AD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Question Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.quiz,
                        size: 40,
                        color: Color(0xFF9B59B6),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Question Text
                    Text(
                      question.question,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Answer Options
                    ...question.options.map((option) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton(
                        onPressed: () => _selectAnswer(option, question.correctAnswer),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF9B59B6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )).toList(),
                    
                    const SizedBox(height: 10), // Extra space at bottom
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAnswer(String selectedAnswer, String correctAnswer) {
    if (selectedAnswer == correctAnswer) {
      _correctAnswers++;
      _confettiController.play();
    }
    
    setState(() {
      _currentQuizIndex++;
    });
    
    // Check if quiz is completed
    if (_currentQuizIndex >= _quizQuestions.length) {
      _endQuiz();
    }
  }

  Future<void> _saveQuizResults() async {
    try {
      final accuracy = (_correctAnswers / _totalQuizQuestions * 100).round();
      final timeSpent = _totalQuizTime - _timeRemaining;
      final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 0.1).round() : 0;
      final totalXP = (_correctAnswers * 15) + timeBonus;
      
      // Save to Adaptive Assessment System
      await AdaptiveAssessmentSystem.saveAssessmentResult(
        nickname: widget.nickname,
        assessmentType: 'flashcard_quiz',
        moduleName: 'Flashcard Quiz Game',
        totalQuestions: _totalQuizQuestions,
        correctAnswers: _correctAnswers,
        timeSpent: Duration(seconds: timeSpent),
        attemptedQuestions: _quizQuestions.map((q) => q.question).toList(),
        correctQuestions: _quizQuestions.where((q) => q.correctAnswer == q.correctAnswer).map((q) => q.question).toList(),
      );
      
      // Award XP based on performance
      final isPerfect = accuracy >= 90;
      final isGood = accuracy >= 70;
      final isFast = timeSpent < (_totalQuizTime * 0.7); // Completed in less than 70% of time
      
      String activity = 'flashcard_quiz';
      if (isPerfect && isFast) {
        activity = 'perfect_flashcard_quiz';
      } else if (isPerfect) {
        activity = 'perfect_flashcard_quiz';
      } else if (isGood) {
        activity = 'good_flashcard_quiz';
      }
      
      _lastReward = await _gamificationSystem!.awardXP(
        nickname: widget.nickname,
        activity: activity,
        metadata: {
          'module': 'flashcard_quiz',
          'accuracy': accuracy,
          'correctAnswers': _correctAnswers,
          'totalQuestions': _totalQuizQuestions,
          'timeSpent': timeSpent,
          'timeRemaining': _timeRemaining,
          'timeBonus': timeBonus,
          'totalXP': totalXP,
          'perfect': isPerfect,
          'fast': isFast,
        },
      );
      
      // Save to Memory Retention System
      await MemoryRetentionSystem().saveLessonCompletion(
        nickname: widget.nickname,
        moduleName: 'Flashcard Quiz',
        lessonType: 'Quiz Assessment',
        score: _correctAnswers,
        totalQuestions: _totalQuizQuestions,
        passed: accuracy >= 70,
      );
      
      print('Quiz results saved successfully');
    } catch (e) {
      print('Error saving quiz results: $e');
    }
  }

  Widget _buildQuizResults() {
    final accuracy = (_correctAnswers / _totalQuizQuestions * 100).round();
    final timeSpent = _totalQuizTime - _timeRemaining;
    final timeBonus = _timeRemaining > 0 ? (_timeRemaining * 0.1).round() : 0;
    final totalXP = (_correctAnswers * 15) + timeBonus;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: const Text('🎉 Quiz Complete!'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9B59B6),
                  const Color(0xFF8E44AD),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎉',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Complete! 🎊',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Questions Answered', '$_totalQuizQuestions'),
                    _buildStatRow('Correct Answers', '$_correctAnswers'),
                    _buildStatRow('Accuracy', '$accuracy%'),
                    _buildStatRow('Time Spent', _formatTime(timeSpent)),
                    _buildStatRow('Time Remaining', _formatTime(_timeRemaining)),
                    if (timeBonus > 0) _buildStatRow('Time Bonus', '+${timeBonus} XP'),
                    _buildStatRow('Total XP Earned', '$totalXP'),
                    if (_lastReward != null && _lastReward!.leveledUp)
                      _buildStatRow('Level Up!', '🎉'),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isQuizMode = false;
                        });
                        _restartSession();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Play Flashcards Again! 🎮'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9B59B6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Home 🏠'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuizMode) {
      return _buildQuizUI();
    }
    
    final currentCard = _flashcards[_currentIndex];
    final progress = (_currentIndex + 1) / _flashcards.length;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: Text('🎴 Flashcard Game (${_currentIndex + 1}/${_flashcards.length})'),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: _speakCard,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.yellow,
                Colors.purple,
              ],
            ),
          ),
          
          Column(
            children: [
              // Progress Bar
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF648BA2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation.value * progress,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF648BA2),
                          ),
                          minHeight: 8,
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Flashcard
              Expanded(
                child: AnimatedBuilder(
                  animation: _slideAnimation,
                  builder: (context, child) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        child: GestureDetector(
                          onTap: _flipCard,
                          child: AnimatedBuilder(
                            animation: _flipAnimation,
                            builder: (context, child) {
                              // Determine which side to show based on current flip state
                              final isShowingFront = !_isFlipped;
                              
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(_isFlipped ? 3.14159 : 0.0),
                                child: Container(
                                  width: double.infinity,
                                  height: 400,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 40,
                                        offset: const Offset(0, 16),
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: isShowingFront
                                        ? _buildCardFront(currentCard)
                                        : Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.identity()
                                              ..rotateY(3.14159),
                                            child: _buildCardBack(currentCard),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Navigation Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Navigation Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isAnimating || _currentIndex == 0 ? null : _goToPreviousCard,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous ⬅️'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isAnimating || _currentIndex == _flashcards.length - 1 ? null : _goToNextCard,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next ➡️'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Finish Game Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 15),
                      child: ElevatedButton.icon(
                        onPressed: _isAnimating ? null : _showCompletionDialog,
                        icon: const Icon(Icons.flag),
                        label: const Text('Finish Game 🏁'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardFront(Flashcard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A90E2), // Bright blue
            const Color(0xFF357ABD), // Darker blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Question Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.quiz,
              size: 50,
              color: const Color(0xFF4A90E2),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Question Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              card.frontText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Tap to flip hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Text(
              '👆 Tap to see answer',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Flashcard card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF50C878), // Bright green
            const Color(0xFF3CB371), // Darker green
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          
          // Answer Text - BIGGER for kids
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              card.backText,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
                letterSpacing: 2.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Tap to flip back hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Text(
              '👆 Tap to flip back',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flashcard data model
class Flashcard {
  final int id;
  final String frontText;
  final String backText;
  final String imagePath;
  final FlashcardDifficulty difficulty;
  final String category;
  final Map<String, dynamic> lessonData;
  final DateTime? lastReviewed;
  final DateTime nextReview;

  Flashcard({
    required this.id,
    required this.frontText,
    required this.backText,
    required this.imagePath,
    required this.difficulty,
    required this.category,
    required this.lessonData,
    this.lastReviewed,
    required this.nextReview,
  });
}

/// Quiz question data model
class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String category;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.category,
  });
}

/// Flashcard difficulty levels
enum FlashcardDifficulty {
  easy,
  medium,
  hard,
}
