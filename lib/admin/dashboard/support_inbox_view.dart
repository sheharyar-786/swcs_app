import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../widgets/universal_header.dart';

class SupportInboxView extends StatelessWidget {
  const SupportInboxView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: CustomScrollView(
        slivers: [
          UniversalHeader(
            title: "Support Inbox",
            showBackButton: true,
          ),
          StreamBuilder(
            stream: FirebaseDatabase.instance.ref('support_messages').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF0A714E))),
                );
              }

              if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        const Text(
                          "All caught up!",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }

              Map data = snapshot.data!.snapshot.value as Map;
              var items = data.entries.toList();
              // Sort by timestamp (newest first)
              items.sort((a, b) => (b.value['timestamp'] ?? 0).compareTo(a.value['timestamp'] ?? 0));

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var msg = items[index].value;
                      String id = items[index].key;
                      DateTime dt = DateTime.fromMillisecondsSinceEpoch(msg['timestamp'] ?? 0);
                      String time = DateFormat('jm').format(dt);
                      String date = DateFormat('dd MMM').format(dt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  msg['sender'] ?? "Unknown",
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "$time, $date",
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              msg['message'] ?? "",
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ),
                          trailing: msg['status'] == 'Pending'
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                  onPressed: () {
                                    FirebaseDatabase.instance
                                        .ref('support_messages/$id')
                                        .update({'status': 'Resolved'});
                                  },
                                )
                              : const Icon(Icons.check_circle, color: Colors.green),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
