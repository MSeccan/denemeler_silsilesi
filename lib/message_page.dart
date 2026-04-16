import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  Future<String> getOrCreateChat(String otherUserId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection("chats")
        .where("users", arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final users = List<String>.from(doc["users"]);
      if (users.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newChat = await FirebaseFirestore.instance
        .collection("chats")
        .add({
      "users": [currentUserId, otherUserId],
      "lastMessage": "",
      "lastMessageTime": FieldValue.serverTimestamp(),
    });

    return newChat.id;
  }



  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          final doctorId = data?["assignedDoctor"];
          final dietitianId = data?["assignedDietitian"];

          print("UID: $uid");
          print("Doctor: $doctorId");

          if (doctorId == null && dietitianId == null) {
            return Center(child: Text(
              "Henüz uzman yok 😔",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (doctorId != null && doctorId.toString().isNotEmpty)
                _card(context, doctorId, "Doktor"),

              if (dietitianId != null && dietitianId.toString().isNotEmpty)
                _card(context, dietitianId, "Diyetisyen"),
            ],
          );
        },
      ),
    );
  }

  Widget _card(BuildContext context, String otherUserId, String role) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder(
      future: getOrCreateChat(otherUserId),
      builder: (context, chatSnapshot) {

        if (!chatSnapshot.hasData) return const SizedBox();

        final chatId = chatSnapshot.data as String;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .snapshots(),
          builder: (context, chatSnap) {

            if (!chatSnap.hasData) return const SizedBox();

            final chatData =
            chatSnap.data!.data() as Map<String, dynamic>?;

            final lastMessage = chatData?["lastMessage"] ?? "";
            final time = chatData?["lastMessageTime"];

            String timeText = "";
            if (time != null) {
              final date = (time as Timestamp).toDate();
              timeText =
              "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherUserId)
                  .get(),
              builder: (context, userSnap) {

                if (!userSnap.hasData) {
                  return ListTile(
                    title: Text(
                      "Yükleniyor...",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  );
                }

                final userData =
                userSnap.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? role;

                String prefix = "";
                if (role == "Doktor") prefix = "Dr.";
                if (role == "Diyetisyen") prefix = "Dyt.";

                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      "$prefix $name",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      lastMessage,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // unread kısmı aynen kalıyor
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            chatId: chatId,
                            title: "$prefix $name",
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}