import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/theme_localization_service.dart';
import '../widgets/base_screen.dart';

class PickLocationPage extends StatefulWidget {
  const PickLocationPage({super.key});

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  GoogleMapController? _mapController;
  LatLng _centerPosition = const LatLng(59.8586, 17.6389); // Default Uppsala

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition position) {
    _centerPosition = position.target;
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _centerPosition.latitude,
      'longitude': _centerPosition.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ThemeAndLocalizationProvider>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('PickLocationTitle'), style: TextStyle(color: provider.textPrimaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: provider.textPrimaryColor),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _centerPosition,
              zoom: 13.0,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Central Pin overlay
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 36), // Align pin tip with camera target center
              child: Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 48,
              ),
            ),
          ),

          // Bottom Control Column
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
                    // Instructions Card overlay
                    Card(
                      color: provider.backgroundColor.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: provider.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          context.tr('MoveMapToPositionPin'),
                          style: TextStyle(color: provider.textPrimaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Save button action
                    ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: provider.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.tr('ConfirmLocation'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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
