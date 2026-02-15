import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sped_friendly_messages.dart';
import 'enhanced_feedback_system.dart';

/// Reading Comprehension System
/// Provides AI-powered comprehension checking with follow-up questions
class ReadingComprehensionSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Generate comprehension questions based on reading content
  static Future<List<ComprehensionQuestion>> generateComprehensionQuestions({
    required String content,
    required String contentType,
    required String studentLevel,
  }) async {
    // This would integrate with an AI service in a real implementation
    // For now, we'll create sample questions based on content analysis
    
    final questions = <ComprehensionQuestion>[];
    
    // Analyze content and generate appropriate questions
    if (contentType.toLowerCase().contains('story')) {
      questions.addAll(_generateStoryQuestions(content));
    } else if (contentType.toLowerCase().contains('lesson')) {
      questions.addAll(_generateLessonQuestions(content));
    } else if (contentType.toLowerCase().contains('poem')) {
      questions.addAll(_generatePoemQuestions(content));
    } else {
      questions.addAll(_generateGeneralQuestions(content));
    }
    
    // Adjust difficulty based on student level
    return _adjustDifficulty(questions, studentLevel);
  }
  
  /// Check comprehension using AI analysis
  static Future<ComprehensionResult> checkComprehension({
    required String content,
    required List<ComprehensionAnswer> answers,
    required String studentName,
  }) async {
    // This would integrate with an AI service in a real implementation
    // For now, we'll provide basic analysis
    
    final correctAnswers = answers.where((answer) => answer.isCorrect).length;
    final totalQuestions = answers.length;
    final percentage = (correctAnswers / totalQuestions) * 100;
    
    final comprehensionLevel = _determineComprehensionLevel(percentage);
    final feedback = _generateComprehensionFeedback(
      percentage,
      answers,
      studentName,
    );
    
    return ComprehensionResult(
      percentage: percentage,
      comprehensionLevel: comprehensionLevel,
      feedback: feedback,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      detailedAnalysis: _generateDetailedAnalysis(answers),
    );
  }
  
  /// Save comprehension results
  static Future<void> saveComprehensionResults({
    required String studentName,
    required String contentId,
    required ComprehensionResult result,
    required String contentType,
  }) async {
    try {
      await _firestore.collection('readingComprehension').add({
        'studentName': studentName,
        'contentId': contentId,
        'contentType': contentType,
        'percentage': result.percentage,
        'comprehensionLevel': result.comprehensionLevel,
        'correctAnswers': result.correctAnswers,
        'totalQuestions': result.totalQuestions,
        'detailedAnalysis': result.detailedAnalysis,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving comprehension results: $e');
    }
  }
  
  // Helper methods
  static List<ComprehensionQuestion> _generateStoryQuestions(String content) {
    return [
      ComprehensionQuestion(
        id: '1',
        question: "What is the main character's name?",
        type: QuestionType.multipleChoice,
        options: ["The story doesn't say", "It's not mentioned", "We don't know", "Not given"],
        correctAnswer: "The story doesn't say",
        explanation: "Sometimes stories don't tell us everything! 🤔",
        difficulty: QuestionDifficulty.easy,
      ),
      ComprehensionQuestion(
        id: '2',
        question: "What happened at the beginning of the story?",
        type: QuestionType.multipleChoice,
        options: ["Something exciting", "Something sad", "Something happy", "Something interesting"],
        correctAnswer: "Something interesting",
        explanation: "Stories usually start with something interesting to catch our attention! 📖",
        difficulty: QuestionDifficulty.medium,
      ),
      ComprehensionQuestion(
        id: '3',
        question: "How did the story end?",
        type: QuestionType.openEnded,
        correctAnswer: "The story ended happily",
        explanation: "Good stories usually have happy endings! 😊",
        difficulty: QuestionDifficulty.easy,
      ),
    ];
  }
  
  static List<ComprehensionQuestion> _generateLessonQuestions(String content) {
    return [
      ComprehensionQuestion(
        id: '1',
        question: "What is the main topic of this lesson?",
        type: QuestionType.multipleChoice,
        options: ["Learning", "Teaching", "Studying", "Understanding"],
        correctAnswer: "Learning",
        explanation: "Lessons are all about learning new things! 📚",
        difficulty: QuestionDifficulty.easy,
      ),
      ComprehensionQuestion(
        id: '2',
        question: "What did you learn from this lesson?",
        type: QuestionType.openEnded,
        correctAnswer: "Something new and useful",
        explanation: "Every lesson teaches us something new! 🌟",
        difficulty: QuestionDifficulty.medium,
      ),
    ];
  }
  
  static List<ComprehensionQuestion> _generatePoemQuestions(String content) {
    return [
      ComprehensionQuestion(
        id: '1',
        question: "What feeling does this poem give you?",
        type: QuestionType.multipleChoice,
        options: ["Happy", "Sad", "Excited", "Peaceful"],
        correctAnswer: "Happy",
        explanation: "Poems can make us feel many different emotions! 💖",
        difficulty: QuestionDifficulty.easy,
      ),
      ComprehensionQuestion(
        id: '2',
        question: "What do you think the poem is about?",
        type: QuestionType.openEnded,
        correctAnswer: "Something beautiful",
        explanation: "Poems are often about beautiful things! 🌸",
        difficulty: QuestionDifficulty.medium,
      ),
    ];
  }
  
  static List<ComprehensionQuestion> _generateGeneralQuestions(String content) {
    return [
      ComprehensionQuestion(
        id: '1',
        question: "What is this text about?",
        type: QuestionType.multipleChoice,
        options: ["Something important", "Something interesting", "Something useful", "Something fun"],
        correctAnswer: "Something important",
        explanation: "Texts usually tell us about important things! 📖",
        difficulty: QuestionDifficulty.easy,
      ),
      ComprehensionQuestion(
        id: '2',
        question: "What did you understand from reading this?",
        type: QuestionType.openEnded,
        correctAnswer: "Something meaningful",
        explanation: "Reading helps us understand many things! 🧠",
        difficulty: QuestionDifficulty.medium,
      ),
    ];
  }
  
  static List<ComprehensionQuestion> _adjustDifficulty(
    List<ComprehensionQuestion> questions,
    String studentLevel,
  ) {
    // Adjust questions based on student level
    switch (studentLevel.toLowerCase()) {
      case 'beginner':
        return questions.where((q) => q.difficulty == QuestionDifficulty.easy).toList();
      case 'intermediate':
        return questions.where((q) => q.difficulty != QuestionDifficulty.hard).toList();
      case 'advanced':
        return questions;
      default:
        return questions.where((q) => q.difficulty == QuestionDifficulty.easy).toList();
    }
  }
  
  static String _determineComprehensionLevel(double percentage) {
    if (percentage >= 90) return 'excellent';
    if (percentage >= 80) return 'good';
    if (percentage >= 70) return 'satisfactory';
    if (percentage >= 60) return 'needs_improvement';
    return 'needs_support';
  }
  
  static String _generateComprehensionFeedback(
    double percentage,
    List<ComprehensionAnswer> answers,
    String studentName,
  ) {
    if (percentage >= 90) {
      return "Wow, $studentName! You understood everything perfectly! 🌟";
    } else if (percentage >= 80) {
      return "Great job, $studentName! You understood most of it! 🎉";
    } else if (percentage >= 70) {
      return "Good work, $studentName! You're understanding better! 📚";
    } else if (percentage >= 60) {
      return "Nice try, $studentName! Keep practicing! 💪";
    } else {
      return "You're doing great, $studentName! Reading takes practice! 🌈";
    }
  }
  
  static String _generateDetailedAnalysis(List<ComprehensionAnswer> answers) {
    final correctAnswers = answers.where((answer) => answer.isCorrect).length;
    final totalQuestions = answers.length;
    
    if (correctAnswers == totalQuestions) {
      return "Perfect comprehension! You understood everything! 🌟";
    } else if (correctAnswers >= totalQuestions * 0.8) {
      return "Great comprehension! You understood most of it! 🎉";
    } else if (correctAnswers >= totalQuestions * 0.6) {
      return "Good comprehension! You're getting better! 📚";
    } else {
      return "Keep practicing! Reading comprehension improves with practice! 💪";
    }
  }
}

/// Data classes
class ComprehensionQuestion {
  final String id;
  final String question;
  final QuestionType type;
  final List<String>? options;
  final String correctAnswer;
  final String explanation;
  final QuestionDifficulty difficulty;
  
  ComprehensionQuestion({
    required this.id,
    required this.question,
    required this.type,
    this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });
}

class ComprehensionAnswer {
  final String questionId;
  final String answer;
  final bool isCorrect;
  final DateTime timestamp;
  
  ComprehensionAnswer({
    required this.questionId,
    required this.answer,
    required this.isCorrect,
    required this.timestamp,
  });
}

class ComprehensionResult {
  final double percentage;
  final String comprehensionLevel;
  final String feedback;
  final int correctAnswers;
  final int totalQuestions;
  final String detailedAnalysis;
  
  ComprehensionResult({
    required this.percentage,
    required this.comprehensionLevel,
    required this.feedback,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.detailedAnalysis,
  });
}

enum QuestionType {
  multipleChoice,
  openEnded,
  trueFalse,
}

enum QuestionDifficulty {
  easy,
  medium,
  hard,
}

/// Reading Comprehension Widget
class ReadingComprehensionWidget extends StatefulWidget {
  final String content;
  final String contentType;
  final String studentName;
  final String studentLevel;
  final VoidCallback? onComplete;
  
  const ReadingComprehensionWidget({
    super.key,
    required this.content,
    required this.contentType,
    required this.studentName,
    required this.studentLevel,
    this.onComplete,
  });
  
  @override
  State<ReadingComprehensionWidget> createState() => _ReadingComprehensionWidgetState();
}

class _ReadingComprehensionWidgetState extends State<ReadingComprehensionWidget> {
  List<ComprehensionQuestion> _questions = [];
  List<ComprehensionAnswer> _answers = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _showResults = false;
  ComprehensionResult? _result;
  
  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }
  
  Future<void> _loadQuestions() async {
    try {
      final questions = await ReadingComprehensionSystem.generateComprehensionQuestions(
        content: widget.content,
        contentType: widget.contentType,
        studentLevel: widget.studentLevel,
      );
      
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading questions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _answerQuestion(String answer) {
    final question = _questions[_currentQuestionIndex];
    final isCorrect = answer.toLowerCase() == question.correctAnswer.toLowerCase();
    
    setState(() {
      _answers.add(ComprehensionAnswer(
        questionId: question.id,
        answer: answer,
        isCorrect: isCorrect,
        timestamp: DateTime.now(),
      ));
    });
    
    _showAnswerFeedback(question, answer, isCorrect);
  }
  
  void _showAnswerFeedback(ComprehensionQuestion question, String answer, bool isCorrect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isCorrect ? "Great job! 🌟" : "Good try! 💪",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              question.explanation,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isCorrect 
                  ? SPEDFriendlyMessages.getRandomSuccessMessage()
                  : SPEDFriendlyMessages.getRandomGentleCorrectionMessage(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _nextQuestion();
            },
            child: const Text(
              "Continue",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _completeAssessment();
    }
  }
  
  Future<void> _completeAssessment() async {
    try {
      final result = await ReadingComprehensionSystem.checkComprehension(
        content: widget.content,
        answers: _answers,
        studentName: widget.studentName,
      );
      
      await ReadingComprehensionSystem.saveComprehensionResults(
        studentName: widget.studentName,
        contentId: 'content_${DateTime.now().millisecondsSinceEpoch}',
        result: result,
        contentType: widget.contentType,
      );
      
      setState(() {
        _result = result;
        _showResults = true;
      });
    } catch (e) {
      print('Error completing assessment: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Preparing questions...",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    if (_showResults && _result != null) {
      return _buildResults();
    }
    
    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          "No questions available",
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return _buildQuestion();
  }
  
  Widget _buildQuestion() {
    final question = _questions[_currentQuestionIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          
          // Question
          Text(
            "Question ${_currentQuestionIndex + 1} of ${_questions.length}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          
          // Answer options
          if (question.type == QuestionType.multipleChoice) ...[
            ...question.options!.map((option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _answerQuestion(option),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            )),
          ] else if (question.type == QuestionType.openEnded) ...[
            TextField(
              decoration: InputDecoration(
                hintText: "Type your answer here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (value) => _answerQuestion(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Get answer from text field
                final answer = "Student's answer"; // This would be from the text field
                _answerQuestion(answer);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Submit Answer",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildResults() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Results header
          Text(
            "Reading Comprehension Results",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Score display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Text(
                  "${_result!.correctAnswers}/${_result!.totalQuestions}",
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  "${_result!.percentage.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _result!.feedback,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Detailed analysis
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              _result!.detailedAnalysis,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          // Continue button
          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Continue Learning",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
