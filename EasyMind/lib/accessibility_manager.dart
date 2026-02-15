import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility Manager - Provides comprehensive accessibility features
class AccessibilityManager {
  static final AccessibilityManager _instance = AccessibilityManager._internal();
  factory AccessibilityManager() => _instance;
  AccessibilityManager._internal();

  // Removed unused _prefs field

  /// Initialize accessibility features
  Future<void> initialize() async {
    try {
      // Enable accessibility features by default
      await _enableDefaultAccessibilityFeatures();
    } catch (e) {
      // Error initializing accessibility: $e
    }
  }

  /// Enable default accessibility features
  Future<void> _enableDefaultAccessibilityFeatures() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Set default accessibility settings
      await prefs.setBool('accessibility_large_text', true);
      await prefs.setBool('accessibility_high_contrast', true);
      await prefs.setBool('accessibility_sound_feedback', true);
      await prefs.setBool('accessibility_vibration_feedback', true);
      await prefs.setBool('accessibility_screen_reader', false);
      await prefs.setBool('accessibility_simplified_ui', true);
      await prefs.setDouble('accessibility_text_scale', 1.2);
      await prefs.setInt('accessibility_animation_speed', 1); // 0=slow, 1=normal, 2=fast
      
      // Default accessibility features enabled
    } catch (e) {
      // Error enabling default accessibility features: $e
    }
  }

  /// Get accessibility settings
  Future<AccessibilitySettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return AccessibilitySettings(
        largeText: prefs.getBool('accessibility_large_text') ?? true,
        highContrast: prefs.getBool('accessibility_high_contrast') ?? true,
        soundFeedback: prefs.getBool('accessibility_sound_feedback') ?? true,
        vibrationFeedback: prefs.getBool('accessibility_vibration_feedback') ?? true,
        screenReader: prefs.getBool('accessibility_screen_reader') ?? false,
        simplifiedUI: prefs.getBool('accessibility_simplified_ui') ?? true,
        textScale: prefs.getDouble('accessibility_text_scale') ?? 1.2,
        animationSpeed: prefs.getInt('accessibility_animation_speed') ?? 1,
      );
    } catch (e) {
      // Error getting accessibility settings: $e
      return AccessibilitySettings.defaultSettings();
    }
  }

  /// Update accessibility settings
  Future<void> updateSettings(AccessibilitySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('accessibility_large_text', settings.largeText);
      await prefs.setBool('accessibility_high_contrast', settings.highContrast);
      await prefs.setBool('accessibility_sound_feedback', settings.soundFeedback);
      await prefs.setBool('accessibility_vibration_feedback', settings.vibrationFeedback);
      await prefs.setBool('accessibility_screen_reader', settings.screenReader);
      await prefs.setBool('accessibility_simplified_ui', settings.simplifiedUI);
      await prefs.setDouble('accessibility_text_scale', settings.textScale);
      await prefs.setInt('accessibility_animation_speed', settings.animationSpeed);
      
      // Accessibility settings updated
    } catch (e) {
      // Error updating accessibility settings: $e
    }
  }

  /// Provide haptic feedback
  Future<void> provideHapticFeedback(HapticFeedbackType type) async {
    try {
      final settings = await getSettings();
      if (!settings.vibrationFeedback) return;

      switch (type) {
        case HapticFeedbackType.light:
          HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.selection:
          HapticFeedback.selectionClick();
          break;
        case HapticFeedbackType.success:
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 100));
          HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.error:
          HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 200));
          HapticFeedback.heavyImpact();
          break;
      }
    } catch (e) {
      // Error providing haptic feedback: $e
    }
  }

  /// Get accessible colors based on settings
  Future<Color> getAccessibleColor(Color baseColor, bool isBackground) async {
    try {
      final settings = await getSettings();
      
      if (!settings.highContrast) return baseColor;
      
      // High contrast color adjustments
      if (isBackground) {
        return baseColor.withValues(alpha: 0.9);
      } else {
        // Ensure text is highly visible
        final luminance = baseColor.computeLuminance();
        return luminance > 0.5 ? Colors.black : Colors.white;
      }
    } catch (e) {
      return baseColor;
    }
  }

  /// Get accessible text style
  Future<TextStyle> getAccessibleTextStyle(TextStyle baseStyle) async {
    try {
      final settings = await getSettings();
      
      return baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 14) * settings.textScale,
        fontWeight: settings.largeText ? FontWeight.w600 : baseStyle.fontWeight,
        color: await getAccessibleColor(baseStyle.color ?? Colors.black, false),
      );
    } catch (e) {
      return baseStyle;
    }
  }

  /// Get animation duration based on settings
  Future<Duration> getAnimationDuration(Duration baseDuration) async {
    try {
      final settings = await getSettings();
      
      switch (settings.animationSpeed) {
        case 0: // Slow
          return Duration(milliseconds: (baseDuration.inMilliseconds * 1.5).round());
        case 1: // Normal
          return baseDuration;
        case 2: // Fast
          return Duration(milliseconds: (baseDuration.inMilliseconds * 0.5).round());
        default:
          return baseDuration;
      }
    } catch (e) {
      return baseDuration;
    }
  }
}

/// Accessibility Settings Model
class AccessibilitySettings {
  final bool largeText;
  final bool highContrast;
  final bool soundFeedback;
  final bool vibrationFeedback;
  final bool screenReader;
  final bool simplifiedUI;
  final double textScale;
  final int animationSpeed; // 0=slow, 1=normal, 2=fast

  AccessibilitySettings({
    required this.largeText,
    required this.highContrast,
    required this.soundFeedback,
    required this.vibrationFeedback,
    required this.screenReader,
    required this.simplifiedUI,
    required this.textScale,
    required this.animationSpeed,
  });

  AccessibilitySettings.defaultSettings() :
    largeText = true,
    highContrast = true,
    soundFeedback = true,
    vibrationFeedback = true,
    screenReader = false,
    simplifiedUI = true,
    textScale = 1.2,
    animationSpeed = 1;
}

/// Haptic Feedback Types
enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
  success,
  error,
}

/// Accessible Button Widget
class AccessibleButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final String? accessibilityLabel;
  final bool isLarge;
  final EdgeInsetsGeometry? padding;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.accessibilityLabel,
    this.isLarge = false,
    this.padding,
  });

  @override
  State<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends State<AccessibleButton> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessibilitySettings>(
      future: _accessibilityManager.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? AccessibilitySettings.defaultSettings();
        
        return Semantics(
          label: widget.accessibilityLabel ?? widget.text,
          button: true,
          enabled: widget.onPressed != null,
          child: GestureDetector(
            onTap: widget.onPressed != null ? () async {
              await _accessibilityManager.provideHapticFeedback(HapticFeedbackType.selection);
              widget.onPressed!();
            } : null,
            child: Container(
              padding: widget.padding ?? EdgeInsets.symmetric(
                horizontal: settings.largeText ? 24 : 16,
                vertical: settings.largeText ? 16 : 12,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(settings.largeText ? 16 : 12),
                border: settings.highContrast ? Border.all(color: Colors.white, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.textColor ?? Colors.white,
                      size: settings.largeText ? 24 : 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.text,
                    style: TextStyle(
                      color: widget.textColor ?? Colors.white,
                      fontSize: settings.largeText ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Accessible Card Widget
class AccessibleCard extends StatefulWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? accessibilityLabel;

  const AccessibleCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.accessibilityLabel,
  });

  @override
  State<AccessibleCard> createState() => _AccessibleCardState();
}

class _AccessibleCardState extends State<AccessibleCard> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessibilitySettings>(
      future: _accessibilityManager.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? AccessibilitySettings.defaultSettings();
        
        return Semantics(
          label: widget.accessibilityLabel,
          button: widget.onTap != null,
          child: GestureDetector(
            onTap: widget.onTap != null ? () async {
              await _accessibilityManager.provideHapticFeedback(HapticFeedbackType.light);
              widget.onTap!();
            } : null,
            child: Container(
              padding: widget.padding ?? EdgeInsets.all(settings.largeText ? 20 : 16),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(settings.largeText ? 20 : 16),
                border: settings.highContrast ? Border.all(color: Colors.grey.shade300, width: 2) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Accessible Text Widget
class AccessibleText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final String? accessibilityLabel;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.accessibilityLabel,
  });

  @override
  State<AccessibleText> createState() => _AccessibleTextState();
}

class _AccessibleTextState extends State<AccessibleText> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccessibilitySettings>(
      future: _accessibilityManager.getSettings(),
      builder: (context, snapshot) {
        final settings = snapshot.data ?? AccessibilitySettings.defaultSettings();
        
        return Semantics(
          label: widget.accessibilityLabel ?? widget.text,
          child: Text(
            widget.text,
            style: widget.style?.copyWith(
              fontSize: (widget.style?.fontSize ?? 14) * settings.textScale,
              fontWeight: settings.largeText ? FontWeight.w600 : widget.style?.fontWeight,
            ),
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
          ),
        );
      },
    );
  }
}

/// Accessibility Settings Screen
class AccessibilitySettingsScreen extends StatefulWidget {
  final String nickname;

  const AccessibilitySettingsScreen({
    super.key,
    required this.nickname,
  });

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  final AccessibilityManager _accessibilityManager = AccessibilityManager();
  AccessibilitySettings _settings = AccessibilitySettings.defaultSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _accessibilityManager.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      AccessibilitySettings newSettings;
      
      switch (key) {
        case 'largeText':
          newSettings = _settings.copyWith(largeText: value);
          break;
        case 'highContrast':
          newSettings = _settings.copyWith(highContrast: value);
          break;
        case 'soundFeedback':
          newSettings = _settings.copyWith(soundFeedback: value);
          break;
        case 'vibrationFeedback':
          newSettings = _settings.copyWith(vibrationFeedback: value);
          break;
        case 'screenReader':
          newSettings = _settings.copyWith(screenReader: value);
          break;
        case 'simplifiedUI':
          newSettings = _settings.copyWith(simplifiedUI: value);
          break;
        case 'textScale':
          newSettings = _settings.copyWith(textScale: value);
          break;
        case 'animationSpeed':
          newSettings = _settings.copyWith(animationSpeed: value);
          break;
        default:
          return;
      }
      
      await _accessibilityManager.updateSettings(newSettings);
      setState(() {
        _settings = newSettings;
      });
      
      // Provide feedback
      await _accessibilityManager.provideHapticFeedback(HapticFeedbackType.selection);
    } catch (e) {
      // Error updating setting: $e
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '♿ Accessibility Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Visual Settings
            AccessibleCard(
              accessibilityLabel: 'Visual accessibility settings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    '👁️ Visual Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    'Large Text',
                    'Make text bigger and easier to read',
                    '🔍',
                    _settings.largeText,
                    (value) => _updateSetting('largeText', value),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSwitchTile(
                    'High Contrast',
                    'Increase contrast for better visibility',
                    '🎨',
                    _settings.highContrast,
                    (value) => _updateSetting('highContrast', value),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSliderTile(
                    'Text Scale',
                    'Adjust text size',
                    '📏',
                    _settings.textScale,
                    0.8,
                    2.0,
                    (value) => _updateSetting('textScale', value),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Interaction Settings
            AccessibleCard(
              accessibilityLabel: 'Interaction accessibility settings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    '👆 Interaction Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    'Sound Feedback',
                    'Play sounds for interactions',
                    '🔊',
                    _settings.soundFeedback,
                    (value) => _updateSetting('soundFeedback', value),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSwitchTile(
                    'Vibration Feedback',
                    'Vibrate for interactions',
                    '📳',
                    _settings.vibrationFeedback,
                    (value) => _updateSetting('vibrationFeedback', value),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSliderTile(
                    'Animation Speed',
                    'Adjust animation speed',
                    '⚡',
                    _settings.animationSpeed.toDouble(),
                    0,
                    2,
                    (value) => _updateSetting('animationSpeed', value.round()),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // UI Settings
            AccessibleCard(
              accessibilityLabel: 'User interface accessibility settings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    '🎨 UI Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSwitchTile(
                    'Simplified UI',
                    'Use simpler interface elements',
                    '🎯',
                    _settings.simplifiedUI,
                    (value) => _updateSetting('simplifiedUI', value),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSwitchTile(
                    'Screen Reader',
                    'Enable screen reader support',
                    '📖',
                    _settings.screenReader,
                    (value) => _updateSetting('screenReader', value),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Test Button
            AccessibleButton(
              text: 'Test Settings',
              icon: Icons.play_arrow,
              onPressed: () async {
                await _accessibilityManager.provideHapticFeedback(HapticFeedbackType.success);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Accessibility settings are working!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, String emoji, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF6C63FF).withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFF6C63FF).withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                AccessibleText(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6C63FF),
            activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String title, String subtitle, String emoji, double value, double min, double max, Function(double) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    AccessibleText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round() * 10,
            label: value.toStringAsFixed(1),
            onChanged: onChanged,
            activeColor: const Color(0xFF3B82F6),
            inactiveColor: Colors.grey.shade300,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
              Text(max.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Extension for AccessibilitySettings
extension AccessibilitySettingsExtension on AccessibilitySettings {
  AccessibilitySettings copyWith({
    bool? largeText,
    bool? highContrast,
    bool? soundFeedback,
    bool? vibrationFeedback,
    bool? screenReader,
    bool? simplifiedUI,
    double? textScale,
    int? animationSpeed,
  }) {
    return AccessibilitySettings(
      largeText: largeText ?? this.largeText,
      highContrast: highContrast ?? this.highContrast,
      soundFeedback: soundFeedback ?? this.soundFeedback,
      vibrationFeedback: vibrationFeedback ?? this.vibrationFeedback,
      screenReader: screenReader ?? this.screenReader,
      simplifiedUI: simplifiedUI ?? this.simplifiedUI,
      textScale: textScale ?? this.textScale,
      animationSpeed: animationSpeed ?? this.animationSpeed,
    );
  }
}
