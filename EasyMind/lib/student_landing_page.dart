import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'ReadingMaterialsPage.dart';
import 'GamesLandingPage.dart';
import 'unified_analytics_dashboard.dart';
import 'focus_system_demo.dart';
import 'app_initialization_service.dart';
import 'student_profile.dart';
import 'responsive_utils.dart';

class StudentLandingPage extends StatefulWidget {
  final String nickname;

  const StudentLandingPage({super.key, required this.nickname});

  @override
  _StudentLandingPageState createState() => _StudentLandingPageState();
}

class _StudentLandingPageState extends State<StudentLandingPage> {
  final GlobalKey _readingKey = GlobalKey();
  final GlobalKey _gamesKey = GlobalKey();
  final FlutterTts flutterTts = FlutterTts();

  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];
  bool tutorialShown = false;

  @override
  void initState() {
    super.initState();
    _setupTts();
    _initializeMemoryRetention();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkTutorialStatus();
      if (!tutorialShown) {
        _initTargets();
        _showTutorial();
      }
    });
  }

  Future<void> _initializeMemoryRetention() async {
    try {
      await AppInitializationService().initializeUser(widget.nickname);
    } catch (e) {
      print('Error initializing memory retention: $e');
    }
  }

  Future<void> _setupTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setPitch(1.3);
      await flutterTts.setSpeechRate(0.8);

      List<dynamic> voices = await flutterTts.getVoices;
      for (var voice in voices) {
        final name = (voice["name"] ?? "").toLowerCase();
        final locale = (voice["locale"] ?? "").toLowerCase();
        if ((name.contains("female") || name.contains("woman") || name.contains("natural")) &&
            locale.contains("en")) {
          await flutterTts.setVoice({
            "name": voice["name"],
            "locale": voice["locale"],
          });
          break;
        }
      }
    } catch (e) {
      print("TTS setup error: $e");
    }
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    tutorialShown = prefs.getBool('tutorialShown') ?? false;
  }

  void _markTutorialShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorialShown', true);
    setState(() {
      tutorialShown = true;
    });
  }

  void _initTargets() {
    targets = [
      TargetFocus(
        identify: "Reading",
        keyTarget: _readingKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                "Click here to access fun reading materials designed for you!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "Games",
        keyTarget: _gamesKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.7),
              child: const Text(
                "Click here to play educational games and test your skills!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    if (tutorialShown) return;

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      skipWidget: GestureDetector(
        onTap: () {
          tutorialCoachMark.finish();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          margin: const EdgeInsets.only(bottom: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'SKIP',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      onFinish: () => _markTutorialShown(),
      onClickTarget: (target) {},
    );

    tutorialCoachMark.show(context: context);
  }

  Future<void> _speak(String text) async {
    try {
      await flutterTts.speak(text);
    } catch (e) {
      print("TTS error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: SingleChildScrollView(
              child: Column(
                children: [
              
                  ResponsiveSpacing(mobileSpacing: 20),
                  _buildIconButtons(context),
                  ResponsiveSpacing(mobileSpacing: 30),
                  _buildMainCards(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  
                  ResponsiveSpacing(mobileSpacing: 30),
                  _buildIconButtons(context),
                  ResponsiveSpacing(mobileSpacing: 40),
                  _buildMainCards(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar for desktop
        Container(
          width: 300,
          color: const Color(0xFFFBEED9),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        
                        ResponsiveSpacing(mobileSpacing: 30),
                        _buildIconButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Center(
              child: _buildMainCards(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Sidebar for large desktop
        Container(
          width: 400,
          color: const Color(0xFFFBEED9),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Padding(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        
                        ResponsiveSpacing(mobileSpacing: 40),
                        _buildIconButtons(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main content area
        Expanded(
          child: Padding(
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Center(
              child: _buildMainCards(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final headerHeight = ResponsiveUtils.getResponsiveIconSize(
      context,
      mobile: 150,
      tablet: 180,
      desktop: 200,
      largeDesktop: 220,
    );

    return Stack(
      children: [
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: headerHeight,
            width: double.infinity,
            color: const Color(0xFFFBEED9),
          ),
        ),
        Positioned(
          top: ResponsiveUtils.getResponsiveSpacing(context, mobile: 40),
          left: ResponsiveUtils.getResponsiveHorizontalPadding(context).left,
          right: ResponsiveUtils.getResponsiveHorizontalPadding(context).right,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Hello, ${widget.nickname}! 👋',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A4E69),
                        fontFamily: 'Poppins',
                      ),
                      mobileFontSize: 28,
                      tabletFontSize: 36,
                      desktopFontSize: 42,
                      largeDesktopFontSize: 48,
                    ),
                    ResponsiveSpacing(mobileSpacing: 8),
                    ResponsiveText(
                      'Ready to learn and have fun? 🌟',
                      style: TextStyle(
                        color: const Color(0xFF648BA2),
                        fontFamily: 'Poppins',
                      ),
                      mobileFontSize: 14,
                      tabletFontSize: 16,
                      desktopFontSize: 18,
                      largeDesktopFontSize: 20,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _speak("My Profile");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfile(
                        nickname: widget.nickname,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
                  height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveIconSize(context, mobile: 25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ResponsiveIcon(
                    Icons.person,
                    color: const Color(0xFF648BA2),
                    mobileSize: 28,
                    tabletSize: 32,
                    desktopSize: 36,
                    largeDesktopSize: 40,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconButtons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
      runSpacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8),
      children: [
        _buildIconOnlyButton(
          icon: Icons.analytics,
          emoji: "📊",
          color: const Color(0xFF648BA2),
          title: "Analytics Hub",
          onPressed: () async {
            await _speak("Analytics Hub");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UnifiedAnalyticsDashboard(
                  nickname: widget.nickname,
                ),
              ),
            );
          },
          context: context,
        ),
        _buildIconOnlyButton(
          icon: Icons.timer,
          emoji: "⏰",
          color: const Color(0xFF9C27B0),
          title: "Focus System",
          onPressed: () async {
            await _speak("Focus System Demo");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FocusSystemDemo(
                  nickname: widget.nickname,
                ),
              ),
            );
          },
          context: context,
        ),
      ],
    );
  }

  Widget _buildMainCards(BuildContext context) {
    final screenType = ResponsiveUtils.getScreenType(context);
    
    if (screenType == ScreenType.mobile) {
      return Column(
        children: [
          _buildEnhancedLearningCard(context),
          ResponsiveSpacing(mobileSpacing: 16),
          CustomCardButton(
            key: _gamesKey,
            imagePath: 'assets/games.png',
            title: '',
            width: double.infinity,
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
            onTap: () async {
              await _speak("Educational Games");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GamesLandingPage(nickname: widget.nickname),
                ),
              );
            },
          ),
        ],
      );
    } else {
      return Wrap(
        spacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
        runSpacing: ResponsiveUtils.getResponsiveSpacing(context, mobile: 20),
        alignment: WrapAlignment.center,
        children: [
          _buildEnhancedLearningCard(context),
          CustomCardButton(
            key: _gamesKey,
            imagePath: 'assets/games.png',
            title: '',
            width: ResponsiveUtils.getResponsiveCardWidth(context),
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 300),
            onTap: () async {
              await _speak("Educational Games");
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GamesLandingPage(nickname: widget.nickname),
                ),
              );
            },
          ),
        ],
      );
    }
  }

  Widget _buildEnhancedLearningCard(BuildContext context) {
  final screenType = ResponsiveUtils.getScreenType(context);
  final cardWidth = screenType == ScreenType.mobile
      ? double.infinity
      : ResponsiveUtils.getResponsiveCardWidth(context);
  final cardHeight = ResponsiveUtils.getResponsiveIconSize(context, mobile: 200);

  return CustomCardButton(
    key: _readingKey,
    width: cardWidth,
    height: cardHeight,
    imagePath: 'assets/lrn.png', // ✅ ito yung image cover mo
    title: '',
    onTap: () async {
      await _speak("Learning Materials");
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Readingmaterialspage(nickname: widget.nickname),
        ),
      );
    },
  );
}

  Widget _buildIconOnlyButton({
    required IconData icon,
    required String emoji,
    required Color color,
    required VoidCallback onPressed,
    required BuildContext context,
    String? title,
  }) {
    final buttonSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      mobile: 80,
      tablet: 90,
      desktop: 100,
      largeDesktop: 110,
    );
    final iconSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      mobile: 32,
      tablet: 36,
      desktop: 40,
      largeDesktop: 44,
    );
    final emojiSize = ResponsiveUtils.getResponsiveIconSize(
      context,
      mobile: 28,
      tablet: 32,
      desktop: 36,
      largeDesktop: 40,
    );
    final titleSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: 12,
      tablet: 14,
      desktop: 16,
      largeDesktop: 18,
    );
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: buttonSize,
          height: buttonSize,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonSize / 2),
              ),
              elevation: 10,
              shadowColor: color.withValues(alpha: 0.4),
              padding: EdgeInsets.zero,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: emojiSize),
                ),
                ResponsiveIcon(
                  icon,
                  color: Colors.white,
                  mobileSize: iconSize,
                  tabletSize: iconSize * 1.1,
                  desktopSize: iconSize * 1.2,
                  largeDesktopSize: iconSize * 1.3,
                ),
              ],
            ),
          ),
        ),
        if (title != null) ...[
          ResponsiveSpacing(mobileSpacing: 8),
          ResponsiveText(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
            mobileFontSize: titleSize,
            tabletFontSize: titleSize * 1.1,
            desktopFontSize: titleSize * 1.2,
            largeDesktopFontSize: titleSize * 1.3,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class CustomCardButton extends StatelessWidget {
  final double width;
  final double height;
  final String imagePath;
  final String title;
  final VoidCallback onTap;

  const CustomCardButton({
    super.key,
    required this.width,
    required this.height,
    required this.imagePath,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          color: const Color(0xFFFFF9E4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 20),
            ),
          ),
          elevation: ResponsiveUtils.isSmallScreen(context) ? 6 : 8,
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveUtils.getResponsiveSpacing(context, mobile: 12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
              ),
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: height * 0.8,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 50);
    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 100);
    var secondEndPoint = Offset(size.width, size.height - 50);

    path.quadraticBezierTo(
        firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    path.quadraticBezierTo(
        secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
