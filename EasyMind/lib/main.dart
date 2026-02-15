import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'student_landing_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_initialization_service.dart';
import 'responsive_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize memory retention features
  await AppInitializationService().initializeApp();
  
  runApp(EasyMindApp());
}

class EasyMindApp extends StatelessWidget {
  const EasyMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: Color(0xFF648BA2),
      ),
      home: StudentLoginScreen(),
    );
  }
}

class StudentLoginScreen extends StatelessWidget {
  final TextEditingController nicknameController = TextEditingController();

  StudentLoginScreen({super.key});

  // Function to record student login and create/update student profile
  Future<void> _updateStudentLogin(String nickname) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = Timestamp.now();

      // Query the students collection to find the student by nickname
      final querySnapshot =
          await firestore
              .collection('students')
              .where('nickname', isEqualTo: nickname)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Student exists - update lastLogin
        final studentDoc = querySnapshot.docs.first;
        await studentDoc.reference.update({'lastLogin': now});
        print('Existing student login updated: $nickname');
        
        // Write to the studentLogins collection with timestamp log
        print('Student Login time set to: $now');
        await firestore.collection('studentLogins').add({
          'nickname': nickname,
          'loginTime': now,
        });
      } else {
        // Student doesn't exist - show error message
        print('Student not found: $nickname');
        throw Exception('Student not found. Please contact your teacher to add your nickname to the system.');
      }
    } catch (e) {
      print('Error recording student login: $e');
      rethrow; // Re-throw to handle in the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFE9D5),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
        largeDesktop: _buildLargeDesktopLayout(context),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            Image.asset(
              'assets/logo.png',
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 200),
            ),
            ResponsiveSpacing(mobileSpacing: 20),
            ResponsiveText(
              'EasyMind',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF648BA2),
                fontFamily: 'Poppins',
              ),
              mobileFontSize: 40,
              tabletFontSize: 50,
              desktopFontSize: 60,
              largeDesktopFontSize: 70,
            ),
            ResponsiveSpacing(mobileSpacing: 30),
            CustomTextField(
              controller: nicknameController,
              labelText: 'Enter your nickname',
              width: MediaQuery.of(context).size.width - 32,
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
            ),
            ResponsiveSpacing(mobileSpacing: 20),
            CustomButton(
              text: 'LOGIN',
              width: MediaQuery.of(context).size.width - 32,
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 50),
              onPressed: () => _handleLogin(context),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: ResponsiveUtils.getResponsiveConstraints(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 300),
            ),
            ResponsiveSpacing(mobileSpacing: 30),
            ResponsiveText(
              'EasyMind',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF648BA2),
                fontFamily: 'Poppins',
              ),
              mobileFontSize: 50,
              tabletFontSize: 60,
              desktopFontSize: 70,
              largeDesktopFontSize: 80,
            ),
            ResponsiveSpacing(mobileSpacing: 40),
            CustomTextField(
              controller: nicknameController,
              labelText: 'Enter your nickname',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 60),
            ),
            ResponsiveSpacing(mobileSpacing: 30),
            CustomButton(
              text: 'LOGIN',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 60),
              onPressed: () => _handleLogin(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: ResponsiveUtils.getResponsiveConstraints(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 400),
            ),
            ResponsiveSpacing(mobileSpacing: 40),
            ResponsiveText(
              'EasyMind',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF648BA2),
                fontFamily: 'Poppins',
              ),
              mobileFontSize: 60,
              tabletFontSize: 70,
              desktopFontSize: 80,
              largeDesktopFontSize: 90,
            ),
            ResponsiveSpacing(mobileSpacing: 50),
            CustomTextField(
              controller: nicknameController,
              labelText: 'Enter your nickname',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 70),
            ),
            ResponsiveSpacing(mobileSpacing: 40),
            CustomButton(
              text: 'LOGIN',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 70),
              onPressed: () => _handleLogin(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLargeDesktopLayout(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: ResponsiveUtils.getResponsiveConstraints(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 500),
            ),
            ResponsiveSpacing(mobileSpacing: 50),
            ResponsiveText(
              'EasyMind',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF648BA2),
                fontFamily: 'Poppins',
              ),
              mobileFontSize: 70,
              tabletFontSize: 80,
              desktopFontSize: 90,
              largeDesktopFontSize: 100,
            ),
            ResponsiveSpacing(mobileSpacing: 60),
            CustomTextField(
              controller: nicknameController,
              labelText: 'Enter your nickname',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 80),
            ),
            ResponsiveSpacing(mobileSpacing: 50),
            CustomButton(
              text: 'LOGIN',
              width: ResponsiveUtils.getResponsiveCardWidth(context),
              height: ResponsiveUtils.getResponsiveIconSize(context, mobile: 80),
              onPressed: () => _handleLogin(context),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context) {
    String nickname = nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      _updateStudentLogin(nickname).then((_) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentLandingPage(nickname: nickname),
          ),
        );
      }).catchError((error) {
        // Show error message when student is not found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              error.toString().replaceFirst('Exception: ', ''),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              mobileFontSize: 14,
              tabletFontSize: 16,
              desktopFontSize: 18,
              largeDesktopFontSize: 20,
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            margin: ResponsiveUtils.getResponsivePadding(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
              ),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            "Please enter a nickname",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            mobileFontSize: 16,
            tabletFontSize: 18,
            desktopFontSize: 20,
            largeDesktopFontSize: 22,
          ),
          backgroundColor: const Color.fromARGB(255, 39, 39, 39),
          behavior: SnackBarBehavior.floating,
          margin: ResponsiveUtils.getResponsivePadding(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 15),
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class CustomTextField extends StatelessWidget {
  final String labelText;
  final double width;
  final double height;
  final TextEditingController controller;

  const CustomTextField({super.key, 
    required this.labelText,
    required this.controller,
    this.width = 380,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
      largeDesktop: 22,
    );
    
    final hintFontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: 14,
      tablet: 16,
      desktop: 18,
      largeDesktop: 20,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 25),
        ),
        border: Border.all(
          color: Color(0xFF6EABCF), 
          width: ResponsiveUtils.isSmallScreen(context) ? 4 : 8,
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getResponsiveSpacing(context, mobile: 15),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(fontSize: fontSize, color: Colors.black),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: labelText,
            hintStyle: TextStyle(fontSize: hintFontSize, color: Colors.black54),
            contentPadding: EdgeInsets.only(
              left: 5, 
              top: ResponsiveUtils.isSmallScreen(context) ? 15 : 30,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const CustomButton({super.key, 
    required this.text,
    this.width = 380,
    this.height = 60,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
      largeDesktop: 22,
    );

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF648BA2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveBorderRadius(context, mobile: 30),
            ),
          ),
        ),
        child: ResponsiveText(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          mobileFontSize: fontSize,
          tabletFontSize: fontSize * 1.1,
          desktopFontSize: fontSize * 1.2,
          largeDesktopFontSize: fontSize * 1.3,
        ),
      ),
    );
  }
}
