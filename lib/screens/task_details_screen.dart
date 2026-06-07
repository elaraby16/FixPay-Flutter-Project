import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';
import 'main_aej_screen.dart';
import 'welcome_screen_modified.dart'; // تأكدي من مسار الألوان
import 'user_provider.dart';
import 'package:provider/provider.dart';
import 'make_offer_screen.dart';
import 'chat_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String title;
  final int price;
  final String specialty;
  final String details;
  final Map<String, dynamic> customer;
  final String taskId;

  const TaskDetailsScreen({
    super.key,
    required this.title,
    required this.price,
    required this.specialty,
    required this.details,
    required this.customer,
    required this.taskId,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late int currentPrice;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    currentPrice = widget.price;
    _dateController = TextEditingController(text: "11 / 05 / 2025");
    _timeController = TextEditingController(text: "10 : 00 AM");
    priceController = TextEditingController(text: widget.price.toString());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDarkGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.primaryDarkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(
        () => _dateController.text =
            "${picked.day} / ${picked.month} / ${picked.year}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    
    // Search for the task in all potential lists
    Map<String, dynamic> task = {};
    task = provider.availableJobs.firstWhere(
      (j) => j['id'] == widget.taskId,
      orElse: () => <String, dynamic>{},
    );
    if (task.isEmpty) {
      task = provider.scheduledJobs.firstWhere(
        (j) => j['id'] == widget.taskId,
        orElse: () => <String, dynamic>{},
      );
    }
    if (task.isEmpty) {
      task = provider.myRequests.firstWhere(
        (j) => j['id'] == widget.taskId,
        orElse: () => <String, dynamic>{},
      );
    }

    final locationCoords = task['locationCoords'];
    final images = task['images'];
    String? imageUrl;
    if (images is List && images.isNotEmpty) {
      imageUrl = images[0]?.toString();
    } else if (images is String && images.isNotEmpty) {
      imageUrl = images;
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Task Details',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTaskDetailsCard(task, imageUrl, locationCoords),
            const SizedBox(height: 20),
            _buildCustomerInfoCard(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // الكارت الأول: تعديل ترتيب العنوان والتخصص والسعر
  Widget _buildTaskDetailsCard(Map<String, dynamic> task, String? imageUrl, dynamic locationCoords) {
    final String locationName = task['location'] ?? 'Unknown Location';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2EFE9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  color: AppColors.button,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.specialty,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$$currentPrice',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDarkGreen,
                ),
              ),
              (() {
                final status = Provider.of<UserProvider>(context).myBids[widget.taskId];
                String text = "Open for Bids";
                Color color = Colors.grey;
                
                if (status == 'pending') {
                  text = "Pending Acceptance";
                  color = AppColors.primaryDarkGreen;
                } else if (status == 'accepted') {
                  text = "Job Accepted";
                  color = Colors.green;
                } else if (status == 'countered') {
                  text = "Counter-Offer Received";
                  color = Colors.orange;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.backgroundWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              })(),
            ],
          ),
          const Divider(height: 30, color: Colors.grey),
          const Text(
            'Job Description',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(widget.details, style: const TextStyle(fontSize: 13)),
          
          // --- Task image display ---
          _buildTaskImage(imageUrl),

          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location & Timing',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    // --- Task location indicator with map icon ---
                    _buildLocationTile(locationCoords, locationName),

                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          task['posted'] != null ? ' ${task['posted']}' : ' Tomorrow, 10:00 AM',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  _buildSmallActionBtn(
                    'Propose Reschedule',
                    _showRescheduleDialog,
                  ),
                  const SizedBox(height: 8),
                  _buildSmallActionBtn(
                    'Propose Counter-Offer',
                    _showCounterOfferDialog,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskImage(String? imageUrl) {
    return Container(
      width: double.infinity,
      height: 180,
      margin: const EdgeInsets.only(top: 15, bottom: 15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.primaryDarkGreen,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage("Failed to load image");
                },
              )
            : _buildPlaceholderImage("No image provided"),
      ),
    );
  }

  Widget _buildPlaceholderImage(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(dynamic locationCoords, String locationName) {
    final bool hasCoords = locationCoords != null && 
        locationCoords is Map &&
        locationCoords['lat'] != null && 
        locationCoords['lng'] != null;
        
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryDarkGreen.withOpacity(0.1),
          child: const Icon(Icons.map_outlined, color: AppColors.primaryDarkGreen, size: 20),
        ),
        title: Text(
          locationName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          hasCoords ? '📍 Location provided' : 'No coordinates available',
          style: TextStyle(
            fontSize: 11, 
            color: hasCoords ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: hasCoords ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF2EFE9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDarkGreen,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFDDE3D5),
                backgroundImage: widget.customer['avatar'] != null ? NetworkImage(widget.customer['avatar']) : null,
                child: widget.customer['avatar'] == null
                    ? Text(
                        (() {
                          final nameData = widget.customer['name'];
                          String displayName = "";
                          if (nameData is Map) {
                            displayName = "${nameData['first'] ?? ''} ${nameData['last'] ?? ''}".trim();
                          } else {
                            displayName = widget.customer['userName'] ?? "C";
                          }
                          return displayName.isNotEmpty ? displayName[0].toUpperCase() : "C";
                        })(),
                        style: const TextStyle(
                          color: AppColors.primaryDarkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (() {
                        final nameData = widget.customer['name'];
                        if (nameData is Map) {
                          String full = "${nameData['first'] ?? ''} ${nameData['last'] ?? ''}".trim();
                          return full.isNotEmpty ? full : (widget.customer['userName'] ?? 'Customer');
                        }
                        return widget.customer['userName'] ?? 'Customer';
                      })(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: AppColors.button, size: 14),
                        Text(
                          ' 4.8 Rating',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                    color: AppColors.backgroundWhite,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 18,
                color: AppColors.primaryDarkGreen,
              ),
              const SizedBox(width: 8),
              Text(widget.customer['email'] ?? 'No email provided', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  void _showCounterOfferDialog() {
    TextEditingController priceController = TextEditingController(
      text: currentPrice.toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text(
          'Propose New Price',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.primaryDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true,
            fillColor: const Color(0xFFF1F1E6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(
                      () => currentPrice =
                          int.tryParse(priceController.text) ?? currentPrice,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDarkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Send',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Propose New Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDarkGreen,
              ),
            ),
            const SizedBox(height: 20),
            _buildDialogField(
              'New Date',
              _dateController,
              Icons.calendar_today,
              true,
            ),
            const SizedBox(height: 15),
            _buildDialogField(
              'New Time',
              _timeController,
              Icons.access_time,
              false,
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDarkGreen,
                    ),
                    child: const Text(
                      'Send',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDate,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(icon),
          onPressed: isDate ? () => _selectDate(context) : null,
        ),
        filled: true,
        fillColor: const Color(0xFFF1F1E6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSmallActionBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 135,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.button,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDarkGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: Provider.of<UserProvider>(context).myBids[widget.taskId] != null 
                ? null 
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MakeOfferScreen(
                    taskId: widget.taskId,
                    initialPrice: widget.price,
                    taskTitle: widget.title,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              Provider.of<UserProvider>(context).myBids[widget.taskId] != null
                  ? 'Offer Submitted'
                  : 'Make Offer (\$$currentPrice)',
              style: const TextStyle(
                color: AppColors.backgroundWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            onPressed: () {
              final customerName = widget.customer['userName'] ?? widget.customer['name'] ?? "Customer";
              final customerId = widget.customer['_id'] ?? "";
              
              if (customerId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: customerId,
                      otherUserName: customerName,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.message_outlined),
            label: const Text('Message Customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDarkGreen,
              side: const BorderSide(color: AppColors.primaryDarkGreen, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Decline Job',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
