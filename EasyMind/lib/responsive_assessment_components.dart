import 'package:flutter/material.dart';
import 'responsive_design_system.dart';
import 'sped_friendly_messages.dart';
import 'enhanced_feedback_system.dart';
import 'enhanced_answer_highlighting.dart';

/// Responsive Assessment Base Widget
/// Provides a responsive foundation for all assessment components
class ResponsiveAssessmentBase extends StatefulWidget {
  final String title;
  final String description;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final bool showProgress;
  final int currentQuestion;
  final int totalQuestions;
  final bool isCompleted;
  
  const ResponsiveAssessmentBase({
    super.key,
    required this.title,
    required this.description,
    required this.child,
    this.onBack,
    this.onSkip,
    this.showProgress = true,
    this.currentQuestion = 0,
    this.totalQuestions = 0,
    this.isCompleted = false,
  });
  
  @override
  State<ResponsiveAssessmentBase> createState() => _ResponsiveAssessmentBaseState();
}

class _ResponsiveAssessmentBaseState extends State<ResponsiveAssessmentBase> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveSafeArea(
      child: ResponsiveLayoutBuilder(
        builder: (context, screenType, constraints) {
          return Scaffold(
            appBar: ResponsiveAppBar(
              title: widget.title,
              leading: widget.onBack != null
                  ? IconButton(
                      icon: const ResponsiveIcon(icon: Icons.arrow_back, size: 24),
                      onPressed: widget.onBack,
                    )
                  : null,
              actions: widget.onSkip != null
                  ? [
                      TextButton(
                        onPressed: widget.onSkip,
                        child: ResponsiveText(
                          "Skip",
                          fontSize: 16,
                          color: Colors.orange,
                        ),
                      ),
                    ]
                  : null,
            ),
            body: Column(
              children: [
                // Progress indicator
                if (widget.showProgress && widget.totalQuestions > 0)
                  Container(
                    padding: ResponsiveDesignSystem.getResponsivePadding(context),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ResponsiveText(
                              "Question ${widget.currentQuestion + 1}",
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                            ResponsiveText(
                              "${widget.totalQuestions} total",
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        ResponsiveSpacing(height: 8),
                        LinearProgressIndicator(
                          value: widget.totalQuestions > 0 
                              ? (widget.currentQuestion + 1) / widget.totalQuestions 
                              : 0,
                          backgroundColor: Colors.grey.shade300,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                
                // Description
                if (widget.description.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: ResponsiveDesignSystem.getResponsivePadding(context),
                    child: ResponsiveText(
                      widget.description,
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: ResponsiveDesignSystem.getResponsivePadding(context),
                    child: widget.child,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Responsive Multiple Choice Assessment Widget
class ResponsiveMultipleChoiceAssessment extends StatefulWidget {
  final String question;
  final List<String> options;
  final String? correctAnswer;
  final Function(String)? onAnswerSelected;
  final bool showResult;
  final bool isDisabled;
  final String? explanation;
  final List<String>? letters;
  
  const ResponsiveMultipleChoiceAssessment({
    super.key,
    required this.question,
    required this.options,
    this.correctAnswer,
    this.onAnswerSelected,
    this.showResult = false,
    this.isDisabled = false,
    this.explanation,
    this.letters,
  });
  
  @override
  State<ResponsiveMultipleChoiceAssessment> createState() => _ResponsiveMultipleChoiceAssessmentState();
}

class _ResponsiveMultipleChoiceAssessmentState extends State<ResponsiveMultipleChoiceAssessment> {
  String? selectedAnswer;
  
  @override
  void initState() {
    super.initState();
    selectedAnswer = widget.correctAnswer;
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            ResponsiveCard(
              child: ResponsiveText(
                widget.question,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // Options
            ResponsiveList(
              children: widget.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final letter = widget.letters != null && index < widget.letters!.length
                    ? widget.letters![index]
                    : String.fromCharCode(65 + index);
                
                final isSelected = selectedAnswer == option;
                final isCorrect = option == widget.correctAnswer;
                
                AnswerState state;
                if (widget.showResult) {
                  state = isCorrect ? AnswerState.correct : AnswerState.incorrect;
                } else if (isSelected) {
                  state = AnswerState.selected;
                } else {
                  state = AnswerState.neutral;
                }
                
                return EnhancedAnswerButton(
                  text: option,
                  letter: letter,
                  isSelected: isSelected,
                  isCorrect: isCorrect,
                  showResult: widget.showResult,
                  state: state,
                  isDisabled: widget.isDisabled,
                  onTap: () {
                    setState(() {
                      selectedAnswer = option;
                    });
                    widget.onAnswerSelected?.call(option);
                  },
                );
              }).toList(),
            ),
            
            // Explanation
            if (widget.explanation != null && widget.showResult) ...[
              ResponsiveSpacing(height: 24),
              ResponsiveCard(
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ResponsiveIcon(
                          icon: Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.blue,
                        ),
                        ResponsiveSpacing(width: 8, isVertical: false),
                        ResponsiveText(
                          "Explanation",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      widget.explanation!,
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Responsive True/False Assessment Widget
class ResponsiveTrueFalseAssessment extends StatefulWidget {
  final String question;
  final bool? correctAnswer;
  final Function(bool)? onAnswerSelected;
  final bool showResult;
  final bool isDisabled;
  final String? explanation;
  
  const ResponsiveTrueFalseAssessment({
    super.key,
    required this.question,
    this.correctAnswer,
    this.onAnswerSelected,
    this.showResult = false,
    this.isDisabled = false,
    this.explanation,
  });
  
  @override
  State<ResponsiveTrueFalseAssessment> createState() => _ResponsiveTrueFalseAssessmentState();
}

class _ResponsiveTrueFalseAssessmentState extends State<ResponsiveTrueFalseAssessment> {
  bool? selectedAnswer;
  
  @override
  void initState() {
    super.initState();
    selectedAnswer = widget.correctAnswer;
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            ResponsiveCard(
              child: ResponsiveText(
                widget.question,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // True/False options
            Row(
              children: [
                Expanded(
                  child: EnhancedAnswerButton(
                    text: "True",
                    letter: "T",
                    isSelected: selectedAnswer == true,
                    isCorrect: true == widget.correctAnswer,
                    showResult: widget.showResult,
                    state: widget.showResult
                        ? (true == widget.correctAnswer ? AnswerState.correct : AnswerState.incorrect)
                        : (selectedAnswer == true ? AnswerState.selected : AnswerState.neutral),
                    isDisabled: widget.isDisabled,
                    onTap: () {
                      setState(() {
                        selectedAnswer = true;
                      });
                      widget.onAnswerSelected?.call(true);
                    },
                    customIcon: Icons.check,
                  ),
                ),
                ResponsiveSpacing(width: 16, isVertical: false),
                Expanded(
                  child: EnhancedAnswerButton(
                    text: "False",
                    letter: "F",
                    isSelected: selectedAnswer == false,
                    isCorrect: false == widget.correctAnswer,
                    showResult: widget.showResult,
                    state: widget.showResult
                        ? (false == widget.correctAnswer ? AnswerState.correct : AnswerState.incorrect)
                        : (selectedAnswer == false ? AnswerState.selected : AnswerState.neutral),
                    isDisabled: widget.isDisabled,
                    onTap: () {
                      setState(() {
                        selectedAnswer = false;
                      });
                      widget.onAnswerSelected?.call(false);
                    },
                    customIcon: Icons.close,
                  ),
                ),
              ],
            ),
            
            // Explanation
            if (widget.explanation != null && widget.showResult) ...[
              ResponsiveSpacing(height: 24),
              ResponsiveCard(
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ResponsiveIcon(
                          icon: Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.blue,
                        ),
                        ResponsiveSpacing(width: 8, isVertical: false),
                        ResponsiveText(
                          "Explanation",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      widget.explanation!,
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Responsive Fill-in-the-Blank Assessment Widget
class ResponsiveFillInTheBlankAssessment extends StatefulWidget {
  final String question;
  final String? correctAnswer;
  final Function(String)? onAnswerSubmitted;
  final bool showResult;
  final bool isDisabled;
  final String? explanation;
  final String? hint;
  
  const ResponsiveFillInTheBlankAssessment({
    super.key,
    required this.question,
    this.correctAnswer,
    this.onAnswerSubmitted,
    this.showResult = false,
    this.isDisabled = false,
    this.explanation,
    this.hint,
  });
  
  @override
  State<ResponsiveFillInTheBlankAssessment> createState() => _ResponsiveFillInTheBlankAssessmentState();
}

class _ResponsiveFillInTheBlankAssessmentState extends State<ResponsiveFillInTheBlankAssessment> {
  final TextEditingController _controller = TextEditingController();
  String? submittedAnswer;
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final isCorrect = submittedAnswer != null && 
            submittedAnswer!.toLowerCase() == widget.correctAnswer?.toLowerCase();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question
            ResponsiveCard(
              child: ResponsiveText(
                widget.question,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // Answer input
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    "Your Answer:",
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  ResponsiveSpacing(height: 12),
                  TextField(
                    controller: _controller,
                    enabled: !widget.isDisabled && !widget.showResult,
                    decoration: InputDecoration(
                      hintText: widget.hint ?? "Type your answer here...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveDesignSystem.getResponsiveBorderRadius(context, 8),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveDesignSystem.getResponsiveBorderRadius(context, 8),
                        ),
                        borderSide: BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (value) {
                      setState(() {
                        submittedAnswer = value;
                      });
                      widget.onAnswerSubmitted?.call(value);
                    },
                  ),
                  ResponsiveSpacing(height: 16),
                  ResponsiveButton(
                    text: "Submit Answer",
                    onPressed: widget.isDisabled || widget.showResult
                        ? null
                        : () {
                            setState(() {
                              submittedAnswer = _controller.text;
                            });
                            widget.onAnswerSubmitted?.call(_controller.text);
                          },
                    isFullWidth: true,
                  ),
                ],
              ),
            ),
            
            // Result feedback
            if (submittedAnswer != null && widget.showResult) ...[
              ResponsiveSpacing(height: 24),
              ResponsiveCard(
                color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ResponsiveIcon(
                          icon: isCorrect ? Icons.check_circle : Icons.cancel,
                          size: 20,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                        ResponsiveSpacing(width: 8, isVertical: false),
                        ResponsiveText(
                          isCorrect ? "Correct!" : "Not quite right",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      "Your answer: \"$submittedAnswer\"",
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    if (widget.correctAnswer != null) ...[
                      ResponsiveSpacing(height: 4),
                      ResponsiveText(
                        "Correct answer: \"${widget.correctAnswer}\"",
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            // Explanation
            if (widget.explanation != null && widget.showResult) ...[
              ResponsiveSpacing(height: 24),
              ResponsiveCard(
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ResponsiveIcon(
                          icon: Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.blue,
                        ),
                        ResponsiveSpacing(width: 8, isVertical: false),
                        ResponsiveText(
                          "Explanation",
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                    ResponsiveSpacing(height: 8),
                    ResponsiveText(
                      widget.explanation!,
                      fontSize: 14,
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Responsive Assessment Results Widget
class ResponsiveAssessmentResults extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final String studentName;
  final String assessmentType;
  final List<Map<String, dynamic>> answers;
  final VoidCallback? onRetry;
  final VoidCallback? onContinue;
  final VoidCallback? onReview;
  
  const ResponsiveAssessmentResults({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.studentName,
    required this.assessmentType,
    required this.answers,
    this.onRetry,
    this.onContinue,
    this.onReview,
  });
  
  @override
  Widget build(BuildContext context) {
    final percentage = (score / totalQuestions) * 100;
    final feedback = EnhancedFeedbackSystem.generateAssessmentFeedback(
      assessmentType: assessmentType,
      score: score.toDouble(),
      totalQuestions: totalQuestions.toDouble(),
      answers: answers,
      studentName: studentName,
      isFirstAttempt: true,
    );
    
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Column(
          children: [
            // Results header
            ResponsiveCard(
              child: Column(
                children: [
                  ResponsiveText(
                    "Assessment Complete!",
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveSpacing(height: 16),
                  
                  // Score display
                  Container(
                    padding: ResponsiveDesignSystem.getResponsivePadding(context),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(
                        ResponsiveDesignSystem.getResponsiveBorderRadius(context, 16),
                      ),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        ResponsiveText(
                          "$score/$totalQuestions",
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        ResponsiveText(
                          "${percentage.toStringAsFixed(1)}%",
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  
                  ResponsiveSpacing(height: 16),
                  
                  // Feedback message
                  ResponsiveText(
                    feedback.overallMessage,
                    fontSize: 18,
                    color: Colors.black87,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // Detailed feedback
            ResponsiveCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    "How you did:",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  ResponsiveSpacing(height: 12),
                  ResponsiveText(
                    feedback.specificFeedback,
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  ResponsiveSpacing(height: 12),
                  ResponsiveText(
                    feedback.encouragement,
                    fontSize: 16,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // Tips
            ResponsiveCard(
              color: Colors.green.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ResponsiveIcon(
                        icon: Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.green,
                      ),
                      ResponsiveSpacing(width: 8, isVertical: false),
                      ResponsiveText(
                        "Tip for next time:",
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  ResponsiveSpacing(height: 8),
                  ResponsiveText(
                    feedback.tips,
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ],
              ),
            ),
            
            ResponsiveSpacing(height: 24),
            
            // Action buttons
            ResponsiveList(
              children: [
                if (onRetry != null)
                  ResponsiveButton(
                    text: "Try Again",
                    onPressed: onRetry,
                    backgroundColor: Colors.orange,
                    icon: Icons.refresh,
                  ),
                if (onReview != null)
                  ResponsiveButton(
                    text: "Review Answers",
                    onPressed: onReview,
                    backgroundColor: Colors.blue,
                    icon: Icons.visibility,
                  ),
                if (onContinue != null)
                  ResponsiveButton(
                    text: "Continue Learning",
                    onPressed: onContinue,
                    backgroundColor: Colors.green,
                    icon: Icons.arrow_forward,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Responsive Loading Widget
class ResponsiveLoadingWidget extends StatelessWidget {
  final String message;
  final double? size;
  
  const ResponsiveLoadingWidget({
    super.key,
    this.message = "Loading...",
    this.size,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        final responsiveSize = size ?? ResponsiveDesignSystem.getResponsiveIconSize(context, 40);
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: responsiveSize,
                height: responsiveSize,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              ResponsiveSpacing(height: 16),
              ResponsiveText(
                message,
                fontSize: 16,
                color: Colors.grey.shade600,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Responsive Error Widget
class ResponsiveErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  
  const ResponsiveErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutBuilder(
      builder: (context, screenType, constraints) {
        return Center(
          child: ResponsiveCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveIcon(
                  icon: icon ?? Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                ResponsiveSpacing(height: 16),
                ResponsiveText(
                  "Oops! Something went wrong",
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  textAlign: TextAlign.center,
                ),
                ResponsiveSpacing(height: 8),
                ResponsiveText(
                  message,
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  ResponsiveSpacing(height: 16),
                  ResponsiveButton(
                    text: "Try Again",
                    onPressed: onRetry,
                    backgroundColor: Colors.red,
                    icon: Icons.refresh,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
