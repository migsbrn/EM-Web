import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ColorAssessment.dart';
import 'responsive_utils.dart';

class LearnColors extends StatefulWidget {
  final String nickname;
  const LearnColors({super.key, required this.nickname});

  @override
  _LearnColorsState createState() => _LearnColorsState();
}

class _LearnColorsState extends State<LearnColors>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  String? _animationDirection;

  final List<Map<String, dynamic>> items = [
    {
      'type': 'color',
      'name': 'Red',
      'color': Colors.red,
      'image': 'assets/red.png',
    },
    {
      'type': 'example',
      'description': 'An apple is red.',
      'color': Colors.red,
      'image': 'assets/app.png',
    },
    {
      'type': 'color',
      'name': 'Blue',
      'color': Colors.blue,
      'image': 'assets/blue.png',
    },
    {
      'type': 'example',
      'description': 'The sky is blue.',
      'color': Colors.blue,
      'image': 'assets/sky.jpg',
    },
    {
      'type': 'color',
      'name': 'Green',
      'color': Colors.green,
      'image': 'assets/green.png',
    },
    {
      'type': 'example',
      'description': 'Grass is green.',
      'color': Colors.green,
      'image': 'assets/grass.jpg',
    },
    {
      'type': 'color',
      'name': 'Yellow',
      'color': Colors.yellow,
      'image': 'assets/yellow.png',
    },
    {
      'type': 'example',
      'description': 'The sun is yellow.',
      'color': Colors.yellow,
      'image': 'assets/sun.jpg',
    },
    {
      'type': 'color',
      'name': 'Purple',
      'color': Colors.purple,
      'image': 'assets/purple.png',
    },
    {
      'type': 'example',
      'description': 'A grape is purple.',
      'color': Colors.purple,
      'image': 'assets/grape.png',
    },
    {
      'type': 'color',
      'name': 'Orange',
      'color': Colors.orange,
      'image': 'assets/orange_color.png',
    },
    {
      'type': 'example',
      'description': 'An orange is orange.',
      'color': Colors.orange,
      'image': 'assets/oranges.png',
    },
    {
      'type': 'color',
      'name': 'Pink',
      'color': Colors.pink,
      'image': 'assets/pink.png',
    },
    {
      'type': 'example',
      'description': 'A flower is pink.',
      'color': Colors.pink,
      'image': 'assets/flowers.png',
    },
  ];

  int currentIndex = 0;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _loadProgress();

    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _bounceController.reverse();
    });
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentIndex = prefs.getInt('colorIndex') ?? 0);
    _speakContent();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('colorIndex', currentIndex);
  }

  void _speakContent() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.4);
    await flutterTts.setPitch(1.0);
    final item = items[currentIndex];
    if (item['type'] == 'color') {
      await flutterTts.speak(item['name']);
    } else {
      await flutterTts.speak(item['description']);
    }
  }

  void _nextColor() async {
    if (currentIndex < items.length - 1) {
      setState(() {
        _animationDirection = 'next';
        currentIndex++;
      });
      _saveProgress();
      _bounceController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _speakContent();
    } else {
      await flutterTts.stop();
      _showCompletionDialog();
    }
  }

  void _previousColor() async {
    if (currentIndex > 0) {
      setState(() {
        _animationDirection = 'previous';
        currentIndex--;
      });
      _saveProgress();
      _bounceController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      _speakContent();
    }
  }

  void _showCompletionDialog() async {
    await flutterTts.stop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFFF6DC),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/star.png', height: 150, width: 150),
                      const SizedBox(height: 20),
                      const Text(
                        "What would you like to do next?",
                        style: TextStyle(
                          fontSize: 26,
                          color: Color(0xFF4C4F6B),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.setInt('colorIndex', 0);
                            setState(() {
                              _animationDirection = null;
                              currentIndex = 0;
                            });
                            Navigator.pop(context);
                            _speakContent();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4C4F6B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text(
                            "Restart Module",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ColorAssessment(
                                      nickname: widget.nickname,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3C7E71),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: const Text(
                            "Take Assessment",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = items[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0DC),
      body: SafeArea(
        child: ResponsiveWidget(
          mobile: _buildLayout(context, item),
          tablet: _buildLayout(context, item),
          desktop: _buildLayout(context, item),
          largeDesktop: _buildLayout(context, item),
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context, Map<String, dynamic> item) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildBackButton(context),
            const SizedBox(height: 20),
            _buildTitle(context),
            const SizedBox(height: 20),
            _buildContentCard(context, item),
            const SizedBox(height: 30),
            _buildNavigationButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF648BA2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Go Back',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return const Center(
      child: Text(
        'Learn the Colors',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A4E69),
          fontSize: 36,
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, Map<String, dynamic> item) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth * 0.6;
    final imageWidth = screenWidth * 0.8;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin:
              _animationDirection == 'next'
                  ? const Offset(1.0, 0.0)
                  : _animationDirection == 'previous'
                  ? const Offset(-1.0, 0.0)
                  : Offset.zero,
          end: Offset.zero,
        ).animate(animation);
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: _bounceAnimation, child: child),
          ),
        );
      },
      child: Container(
        key: ValueKey<int>(currentIndex),
        width: screenWidth * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title + Volume
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['type'] == 'color' ? item['name'] : 'Example',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4E69),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(
                    Icons.volume_up,
                    size: 40,
                    color: Color(0xFF648BA2),
                  ),
                  onPressed: _speakContent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                item['image'],
                height: imageHeight,
                width: imageWidth,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.red,
                      size: 80,
                    ),
              ),
            ),
            const SizedBox(height: 24),

            // Description
            if (item['type'] == 'example') ...[
              Text(
                item['description'],
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A4E69),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: currentIndex == 0 ? null : _previousColor,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                currentIndex == 0 ? Colors.grey : const Color(0xFF648BA2),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Previous',
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: _nextColor,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF648BA2),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Next',
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    _bounceController.dispose();
    super.dispose();
  }
}
