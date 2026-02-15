import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Skipped Modules Tracking System
/// Handles tracking and management of skipped assessments and modules
class SkippedModulesSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Track a skipped module/assessment
  static Future<void> trackSkippedModule({
    required String studentName,
    required String moduleId,
    required String moduleName,
    required String moduleType,
    required String reason,
    required String currentLevel,
  }) async {
    try {
      await _firestore.collection('skippedModules').add({
        'studentName': studentName,
        'moduleId': moduleId,
        'moduleName': moduleName,
        'moduleType': moduleType,
        'reason': reason,
        'currentLevel': currentLevel,
        'skippedAt': FieldValue.serverTimestamp(),
        'status': 'skipped',
        'retryCount': 0,
        'lastRetryAt': null,
      });
    } catch (e) {
      print('Error tracking skipped module: $e');
    }
  }
  
  /// Get all skipped modules for a student
  static Future<List<SkippedModule>> getSkippedModules(String studentName) async {
    try {
      final querySnapshot = await _firestore
          .collection('skippedModules')
          .where('studentName', isEqualTo: studentName)
          .where('status', isEqualTo: 'skipped')
          .orderBy('skippedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return SkippedModule(
          id: doc.id,
          studentName: data['studentName'],
          moduleId: data['moduleId'],
          moduleName: data['moduleName'],
          moduleType: data['moduleType'],
          reason: data['reason'],
          currentLevel: data['currentLevel'],
          skippedAt: data['skippedAt']?.toDate(),
          status: data['status'],
          retryCount: data['retryCount'] ?? 0,
          lastRetryAt: data['lastRetryAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting skipped modules: $e');
      return [];
    }
  }
  
  /// Mark a module as retried
  static Future<void> markModuleAsRetried({
    required String skippedModuleId,
    required String studentName,
    required String moduleId,
    required String moduleName,
    required String moduleType,
    required bool completed,
    required double score,
  }) async {
    try {
      // Update the skipped module record
      await _firestore.collection('skippedModules').doc(skippedModuleId).update({
        'retryCount': FieldValue.increment(1),
        'lastRetryAt': FieldValue.serverTimestamp(),
        'status': completed ? 'completed' : 'skipped',
      });
      
      // Create a retry record
      await _firestore.collection('moduleRetries').add({
        'studentName': studentName,
        'moduleId': moduleId,
        'moduleName': moduleName,
        'moduleType': moduleType,
        'skippedModuleId': skippedModuleId,
        'completed': completed,
        'score': score,
        'retriedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking module as retried: $e');
    }
  }
  
  /// Get retry history for a student
  static Future<List<ModuleRetry>> getRetryHistory(String studentName) async {
    try {
      final querySnapshot = await _firestore
          .collection('moduleRetries')
          .where('studentName', isEqualTo: studentName)
          .orderBy('retriedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return ModuleRetry(
          id: doc.id,
          studentName: data['studentName'],
          moduleId: data['moduleId'],
          moduleName: data['moduleName'],
          moduleType: data['moduleType'],
          skippedModuleId: data['skippedModuleId'],
          completed: data['completed'],
          score: data['score']?.toDouble() ?? 0.0,
          retriedAt: data['retriedAt']?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting retry history: $e');
      return [];
    }
  }
  
  /// Get suggested modules to retry
  static Future<List<SkippedModule>> getSuggestedRetries(String studentName) async {
    try {
      final skippedModules = await getSkippedModules(studentName);
      
      // Sort by priority: recent skips first, then by retry count
      skippedModules.sort((a, b) {
        if (a.retryCount != b.retryCount) {
          return a.retryCount.compareTo(b.retryCount); // Fewer retries first
        }
        return b.skippedAt!.compareTo(a.skippedAt!); // More recent first
      });
      
      return skippedModules.take(5).toList(); // Return top 5 suggestions
    } catch (e) {
      print('Error getting suggested retries: $e');
      return [];
    }
  }
  
  /// Check if a module was previously skipped
  static Future<bool> wasModuleSkipped(String studentName, String moduleId) async {
    try {
      final querySnapshot = await _firestore
          .collection('skippedModules')
          .where('studentName', isEqualTo: studentName)
          .where('moduleId', isEqualTo: moduleId)
          .where('status', isEqualTo: 'skipped')
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking if module was skipped: $e');
      return false;
    }
  }
  
  /// Get skip statistics for a student
  static Future<SkipStatistics> getSkipStatistics(String studentName) async {
    try {
      final skippedModules = await getSkippedModules(studentName);
      final retryHistory = await getRetryHistory(studentName);
      
      final totalSkipped = skippedModules.length;
      final totalRetried = retryHistory.length;
      final completedRetries = retryHistory.where((r) => r.completed).length;
      final completionRate = totalRetried > 0 ? (completedRetries / totalRetried) * 100 : 0.0;
      
      return SkipStatistics(
        totalSkipped: totalSkipped,
        totalRetried: totalRetried,
        completedRetries: completedRetries,
        completionRate: completionRate,
        averageRetryCount: skippedModules.isNotEmpty 
            ? skippedModules.map((m) => m.retryCount).reduce((a, b) => a + b) / skippedModules.length
            : 0.0,
      );
    } catch (e) {
      print('Error getting skip statistics: $e');
      return SkipStatistics(
        totalSkipped: 0,
        totalRetried: 0,
        completedRetries: 0,
        completionRate: 0.0,
        averageRetryCount: 0.0,
      );
    }
  }
}

/// Data classes
class SkippedModule {
  final String id;
  final String studentName;
  final String moduleId;
  final String moduleName;
  final String moduleType;
  final String reason;
  final String currentLevel;
  final DateTime? skippedAt;
  final String status;
  final int retryCount;
  final DateTime? lastRetryAt;
  
  SkippedModule({
    required this.id,
    required this.studentName,
    required this.moduleId,
    required this.moduleName,
    required this.moduleType,
    required this.reason,
    required this.currentLevel,
    this.skippedAt,
    required this.status,
    required this.retryCount,
    this.lastRetryAt,
  });
}

class ModuleRetry {
  final String id;
  final String studentName;
  final String moduleId;
  final String moduleName;
  final String moduleType;
  final String skippedModuleId;
  final bool completed;
  final double score;
  final DateTime? retriedAt;
  
  ModuleRetry({
    required this.id,
    required this.studentName,
    required this.moduleId,
    required this.moduleName,
    required this.moduleType,
    required this.skippedModuleId,
    required this.completed,
    required this.score,
    this.retriedAt,
  });
}

class SkipStatistics {
  final int totalSkipped;
  final int totalRetried;
  final int completedRetries;
  final double completionRate;
  final double averageRetryCount;
  
  SkipStatistics({
    required this.totalSkipped,
    required this.totalRetried,
    required this.completedRetries,
    required this.completionRate,
    required this.averageRetryCount,
  });
}

/// Skipped Modules Widget
class SkippedModulesWidget extends StatefulWidget {
  final String studentName;
  final Function(String moduleId, String moduleName)? onRetryModule;
  
  const SkippedModulesWidget({
    super.key,
    required this.studentName,
    this.onRetryModule,
  });
  
  @override
  State<SkippedModulesWidget> createState() => _SkippedModulesWidgetState();
}

class _SkippedModulesWidgetState extends State<SkippedModulesWidget> {
  List<SkippedModule> _skippedModules = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSkippedModules();
  }
  
  Future<void> _loadSkippedModules() async {
    try {
      final modules = await SkippedModulesSystem.getSkippedModules(widget.studentName);
      setState(() {
        _skippedModules = modules;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading skipped modules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_skippedModules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              "No skipped modules!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "You're doing great!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.schedule,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                "Skipped Modules (${_skippedModules.length})",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        
        // Modules list
        Expanded(
          child: ListView.builder(
            itemCount: _skippedModules.length,
            itemBuilder: (context, index) {
              final module = _skippedModules[index];
              return _buildSkippedModuleCard(module);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSkippedModuleCard(SkippedModule module) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Module name and type
            Row(
              children: [
                Expanded(
                  child: Text(
                    module.moduleName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    module.moduleType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Reason
            Text(
              "Reason: ${module.reason}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            
            // Skip date and retry count
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  "Skipped: ${_formatDate(module.skippedAt)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (module.retryCount > 0) ...[
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Retried ${module.retryCount} time${module.retryCount > 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // Retry button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onRetryModule?.call(module.moduleId, module.moduleName);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  module.retryCount > 0 ? "Try Again" : "Start Module",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown";
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }
}

/// Skip Confirmation Dialog
class SkipConfirmationDialog extends StatelessWidget {
  final String moduleName;
  final String moduleType;
  final Function(String reason)? onSkip;
  final VoidCallback? onCancel;
  
  const SkipConfirmationDialog({
    super.key,
    required this.moduleName,
    required this.moduleType,
    this.onSkip,
    this.onCancel,
  });
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        "Skip Module",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Are you sure you want to skip '$moduleName'?",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "You can always come back to it later!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text(
            "Cancel",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _showReasonDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Skip",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  void _showReasonDialog(BuildContext context) {
    String selectedReason = "Too difficult";
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Why are you skipping?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "This helps us understand how to help you better!",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...["Too difficult", "Not interested", "Need a break", "Want to try later"]
                  .map((reason) => RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                      )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onSkip?.call(selectedReason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Skip"),
            ),
          ],
        ),
      ),
    );
  }
}
