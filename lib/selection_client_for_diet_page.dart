import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'create_diet_page.dart';

class SelectClientForDietPage extends StatelessWidget {
  const SelectClientForDietPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Danışan Seç"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("expert_requests")
            .where("expertId", isEqualTo: uid)
            .where("status", isEqualTo: "approved")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Danışan bulunamadı",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final clientId = docs[index]["clientId"];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(clientId)
                    .get(),
                builder: (context, userSnap) {

                  if (!userSnap.hasData) {
                    return const ListTile(title: Text("Yükleniyor..."));
                  }

                  final data = userSnap.data!.data() as Map<String, dynamic>;

                  final name = data["name"] ?? "";
                  final surname = data["surname"] ?? "";

                  return Card(
                    color: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        "$name $surname",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CreateDietPage(clientId: clientId),
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
      ),
    );
  }
}