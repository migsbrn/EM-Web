import 'package:flutter/material.dart';
import 'PictureStoryReading.dart';
import 'SoftLoudSoundsPage.dart';
import 'TexttoSpeech.dart';

class CommunicationSkillsPage extends StatelessWidget {
  final String nickname;

  const CommunicationSkillsPage({super.key, required this.nickname});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFE9D5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Go Back Button
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 50,
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF648BA2),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "Let's Start Learning",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A4E69),
                ),
              ),

              const SizedBox(height: 16),

              // LIST OF FULL-WIDTH BANNERS
              Expanded(
                child: ListView(
                  children: [
                    _buildImageCard(
                      context,
                      'assets/lrn_reading.png',
                      PictureStoryReading(nickname: nickname),
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_sounds.png',
                      SoftLoudSoundsPage(nickname: nickname),
                    ),
                    _buildImageCard(
                      context,
                      'assets/lrn_tts.png',
                      LearningMaterialsPage(nickname: nickname),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FULL-WIDTH IMAGE BANNER (same design as Functional Academics)
  Widget _buildImageCard(
    BuildContext context,
    String imagePath,
    Widget destination,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        },
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
