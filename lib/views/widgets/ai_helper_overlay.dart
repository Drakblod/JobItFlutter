import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/job.dart';
import '../../models/timesheet_entry.dart';
import '../../services/ai_service.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import 'glass_card.dart';

class AiHelperOverlay extends StatefulWidget {
  const AiHelperOverlay({super.key});

  @override
  State<AiHelperOverlay> createState() => _AiHelperOverlayState();
}

class _AiHelperOverlayState extends State<AiHelperOverlay> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final _aiService = AiService();
  final _jobService = JobService();
  final _textController = TextEditingController();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isExpanded = false;

  String _transcript = '';
  String _statusText = 'Ready';
  Color _statusColor = Colors.cyan;

  // Draggable position coordinates
  double _x = 20.0;
  double _y = 150.0;

  List<Job> _activeJobs = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadActiveJobs();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onError: (val) {
          debugPrint('STT Init Error: $val');
          setState(() {
            _speechAvailable = false;
          });
        },
        onStatus: (val) => debugPrint('STT Init Status: $val'),
      );
      setState(() {});
    } catch (e) {
      debugPrint('STT Exception: $e');
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  Future<void> _loadActiveJobs() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    try {
      List<Job> jobs;
      if (user.role == 'Foreman') {
        jobs = await _jobService.getJobsForForeman(user.id);
      } else {
        jobs = await _jobService.getJobsForWorker(user.id);
      }
      setState(() {
        _activeJobs = jobs;
      });
    } catch (e) {
      debugPrint('Error pre-loading jobs for AI overlay: $e');
    }
  }

  void _startListening() async {
    if (!_speechAvailable) {
      setState(() {
        _statusText = 'Voice not supported';
        _statusColor = Colors.redAccent;
      });
      return;
    }

    final locale = Localizations.localeOf(context).languageCode == 'sv' ? 'sv-SE' : 'en-US';

    setState(() {
      _isListening = true;
      _transcript = '';
      _statusText = 'Listening...';
      _statusColor = Colors.greenAccent;
    });

    try {
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _transcript = result.recognizedWords;
          });
        },
        localeId: locale,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error starting listening: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
    if (_transcript.isNotEmpty) {
      _processCommand(_transcript);
    } else {
      setState(() {
        _statusText = 'No speech detected';
        _statusColor = Colors.amber;
      });
    }
  }

  Future<void> _processCommand(String commandText) async {
    if (commandText.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Parsing with AI...';
      _statusColor = Colors.indigoAccent;
    });

    try {
      final response = await _aiService.parseVoiceCommand(commandText, _activeJobs);
      await _executeParsedAction(response);
    } catch (e) {
      setState(() {
        _statusText = 'AI processing failed';
        _statusColor = Colors.redAccent;
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _executeParsedAction(Map<String, dynamic> response) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final action = response['action'] ?? 'unknown';
    final jobCode = response['jobCode'] as String?;
    
    // Find matching job in active lists if code is provided
    Job? matchedJob;
    if (jobCode != null && jobCode.isNotEmpty) {
      for (var j in _activeJobs) {
        if (j.jobCode.toUpperCase() == jobCode.toUpperCase() ||
            j.id == jobCode ||
            j.title.toLowerCase().contains(jobCode.toLowerCase())) {
          matchedJob = j;
          break;
        }
      }
    }

    if (action == 'log_hours') {
      final hours = (response['hours'] ?? 1.0) as double;
      final notes = response['notes'] as String?;
      
      if (matchedJob == null || matchedJob.id.isEmpty) {
        setState(() {
          _statusText = 'Job match not found';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      final entry = TimesheetEntry(
        id: '',
        jobId: matchedJob.id,
        workerId: user.id,
        workerName: user.displayName,
        hoursWorked: hours,
        date: DateTime.now(),
        notes: notes ?? 'Logged via AI Assistant',
        createdAt: DateTime.now(),
      );

      await _jobService.logHours(entry);
      setState(() {
        _statusText = 'Logged $hours hrs for "${matchedJob!.title}"!';
        _statusColor = Colors.greenAccent;
      });

    } else if (action == 'navigate') {
      if (matchedJob == null || matchedJob.id.isEmpty) {
        setState(() {
          _statusText = 'Job match not found';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      setState(() {
        _statusText = 'Navigating...';
        _statusColor = Colors.cyan;
        _isExpanded = false;
      });

      if (matchedJob.jobType == 'Snowracer') {
        Navigator.pushNamed(context, '/snowracer_live', arguments: matchedJob.id);
      } else {
        Navigator.pushNamed(context, '/job_details', arguments: matchedJob.id);
      }

    } else if (action == 'join_job') {
      if (user.role == 'Foreman') {
        setState(() {
          _statusText = 'Foreman cannot join jobs';
          _statusColor = Colors.amber;
        });
        return;
      }

      if (jobCode == null || jobCode.isEmpty) {
        setState(() {
          _statusText = 'Please provide job code';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      final job = await _jobService.getJobByCode(jobCode);
      if (job == null) {
        setState(() {
          _statusText = 'Job not found';
          _statusColor = Colors.redAccent;
        });
        return;
      }

      if (job.assignedWorkers.containsKey(user.id)) {
        setState(() {
          _statusText = 'Already assigned';
          _statusColor = Colors.amber;
        });
        return;
      }

      await _jobService.assignJob(job.id, user.id, user.displayName);
      await _loadActiveJobs(); // Refresh jobs list
      
      setState(() {
        _statusText = 'Joined "${job.title}" successfully!';
        _statusColor = Colors.greenAccent;
      });

    } else {
      setState(() {
        _statusText = 'Command not recognized';
        _statusColor = Colors.amber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeProvider = Provider.of<ThemeAndLocalizationProvider>(context);

    // Keep within bounds
    final bottomOffset = _isExpanded ? 350.0 : 80.0;
    final double maxPosX = size.width - (_isExpanded ? 300.0 : 64.0);
    final double maxPosY = size.height - bottomOffset;

    final xPos = _x.clamp(8.0, maxPosX);
    final yPos = _y.clamp(8.0, maxPosY);

    return Positioned(
      left: xPos,
      top: yPos,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
        },
        child: AnimatedCrossFade(
          firstChild: _buildCollapsedBubble(themeProvider),
          secondChild: _buildExpandedCard(themeProvider),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ),
    );
  }

  // Floating small circular helper bubble
  Widget _buildCollapsedBubble(ThemeAndLocalizationProvider themeProvider) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: themeProvider.primaryColor.withOpacity(0.5),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: () {
          setState(() {
            _isExpanded = true;
          });
          _loadActiveJobs(); // Reload whenever expanding
        },
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                themeProvider.primaryColor,
                themeProvider.primaryColor.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white30, width: 1.5),
          ),
          child: const Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  // Expanded glass assistant interface
  Widget _buildExpandedCard(ThemeAndLocalizationProvider themeProvider) {
    return Material(
      color: Colors.transparent,
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: themeProvider.primaryColor, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        context.tr('AiAssistant'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (_isListening) _speech.stop();
                      setState(() {
                        _isExpanded = false;
                        _transcript = '';
                        _statusText = 'Ready';
                        _statusColor = Colors.cyan;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Status Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Speech transcript or feedback
              if (_transcript.isNotEmpty || _isListening)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _transcript.isEmpty ? 'Say something...' : _transcript,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontStyle: FontStyle.italic),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Command text field input (Manual fallback)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Type command...',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            _textController.clear();
                            _processCommand(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      final val = _textController.text.trim();
                      if (val.isNotEmpty) {
                        _textController.clear();
                        _processCommand(val);
                      }
                    },
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: themeProvider.primaryColor,
                      child: const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Voice Action / Pulse mic button
              Center(
                child: GestureDetector(
                  onTapDown: (_) => _startListening(),
                  onTapUp: (_) => _stopListening(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening 
                          ? Colors.redAccent.withOpacity(0.8) 
                          : themeProvider.primaryColor.withOpacity(0.2),
                      border: Border.all(
                        color: _isListening ? Colors.redAccent : themeProvider.primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        if (_isListening)
                          const BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _isListening ? 'Release to Send' : 'Hold to Speak',
                  style: TextStyle(
                    color: _isListening ? Colors.redAccent : Colors.white60,
                    fontSize: 10,
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
}
