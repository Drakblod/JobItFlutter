import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/job.dart';
import '../../models/route_point.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';
import '../widgets/glass_card.dart';

class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends State<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addrController = TextEditingController();
  final _codeController = TextEditingController();
  
  final _jobService = JobService();
  String _jobType = 'Normal'; // 'Normal' or 'Snowracer'
  List<RoutePoint> _routePoints = [];
  bool _isCheckingCode = false;
  String? _codeFeedback;
  bool _isCodeAvailable = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addrController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _checkCodeAvailability() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeFeedback = context.tr('EnterCode');
        _isCodeAvailable = false;
      });
      return;
    }

    if (code.length < 3 || code.length > 10) {
      setState(() {
        _codeFeedback = context.tr('InvalidCodeFormat');
        _isCodeAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingCode = true;
      _codeFeedback = null;
    });

    try {
      final available = await _jobService.isJobCodeAvailable(code);
      setState(() {
        _isCodeAvailable = available;
        _codeFeedback = available 
            ? context.tr('CodeAvailable', [code]) 
            : context.tr('CodeTaken', [code]);
      });
    } catch (e) {
      setState(() {
        _codeFeedback = 'Error checking code: $e';
        _isCodeAvailable = false;
      });
    } finally {
      setState(() {
        _isCheckingCode = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      String finalCode = _codeController.text.trim().toUpperCase();
      if (finalCode.isEmpty) {
        // Generate random unique code
        bool codeOk = false;
        while (!codeOk) {
          finalCode = _generateRandomCode();
          codeOk = await _jobService.isJobCodeAvailable(finalCode);
        }
      } else {
        // Check custom code one last time
        final available = await _jobService.isJobCodeAvailable(finalCode);
        if (!available) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.tr('CodeTaken', [finalCode]))),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Check if Snowracer job has a route defined
      if (_jobType == 'Snowracer' && _routePoints.isEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
            return AlertDialog(
              backgroundColor: provider.backgroundColor,
              title: Text(context.tr('WarningTitle'), style: TextStyle(color: provider.textPrimaryColor)),
              content: Text(
                context.tr('AddPointsError').replaceAll('Please add at least 2 points to define a route.', 'No route defined. Save anyway?'),
                style: TextStyle(color: provider.textSecondaryColor),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.tr('Cancel'), style: TextStyle(color: provider.textSecondaryColor)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.tr('Ok'), style: TextStyle(color: provider.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
        if (proceed != true) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Construct Job
      final newJob = Job(
        id: '', // Will be generated by Firebase push key
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        address: _addrController.text.trim(),
        status: 'Open',
        createdBy: user.id,
        assignedWorkers: {},
        jobCode: finalCode,
        latitude: _routePoints.isNotEmpty ? _routePoints.first.latitude : 0.0,
        longitude: _routePoints.isNotEmpty ? _routePoints.first.longitude : 0.0,
        jobType: _jobType,
        routePoints: _routePoints,
        createdAt: DateTime.now(),
        images: {},
        messages: {},
        subtasks: {},
      );

      final jobId = await _jobService.createJob(newJob);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('JobCreatedSuccessFormat', [finalCode]))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('CreateJobError')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return BaseScreen(
      title: context.tr('CreateJobTitle'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('JobDetailsLabel'),
                      style: TextStyle(
                        color: provider.textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 24),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: context.tr('JobTitlePlaceholder'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('EnterTitleError');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: context.tr('DescriptionLabel'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('FillAllFields');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addrController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: context.tr('AddressLocationPlaceholder'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return context.tr('FillAllFields');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Job Type Selection Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('JobTypeLabel'),
                      style: TextStyle(
                        color: provider.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 20),

                    // Job Type Selection Segmented Style
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _jobType = 'Normal';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _jobType == 'Normal'
                                    ? provider.primaryColor
                                    : Colors.black.withOpacity(0.15),
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                                border: Border.all(
                                  color: _jobType == 'Normal'
                                      ? provider.primaryColor
                                      : provider.borderColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                context.tr('StandardJob'),
                                style: TextStyle(
                                  color: _jobType == 'Normal' ? Colors.white : provider.textSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _jobType = 'Snowracer';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _jobType == 'Snowracer'
                                    ? provider.primaryColor
                                    : Colors.black.withOpacity(0.15),
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                                border: Border.all(
                                  color: _jobType == 'Snowracer'
                                      ? provider.primaryColor
                                      : provider.borderColor.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                context.tr('SnowracerJob'),
                                style: TextStyle(
                                  color: _jobType == 'Snowracer' ? Colors.white : provider.textSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_jobType == 'Snowracer') ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/define_route',
                          );
                          if (result != null && result is List<RoutePoint>) {
                            setState(() {
                              _routePoints = result;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.map),
                        label: Text(
                          _routePoints.isEmpty 
                              ? context.tr('DefineRouteLabel') 
                              : context.tr('RoutePointsFormat', [_routePoints.length]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Code Editor Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('CustomJoinCode'),
                      style: TextStyle(
                        color: provider.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            style: TextStyle(color: provider.textPrimaryColor),
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: context.tr('CustomCodePlaceholder'),
                              hintStyle: TextStyle(color: provider.textSecondaryColor),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.1),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isCheckingCode ? null : _checkCodeAvailability,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isCheckingCode
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : Text(context.tr('CheckAvailability')),
                        ),
                      ],
                    ),
                    if (_codeFeedback != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _codeFeedback!,
                        style: TextStyle(
                          color: _isCodeAvailable ? Colors.greenAccent : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                    : Text(
                        context.tr('Save'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
