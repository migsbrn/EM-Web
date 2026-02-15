import 'package:flutter/material.dart';
import 'responsive_design_system.dart';
import 'responsive_navigation_system.dart';
import 'responsive_assessment_components.dart';
import 'responsive_media_components.dart';
import 'responsive_theme_system.dart';
import 'sped_friendly_messages.dart';
import 'enhanced_feedback_system.dart';
import 'enhanced_answer_highlighting.dart';

/// Responsive App Implementation Guide
/// This file demonstrates how to implement responsive design throughout the app
class ResponsiveAppImplementation {
  
  /// Example of implementing a responsive main app
  static Widget buildResponsiveApp() {
    return ResponsiveThemeWidget(
      child: MaterialApp(
        title: 'EasyMind - Responsive Learning App',
        theme: ResponsiveThemeSystem.getResponsiveTheme(
          // This would be passed from context in real implementation
          null as BuildContext, // Placeholder
        ),
        home: const ResponsiveHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
  
  /// Example responsive home page
  static Widget buildResponsiveHomePage() {
    return ResponsiveMainLayout(
      title: "EasyMind Learning",
      currentIndex: 0,
      onNavigationChanged: (index) {
        // Handle navigation
      },
      child: ResponsiveLayoutBuilder(
        builder: (context, screenType, constraints) {
          return ResponsiveList(
            children: [
              // Welcome section
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      "Welcome to EasyMind! 🌟",
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      "Your personalized learning journey starts here",
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              
              // Quick actions
              ResponsiveText(
                "Quick Actions",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              ResponsiveSpacing(height: 16),
              
              ResponsiveGrid(
                children: [
                  _buildQuickActionCard(
                    "Start Learning",
                    Icons.school,
                    Colors.blue,
                    () {},
                  ),
                  _buildQuickActionCard(
                    "Take Assessment",
                    Icons.quiz,
                    Colors.green,
                    () {},
                  ),
                  _buildQuickActionCard(
                    "Play Games",
                    Icons.games,
                    Colors.orange,
                    () {},
                  ),
                  _buildQuickActionCard(
                    "View Progress",
                    Icons.trending_up,
                    Colors.purple,
                    () {},
                  ),
                ],
              ),
              
              ResponsiveSpacing(height: 24),
              
              // Recent activities
              ResponsiveText(
                "Recent Activities",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              ResponsiveSpacing(height: 16),
              
              ResponsiveList(
                children: [
                  _buildActivityCard(
                    "Completed Alphabet Assessment",
                    "Great job! You scored 85%",
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildActivityCard(
                    "Started Color Learning",
                    "Continue your progress",
                    Icons.play_circle,
                    Colors.blue,
                  ),
                  _buildActivityCard(
                    "Earned New Badge",
                    "Reading Star Badge unlocked!",
                    Icons.star,
                    Colors.amber,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Example responsive assessment page
  static Widget buildResponsiveAssessmentPage() {
    return ResponsiveAssessmentBase(
      title: "Alphabet Assessment",
      description: "Let's test your alphabet knowledge!",
      currentQuestion: 0,
      totalQuestions: 5,
      onBack: () {},
      onSkip: () {},
      child: ResponsiveMultipleChoiceAssessment(
        question: "What letter comes after 'A'?",
        options: ["B", "C", "D", "E"],
        correctAnswer: "B",
        onAnswerSelected: (answer) {
          // Handle answer selection
        },
        explanation: "The letter 'B' comes right after 'A' in the alphabet! 🔤",
      ),
    );
  }
  
  /// Example responsive lesson page
  static Widget buildResponsiveLessonPage() {
    return ResponsiveMainLayout(
      title: "Learning Colors",
      child: ResponsiveLayoutBuilder(
        builder: (context, screenType, constraints) {
          return ResponsiveList(
            children: [
              // Lesson content
              ResponsiveCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      "Learning Colors",
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    ResponsiveSpacing(height: 16),
                    
                    // Interactive content
                    ResponsiveImage(
                      imagePath: "https://example.com/colors-image.jpg",
                      height: 0.3,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    
                    ResponsiveSpacing(height: 16),
                    
                    ResponsiveText(
                      "Colors are everywhere around us! Let's learn about the basic colors.",
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    
                    ResponsiveSpacing(height: 16),
                    
                    // Color examples
                    ResponsiveGrid(
                      crossAxisCount: 2,
                      children: [
                        _buildColorExample("Red", Colors.red),
                        _buildColorExample("Blue", Colors.blue),
                        _buildColorExample("Green", Colors.green),
                        _buildColorExample("Yellow", Colors.yellow),
                      ],
                    ),
                  ],
                ),
              ),
              
              ResponsiveSpacing(height: 24),
              
              // Action buttons
              ResponsiveButton(
                text: "Start Practice",
                onPressed: () {},
                backgroundColor: Colors.green,
                icon: Icons.play_arrow,
              ),
              ResponsiveSpacing(height: 12),
              ResponsiveButton(
                text: "Take Quiz",
                onPressed: () {},
                backgroundColor: Colors.orange,
                icon: Icons.quiz,
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// Example responsive profile page
  static Widget buildResponsiveProfilePage() {
    return ResponsiveMainLayout(
      title: "My Profile",
      child: ResponsiveLayoutBuilder(
        builder: (context, screenType, constraints) {
          return ResponsiveList(
            children: [
              // Profile header
              ResponsiveCard(
                child: Column(
                  children: [
                    // Profile picture
                    CircleAvatar(
                      radius: ResponsiveDesignSystem.getResponsiveIconSize(context, 40),
                      backgroundColor: Colors.blue,
                      child: ResponsiveIcon(
                        icon: Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    ResponsiveSpacing(height: 16),
                    
                    ResponsiveText(
                      "Student Name",
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    
                    ResponsiveSpacing(height: 8),
                    
                    ResponsiveText(
                      "Learning Level: Intermediate",
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              
              ResponsiveSpacing(height: 24),
              
              // Statistics
              ResponsiveText(
                "Learning Statistics",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              
              ResponsiveSpacing(height: 16),
              
              ResponsiveGrid(
                children: [
                  _buildStatCard("Lessons Completed", "24", Icons.school, Colors.blue),
                  _buildStatCard("Assessments Taken", "12", Icons.quiz, Colors.green),
                  _buildStatCard("Games Played", "8", Icons.games, Colors.orange),
                  _buildStatCard("Badges Earned", "5", Icons.star, Colors.amber),
                ],
              ),
              
              ResponsiveSpacing(height: 24),
              
              // Settings
              ResponsiveText(
                "Settings",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              
              ResponsiveSpacing(height: 16),
              
              ResponsiveList(
                children: [
                  _buildSettingItem("Notifications", Icons.notifications, () {}),
                  _buildSettingItem("Sound Effects", Icons.volume_up, () {}),
                  _buildSettingItem("Learning Preferences", Icons.settings, () {}),
                  _buildSettingItem("Help & Support", Icons.help, () {}),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Helper methods for building UI components
  static Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        children: [
          ResponsiveIcon(
            icon: icon,
            size: 32,
            color: color,
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            title,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  static Widget _buildActivityCard(String title, String subtitle, IconData icon, Color color) {
    return ResponsiveCard(
      child: Row(
        children: [
          ResponsiveIcon(
            icon: icon,
            size: 24,
            color: color,
          ),
          ResponsiveSpacing(width: 12, isVertical: false),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                ResponsiveSpacing(height: 4),
                ResponsiveText(
                  subtitle,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildColorExample(String colorName, Color color) {
    return ResponsiveCard(
      child: Column(
        children: [
          Container(
            width: ResponsiveDesignSystem.getResponsiveWidth(null as BuildContext, 0.2),
            height: ResponsiveDesignSystem.getResponsiveHeight(null as BuildContext, 0.1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            colorName,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
  
  static Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ResponsiveCard(
      child: Column(
        children: [
          ResponsiveIcon(
            icon: icon,
            size: 24,
            color: color,
          ),
          ResponsiveSpacing(height: 8),
          ResponsiveText(
            value,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ResponsiveSpacing(height: 4),
          ResponsiveText(
            title,
            fontSize: 12,
            color: Colors.grey.shade600,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  static Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return ResponsiveCard(
      onTap: onTap,
      child: Row(
        children: [
          ResponsiveIcon(
            icon: icon,
            size: 24,
            color: Colors.grey.shade600,
          ),
          ResponsiveSpacing(width: 12, isVertical: false),
          Expanded(
            child: ResponsiveText(
              title,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          ResponsiveIcon(
            icon: Icons.chevron_right,
            size: 20,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}

/// Responsive Home Page Implementation
class ResponsiveHomePage extends StatefulWidget {
  const ResponsiveHomePage({super.key});
  
  @override
  State<ResponsiveHomePage> createState() => _ResponsiveHomePageState();
}

class _ResponsiveHomePageState extends State<ResponsiveHomePage> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveMainLayout(
      currentIndex: _currentIndex,
      onNavigationChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      child: _buildCurrentPage(),
    );
  }
  
  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return ResponsiveAppImplementation.buildResponsiveHomePage();
      case 1:
        return ResponsiveAppImplementation.buildResponsiveLessonPage();
      case 2:
        return ResponsiveAppImplementation.buildResponsiveAssessmentPage();
      case 3:
        return ResponsiveAppImplementation.buildResponsiveProfilePage();
      default:
        return ResponsiveAppImplementation.buildResponsiveHomePage();
    }
  }
}

/// Responsive Implementation Examples
class ResponsiveImplementationExamples {
  
  /// Example 1: Basic responsive container
  static Widget basicResponsiveContainer() {
    return ResponsiveContainer(
      child: ResponsiveText(
        "This text adapts to screen size!",
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
  
  /// Example 2: Responsive button with different behaviors
  static Widget responsiveButtonExample() {
    return ResponsiveButton(
      text: "Tap Me!",
      onPressed: () {
        // Handle button press
      },
      backgroundColor: Colors.blue,
      icon: Icons.touch_app,
    );
  }
  
  /// Example 3: Responsive card with adaptive content
  static Widget responsiveCardExample() {
    return ResponsiveCard(
      child: Column(
        children: [
          ResponsiveText(
            "Adaptive Card",
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          ResponsiveSpacing(height: 16),
          ResponsiveText(
            "This card adjusts its padding, margins, and styling based on screen size.",
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
  
  /// Example 4: Responsive grid with adaptive columns
  static Widget responsiveGridExample() {
    return ResponsiveGrid(
      children: List.generate(6, (index) {
        return ResponsiveCard(
          child: Center(
            child: ResponsiveText(
              "Item ${index + 1}",
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }),
    );
  }
  
  /// Example 5: Responsive image with adaptive sizing
  static Widget responsiveImageExample() {
    return ResponsiveImage(
      imagePath: "https://example.com/sample-image.jpg",
      width: 0.8,
      height: 0.3,
      borderRadius: BorderRadius.circular(12),
      fit: BoxFit.cover,
    );
  }
  
  /// Example 6: Responsive assessment with adaptive feedback
  static Widget responsiveAssessmentExample() {
    return ResponsiveMultipleChoiceAssessment(
      question: "What is the capital of France?",
      options: ["London", "Paris", "Berlin", "Madrid"],
      correctAnswer: "Paris",
      onAnswerSelected: (answer) {
        // Show SPED-friendly feedback
        final feedback = SPEDFriendlyMessages.getRandomSuccessMessage();
        // Display feedback to user
      },
      explanation: "Paris is the beautiful capital city of France! 🇫🇷",
    );
  }
  
  /// Example 7: Responsive navigation with adaptive layout
  static Widget responsiveNavigationExample() {
    return ResponsiveMainLayout(
      title: "Responsive Navigation",
      currentIndex: 0,
      onNavigationChanged: (index) {
        // Handle navigation
      },
      child: ResponsiveText(
        "This navigation adapts to screen size!",
        fontSize: 18,
        textAlign: TextAlign.center,
      ),
    );
  }
  
  /// Example 8: Responsive theme with adaptive styling
  static Widget responsiveThemeExample() {
    return ResponsiveThemeBuilder(
      builder: (context, theme, isDark) {
        return ResponsiveCard(
          child: Column(
            children: [
              ResponsiveText(
                "Theme Example",
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              ResponsiveSpacing(height: 16),
              ResponsiveText(
                "This theme adapts to screen size and provides consistent styling.",
                fontSize: 14,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ],
          ),
        );
      },
    );
  }
}
