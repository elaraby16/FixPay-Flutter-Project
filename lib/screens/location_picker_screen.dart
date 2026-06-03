import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class PickerColors {
  static const Color primary = Color(0xFF385E48);
  static const Color background = Color(0xFFE7E3D8);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF757575);
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedPosition = const LatLng(30.0444, 31.2357); // Default Cairo Center
  bool _loadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocation();
    });
  }

  Future<void> _requestLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location services are disabled. Using default location.";
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Location permissions were denied. Using default location.";
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Location permissions are permanently denied. Using default location.";
          _loadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPosition = userLatLng;
        _loadingLocation = false;
      });
      _mapController.move(userLatLng, 15.0);
    } catch (e) {
      setState(() {
        _locationError = "Failed to fetch GPS location: $e. Using default location.";
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location (تأكيد المكان)'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Flutter Map View
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 15.0,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                setState(() {
                  _selectedPosition = camera.center;
                });
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedPosition = point;
                });
                _mapController.move(point, _mapController.camera.zoom);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.second_project',
              ),
            ],
          ),

          // Centered Target Pin (Overlay)
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: const BoxDecoration(
                      color: PickerColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: PickerColors.background,
                      size: 30,
                    ),
                  ),
                  Container(
                    width: 2.5,
                    height: 12,
                    color: PickerColors.primary,
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: PickerColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Temporary Location Info Banner (Error / Warning)
          if (_locationError != null)
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[200]!),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _locationError = null;
                        });
                      },
                    )
                  ],
                ),
              ),
            ),

          // Refocus Floating Button
          Positioned(
            bottom: 195, // Positioned right above the details overlay card
            right: 20,
            child: Material(
              color: PickerColors.primary,
              elevation: 6,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.my_location_rounded, color: PickerColors.background),
                tooltip: 'Refocus on Current Location',
                onPressed: _requestLocation,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
          ),

          // Bottom card overlay for confirming selection
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Card(
              elevation: 10,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: PickerColors.background,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_rounded, color: PickerColors.primary, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECTED COORDINATES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: PickerColors.textLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: PickerColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PickerColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context, _selectedPosition);
                        },
                        child: const Text(
                          'Confirm Location (تأكيد المكان)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_loadingLocation)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: PickerColors.background,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(PickerColors.primary),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Fetching GPS Location...',
                          style: TextStyle(
                            color: PickerColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}
