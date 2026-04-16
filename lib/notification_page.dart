import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String timeAgo(Timestamp? timestamp) {
  if (timestamp == null) return "";

  final now = DateTime.now();
  final date = timestamp.toDate();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return "Az önce";
  if (diff.inMinutes < 60) return "${diff.inMinutes} dk önce";
  if (diff.inHours < 24) return "${diff.inHours} saat önce";
  if (diff.inDays < 7) return "${diff.inDays} gün önce";

  return "${date.day}.${date.month}.${date.year}";
}

class NotificationPanel extends StatelessWidget {
  const NotificationPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(
          "Giriş yapılmamış",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        )),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get(),
      builder: (context, userSnap) {

        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData =
        userSnap.data!.data() as Map<String, dynamic>?;

        final role = userData?["role"] ?? "pregnant";

        final primaryColor = Theme.of(context).colorScheme.primary;

        final backgroundColor = Theme.of(context).colorScheme.surface;

        return Scaffold(
          backgroundColor: backgroundColor,

          appBar: AppBar(
            backgroundColor: primaryColor,
            title: Text(
              "Bildirimler",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            centerTitle: true,
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notification')
                .where('uid', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ));
              }

              if (!snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "Henüz bildirim yok",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {

                  final doc = docs[index];
                  final data =
                  doc.data() as Map<String, dynamic>;

                  final isRead = data['isRead'] ?? false;
                  final type = data['type'] ?? "general";
                  final title = data['title'] ?? "";
                  final message = data['message'] ?? "";

                  final createdAt =
                  data['createdAt'] as Timestamp?;
                  final timeText = timeAgo(createdAt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Theme.of(context).colorScheme.surface
                          : primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? Theme.of(context).dividerColor
                            : primaryColor,
                      ),
                    ),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: primaryColor,
                            child: Icon(
                              type == "risk_alert"
                                  ? Icons.warning
                                  : Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          if (!isRead)
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: Colors.black,
                              ),
                            ),
                        ],
                      ),

                      title: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w500
                              : FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),

                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),

                      onTap: () async {
                        if (!isRead) {
                          await doc.reference
                              .update({'isRead': true});
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}