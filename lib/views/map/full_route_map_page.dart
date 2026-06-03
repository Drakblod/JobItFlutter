import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';

class FullRouteMapPage extends StatefulWidget {
  final String jobId;
  const FullRouteMapPage({super.key, required this.jobId});

  @override
  State<FullRouteMapPage> createState() => _FullRouteMapPageState();
}

class _FullRouteMapPageState extends State<FullRouteMapPage> {
  final _jobService = JobService();
  GoogleMapController? _mapController;
  Job? _job;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    final snapshot = await _jobService.streamJob(widget.jobId).first;
    if (snapshot != null) {
      setState(() {
        _job = snapshot;
      });
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_job == null || _mapController == null) return;

    if (_job!.routePoints.length < 2) {
      final double lat = _job!.routePoints.isNotEmpty ? _job!.routePoints.first.latitude : _job!.latitude;
      final double lng = _job!.routePoints.isNotEmpty ? _job!.routePoints.first.longitude : _job!.longitude;
      final LatLng centerLatLng = LatLng(lat, lng);
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(centerLatLng, 15.0));
      return;
    }

    // Calculate bounds containing all points
    double minLat = _job!.routePoints.first.latitude;
    double maxLat = _job!.routePoints.first.latitude;
    double minLng = _job!.routePoints.first.longitude;
    double maxLng = _job!.routePoints.first.longitude;

    for (var p in _job!.routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Delay camera updates to ensure the GoogleMap widget has completed native layout sizing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
        }
      });
    });
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

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('full_route'),
        points: routeCoords,
        color: provider.primaryColor,
        width: 6,
      ),
    };

    final Set<Marker> markers = {};
    if (_job!.routePoints.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(_job!.routePoints.first.latitude, _job!.routePoints.first.longitude),
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      if (_job!.routePoints.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: LatLng(_job!.routePoints.last.latitude, _job!.routePoints.last.longitude),
            infoWindow: const InfoWindow(title: 'End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_job!.title, style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: provider.textPrimaryColor),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_job!.latitude, _job!.longitude),
          zoom: 13.0,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _fitBounds();
        },
        polylines: polylines,
        markers: markers,
        zoomControlsEnabled: false,
      ),
    );
  }
}
