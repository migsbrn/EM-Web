import 'package:flutter/material.dart';
import 'SayItRight.dart'; // ✅ Ensure this file exists
import 'MatchTheSound.dart'; // ✅ Ensure this file exists
import 'FormTheWord.dart'; // ✅ This must contain AppleWordGame
import 'WhereDoesItBelong.dart'; // ✅ Newly added
import 'LetterTracing.dart'; // ✅ Newly added tracing game
import 'flashcard_system.dart'; // ✅ Flashcard Game
import 'ColorMatchingGame.dart'; // ✅ Color Matching Game
import 'responsive_utils.dart';

class GamesLandingPage extends StatelessWidget {
  final String nickname;

  const GamesLandingPage({super.key, required this.nickname});

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
    return Stack(
      children: [
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
            width: double.infinity,
            color: const Color(0xFFFBEED9),
          ),
        ),
        Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveSpacing(mobileSpacing: 20),
              _buildBackButton(context),
              ResponsiveSpacing(mobileSpacing: 100),
              _buildTitle(context),
              ResponsiveSpacing(mobileSpacing: 20),
              Expanded(child: _buildGamesGrid(context, crossAxisCount: 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 220),
            width: double.infinity,
            color: const Color(0xFFFBEED9),
          ),
        ),
        Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveSpacing(mobileSpacing: 25),
              _buildBackButton(context),
              ResponsiveSpacing(mobileSpacing: 115),
              _buildTitle(context),
              ResponsiveSpacing(mobileSpacing: 20),
              Expanded(child: _buildGamesGrid(context, crossAxisCount: 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 240),
            width: double.infinity,
            color: const Color(0xFFFBEED9),
          ),
        ),
        Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveSpacing(mobileSpacing: 30),
              _buildBackButton(context),
              ResponsiveSpacing(mobileSpacing: 130),
              _buildTitle(context),
              ResponsiveSpacing(mobileSpacing: 20),
              Expanded(child: _buildGamesGrid(context, crossAxisCount: 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: TopWaveClipper(),
          child: Container(
            height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 260),
            width: double.infinity,
            color: const Color(0xFFFBEED9),
          ),
        ),
        Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveSpacing(mobileSpacing: 35),
              _buildBackButton(context),
              ResponsiveSpacing(mobileSpacing: 145),
              _buildTitle(context),
              ResponsiveSpacing(mobileSpacing: 20),
              Expanded(child: _buildGamesGrid(context, crossAxisCount: 4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
        width: ResponsiveUtils.getResponsiveIconSize(context, mobile: 150),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF648BA2),
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveUtils.getResponsiveSpacing(
                context,
                mobile: 15,
              ),
              horizontal: ResponsiveUtils.getResponsiveSpacing(
                context,
                mobile: 20,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 12),
              ),
            ),
          ),
          child: ResponsiveText(
            'Go Back',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            mobileFontSize: 20,
            tabletFontSize: 22,
            desktopFontSize: 24,
            largeDesktopFontSize: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ResponsiveText(
          "",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A4E69),
          ),
          mobileFontSize: 35,
          tabletFontSize: 40,
          desktopFontSize: 45,
          largeDesktopFontSize: 50,
        ),
      ],
    );
  }

  Widget _buildGamesGrid(BuildContext context, {required int crossAxisCount}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          shrinkWrap: ResponsiveUtils.isSmallScreen(context) ? false : true,
          physics:
              ResponsiveUtils.isSmallScreen(context)
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
              context,
              mobile: 15,
            ),
            mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(
              context,
              mobile: 15,
            ),
            childAspectRatio:
                ResponsiveUtils.isSmallScreen(context) ? 1.0 : 0.85,
          ),
          children: _buildGameCards(context),
        );
      },
    );
  }

  List<Widget> _buildGameCards(BuildContext context) {
    return [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SayItRight(
                        nickname: nickname,
                        targetWord:
                            'exampleWord', // Replace with the actual target word
                        emoji: '😊', // Replace with the desired emoji
                        videoPath:
                            'assets/videos/example.mp4', // Replace with the actual video path
                      ),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/SayItRight!.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchSoundPage(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/MatchTheSound.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppleWordGame(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/FormTheWord.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WhereDoesItBelongGame(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/WhereDoesItBelong.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LetterTracingGame(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/LetterTracing.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlashcardGame(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/Flashcard.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 2,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ColorMatchingGame(nickname: nickname),
                ),
              ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
            child: Image.asset(
              'assets/ColorMatching.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    ];
  }
}

// Custom widget to handle image loading with error fallback
class SafeImage extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final double radius;

  const SafeImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey,
            child: const Icon(Icons.error, color: Colors.red),
          );
        },
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
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
