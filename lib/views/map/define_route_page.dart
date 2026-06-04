import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/route_point.dart';
import '../../services/maps_service.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';

class DefineRoutePage extends StatefulWidget {
  const DefineRoutePage({super.key});

  @override
  State<DefineRoutePage> createState() => _DefineRoutePageState();
}

class _DefineRoutePageState extends State<DefineRoutePage> {
  final MapsService _mapsService = MapsService();
  final TextEditingController _searchController = TextEditingController();
  
  GoogleMapController? _mapController;
  final List<RoutePoint> _points = [];
  final List<int> _stepPointCounts = [];
  bool _isBusy = false;

  // Default Uppsala camera position
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.8586, 17.6389),
    zoom: 13.0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _handleMapTap(LatLng latLng) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
    });

    try {
      if (_points.isEmpty) {
        final p = RoutePoint(
          order: 0,
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        );
        setState(() {
          _points.add(p);
          _stepPointCounts.add(1);
        });
      } else {
        final lastPoint = _points.last;
        final snapped = await _mapsService.getRoadPath(
          lastPoint.latitude,
          lastPoint.longitude,
          latLng.latitude,
          latLng.longitude,
        );

        // First point is the start, skip it to avoid duplicates
        final pointsToAdd = snapped.skip(1).toList();
        int addedCount = 0;
        
        setState(() {
          for (var p in pointsToAdd) {
            final rp = RoutePoint(
              order: _points.length,
              latitude: p.latitude,
              longitude: p.longitude,
            );
            _points.add(rp);
            addedCount++;
          }
          _stepPointCounts.add(addedCount);
        });
      }
    } catch (e) {
      debugPrint('Error adding snap point: $e');
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  void _handleUndo() {
    if (_stepPointCounts.isEmpty) return;

    setState(() {
      int toRemove = _stepPointCounts.removeLast();
      for (int i = 0; i < toRemove; i++) {
        if (_points.isNotEmpty) {
          _points.removeLast();
        }
      }
    });
  }

  void _handleClear() {
    setState(() {
      _points.clear();
      _stepPointCounts.clear();
    });
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isBusy = true;
    });

    try {
      final coords = await _mapsService.searchAddress(query);
      if (coords != null && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(coords[0], coords[1]), 15.0),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('LocationNotFound'))),
          );
        }
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isBusy = false;
      });
    }
  }

  void _handleSave() {
    if (_points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('AddPointsError'))),
      );
      return;
    }
    Navigator.pop(context, _points);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    // Create polyline for map display
    final Set<Polyline> polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
        color: provider.primaryColor,
        width: 6,
      ),
    };

    // Create start and end markers
    final Set<Marker> markers = {};
    if (_points.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(_points.first.latitude, _points.first.longitude),
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      if (_points.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: LatLng(_points.last.latitude, _points.last.longitude),
            infoWindow: const InfoWindow(title: 'End'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('DefineRouteTitle'), style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: provider.textPrimaryColor),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _handleMapTap,
            polylines: polylines,
            markers: markers,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Search overlay
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: provider.backgroundColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: provider.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: provider.textPrimaryColor),
                      decoration: InputDecoration(
                        hintText: context.tr('SearchAddressPlaceholder'),
                        hintStyle: TextStyle(color: provider.textSecondaryColor),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSearch(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.search, color: provider.primaryColor),
                    onPressed: _handleSearch,
                  ),
                ],
              ),
            ),
          ),

          // Indicator loader
          if (_isBusy)
            const Positioned(
              top: 160,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Snapping to road...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Bottom Control & Help Column
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Help Tooltip Bottom banner
                    Card(
                      color: provider.backgroundColor.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: provider.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          context.tr('TapMapToAddPoints'),
                          style: TextStyle(color: provider.textPrimaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bottom Control Actions Layout
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _points.isEmpty ? null : _handleUndo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(context.tr('Undo')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _points.isEmpty ? null : _handleClear,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(context.tr('Clear')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: provider.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(context.tr('Save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
