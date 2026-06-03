import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class MapColors {
  static const Color primary = Color(0xFF385E48);
  static const Color background = Color(0xFFE7E3D8);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textLight = Color(0xFF757575);
  static const Color blueLocation = Color(0xFF2196F3);
  static const Color redMarker = Color(0xFFE53935);
}

class MockTask {
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final double price;
  final String category;

  MockTask({
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.category,
  });
}

class WorkerMapTestScreen extends StatefulWidget {
  const WorkerMapTestScreen({super.key});

  @override
  State<WorkerMapTestScreen> createState() => _WorkerMapTestScreenState();
}

class _WorkerMapTestScreenState extends State<WorkerMapTestScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _loadingLocation = true;
  String? _locationError;
  List<MockTask> _mockTasks = [];
  MockTask? _selectedTask;

  @override
  void initState() {
    super.initState();
    _initLocationAndTasks();
  }

  void _initLocationAndTasks() {
    _fetchMockTasks();
    // Use WidgetsBinding to run permission request after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionAndFetchLocation();
    });
  }

  void _fetchMockTasks() {
    setState(() {
      _mockTasks = [
        MockTask(
          title: 'Appliance Repair',
          description: 'Repairing a washing machine drum and seal in Heliopolis.',
          latitude: 30.0984,
          longitude: 31.3300,
          price: 450.0,
          category: 'repair',
        ),
        MockTask(
          title: 'Deep House Cleaning',
          description: 'Complete 3-bedroom apartment cleaning in Maadi.',
          latitude: 29.9602,
          longitude: 31.2569,
          price: 600.0,
          category: 'cleaning',
        ),
        MockTask(
          title: 'Emergency Plumbing',
          description: 'Fixing a high-pressure pipe burst behind bathroom wall in Zamalek.',
          latitude: 30.0626,
          longitude: 31.2223,
          price: 350.0,
          category: 'plumbing',
        ),
      ];
    });
  }

  Future<void> _requestPermissionAndFetchLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location services are disabled. Please enable them in settings.";
          _loadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Location permissions were denied.";
            _loadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Location permissions are permanently denied. Please enable them in settings.";
          _loadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
      });

      // Move map to the current position
      _mapController.move(LatLng(position.latitude, position.longitude), 13.0);
    } catch (e) {
      setState(() {
        _locationError = "Failed to retrieve location: $e";
        _loadingLocation = false;
      });
    }
  }

  void _focusMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 14.0);
    }
  }

  void _focusCairo() {
    _mapController.move(const LatLng(30.0444, 31.2357), 11.5);
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'repair':
        return Icons.construction_rounded;
      case 'cleaning':
        return Icons.cleaning_services_rounded;
      case 'plumbing':
        return Icons.plumbing_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: MapColors.blueLocation.withOpacity(0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: MapColors.blueLocation,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskMarker(MockTask task) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTask = task;
        });
        _mapController.move(LatLng(task.latitude, task.longitude), 14.5);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 2,
            child: Container(
              width: 12,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.all(Radius.elliptical(12, 4)),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: MapColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCategoryIcon(task.category),
                    color: MapColors.background,
                    size: 16,
                  ),
                ),
                ClipPath(
                  clipper: TriangleClipper(),
                  child: Container(
                    width: 8,
                    height: 6,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    return Material(
      color: enabled ? MapColors.primary : Colors.grey[400],
      elevation: 4,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: MapColors.background),
        tooltip: tooltip,
        onPressed: enabled ? onPressed : null,
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }

  Widget _buildTaskDetailCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutQuad)),
          child: child,
        );
      },
      child: _selectedTask == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                key: ValueKey<String>(_selectedTask!.title),
                elevation: 10,
                shadowColor: Colors.black38,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: MapColors.background,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: MapColors.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(_selectedTask!.category),
                                  color: MapColors.background,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedTask!.category.toUpperCase(),
                                  style: const TextStyle(
                                    color: MapColors.background,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close_rounded, color: MapColors.textDark, size: 24),
                            onPressed: () {
                              setState(() {
                                _selectedTask = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedTask!.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: MapColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTask!.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: MapColors.textLight,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PAYMENT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: MapColors.textLight,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'EGP ${_selectedTask!.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: MapColors.primary,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MapColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text('Accepted task: "${_selectedTask!.title}" (Mock Offline Mode)'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: MapColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            child: const Text(
                              'Accept Task',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Map (Test Screen)'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(30.0444, 31.2357), // Default Cairo Center
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.second_project',
              ),
              MarkerLayer(
                markers: [
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: _buildUserLocationMarker(),
                    ),
                  ..._mockTasks.map((task) => Marker(
                        point: LatLng(task.latitude, task.longitude),
                        width: 45,
                        height: 45,
                        child: _buildTaskMarker(task),
                      )),
                ],
              ),
            ],
          ),
          
          // Top Info / Error Bar
          if (_loadingLocation)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(MapColors.primary),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Requesting location permissions...',
                      style: TextStyle(color: MapColors.textDark, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else if (_locationError != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[100]!),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locationError!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Floating Controls Drawer (Vertical column on the right side)
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              children: [
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  tooltip: 'Focus My Location',
                  onPressed: _focusMyLocation,
                  enabled: _currentPosition != null,
                ),
                const SizedBox(height: 12),
                _buildFloatingButton(
                  icon: Icons.location_city_rounded,
                  tooltip: 'Focus Cairo Tasks',
                  onPressed: _focusCairo,
                  enabled: true,
                ),
                const SizedBox(height: 12),
                _buildFloatingButton(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh Location',
                  onPressed: _requestPermissionAndFetchLocation,
                  enabled: !_loadingLocation,
                ),
              ],
            ),
          ),

          // Bottom card overlay containing details of selected task
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildTaskDetailCard(),
          ),
        ],
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
