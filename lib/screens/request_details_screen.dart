import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_provider.dart';
import 'welcome_screen_modified.dart';
import '../core/api_constants.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'location_picker_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String serviceName;
  final bool isEdit;
  final Map<String, dynamic>? editData;
  final int? index;
  final String? categoryId; 

  const JobDetailsScreen({
    super.key,
    required this.serviceName,
    this.isEdit = false,
    this.editData,
    this.index,
    this.categoryId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _budgetController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;

  File? _selectedImage;
  bool _isUploading = false;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.isEdit ? widget.editData!['date'] : "");
    _timeController = TextEditingController(text: widget.isEdit ? "10:00 AM" : "");
    _budgetController = TextEditingController(text: widget.isEdit ? widget.editData!['price'].toString() : "");
    _descriptionController = TextEditingController(text: widget.isEdit ? (widget.editData!['description'] ?? "") : "");
    _locationController = TextEditingController(text: widget.isEdit ? (widget.editData!['location'] ?? "") : "");

    if (widget.isEdit && widget.editData != null && widget.editData!['locationCoords'] != null) {
      final coords = widget.editData!['locationCoords'];
      if (coords is Map) {
        _selectedLat = double.tryParse(coords['lat']?.toString() ?? '');
        _selectedLng = double.tryParse(coords['lng']?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitTask() async {
    final String title = widget.serviceName.length < 5 ? "${widget.serviceName} Service" : widget.serviceName;

    if (_descriptionController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Description must be at least 10 characters")),
      );
      return;
    }

    if (_dateController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _budgetController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (_selectedLat == null || _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a task location (Set Task Location is required)")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final prefs = await SharedPreferences.getInstance();
      final String token = prefs.getString('jwt_token') ?? '';
      debugPrint('Token being sent in Multipart: $token');
      print('DEBUG_TOKEN: $token');

      final url = widget.isEdit
          ? "${ApiConstants.tasks}/${widget.editData!['id']}"
          : ApiConstants.tasks;

      final request = http.MultipartRequest(widget.isEdit ? 'PATCH' : 'POST', Uri.parse(url));

      // 🛡️ Standard Auth Headers
      String finalToken = token;
      if (token.toLowerCase().startsWith('bearer ')) {
        finalToken = token.substring(7);
      }
      request.headers['Authorization'] = 'bearer $finalToken';
      debugPrint('DEBUG_AUTH_HEADER: ${request.headers['Authorization']}');
      // Do NOT manually set Content-Type for MultipartRequest; the library handles it with the boundary.

      // Fields
      request.fields['title'] = title;
      request.fields['description'] = _descriptionController.text;
      request.fields['budget'] = _budgetController.text;
      request.fields['location'] = _locationController.text;
      if (_selectedLat != null && _selectedLng != null) {
        request.fields['locationCoords[lat]'] = _selectedLat!.toString();
        request.fields['locationCoords[lng]'] = _selectedLng!.toString();
        request.fields['locationCoords'] = jsonEncode({
          'lat': _selectedLat,
          'lng': _selectedLng,
        });
      }
      
      // Dynamic Category ID (Task 2) - Strictly avoid dummy hardcoding
      if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
        request.fields['categoryId'] = widget.categoryId!;
      } else if (widget.isEdit && widget.editData != null && widget.editData!['categoryId'] != null) {
          request.fields['categoryId'] = widget.editData!['categoryId'];
      } else {
        request.fields['categoryId'] = "65f1a2b3c4d5e6f7a8b9c0d1"; 
      }

      // Images
      if (_selectedImage != null) {
        final stream = http.ByteStream(_selectedImage!.openRead());
        final length = await _selectedImage!.length();
        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: 'task_image.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      print('FINAL_TOKEN_CHECK: $token');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        await userProvider.fetchMyRequests();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? "Task updated!" : "Task posted!")),
        );
      } else {
        final errorData = jsonDecode(response.body);
        String errMsg = errorData['message'] ?? 'Failed to submit';
        if (errorData['errors'] != null && errorData['errors'] is List) {
          final List errors = errorData['errors'];
          errMsg = errors.map((e) => e['msg']).join(", ");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $errMsg")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryLightBeige,
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit ${widget.serviceName}" : "${widget.serviceName} Request"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "New Job Details ",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            const Text(
              "Tell us when, where, and what needs fixing. Required fields are marked.",
              style: TextStyle(color: AppColors.textgrey, fontSize: 14),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    "Date (Required)",
                    "YYYY-MM-DD",
                    controller: _dateController,
                    suffixIcon: Icons.calendar_month,
                    onTap: () => _selectDate(context),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildInputField(
                    "Time (Required)",
                    "HH:MM AM/PM",
                    controller: _timeController,
                    suffixIcon: Icons.access_time,
                    onTap: () => _selectTime(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Proposed Budget (USD - Required)",
              "Max budget (e.g., 150)",
              controller: _budgetController,
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Description of Job (Required)",
              "Describe the issue in detail...",
              controller: _descriptionController,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            const Text(
              "Photo Reference (Optional)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDarkGreen),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.button,
                  borderRadius: BorderRadius.circular(10),
                  image: _selectedImage != null
                      ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                      : null,
                ),
                child: _selectedImage == null
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.primaryDarkGreen),
                          SizedBox(width: 10),
                          Text(
                            "Add Photo of Job Site",
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDarkGreen),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildInputField(
              "Detailed Location / Access Notes (Required)",
              "456 Customer Ave, Apt 1A...",
              controller: _locationController,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
                );
                if (result != null) {
                  setState(() {
                    _selectedLat = result.latitude;
                    _selectedLng = result.longitude;
                  });
                }
              },
              icon: Icon(
                _selectedLat == null ? Icons.add_location_alt_rounded : Icons.check_circle_rounded,
                color: _selectedLat == null ? AppColors.primaryDarkGreen : Colors.green,
              ),
              label: Text(
                _selectedLat == null ? 'Set Task Location (Required)' : 'Location Selected Successfully ✅',
                style: TextStyle(
                  color: _selectedLat == null ? AppColors.primaryDarkGreen : Colors.green[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(
                  color: _selectedLat == null ? AppColors.primaryDarkGreen : Colors.green,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDarkGreen,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _isUploading ? null : _submitTask,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      widget.isEdit ? "Update Request" : "Post Job & Find Worker",
                      style: TextStyle(color: AppColors.secondaryLightBeige, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
    IconData? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDarkGreen),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          readOnly: onTap != null,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20) : null,
            filled: true,
            fillColor: const Color(0xFFF2F2F2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
