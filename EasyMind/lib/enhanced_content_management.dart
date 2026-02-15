import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced Content Management System
/// Provides better organization, tracking, and personalization of learning content
class EnhancedContentManagementSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Content types and their properties
  static const Map<String, ContentTypeInfo> contentTypes = {
    'lesson': ContentTypeInfo(
      name: 'Lesson',
      icon: Icons.school,
      color: Colors.blue,
      description: 'Educational content to learn new concepts',
    ),
    'assessment': ContentTypeInfo(
      name: 'Assessment',
      icon: Icons.quiz,
      color: Colors.green,
      description: 'Tests to check understanding',
    ),
    'activity': ContentTypeInfo(
      name: 'Activity',
      icon: Icons.games,
      color: Colors.orange,
      description: 'Interactive learning activities',
    ),
    'game': ContentTypeInfo(
      name: 'Game',
      icon: Icons.videogame_asset,
      color: Colors.purple,
      description: 'Fun games for learning',
    ),
    'story': ContentTypeInfo(
      name: 'Story',
      icon: Icons.menu_book,
      color: Colors.pink,
      description: 'Reading stories and comprehension',
    ),
  };
  
  /// Difficulty levels
  static const Map<String, DifficultyLevel> difficultyLevels = {
    'beginner': DifficultyLevel(
      name: 'Beginner',
      color: Colors.green,
      description: 'Easy content for new learners',
      minAge: 3,
      maxAge: 6,
    ),
    'intermediate': DifficultyLevel(
      name: 'Intermediate',
      color: Colors.orange,
      description: 'Moderate difficulty content',
      minAge: 6,
      maxAge: 10,
    ),
    'advanced': DifficultyLevel(
      name: 'Advanced',
      color: Colors.red,
      description: 'Challenging content for experienced learners',
      minAge: 10,
      maxAge: 15,
    ),
  };
  
  /// Learning styles
  static const Map<String, LearningStyle> learningStyles = {
    'visual': LearningStyle(
      name: 'Visual',
      icon: Icons.visibility,
      color: Colors.blue,
      description: 'Learn through images, charts, and visual aids',
    ),
    'auditory': LearningStyle(
      name: 'Auditory',
      icon: Icons.hearing,
      color: Colors.green,
      description: 'Learn through listening and sound',
    ),
    'kinesthetic': LearningStyle(
      name: 'Kinesthetic',
      icon: Icons.touch_app,
      color: Colors.orange,
      description: 'Learn through movement and touch',
    ),
    'reading': LearningStyle(
      name: 'Reading/Writing',
      icon: Icons.edit,
      color: Colors.purple,
      description: 'Learn through reading and writing',
    ),
  };
  
  /// Get personalized content recommendations
  static Future<List<ContentItem>> getPersonalizedContent({
    required String studentName,
    required String studentLevel,
    required List<String> preferredLearningStyles,
    required List<String> completedContent,
    required List<String> skippedContent,
    int limit = 10,
  }) async {
    try {
      // Get student's learning profile
      final learningProfile = await _getStudentLearningProfile(studentName);
      
      // Get all available content
      final allContent = await _getAllContent();
      
      // Filter and rank content based on personalization
      final personalizedContent = _rankContentByPersonalization(
        allContent,
        learningProfile,
        studentLevel,
        preferredLearningStyles,
        completedContent,
        skippedContent,
      );
      
      return personalizedContent.take(limit).toList();
    } catch (e) {
      print('Error getting personalized content: $e');
      return [];
    }
  }
  
  /// Track content completion
  static Future<void> trackContentCompletion({
    required String studentName,
    required String contentId,
    required String contentType,
    required double score,
    required int timeSpent,
    required String difficulty,
  }) async {
    try {
      await _firestore.collection('contentCompletions').add({
        'studentName': studentName,
        'contentId': contentId,
        'contentType': contentType,
        'score': score,
        'timeSpent': timeSpent,
        'difficulty': difficulty,
        'completedAt': FieldValue.serverTimestamp(),
        'sessionId': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      
      // Update student's learning profile
      await _updateStudentLearningProfile(studentName, contentId, contentType, score);
    } catch (e) {
      print('Error tracking content completion: $e');
    }
  }
  
  /// Get content progress for a student
  static Future<ContentProgress> getContentProgress(String studentName) async {
    try {
      final completions = await _firestore
          .collection('contentCompletions')
          .where('studentName', isEqualTo: studentName)
          .get();
      
      final totalContent = await _getAllContent();
      final completedContent = completions.docs.map((doc) => doc.data()['contentId']).toSet();
      
      final progressByType = <String, int>{};
      final progressByDifficulty = <String, int>{};
      final averageScores = <String, double>{};
      
      for (final completion in completions.docs) {
        final data = completion.data();
        final type = data['contentType'];
        final difficulty = data['difficulty'];
        final score = data['score']?.toDouble() ?? 0.0;
        
        progressByType[type] = (progressByType[type] ?? 0) + 1;
        progressByDifficulty[difficulty] = (progressByDifficulty[difficulty] ?? 0) + 1;
        averageScores[type] = (averageScores[type] ?? 0.0) + score;
      }
      
      // Calculate averages
      for (final type in averageScores.keys) {
        final count = progressByType[type] ?? 1;
        averageScores[type] = averageScores[type]! / count;
      }
      
      return ContentProgress(
        totalContent: totalContent.length,
        completedContent: completedContent.length,
        completionRate: totalContent.isNotEmpty ? (completedContent.length / totalContent.length) * 100 : 0.0,
        progressByType: progressByType,
        progressByDifficulty: progressByDifficulty,
        averageScores: averageScores,
        lastActivity: completions.docs.isNotEmpty 
            ? completions.docs.first.data()['completedAt']?.toDate()
            : null,
      );
    } catch (e) {
      print('Error getting content progress: $e');
      return ContentProgress(
        totalContent: 0,
        completedContent: 0,
        completionRate: 0.0,
        progressByType: {},
        progressByDifficulty: {},
        averageScores: {},
        lastActivity: null,
      );
    }
  }
  
  /// Get content recommendations based on learning gaps
  static Future<List<ContentItem>> getLearningGapRecommendations({
    required String studentName,
    required String studentLevel,
  }) async {
    try {
      final progress = await getContentProgress(studentName);
      final allContent = await _getAllContent();
      
      // Identify learning gaps based on low scores or missing content
      final gaps = <String, double>{};
      
      for (final type in contentTypes.keys) {
        final averageScore = progress.averageScores[type] ?? 0.0;
        if (averageScore < 70.0) {
          gaps[type] = 70.0 - averageScore;
        }
      }
      
      // Sort gaps by severity
      final sortedGaps = gaps.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      // Get content recommendations for each gap
      final recommendations = <ContentItem>[];
      for (final gap in sortedGaps) {
        final typeContent = allContent.where((c) => c.type == gap.key).toList();
        recommendations.addAll(typeContent.take(3));
      }
      
      return recommendations;
    } catch (e) {
      print('Error getting learning gap recommendations: $e');
      return [];
    }
  }
  
  /// Update content difficulty based on performance
  static Future<void> updateContentDifficulty({
    required String studentName,
    required String contentId,
    required double performance,
  }) async {
    try {
      // Get current difficulty
      final contentDoc = await _firestore.collection('contents').doc(contentId).get();
      if (!contentDoc.exists) return;
      
      final currentDifficulty = contentDoc.data()?['difficulty'] ?? 'beginner';
      String newDifficulty = currentDifficulty;
      
      // Adjust difficulty based on performance
      if (performance >= 90 && currentDifficulty == 'beginner') {
        newDifficulty = 'intermediate';
      } else if (performance >= 90 && currentDifficulty == 'intermediate') {
        newDifficulty = 'advanced';
      } else if (performance < 60 && currentDifficulty == 'advanced') {
        newDifficulty = 'intermediate';
      } else if (performance < 60 && currentDifficulty == 'intermediate') {
        newDifficulty = 'beginner';
      }
      
      // Update content difficulty
      if (newDifficulty != currentDifficulty) {
        await _firestore.collection('contents').doc(contentId).update({
          'difficulty': newDifficulty,
          'lastDifficultyUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating content difficulty: $e');
    }
  }
  
  // Helper methods
  static Future<StudentLearningProfile> _getStudentLearningProfile(String studentName) async {
    try {
      final doc = await _firestore.collection('studentProfiles').doc(studentName).get();
      if (doc.exists) {
        final data = doc.data()!;
        return StudentLearningProfile(
          name: studentName,
          preferredLearningStyles: List<String>.from(data['preferredLearningStyles'] ?? []),
          strengths: List<String>.from(data['strengths'] ?? []),
          weaknesses: List<String>.from(data['weaknesses'] ?? []),
          averagePerformance: data['averagePerformance']?.toDouble() ?? 0.0,
          totalContentCompleted: data['totalContentCompleted'] ?? 0,
          lastUpdated: data['lastUpdated']?.toDate(),
        );
      }
    } catch (e) {
      print('Error getting student learning profile: $e');
    }
    
    return StudentLearningProfile(
      name: studentName,
      preferredLearningStyles: [],
      strengths: [],
      weaknesses: [],
      averagePerformance: 0.0,
      totalContentCompleted: 0,
      lastUpdated: null,
    );
  }
  
  static Future<void> _updateStudentLearningProfile(
    String studentName,
    String contentId,
    String contentType,
    double score,
  ) async {
    try {
      await _firestore.collection('studentProfiles').doc(studentName).set({
        'name': studentName,
        'totalContentCompleted': FieldValue.increment(1),
        'averagePerformance': FieldValue.increment(score),
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastContentType': contentType,
        'lastContentId': contentId,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating student learning profile: $e');
    }
  }
  
  static Future<List<ContentItem>> _getAllContent() async {
    try {
      // Query the 'contents' collection (where teacher uploads are saved)
      // Filter for content that is ready for student app
      final querySnapshot = await _firestore
          .collection('contents')
          .where('studentAppReady', isEqualTo: true)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();
      
      print('Fetched ${querySnapshot.docs.length} content items from Firestore');
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Processing content: ${data['title']} (${data['type']})');
        
        return ContentItem(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          type: data['type'] ?? 'lesson',
          difficulty: data['difficulty'] ?? 'beginner',
          learningStyles: List<String>.from(data['learningStyles'] ?? []),
          description: data['description'] ?? '',
          estimatedTime: data['estimatedTime'] ?? 10,
          tags: List<String>.from(data['tags'] ?? []),
          createdAt: data['createdAt']?.toDate(),
          updatedAt: data['updatedAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting all content: $e');
      return [];
    }
  }
  
  static List<ContentItem> _rankContentByPersonalization(
    List<ContentItem> allContent,
    StudentLearningProfile profile,
    String studentLevel,
    List<String> preferredLearningStyles,
    List<String> completedContent,
    List<String> skippedContent,
  ) {
    final rankedContent = allContent.map((content) {
      double score = 0.0;
      
      // Base score
      score += 10.0;
      
      // Difficulty matching
      if (content.difficulty == studentLevel) {
        score += 20.0;
      } else if (_isDifficultyAppropriate(content.difficulty, studentLevel)) {
        score += 10.0;
      }
      
      // Learning style matching
      for (final style in preferredLearningStyles) {
        if (content.learningStyles.contains(style)) {
          score += 15.0;
        }
      }
      
      // Avoid completed content
      if (completedContent.contains(content.id)) {
        score -= 50.0;
      }
      
      // Avoid recently skipped content
      if (skippedContent.contains(content.id)) {
        score -= 30.0;
      }
      
      // Content type preferences (based on performance)
      if (profile.strengths.contains(content.type)) {
        score += 10.0;
      }
      if (profile.weaknesses.contains(content.type)) {
        score += 5.0; // Still include but with lower priority
      }
      
      return MapEntry(content, score);
    }).toList();
    
    // Sort by score
    rankedContent.sort((a, b) => b.value.compareTo(a.value));
    
    return rankedContent.map((entry) => entry.key).toList();
  }
  
  static bool _isDifficultyAppropriate(String contentDifficulty, String studentLevel) {
    final difficultyOrder = ['beginner', 'intermediate', 'advanced'];
    final contentIndex = difficultyOrder.indexOf(contentDifficulty);
    final studentIndex = difficultyOrder.indexOf(studentLevel);
    
    return (contentIndex - studentIndex).abs() <= 1;
  }
}

/// Data classes
class ContentTypeInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  
  const ContentTypeInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class DifficultyLevel {
  final String name;
  final Color color;
  final String description;
  final int minAge;
  final int maxAge;
  
  const DifficultyLevel({
    required this.name,
    required this.color,
    required this.description,
    required this.minAge,
    required this.maxAge,
  });
}

class LearningStyle {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  
  const LearningStyle({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class ContentItem {
  final String id;
  final String title;
  final String type;
  final String difficulty;
  final List<String> learningStyles;
  final String description;
  final int estimatedTime;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  ContentItem({
    required this.id,
    required this.title,
    required this.type,
    required this.difficulty,
    required this.learningStyles,
    required this.description,
    required this.estimatedTime,
    required this.tags,
    this.createdAt,
    this.updatedAt,
  });
}

class StudentLearningProfile {
  final String name;
  final List<String> preferredLearningStyles;
  final List<String> strengths;
  final List<String> weaknesses;
  final double averagePerformance;
  final int totalContentCompleted;
  final DateTime? lastUpdated;
  
  StudentLearningProfile({
    required this.name,
    required this.preferredLearningStyles,
    required this.strengths,
    required this.weaknesses,
    required this.averagePerformance,
    required this.totalContentCompleted,
    this.lastUpdated,
  });
}

class ContentProgress {
  final int totalContent;
  final int completedContent;
  final double completionRate;
  final Map<String, int> progressByType;
  final Map<String, int> progressByDifficulty;
  final Map<String, double> averageScores;
  final DateTime? lastActivity;
  
  ContentProgress({
    required this.totalContent,
    required this.completedContent,
    required this.completionRate,
    required this.progressByType,
    required this.progressByDifficulty,
    required this.averageScores,
    this.lastActivity,
  });
}

/// Enhanced Content Management Widget
class EnhancedContentManagementWidget extends StatefulWidget {
  final String studentName;
  final String studentLevel;
  final Function(ContentItem)? onContentSelected;
  
  const EnhancedContentManagementWidget({
    super.key,
    required this.studentName,
    required this.studentLevel,
    this.onContentSelected,
  });
  
  @override
  State<EnhancedContentManagementWidget> createState() => _EnhancedContentManagementWidgetState();
}

class _EnhancedContentManagementWidgetState extends State<EnhancedContentManagementWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<ContentItem> _personalizedContent = [];
  List<ContentItem> _gapRecommendations = [];
  ContentProgress? _progress;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContent();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadContent() async {
    try {
      final personalizedContent = await EnhancedContentManagementSystem.getPersonalizedContent(
        studentName: widget.studentName,
        studentLevel: widget.studentLevel,
        preferredLearningStyles: ['visual', 'auditory'], // This would come from student profile
        completedContent: [], // This would come from completion tracking
        skippedContent: [], // This would come from skip tracking
      );
      
      final gapRecommendations = await EnhancedContentManagementSystem.getLearningGapRecommendations(
        studentName: widget.studentName,
        studentLevel: widget.studentLevel,
      );
      
      final progress = await EnhancedContentManagementSystem.getContentProgress(widget.studentName);
      
      setState(() {
        _personalizedContent = personalizedContent;
        _gapRecommendations = gapRecommendations;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Recommended", icon: Icon(Icons.star)),
            Tab(text: "Learning Gaps", icon: Icon(Icons.school)),
            Tab(text: "Progress", icon: Icon(Icons.trending_up)),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalizedContent(),
              _buildGapRecommendations(),
              _buildProgressView(),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPersonalizedContent() {
    if (_personalizedContent.isEmpty) {
      return const Center(
        child: Text(
          "No personalized content available",
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _personalizedContent.length,
      itemBuilder: (context, index) {
        final content = _personalizedContent[index];
        return _buildContentCard(content);
      },
    );
  }
  
  Widget _buildGapRecommendations() {
    if (_gapRecommendations.isEmpty) {
      return const Center(
        child: Text(
          "No learning gaps identified",
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _gapRecommendations.length,
      itemBuilder: (context, index) {
        final content = _gapRecommendations[index];
        return _buildContentCard(content, isGapRecommendation: true);
      },
    );
  }
  
  Widget _buildProgressView() {
    if (_progress == null) {
      return const Center(
        child: Text(
          "No progress data available",
          style: TextStyle(fontSize: 18),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall progress
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overall Progress",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _progress!.completionRate / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_progress!.completionRate.toStringAsFixed(1)}% Complete",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${_progress!.completedContent} of ${_progress!.totalContent} content completed",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Progress by type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Progress by Content Type",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._progress!.progressByType.entries.map((entry) {
                    final type = entry.key;
                    final count = entry.value;
                    final typeInfo = EnhancedContentManagementSystem.contentTypes[type];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            typeInfo?.icon ?? Icons.help,
                            color: typeInfo?.color ?? Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typeInfo?.name ?? type,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            "$count completed",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Average scores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Average Scores",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._progress!.averageScores.entries.map((entry) {
                    final type = entry.key;
                    final score = entry.value;
                    final typeInfo = EnhancedContentManagementSystem.contentTypes[type];
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            typeInfo?.icon ?? Icons.help,
                            color: typeInfo?.color ?? Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typeInfo?.name ?? type,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          Text(
                            "${score.toStringAsFixed(1)}%",
                            style: TextStyle(
                              fontSize: 14,
                              color: score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentCard(ContentItem content, {bool isGapRecommendation = false}) {
    final typeInfo = EnhancedContentManagementSystem.contentTypes[content.type];
    final difficultyInfo = EnhancedContentManagementSystem.difficultyLevels[content.difficulty];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => widget.onContentSelected?.call(content),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    typeInfo?.icon ?? Icons.help,
                    color: typeInfo?.color ?? Colors.grey,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (isGapRecommendation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Learning Gap",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                content.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags
              Row(
                children: [
                  // Difficulty
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: difficultyInfo?.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      difficultyInfo?.name ?? content.difficulty,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: difficultyInfo?.color ?? Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Estimated time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${content.estimatedTime} min",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  
                  // Learning styles
                  ...content.learningStyles.take(2).map((style) {
                    final styleInfo = EnhancedContentManagementSystem.learningStyles[style];
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        styleInfo?.icon ?? Icons.help,
                        color: styleInfo?.color ?? Colors.grey,
                        size: 16,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
