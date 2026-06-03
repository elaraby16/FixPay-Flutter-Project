import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'request_details_screen.dart';
import 'welcome_screen_modified.dart';
import 'user_provider.dart';
import 'task_offers_screen.dart';

class ActiveRequestPage extends StatefulWidget {
  const ActiveRequestPage({super.key});

  @override
  State<ActiveRequestPage> createState() => _ActiveRequestPageState();
}

class _ActiveRequestPageState extends State<ActiveRequestPage> {
  @override
  void initState() {
    super.initState();
    // Fetch latest requests from backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchMyRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "Active Requests",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.backgroundWhite),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDarkGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.backgroundWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final requests = userProvider.myRequests;

          if (requests.isEmpty) {
            return const Center(child: Text("No active requests found."));
          }

          return RefreshIndicator(
            onRefresh: () => userProvider.fetchMyRequests(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 25),
              itemCount: requests.length,
              itemBuilder: (context, index) => _buildJobCard(
                job: requests[index],
                index: index,
                userProvider: userProvider,
                context: context,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getServiceIcon(String? type) {
    if (type == null) return Icons.build;
    if (type.contains('Electric')) return Icons.flash_on;
    if (type.contains('Plumb')) return Icons.water_drop;
    if (type.contains('Clean')) return Icons.cleaning_services;
    return Icons.build;
  }

  Widget _buildJobCard({
    required Map<String, dynamic> job,
    required int index,
    required UserProvider userProvider,
    required BuildContext context,
  }) {
    bool isPending = job['status'] == 'OPEN' || job['status'] == 'Pending';
    String workerName = isPending ? "Awaiting Acceptance" : (job['workerName'] ?? "Assigned");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskOffersScreen(
              taskId: job['id'] ?? "",
              taskTitle: job['title'] ?? "Service Request",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EFE9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getServiceIcon(job['serviceType']),
                  color: AppColors.primaryDarkGreen,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['title'] ?? "Service Request",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: AppColors.primaryDarkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Worker: $workerName",
                        style: const TextStyle(color: AppColors.textgrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "${job['status']} - \$${job['price'] ?? '0'}",
                    style: TextStyle(
                      color: isPending ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  job['date'] ?? "TBD",
                  style: const TextStyle(color: AppColors.textgrey, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailsScreen(
                          serviceName: job['title'] ?? job['serviceType'],
                          isEdit: true,
                          editData: job,
                          index: index,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note, color: AppColors.primaryDarkGreen, size: 30),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, userProvider, job['id']),
                  icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserProvider provider, String? taskId) {
    if (taskId == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              bool success = await provider.deleteRequestApi(taskId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task deleted successfully")));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete task")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
