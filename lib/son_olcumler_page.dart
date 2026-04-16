import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'hasta_klinik_detay_page.dart';

class SonOlcumlerPage extends StatelessWidget {
  const SonOlcumlerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Son Ölçümler"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("risk_olcumleri")
            .where("tarih", isGreaterThan: sevenDaysAgo)
            .orderBy("tarih", descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ));
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "Son 7 günde ölçüm yok",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final data =
              docs[index].data() as Map<String, dynamic>;

              final patientId = data["uid"];
              final tarih = data["tarih"] as Timestamp?;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(patientId)
                    .get(),
                builder: (context, userSnap) {

                  if (!userSnap.hasData) {
                    return const ListTile(
                      title: Text("Yükleniyor..."),
                    );
                  }

                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>?;

                  final name = userData?["name"] ?? "";
                  final surname = userData?["surname"] ?? "";

                  return Card(
                    color: Theme.of(context).colorScheme.surface,
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.favorite, color: Theme.of(context).colorScheme.onPrimary),
                      ),
                      title: Text(
                        "$name $surname",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        tarih != null ? _timeAgo(tarih) : "",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HastaKlinikDetayPage(
                              clientId: patientId,
                              name: name,
                              surname: surname,
                              initialIndex: index,
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
      ),
    );
  }

  String _timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return "${diff.inSeconds} sn önce";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} dk önce";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} saat önce";
    } else {
      return "${diff.inDays} gün önce";
    }
  }
}