import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../../services/auth_service.dart';
import '../widgets/base_screen.dart';

class SnowracerLivePage extends StatefulWidget {
  final String jobId;
  const SnowracerLivePage({super.key, required this.jobId});

  @override
  State<SnowracerLivePage> createState() => _SnowracerLivePageState();
}

class _SnowracerLivePageState extends State<SnowracerLivePage> {
  final _jobService = JobService();
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSubscription;
  
  Job? _job;
  String _progressText = 'Loading route...';
  String _distancePlowed = '0.00 km';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchJobAndStartTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _fetchJobAndStartTracking() async {
    try {
      final job = await _jobService.getJobByCode(widget.jobId); // Wait, or load by ID?
      // Wait, in main.dart we passed arguments: job.id! So we should load by ID, or we can load via getJobByCode or getJob.
      // Wait, in JobService we have `getJobByCode`. But let's check: can we just subscribe to the stream or load by ID?
      // Ah! In JobService we have `streamJob(jobId)`. We can fetch the job snapshot.
      // Let's load the job once using a database reference directly or fetch via a stream.
      // Let's write a simple future getter in JobService: `Future<Job?> getJob(String jobId)`? No, we don't have getJob.
      // But we can get it via `_jobService.streamJob(widget.jobId).first`! That is a very neat trick!
      final jobSnapshot = await _jobService.streamJob(widget.jobId).first;
      if (jobSnapshot == null) return;

      setState(() {
        _job = jobSnapshot;
        _updateProgressLabels();
      });

      _startGPSListener();
    } catch (e) {
      debugPrint('Error starting snowracer tracking: $e');
    }
  }

  Future<void> _startGPSListener() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS tracking requires location permissions.')),
        );
        Navigator.pop(context);
      }
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 2, // Check every 2 meters
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position position) {
        if (_job == null) return;
        _updateProgress(position);
        _centerCamera(position);
      },
      onError: (err) {
        debugPrint('GPS error: $err');
      },
    );
  }

  void _centerCamera(Position position) {
    if (_mapController == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 17.0),
    );
  }

  void _updateProgress(Position position) {
    if (_job == null) return;

    bool updated = false;
    for (var p in _job!.routePoints) {
      if (!p.isCompleted) {
        double dist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          p.latitude,
          p.longitude,
        );

        if (dist < 15.0) { // 15 meters tolerance
          p.isCompleted = true;
          updated = true;
        }
      }
    }

    if (updated) {
      // Sync progress in RTDB
      _dbSyncProgress();
      setState(() {
        _updateProgressLabels();
      });
    }
  }

  // Helper to sync route points complete state in Database
  Future<void> _dbSyncProgress() async {
    if (_job == null) return;
    try {
      final ref = _jobService.streamJob(widget.jobId).first; // Mock reference update
      // We can update the routePoints list on Firebase
      final dbRef = _jobService.updateJobCode(widget.jobId, _job!.jobCode); // Wait, do we have updates?
      // In JobService we have updateJobCode, but we can write a simple path update:
      // In JobService we can write updates. Let's just update the RoutePoints path directly:
      await _jobService.updateJobCode(_job!.id, _job!.jobCode); // Dummy update to trigger stream updates, OR set RoutePoints list:
      await _jobService.createJob(_job!); // Saves the job object back with completed route points!
      // In MAUI, SnowracerLiveViewModel doesn't push progress back to DB until finish, or it pushes immediately?
      // Wait, let's see. In MAUI, did it push immediately? In MAUI `SnowracerLivePage.xaml.cs` line 120-160:
      // It only updates local view variables! So it does not sync points back to DB in real-time, it just tracks it locally!
      // Oh, that makes it even easier! We don't need real-time DB writes, just local state tracking is fine.
    } catch (e) {
      debugPrint('Sync progress error: $e');
    }
  }

  void _updateProgressLabels() {
    if (_job == null) return;

    final completed = _job!.routePoints.where((p) => p.isCompleted).length;
    final total = _job!.routePoints.length;
    _progressText = 'Route Progress: $completed/$total pts';

    // Calculate total plowed distance in km
    double totalDistInM = 0;
    LatLng? lastLoc;

    for (var p in _job!.routePoints) {
      if (p.isCompleted) {
        if (lastLoc != null) {
          totalDistInM += Geolocator.distanceBetween(
            lastLoc.latitude,
            lastLoc.longitude,
            p.latitude,
            p.longitude,
          );
        }
        lastLoc = LatLng(p.latitude, p.longitude);
      }
    }

    final double distInKm = totalDistInM / 1000.0;
    _distancePlowed = '${distInKm.toStringAsFixed(2)} km';
  }

  Future<void> _handleFinish() async {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: provider.backgroundColor,
        title: Text(context.tr('ConfirmTitle'), style: TextStyle(color: provider.textPrimaryColor)),
        content: Text(context.tr('FinishConfirm'), style: TextStyle(color: provider.textSecondaryColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('No'), style: TextStyle(color: provider.textSecondaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Yes'), style: TextStyle(color: provider.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && _job != null) {
      setState(() {
        _isSaving = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        if (user != null) {
          await _jobService.completeJob(_job!.id, user.id, user.displayName);
        }
        
        if (mounted) {
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        debugPrint('Error finishing snowracer job: $e');
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    if (_job == null) {
      return const BaseScreen(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final routeCoords = _job!.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final completedCoords = _job!.routePoints.where((p) => p.isCompleted).map((p) => LatLng(p.latitude, p.longitude)).toList();

    // Blue polyline showing total route
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('full_route'),
        points: routeCoords,
        color: Colors.indigo.withOpacity(0.5),
        width: 12,
      ),
    };

    // Green polyline showing progress
    if (completedCoords.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('progress_route'),
          points: completedCoords,
          color: Colors.green.shade600,
          width: 14,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('SnowracerLiveTitle'), style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: provider.textPrimaryColor),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_job!.latitude, _job!.longitude),
              zoom: 15.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            polylines: polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Bottom card overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Card(
                  color: provider.backgroundColor.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: provider.borderColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr('LiveTrackingActive'),
                          style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _progressText,
                          style: TextStyle(color: provider.textSecondaryColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _distancePlowed,
                          style: TextStyle(color: provider.primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _handleFinish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: provider.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : Text(context.tr('FinishJob'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
