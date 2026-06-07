import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // مكتبة اختيار الصور
import 'dart:io'; // للتعامل مع الملفات
import 'login_screen.dart';
import 'send_code_screen.dart';
import 'welcome_screen_modified.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'location_picker_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ssnController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  bool _isCategoriesLoading = false;
  List<dynamic> _categories = [];
  String? _selectedCategoryId;
  double? _selectedLat;
  double? _selectedLng;

  // 1. تعريف متغير لحفظ الصورة والـ ImagePicker
  XFile? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isCategoriesLoading = true);
    try {
      final response = await http.get(Uri.parse(ApiConstants.categories));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = data['data']['categories'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    } finally {
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    fullNameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ssnController.dispose();
    bioController.dispose();
    super.dispose();
  }

  // 2. دالة اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50, // لتقليل حجم الصورة
      );
      if (pickedFile != null) {
        setState(() {
          _profileImage = pickedFile;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Widget buildRoleButton(String text, String role) {
    bool isSelected = _selectedRole == role;
    IconData iconData = role == 'Worker'
        ? Icons.build
        : Icons.person_2_outlined;

    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(iconData, size: 20),
        label: Text(text, style: const TextStyle(fontSize: 16)),
        onPressed: () {
          setState(() {
            _selectedRole = role;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppColors.primaryDarkGreen
              : const Color.fromARGB(255, 218, 208, 178),
          foregroundColor: isSelected
              ? AppColors.backgroundWhite
              : AppColors.primaryDarkGreen,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryLightBeige,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 100),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Join Fixpay Today',
                  style: TextStyle(
                    fontSize: 23,
                    color: AppColors.primaryDarkGreen,
                  ),
                ),
                const SizedBox(height: 20),
                // خانات الإدخال الأساسية
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: Icon(Icons.person_2_outlined),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your full name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Please enter a valid email'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                  validator: (value) => (value == null || value.length < 11)
                      ? 'Please enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ssnController,
                  keyboardType: TextInputType.number,
                  maxLength: 14,
                  decoration: const InputDecoration(
                    hintText: 'SSN (14 digits)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    counterText: '',
                  ),
                  validator: (value) =>
                      (value!.length != 14) ? 'SSN must be 14 digits' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => (value == null || value.length < 8)
                      ? 'Password must be at least 8 characters'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) => (value != passwordController.text)
                      ? 'Passwords do not match'
                      : null,
                ),
                const SizedBox(height: 20),
                const Text(
                  'I am a :',
                  style: TextStyle(
                    color: AppColors.primaryDarkGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    buildRoleButton('Worker', 'Worker'),
                    const SizedBox(width: 15),
                    buildRoleButton('Customer', 'Customer'),
                  ],
                ),

                if (_selectedRole == 'Worker') ...[
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
                      _selectedLat == null ? 'Set Work Location (Required)' : 'Location Selected Successfully ✅',
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
                  const SizedBox(height: 20),
                  if (_isCategoriesLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_categories.isEmpty)
                    const Text('No categories available. Please check your connection.', 
                               style: TextStyle(color: Colors.red))
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Service Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['_id'],
                          child: Text(cat['name'] ?? 'Unknown'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                      validator: (value) => (_selectedRole == 'Worker' && value == null) ? 'Required for workers' : null,
                    ),
                  const SizedBox(height: 20),

                  // 3. تعديل زرار رفع الصورة ليظهر حالة الرفع أو المعاينة
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: _profileImage == null
                        ? const Icon(Icons.photo_camera_outlined)
                        : const Icon(Icons.check_circle, color: Colors.green),
                    label: Text(
                      _profileImage == null
                          ? 'Upload Profile Photo (Optional)'
                          : 'Photo Selected ✅',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.white70,
                      foregroundColor: AppColors.primaryDarkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                  ),

                  // معاينة الصورة المختارة (اختياري)
                  if (_profileImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_profileImage!.path),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Short Bio (Optional)',
                      hintText: 'e.g., Plumber with 10 years experience',
                    ),
                  ),
                ],

                const SizedBox(height: 25),
                // زر الاستمرار
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_selectedRole == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please select a role')),
                            );
                            return;
                          }
                          if (_selectedRole == 'Worker' && (_selectedLat == null || _selectedLng == null)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select your work location (رجاء تحديد موقع العمل)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            try {
                              List<String> nameParts = fullNameController.text.trim().split(' ');
                              String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
                              String lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ' ';

                              Map<String, dynamic> payload = {
                                "name": {
                                  "first": firstName,
                                  "last": lastName,
                                },
                                "userName": fullNameController.text.trim().replaceAll(' ', '_').toLowerCase() + 
                                            DateTime.now().millisecond.toString(),
                                "email": emailController.text.trim(),
                                "phoneNumber": phoneController.text.trim(),
                                "password": passwordController.text,
                                "confirmPassword": confirmPasswordController.text,
                                "role": _selectedRole == 'Worker' ? 'worker' : 'user',
                                "ssn": ssnController.text.trim(),
                                "dateOfBirth": "01-01-2000", // Placeholder to satisfy schema if needed
                                "gender": 0, // Placeholder
                              };
                              if (_selectedRole == 'Worker' && _selectedLat != null) {
                                payload['locationCoords'] = {
                                  'lat': _selectedLat,
                                  'lng': _selectedLng,
                                };
                              }
                              if (_selectedRole == 'Worker') {
                                payload["categoryId"] = _selectedCategoryId;
                                payload["bio"] = bioController.text.trim();
                              }

                              final response = await http.post(
                                Uri.parse(ApiConstants.register),
                                headers: {'Content-Type': 'application/json'},
                                body: jsonEncode(payload),
                              );

                              if (response.statusCode == 200 ||
                                  response.statusCode == 201) {
                                debugPrint('Raw Backend Response: ${response.body}');
                                final data = jsonDecode(response.body);
                                
                                // Robust extraction: check both root and data object
                                final token = data['token'] ?? (data['data'] != null ? data['data']['token'] : null);
                                final user = data['user'] ?? (data['data'] != null ? data['data']['user'] : null);
                                debugPrint('Extracted Token: $token');

                                if (token != null) {
                                  final prefs = await SharedPreferences.getInstance();
                                  await prefs.setString('jwt_token', token);
                                  await prefs.setString('user_id', user['_id'] ?? '');
                                  await prefs.setString('user_role', user['role'] ?? 'user');
                                  await prefs.setString('user_name', user['userName'] ?? 'User');
                                }
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VerifyAccountScreen(
                                        email: emailController.text,
                                        selectedRole: _selectedRole!,
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                final errorData = jsonDecode(response.body);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorData['message'] ??
                                        'Registration failed'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 218, 208, 178),
                    foregroundColor: AppColors.primaryDarkGreen,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primaryDarkGreen)
                      : const Text('Continue', style: TextStyle(fontSize: 18)),
                ),

                if (_selectedRole != 'Worker') ...[
                  const SizedBox(height: 15),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account?",
                          style: TextStyle(fontSize: 19),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          child: const Text(
                            'log in',
                            style: TextStyle(fontSize: 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
