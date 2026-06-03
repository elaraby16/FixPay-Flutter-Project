import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'welcome_screen_modified.dart';
import 'chat_screen.dart';

class TaskOffersScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const TaskOffersScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<TaskOffersScreen> createState() => _TaskOffersScreenState();
}

class _TaskOffersScreenState extends State<TaskOffersScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final offers = await Provider.of<UserProvider>(context, listen: false)
        .fetchTaskOffers(widget.taskId);
    if (mounted) {
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "Offers",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.backgroundWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.backgroundWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? const Center(child: Text("No offers received yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    final worker = offer['workerId'] ?? {};
                    
                    // Format worker name
                    String workerName = "";
                    final nameData = worker['name'];
                    if (nameData is Map) {
                      workerName = "${nameData['first'] ?? ''} ${nameData['last'] ?? ''}".trim();
                    }
                    if (workerName.isEmpty) {
                      workerName = worker['userName'] ?? "Unknown Worker";
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: worker['avatar'] != null ? NetworkImage(worker['avatar']) : null,
                                  child: worker['avatar'] == null ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        workerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.orange, size: 16),
                                          Text(" ${worker['rating'] ?? '5.0'}", style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "\$${offer['price']}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDarkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (offer['message'] != null && offer['message'].toString().isNotEmpty) ...[
                              const Text("Message:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(offer['message'], style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (offer['estimatedTime'] != null)
                                      Text("⏱ Time: ${offer['estimatedTime']} mins", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    if (offer['estimatedDistance'] != null)
                                      Text("📍 Dist: ${offer['estimatedDistance']} km", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        final worker = offer['workerId'] ?? {};
                                        final workerName = worker['userName'] ?? worker['name'] ?? "Worker";
                                        final workerId = worker['_id'] ?? "";
                                        
                                        if (workerId.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                otherUserId: workerId,
                                                otherUserName: workerName,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.message_outlined, size: 18),
                                      label: const Text("Chat"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primaryDarkGreen,
                                        side: const BorderSide(color: AppColors.primaryDarkGreen),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final provider = Provider.of<UserProvider>(context, listen: false);
                                        bool success = await provider.acceptOfferApi(offer['_id']);
                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Offer accepted! Job assigned successfully. ✅"),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          provider.fetchMyRequests();
                                          Navigator.pop(context);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Failed to accept offer. Please try again. ❌"),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryDarkGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      child: const Text("Accept"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
