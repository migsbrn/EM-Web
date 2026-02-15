import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhanced Answer Highlighting System
/// Provides immediate visual feedback for selected answers
class EnhancedAnswerHighlighting {
  
  /// Get highlight color based on answer state
  static Color getHighlightColor({
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required AnswerState state,
  }) {
    if (!showResult) {
      // Before showing results - just highlight selection
      return isSelected ? Colors.blue.shade100 : Colors.grey.shade50;
    } else {
      // After showing results - show correct/incorrect
      if (isSelected) {
        return isCorrect ? Colors.green.shade100 : Colors.red.shade100;
      } else if (isCorrect) {
        return Colors.green.shade50; // Show correct answer
      } else {
        return Colors.grey.shade50;
      }
    }
  }
  
  /// Get border color based on answer state
  static Color getBorderColor({
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required AnswerState state,
  }) {
    if (!showResult) {
      return isSelected ? Colors.blue : Colors.grey.shade300;
    } else {
      if (isSelected) {
        return isCorrect ? Colors.green : Colors.red;
      } else if (isCorrect) {
        return Colors.green.shade300;
      } else {
        return Colors.grey.shade300;
      }
    }
  }
  
  /// Get text color based on answer state
  static Color getTextColor({
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required AnswerState state,
  }) {
    if (!showResult) {
      return isSelected ? Colors.blue.shade700 : Colors.grey.shade600;
    } else {
      if (isSelected) {
        return isCorrect ? Colors.green.shade700 : Colors.red.shade700;
      } else if (isCorrect) {
        return Colors.green.shade600;
      } else {
        return Colors.grey.shade600;
      }
    }
  }
  
  /// Get icon based on answer state
  static IconData? getIcon({
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required AnswerState state,
  }) {
    if (!showResult) {
      return isSelected ? Icons.check_circle : null;
    } else {
      if (isSelected) {
        return isCorrect ? Icons.check_circle : Icons.cancel;
      } else if (isCorrect) {
        return Icons.check_circle_outline;
      } else {
        return null;
      }
    }
  }
  
  /// Get icon color based on answer state
  static Color getIconColor({
    required bool isSelected,
    required bool isCorrect,
    required bool showResult,
    required AnswerState state,
  }) {
    if (!showResult) {
      return isSelected ? Colors.blue : Colors.grey.shade400;
    } else {
      if (isSelected) {
        return isCorrect ? Colors.green : Colors.red;
      } else if (isCorrect) {
        return Colors.green.shade400;
      } else {
        return Colors.grey.shade400;
      }
    }
  }
  
  /// Get animation duration based on state
  static Duration getAnimationDuration(AnswerState state) {
    switch (state) {
      case AnswerState.selecting:
        return const Duration(milliseconds: 200);
      case AnswerState.selected:
        return const Duration(milliseconds: 300);
      case AnswerState.correct:
        return const Duration(milliseconds: 500);
      case AnswerState.incorrect:
        return const Duration(milliseconds: 400);
      case AnswerState.neutral:
        return const Duration(milliseconds: 250);
    }
  }
  
  /// Get haptic feedback based on state
  static void provideHapticFeedback(AnswerState state) {
    switch (state) {
      case AnswerState.selecting:
        HapticFeedback.lightImpact();
        break;
      case AnswerState.selected:
        HapticFeedback.mediumImpact();
        break;
      case AnswerState.correct:
        HapticFeedback.heavyImpact();
        break;
      case AnswerState.incorrect:
        HapticFeedback.lightImpact();
        break;
      case AnswerState.neutral:
        HapticFeedback.selectionClick();
        break;
    }
  }
}

enum AnswerState {
  selecting,
  selected,
  correct,
  incorrect,
  neutral,
}

/// Enhanced Answer Button Widget
class EnhancedAnswerButton extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback? onTap;
  final AnswerState state;
  final bool isDisabled;
  final String? letter;
  final IconData? customIcon;
  
  const EnhancedAnswerButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showResult,
    required this.state,
    this.onTap,
    this.isDisabled = false,
    this.letter,
    this.customIcon,
  });
  
  @override
  State<EnhancedAnswerButton> createState() => _EnhancedAnswerButtonState();
}

class _EnhancedAnswerButtonState extends State<EnhancedAnswerButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: EnhancedAnswerHighlighting.getAnimationDuration(widget.state),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: Colors.grey.shade50,
      end: EnhancedAnswerHighlighting.getHighlightColor(
        isSelected: widget.isSelected,
        isCorrect: widget.isCorrect,
        showResult: widget.showResult,
        state: widget.state,
      ),
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void didUpdateWidget(EnhancedAnswerButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _colorController.forward();
      
      // Provide haptic feedback
      EnhancedAnswerHighlighting.provideHapticFeedback(widget.state);
    }
  }
  
  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: widget.isDisabled ? null : widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EnhancedAnswerHighlighting.getBorderColor(
                    isSelected: widget.isSelected,
                    isCorrect: widget.isCorrect,
                    showResult: widget.showResult,
                    state: widget.state,
                  ),
                  width: 2,
                ),
                boxShadow: widget.isSelected ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  // Letter indicator
                  if (widget.letter != null) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: EnhancedAnswerHighlighting.getBorderColor(
                          isSelected: widget.isSelected,
                          isCorrect: widget.isCorrect,
                          showResult: widget.showResult,
                          state: widget.state,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          widget.letter!,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  
                  // Answer text
                  Expanded(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: EnhancedAnswerHighlighting.getTextColor(
                          isSelected: widget.isSelected,
                          isCorrect: widget.isCorrect,
                          showResult: widget.showResult,
                          state: widget.state,
                        ),
                      ),
                    ),
                  ),
                  
                  // Icon
                  if (EnhancedAnswerHighlighting.getIcon(
                    isSelected: widget.isSelected,
                    isCorrect: widget.isCorrect,
                    showResult: widget.showResult,
                    state: widget.state,
                  ) != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      widget.customIcon ?? EnhancedAnswerHighlighting.getIcon(
                        isSelected: widget.isSelected,
                        isCorrect: widget.isCorrect,
                        showResult: widget.showResult,
                        state: widget.state,
                      ),
                      color: EnhancedAnswerHighlighting.getIconColor(
                        isSelected: widget.isSelected,
                        isCorrect: widget.isCorrect,
                        showResult: widget.showResult,
                        state: widget.state,
                      ),
                      size: 24,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Multiple Choice Widget
class EnhancedMultipleChoiceWidget extends StatefulWidget {
  final List<String> options;
  final String? selectedAnswer;
  final String? correctAnswer;
  final bool showResult;
  final Function(String)? onAnswerSelected;
  final bool isDisabled;
  final List<String>? letters;
  
  const EnhancedMultipleChoiceWidget({
    super.key,
    required this.options,
    this.selectedAnswer,
    this.correctAnswer,
    this.showResult = false,
    this.onAnswerSelected,
    this.isDisabled = false,
    this.letters,
  });
  
  @override
  State<EnhancedMultipleChoiceWidget> createState() => _EnhancedMultipleChoiceWidgetState();
}

class _EnhancedMultipleChoiceWidgetState extends State<EnhancedMultipleChoiceWidget> {
  String? _selectedAnswer;
  
  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.selectedAnswer;
  }
  
  @override
  void didUpdateWidget(EnhancedMultipleChoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      setState(() {
        _selectedAnswer = widget.selectedAnswer;
      });
    }
  }
  
  void _selectAnswer(String answer) {
    if (widget.isDisabled || widget.showResult) return;
    
    setState(() {
      _selectedAnswer = answer;
    });
    
    widget.onAnswerSelected?.call(answer);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final letter = widget.letters != null && index < widget.letters!.length
            ? widget.letters![index]
            : String.fromCharCode(65 + index); // A, B, C, D...
        
        final isSelected = _selectedAnswer == option;
        final isCorrect = option == widget.correctAnswer;
        
        AnswerState state;
        if (widget.showResult) {
          state = isCorrect ? AnswerState.correct : AnswerState.incorrect;
        } else if (isSelected) {
          state = AnswerState.selected;
        } else {
          state = AnswerState.neutral;
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: EnhancedAnswerButton(
            text: option,
            letter: letter,
            isSelected: isSelected,
            isCorrect: isCorrect,
            showResult: widget.showResult,
            state: state,
            isDisabled: widget.isDisabled,
            onTap: () => _selectAnswer(option),
          ),
        );
      }).toList(),
    );
  }
}

/// Enhanced True/False Widget
class EnhancedTrueFalseWidget extends StatefulWidget {
  final bool? selectedAnswer;
  final bool? correctAnswer;
  final bool showResult;
  final Function(bool)? onAnswerSelected;
  final bool isDisabled;
  
  const EnhancedTrueFalseWidget({
    super.key,
    this.selectedAnswer,
    this.correctAnswer,
    this.showResult = false,
    this.onAnswerSelected,
    this.isDisabled = false,
  });
  
  @override
  State<EnhancedTrueFalseWidget> createState() => _EnhancedTrueFalseWidgetState();
}

class _EnhancedTrueFalseWidgetState extends State<EnhancedTrueFalseWidget> {
  bool? _selectedAnswer;
  
  @override
  void initState() {
    super.initState();
    _selectedAnswer = widget.selectedAnswer;
  }
  
  @override
  void didUpdateWidget(EnhancedTrueFalseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAnswer != oldWidget.selectedAnswer) {
      setState(() {
        _selectedAnswer = widget.selectedAnswer;
      });
    }
  }
  
  void _selectAnswer(bool answer) {
    if (widget.isDisabled || widget.showResult) return;
    
    setState(() {
      _selectedAnswer = answer;
    });
    
    widget.onAnswerSelected?.call(answer);
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: EnhancedAnswerButton(
            text: "True",
            letter: "T",
            isSelected: _selectedAnswer == true,
            isCorrect: true == widget.correctAnswer,
            showResult: widget.showResult,
            state: widget.showResult
                ? (true == widget.correctAnswer ? AnswerState.correct : AnswerState.incorrect)
                : (_selectedAnswer == true ? AnswerState.selected : AnswerState.neutral),
            isDisabled: widget.isDisabled,
            onTap: () => _selectAnswer(true),
            customIcon: Icons.check,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: EnhancedAnswerButton(
            text: "False",
            letter: "F",
            isSelected: _selectedAnswer == false,
            isCorrect: false == widget.correctAnswer,
            showResult: widget.showResult,
            state: widget.showResult
                ? (false == widget.correctAnswer ? AnswerState.correct : AnswerState.incorrect)
                : (_selectedAnswer == false ? AnswerState.selected : AnswerState.neutral),
            isDisabled: widget.isDisabled,
            onTap: () => _selectAnswer(false),
            customIcon: Icons.close,
          ),
        ),
      ],
    );
  }
}
