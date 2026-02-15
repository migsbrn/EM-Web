import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:video_player/video_player.dart';
import 'DailyTasksAssessment.dart'; // <- Replace with your actual assessment page

class DailyTasksModulePage extends StatefulWidget {
  final String nickname;
  const DailyTasksModulePage({super.key, required this.nickname});

  @override
  State<DailyTasksModulePage> createState() => _DailyTasksModulePageState();
}

class _DailyTasksModulePageState extends State<DailyTasksModulePage>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late VideoPlayerController _videoController;
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {"text": "Maria wakes up early", "video": "assets/videos/wake.mp4"},
    {
      "text": "She gets the broom, and sweep the room",
      "video": "assets/videos/sweep.mp4",
    },
    {"text": "Then, she washes the dishes", "video": "assets/videos/wash.mp4"},
    {"text": "She uses soap and water", "video": "assets/videos/wash.mp4"},
    {"text": "Maria waters the plants", "video": "assets/videos/watering.mp4"},
    {
      "text": "Then, she sits down, and drinks cold water",
      "video": "assets/videos/drinking.mp4",
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupTTS();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeVideo();
  }

  Future<void> _setupTTS() async {
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setLanguage("en-US");
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      pages[currentIndex]["video"]!,
    );
    await _videoController.initialize();
    setState(() {});
    _videoController.play();
    _animationController.forward();
    _speakCurrentText();
  }

  Future<void> _speakCurrentText() async {
    await flutterTts.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    await flutterTts.speak(pages[currentIndex]["text"]!);
  }

  Future<void> _goToPage(int newIndex) async {
    if (newIndex < pages.length) {
      await flutterTts.stop();
      _animationController.reset();
      await _videoController.pause();
      await _videoController.dispose();

      setState(() {
        currentIndex = newIndex;
      });

      await _initializeVideo();
    }

    if (newIndex == pages.length) {
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    await flutterTts.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: const Color(0xFFFFF6DC),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/star.png', height: 150, width: 150),
                  const SizedBox(height: 20),
                  const Text(
                    "Great job! What would you like to do next?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4C4F6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        currentIndex = 0;
                      });
                      _initializeVideo();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C4F6B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                    ),
                    child: const Text(
                      "Restart Module",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyTasksAssessment(nickname: widget.nickname),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C7E71),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 40,
                      ),
                    ),
                    child: const Text(
                      "Take Assessment",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<bool> _onWillPop() async {
    if (currentIndex < pages.length - 1) {
      bool? shouldLeave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Are you sure?'),
              content: const Text(
                'Do you want to continue learning or skip to the assessment?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Continue Learning'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Skip to Assessment'),
                ),
              ],
            ),
      );
      if (shouldLeave == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DailyTasksAssessment(nickname: widget.nickname)),
        );
        return false;
      }
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    flutterTts.stop();
    _animationController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = pages[currentIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4EAD5),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    height: 60,
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () async {
                        await flutterTts.stop();
                        await _videoController.pause();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF648BA2),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 560,
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child:
                                  _videoController.value.isInitialized
                                      ? AspectRatio(
                                        aspectRatio:
                                            _videoController.value.aspectRatio,
                                        child: VideoPlayer(_videoController),
                                      )
                                      : const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.volume_up,
                                  color: Color(0xFF648BA2),
                                  size: 32,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    current["text"]!,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                      fontFamily: 'Roboto',
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(pages.length, (index) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 10,
                                width: currentIndex == index ? 12 : 8,
                                decoration: BoxDecoration(
                                  color:
                                      currentIndex == index
                                          ? const Color(0xFF648BA2)
                                          : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                            currentIndex > 0
                                ? () => _goToPage(currentIndex - 1)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF648BA2),
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Previous",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed:
                            currentIndex < pages.length
                                ? () => _goToPage(currentIndex + 1)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF648BA2),
                          disabledBackgroundColor: Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
