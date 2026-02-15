import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'MyFamilyAssessment.dart';
import 'visit_tracking_system.dart';
import 'functional_academics.dart';

class LearnMyFamily extends StatefulWidget {
  final String nickname;
  const LearnMyFamily({super.key, required this.nickname});

  @override
  _LearnMyFamilyState createState() => _LearnMyFamilyState();
}

class _LearnMyFamilyState extends State<LearnMyFamily>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final VisitTrackingSystem _visitTrackingSystem = VisitTrackingSystem();
  String? _animationDirection;

  final List<Map<String, String>> familyItems = [
    {
      'type': 'example',
      'description': 'I live in a house with my mother and father.',
      'image': 'assets/happy.jpg',
    },
    {
      'type': 'example',
      'description': 'My sister and I play with our toys after school.',
      'image': 'assets/playing.jpg',
    },
    {
      'type': 'example',
      'description': 'My father cooks dinner when my mother is working.',
      'image': 'assets/cooking.jpg',
    },
    {
      'type': 'example',
      'description': 'We eat dinner together at the table every night.',
      'image': 'assets/eating_dinner.jpg',
    },
    {
      'type': 'example',
      'description': 'I love my family because they take care of me.',
      'image': 'assets/love_family.jpg',
    },
  ];

  int _currentIndex = 0;

  void _speakContent() async {
    await flutterTts.speak(familyItems[_currentIndex]['description'] ?? '');
  }

  void _nextItem() async {
    if (_currentIndex < familyItems.length - 1) {
      setState(() {
        _animationDirection = 'next';
        _currentIndex++;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      _speakContent();
    } else {
      await flutterTts.stop();
      _showCompletionDialog();
    }
  }

  void _previousItem() async {
    if (_currentIndex > 0) {
      setState(() {
        _animationDirection = 'previous';
        _currentIndex--;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      _speakContent();
    }
  }

  void _resetCurrentIndex() {
    setState(() {
      _animationDirection = null;
      _currentIndex = 0;
    });
  }

  void _showCompletionDialog() async {
    await flutterTts.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFFF6DC),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : 600,
              maxHeight: isSmallScreen ? screenWidth * 0.9 : 700,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : 24, 
                  vertical: isSmallScreen ? 20 : 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/star.png', 
                      height: isSmallScreen ? 80 : 120, 
                      width: isSmallScreen ? 80 : 120,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      "What would you like to do next?",
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 24,
                        color: Color(0xFF4C4F6B),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDialogButton(
                          label: "Restart Module",
                          color: const Color(0xFF4C4F6B),
                          isSmallScreen: isSmallScreen,
                          onPressed: () {
                            _resetCurrentIndex();
                            Navigator.pop(context);
                            _speakContent();
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        _buildDialogButton(
                          label: "Take Assessment",
                          color: const Color(0xFF3C7E71),
                          isSmallScreen: isSmallScreen,
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MyFamilyAssessment(nickname: widget.nickname),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogButton({
    required String label,
    required Color color,
    required bool isSmallScreen,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: isSmallScreen ? 50 : 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _trackVisit();
  }

  Future<void> _trackVisit() async {
    try {
      await _visitTrackingSystem.trackVisit(
        nickname: widget.nickname,
        itemType: 'lesson',
        itemName: 'My Family Lesson',
        moduleName: 'Functional Academics',
      );
      print('Visit tracked for My Family Lesson');
    } catch (e) {
      print('Error tracking visit: $e');
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = familyItems[_currentIndex];
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 30.0,
              vertical: isSmallScreen ? 10.0 : 20.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 10 : 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: isSmallScreen ? 120 : 180,
                    height: isSmallScreen ? 50 : 60,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FunctionalAcademicsPage(nickname: widget.nickname),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 10 : 15,
                          horizontal: isSmallScreen ? 12 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 10 : 20),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(
                      'My Family',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 28 : 45,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4E69),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 15 : 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    final offsetAnimation = Tween<Offset>(
                      begin:
                          _animationDirection == 'next'
                              ? const Offset(1.0, 0.0)
                              : _animationDirection == 'previous'
                              ? const Offset(-1.0, 0.0)
                              : const Offset(0.0, 0.0),
                      end: const Offset(0.0, 0.0),
                    ).animate(animation);
                    return SlideTransition(
                      position: offsetAnimation,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: Container(
                    key: ValueKey<int>(_currentIndex),
                    width: isSmallScreen ? screenWidth * 0.9 : 600,
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      minHeight: isSmallScreen ? 450 : 650,
                      maxHeight: isSmallScreen ? screenHeight * 0.75 : 650,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: isSmallScreen ? 50 : 60),
                            Flexible(
                              child: Image.asset(
                                item['image']!,
                                height: isSmallScreen ? 250 : 400,
                                width: isSmallScreen ? screenWidth * 0.8 : 450,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: isSmallScreen ? 250 : 400,
                                    width: isSmallScreen ? screenWidth * 0.8 : 450,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.image_not_supported,
                                      size: isSmallScreen ? 50 : 80,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 15 : 20),
                            Flexible(
                              child: Text(
                                item['description']!,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  color: Color(0xFF4A4E69),
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: isVerySmallScreen ? 3 : null,
                                overflow: isVerySmallScreen ? TextOverflow.ellipsis : null,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: Icon(
                              Icons.volume_up,
                              size: isSmallScreen ? 40 : 55,
                              color: Color(0xFF648BA2),
                            ),
                            onPressed: _speakContent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),
                Wrap(
                  spacing: isSmallScreen ? 10 : 20,
                  runSpacing: 10,
                  children: [
                    ElevatedButton(
                      onPressed: _currentIndex == 0 ? null : _previousItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _currentIndex == 0
                                ? Colors.grey
                                : const Color(0xFF648BA2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 30 : 50,
                          vertical: isSmallScreen ? 16 : 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _nextItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 30 : 50,
                          vertical: isSmallScreen ? 16 : 22,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
