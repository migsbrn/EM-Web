import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

class QuizDetailPage extends StatefulWidget {
  final String category;

  const QuizDetailPage({super.key, required this.category});

  @override
  _QuizDetailPageState createState() => _QuizDetailPageState();
}

class _QuizDetailPageState extends State<QuizDetailPage> {
  
  /// Build image widget for image-based questions
  Widget _buildQuestionImage(String imageData) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageWidget(imageData),
      ),
    );
  }

  /// Build appropriate image widget based on image type
  Widget _buildImageWidget(String imageData) {
    // Check if it's a base64 image (starts with data:image)
    if (imageData.startsWith('data:image/')) {
      return Image.memory(
        base64Decode(imageData.split(',')[1]), // Remove the data:image/...;base64, prefix
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    } else {
      // It's an asset image
      return Image.asset(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
  }

  /// Build error widget for failed image loads
  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool? isCorrect;
  Map<String, dynamic>? quizData;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('contents')
        .where('type', isEqualTo: 'assessment')
        .where('category', isEqualTo: widget.category)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        quizData = snapshot.docs.first.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (quizData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: const Color(0xFF648BA2),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final questions = quizData!['questions'] as List<dynamic>? ?? [];
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFE9D5),
        appBar: AppBar(
          title: Text(quizData!['title'] ?? 'Quiz'),
          backgroundColor: const Color(0xFF648BA2),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = questions[currentQuestionIndex] as Map<String, dynamic>;
    final questionText = question['questionText'] ?? 'No question';
    final options = question['type'] == 'multiple_choice' ? (question['options'] as List<dynamic>?) ?? [] : [];
    final correctAnswer = question['correctAnswer'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      appBar: AppBar(
        title: Text(quizData!['title'] ?? 'Quiz'),
        backgroundColor: const Color(0xFF648BA2),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${currentQuestionIndex + 1} of ${questions.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4E69),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              color: const Color(0xFFD5D8C4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Image display for image-based questions
                    if ((question['usesImage'] == true && (question['imageUrl'] != null || question['imageBase64'] != null)) || 
                        question['image'] != null) ...[
                      _buildQuestionImage(question['imageBase64'] ?? question['imageUrl'] ?? question['image']),
                      const SizedBox(height: 16),
                    ],
                    if (question['type'] == 'multiple_choice') ...[
                      ...options.asMap().entries.map((entry) {
                        final option = entry.value as String;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedAnswer == option
                                  ? (isCorrect == true ? Colors.green : Colors.red)
                                  : const Color(0xFF648BA2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: selectedAnswer == null
                                ? () {
                                    setState(() {
                                      selectedAnswer = option;
                                      isCorrect = option == correctAnswer;
                                    });
                                  }
                                : null,
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      }),
                    ] else ...[
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            selectedAnswer = value;
                            isCorrect = value.trim().toLowerCase() == correctAnswer?.toLowerCase();
                          });
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Type your answer here',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                    if (selectedAnswer != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        isCorrect == true ? 'Correct!' : 'Incorrect. Try again!',
                        style: TextStyle(
                          color: isCorrect == true ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentQuestionIndex--;
                        selectedAnswer = null;
                        isCorrect = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A4E69),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Previous', style: TextStyle(color: Colors.white)),
                  ),
                ElevatedButton(
                  onPressed: () {
                    if (currentQuestionIndex < questions.length - 1) {
                      setState(() {
                        currentQuestionIndex++;
                        selectedAnswer = null;
                        isCorrect = null;
                      });
                    } else {
                      Navigator.pop(context); // Return to previous screen
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF648BA2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    currentQuestionIndex < questions.length - 1 ? 'Next' : 'Finish',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}