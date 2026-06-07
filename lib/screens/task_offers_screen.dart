import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'welcome_screen_modified.dart';
import 'chat_screen.dart';
import '../widgets/rating_dialog.dart';

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
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    try {
      final offers = await Provider.of<UserProvider>(context, listen: false)
          .fetchTaskOffers(widget.taskId);
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading task offers: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final task = userProvider.myRequests.firstWhere(
      (t) => t['id'] == widget.taskId,
      orElse: () => <String, dynamic>{},
    );
    final status = task['status']?.toString().toUpperCase() ?? '';
    final bool isAssigned = task.isNotEmpty &&
        (status == 'ASSIGNED' ||
         status == 'IN_PROGRESS' ||
         status == 'ONGOING' ||
         status == 'ACCEPTED' ||
         _offers.any((o) => o['status']?.toString().toLowerCase() == 'accepted'));

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
              ? const Center(child: Text("No offers yet. Waiting for workers."))
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
                                      child: const Text("Accept Offer"),
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
      bottomNavigationBar: isAssigned
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDarkGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
                onPressed: _isCompleting
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        setState(() => _isCompleting = true);
                        final provider = Provider.of<UserProvider>(context, listen: false);
                        final success = await provider.completeTask(widget.taskId);

                        if (!mounted) return;
                        setState(() => _isCompleting = false);

                        if (success) {
                          if (!context.mounted) return;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) => const RatingDialog(),
                          );
                          if (result != null && result['rating'] != null) {
                            final rating = result['rating'] as int;
                            if (mounted) {
                              setState(() => _isCompleting = true);
                            }
                            final rateSuccess = await provider.rateWorker(widget.taskId, rating);
                            if (mounted) {
                              setState(() => _isCompleting = false);
                              if (rateSuccess) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Task completed and worker rated successfully! ✅'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Task completed, but rating submission failed. ❌'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              provider.fetchMyRequests();
                              _loadOffers();
                            }
                          } else {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Task completed successfully! ✅'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              provider.fetchMyRequests();
                              _loadOffers();
                            }
                          }
                        } else {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to complete task. Please try again. ❌'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: _isCompleting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Complete Task',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          : null,
    );
  }
}
