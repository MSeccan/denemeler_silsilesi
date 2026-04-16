import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_page.dart';

class ExpertChatListPage extends StatelessWidget {
  const ExpertChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mesajlar"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("users", arrayContains: uid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(
              "Henüz mesaj yok",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {

              final data =
              chats[index].data() as Map<String, dynamic>;

              final users = List<String>.from(data["users"]);

              final otherUserId =
              users.firstWhere((u) => u != uid);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {

                  if (userSnap.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                        title: Text(
                          "Yükleniyor...",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ));
                  }

                  if (!userSnap.hasData ||
                      userSnap.data!.data() == null) {
                    return const ListTile(
                        title: Text("Kullanıcı bulunamadı"));
                  }

                  final userData =
                  userSnap.data!.data()
                  as Map<String, dynamic>;

                  final name = userData["name"] ?? "";
                  final surname = userData["surname"] ?? "";

                  String timeText = "";
                  if (data["lastMessageTime"] != null) {
                    final date =
                    (data["lastMessageTime"] as Timestamp)
                        .toDate();
                    timeText =
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("messages")
                        .where("chatId", isEqualTo: chats[index].id)
                        .snapshots(),

                    builder: (context, msgSnap) {

                      int unreadCount = 0;

                      if (msgSnap.hasData) {
                        unreadCount = msgSnap.data!.docs.where((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return d["isRead"] == false && d["senderId"] != uid;
                        }).length;
                      }

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),

                        title: Text(
                          "$name $surname",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),

                        subtitle: Text(
                          data["lastMessage"] ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),

                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            /// saat
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),

                            const SizedBox(height: 5),

                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: chats[index].id,
                                title: "$name $surname",
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}