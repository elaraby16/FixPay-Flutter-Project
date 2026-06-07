import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_constants.dart';

class UserProvider extends ChangeNotifier {
  // --- [1] User Data (Common & Customer) ---
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  String _userAddress = "";
  String _userBio = "";
  File? _userImage;
  String? _userRole;

  // --- [2] Worker Data ---
  String _workerName = "";
  String _workerSSN = "";
  String _workerBio = "";
  String _workerEmail = "";
  String _workerPhone = "";
  String _workerAddress = "";
  String _workerCategory = "";
  bool _isVerified = false; // identityVerification status
  File? _workerImage;

  // --- [3] Lists & Stats ---
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _earningsHistory = [];
  List<Map<String, dynamic>> _scheduledJobs = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _allRatings = [];
  List<Map<String, dynamic>> _myRequests = [];
  
  // Real categories or empty if not loaded
  List<Map<String, dynamic>> _availableJobs = [];
  List<dynamic> _categories = [];

  bool _hasNewNotifications = false;
  Map<String, String> _myBids = {}; // taskId -> status ('pending', 'accepted', etc.)
  List<Map<String, dynamic>> _taskOffers = [];
  List<Map<String, dynamic>> get taskOffers => _taskOffers;

  // --- [4] Getters ---
  String get userName => _userName.isEmpty ? "" : _userName;
  String get userEmail => _userEmail;
  String get userPhone => _userPhone;
  String get userAddress => _userAddress;
  String get userBio => _userBio;
  File? get userImage => _userImage;
  String? get userRole => _userRole;

  String get workerName => _workerName.isEmpty ? "" : _workerName;
  String get workerSSN => _workerSSN;
  String get workerEmail => _workerEmail;
  String get workerPhone => _workerPhone;
  String get workerAddress => _workerAddress;
  String get workerBio => _workerBio;
  String get workerCategory => _workerCategory;
  bool get isVerified => _isVerified;
  File? get workerImage => _workerImage;

  double get totalEarnings => _totalEarnings;
  List<Map<String, dynamic>> get earningsHistory => _earningsHistory;
  List<Map<String, dynamic>> get scheduledJobs => _scheduledJobs;
  List<Map<String, dynamic>> get myRequests => _myRequests;
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get allRatings => _allRatings;
  List<Map<String, dynamic>> get availableJobs => _availableJobs;
  List<dynamic> get categories => _categories;
  bool get hasNewNotifications => _hasNewNotifications;
  Map<String, String> get myBids => _myBids;

  // --- [5] Authentication ---
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;

  void setAuth(String token, String userId, {String? role, String? verifyStatus}) {
    _token = token;
    _userId = userId;
    if (role != null) _userRole = role;
    if (verifyStatus != null) _isVerified = (verifyStatus == 'verified');
    notifyListeners();
  }

  void updateUserData({String? name, String? email, String? phone, String? address, String? bio, File? image}) {
    if (name != null) _userName = name;
    if (email != null) _userEmail = email;
    if (phone != null) _userPhone = phone;
    if (address != null) _userAddress = address;
    if (bio != null) _userBio = bio;
    if (image != null) _userImage = image;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userId = prefs.getString('user_id');
    _userRole = prefs.getString('user_role');
    
    final name = prefs.getString('user_name') ?? "";
    final email = prefs.getString('user_email') ?? "";
    final category = prefs.getString('user_category') ?? "";
    final verifyStatus = prefs.getString('user_verify_status') ?? "unverified";
    
    if (_userRole == 'worker') {
      _workerName = name;
      _workerEmail = email;
      _workerCategory = category;
      _isVerified = verifyStatus == 'verified';
    } else {
      _userName = name;
      _userEmail = email;
    }
    
    notifyListeners();
  }

  Future<String?> _getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    return _token;
  }

  // --- [6] Logic Methods ---

  void deleteNotification(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications.removeAt(index);
      notifyListeners();
    }
  }

  void clearAllNotifications() {
    _notifications.clear();
    _hasNewNotifications = false;
    notifyListeners();
  }

  // ⭐️ Fixed: POST the actual rating to backend (Task 2)
  Future<void> submitWorkerRating(String workerId, double rating, {String? comment}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('jwt_token');
    final String currentToken = _token ?? savedToken ?? "";

    if (currentToken.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("${ApiConstants.baseApiUrl}/ratings"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'token': currentToken,
        },
        body: jsonEncode({
          'workerId': workerId,
          'rating': rating,
          'comment': comment ?? "",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh local state or just add to local list for immediate feedback
        _allRatings.insert(0, {
          'worker': workerId,
          'rate': rating,
          'date': DateTime.now().toString(),
        });
        addNotification("Rating submitted successfully!", "success");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error submitting rating: $e");
    }
  }

  void completeJob(Map<String, dynamic> job) {
    _scheduledJobs.removeWhere((item) => item['title'] == job['title']);
    double jobAmount = double.tryParse(job['price']?.toString() ?? job['amount']?.toString() ?? "0") ?? 0.0;
    _totalEarnings += jobAmount;
    _earningsHistory.insert(0, {
      'title': job['title'],
      'customer': job['customer'] ?? '',
      'amount': jobAmount,
      'date': DateFormat('MMM dd, yyyy').format(DateTime.now()),
      'type': job['type'] ?? '',
    });
    addNotification("Completed: ${job['title']}. Earnings updated.", "success");
    notifyListeners();
  }

  void acceptJob(Map<String, dynamic> job) {
    _availableJobs.removeWhere((item) => item['title'] == job['title']);
    _scheduledJobs.insert(0, {...job, 'status': 'Confirmed'});
    addNotification("Job '${job['title']}' has been confirmed.", "success");
    notifyListeners();
  }

  void sendCounterOffer(Map<String, dynamic> job) {
    var pendingJob = Map<String, dynamic>.from(job);
    pendingJob['status'] = 'Pending';
    _scheduledJobs.add(pendingJob);
    _availableJobs.removeWhere((item) => item['title'] == job['title']);
    notifyListeners();
  }

  // --- [7] Worker Profile Updates ---
  void updateWorkerData({String? name, String? ssn, String? bio, String? email, String? phone, String? address, String? category, File? image}) {
    if (name != null) _workerName = name;
    if (ssn != null) _workerSSN = ssn;
    if (bio != null) _workerBio = bio;
    if (email != null) _workerEmail = email;
    if (phone != null) _workerPhone = phone;
    if (address != null) _workerAddress = address;
    if (category != null) _workerCategory = category;
    if (image != null) _workerImage = image;
    notifyListeners();
  }

  // --- [8] UI Logic ---
  void markNotificationsAsSeen() {
    _hasNewNotifications = false;
    notifyListeners();
  }

  void addNotification(String title, String type) {
    _notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'type': type,
      'isRead': false,
      'time': DateFormat('hh:mm a').format(DateTime.now()),
    });
    _hasNewNotifications = true;
    notifyListeners();
  }

  // --- [9] API Calls ---
  Future<bool> deleteRequestApi(String taskId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('jwt_token');
    final String currentToken = _token ?? savedToken ?? "";

    if (currentToken.isEmpty) return false;

    try {
      final response = await http.delete(
        Uri.parse("${ApiConstants.tasks}/$taskId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
      );

      if (response.statusCode == 200) {
        _myRequests.removeWhere((t) => t['id'] == taskId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error deleting task: $e");
      return false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.categories));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _categories = data['data']['categories'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> fetchMyRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedToken = prefs.getString('jwt_token');
    final String currentToken = _token ?? savedToken ?? "";
    
    if (currentToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.customerTasks),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List tasks = data['data'] != null && data['data']['tasks'] != null ? data['data']['tasks'] : [];
        
        _myRequests = tasks
            .map<Map<String, dynamic>>((t) => {
                  'id': t['_id'],
                  'title': t['title'],
                  'description': t['description'],
                  'price': t['budget']?.toString() ?? "",
                  'status': t['status'] ?? "",
                  'date': t['createdAt'] != null ? DateFormat('MMM dd, yyyy').format(DateTime.parse(t['createdAt'])) : "",
                  'serviceType': t['categoryId'] != null ? t['categoryId']['name'] : '',
                  'images': t['images'] ?? [],
                  'location': t['location'] ?? "",
                })
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching requests: $e");
    }
  }

  Future<void> fetchWorkerTasks() async {
    final String? currentToken = await _getToken();
    
    if (currentToken == null || currentToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.workerTasks),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
        },
      );

      print('DEBUG_WORKER_TASKS_RESPONSE: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List tasks = data['data'] != null && data['data']['tasks'] != null ? data['data']['tasks'] : [];
        
        final List<Map<String, dynamic>> fetchedJobs = tasks.map<Map<String, dynamic>>((t) {
          // Safe price parsing
          int price = 0;
          if (t['budget'] != null) {
            price = int.tryParse(t['budget'].toString()) ?? (t['budget'] as num).toInt();
          }

          // Safe specialty parsing
          String specialty = 'General';
          if (t['categoryId'] != null) {
            if (t['categoryId'] is Map) {
              specialty = t['categoryId']['name'] ?? 'General';
            } else {
              specialty = t['categoryId'].toString();
            }
          }

          // Safe customer parsing
          Map<String, dynamic> customer = {};
          if (t['customerId'] != null && t['customerId'] is Map) {
            customer = Map<String, dynamic>.from(t['customerId']);
          }

           return {
            'id': t['_id'],
            'title': t['title'] ?? "No Title",
            'details': t['description'] ?? "No Description",
            'price': price,
            'specialty': specialty,
            'location': t['location'] ?? "Unknown",
            'posted': t['createdAt'] != null 
                ? "Posted ${DateFormat('MMM dd').format(DateTime.parse(t['createdAt']))}" 
                : "Recently",
            'icon': Icons.work_outline,
            'customer': customer,
            'locationCoords': t['locationCoords'],
            'images': t['images'],
          };
        }).toList();

        // MERGE: Keep jobs that have active bids so they don't disappear from the worker's feed
        final List<Map<String, dynamic>> mergedJobs = List.from(fetchedJobs);
        for (var entry in _myBids.entries) {
          final taskId = entry.key;
          // If the job we bidded on is not in the 'OPEN' list anymore, keep it from our old list
          if (!mergedJobs.any((j) => j['id'] == taskId)) {
            final oldJob = _availableJobs.firstWhere((j) => j['id'] == taskId, orElse: () => {});
            if (oldJob.isNotEmpty) {
              mergedJobs.add(oldJob);
            }
          }
        }

        _availableJobs = mergedJobs;
        notifyListeners();
      } else if (response.statusCode == 404) {
        // Handle 404 gracefully but keep our bidded jobs
        _availableJobs = _availableJobs.where((j) => _myBids.containsKey(j['id'])).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching worker tasks: $e");
    }
  }

  Future<bool> submitOffer(String taskId, int price, String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedToken = prefs.getString('jwt_token');
      final String? currentToken = _token ?? savedToken;

      if (currentToken == null || currentToken.isEmpty) {
        print('⚠️ Warning: Token is null or empty in submitOffer!');
        return false;
      }
      _token = currentToken; // Update local token cache

      print('🔍 [DEBUG] Token being sent in submitOffer: $currentToken');

      final response = await http.post(
        Uri.parse(ApiConstants.offers),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
        body: jsonEncode({
          'taskId': taskId,
          'price': price,
          'message': message,
        }),
      );

      print('🚀 OFFER_SUBMIT_RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Offer submitted successfully");
        _myBids[taskId] = 'pending';
        notifyListeners();
        return true;
      } else {
        debugPrint("Failed to submit offer: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error submitting offer: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTaskOffers(String taskId) async {
    final String? currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) {
      _taskOffers = [];
      notifyListeners();
      return [];
    }

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? ApiConstants.baseApiUrl;
      final response = await http.get(
        Uri.parse("$baseUrl/tasks/$taskId/offers"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List offers = data['data'] != null && data['data']['offers'] != null 
            ? data['data']['offers'] 
            : (data['offers'] ?? (data['data'] is List ? data['data'] : []));
        
        _taskOffers = offers.map<Map<String, dynamic>>((o) => Map<String, dynamic>.from(o)).toList();
        notifyListeners();
        return _taskOffers;
      }
      _taskOffers = [];
      notifyListeners();
      return [];
    } catch (e) {
      debugPrint("Error fetching task offers: $e");
      _taskOffers = [];
      notifyListeners();
      return [];
    }
  }

  Future<bool> acceptOfferApi(String offerId) async {
    final String? currentToken = await _getToken();
    if (currentToken == null) return false;

    try {
      final response = await http.patch(
        Uri.parse("${ApiConstants.offers}/$offerId/accept"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Offer accepted successfully");
        return true;
      } else {
        debugPrint("Failed to accept offer: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error accepting offer: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatHistory(String otherUserId) async {
    final String? currentToken = await _getToken();
    if (currentToken == null) return [];

    try {
      final response = await http.get(
        Uri.parse("${ApiConstants.messages}/$otherUserId"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List messages = data['data'] != null && data['data']['messages'] != null ? data['data']['messages'] : [];
        return messages.map<Map<String, dynamic>>((m) => Map<String, dynamic>.from(m)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching chat: $e");
      return [];
    }
  }

  Future<bool> sendMessage(String receiverId, String content) async {
    final String? currentToken = await _getToken();
    if (currentToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.messages),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
        },
        body: jsonEncode({
          'receiverId': receiverId,
          'content': content,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Error sending message: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAssignedTasks() async {
    final String? currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) return [];

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? ApiConstants.baseApiUrl;
      print('🔍 [DEBUG] fetchAssignedTasks called. URL: ${dotenv.env['BASE_URL']}/tasks/worker/assigned');

      final response = await http.get(
        Uri.parse("$baseUrl/tasks/worker/assigned"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
      );

      print('🔍 [DEBUG] fetchAssignedTasks Status: ${response.statusCode}');
      print('🔍 [DEBUG] fetchAssignedTasks Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List tasks = data['data'] != null && data['data']['tasks'] != null 
            ? data['data']['tasks'] 
            : (data['tasks'] ?? (data['data'] is List ? data['data'] : []));
        return tasks.map<Map<String, dynamic>>((t) => Map<String, dynamic>.from(t)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching assigned tasks: $e");
      return [];
    }
  }

  Future<bool> completeTask(String taskId) async {
    final String? currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) return false;

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? ApiConstants.baseApiUrl;
      final response = await http.patch(
        Uri.parse("$baseUrl/tasks/$taskId/complete"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
      );

      print('🚀 COMPLETE_TASK_RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Task completed successfully");
        return true;
      } else {
        debugPrint("Failed to complete task: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error completing task: $e");
      return false;
    }
  }

  Future<bool> rateWorker(String taskId, int rating) async {
    final String? currentToken = await _getToken();
    if (currentToken == null || currentToken.isEmpty) return false;

    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? ApiConstants.baseApiUrl;
      final response = await http.post(
        Uri.parse("$baseUrl/tasks/$taskId/rate"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'bearer $currentToken',
          'authorization': 'bearer $currentToken',
          'token': currentToken,
        },
        body: jsonEncode({
          'rating': rating,
        }),
      );

      print('🚀 RATE_WORKER_RESPONSE: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Worker rated successfully");
        return true;
      } else {
        debugPrint("Failed to rate worker: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error rating worker: $e");
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _userRole = null;
    _userName = "";
    _userEmail = "";
    _userPhone = "";
    _userAddress = "";
    _userBio = "";
    _userImage = null;
    _workerName = "";
    _workerEmail = "";
    _workerCategory = "";
    _myRequests.clear();
    _notifications.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Or remove specific keys
    
    notifyListeners();
  }
}
