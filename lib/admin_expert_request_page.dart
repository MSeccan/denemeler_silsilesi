import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expert_detail_page.dart';

class AdminExpertRequestsPage extends StatelessWidget {
  const AdminExpertRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzman Başvuruları"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('expert_applications')
            .where('status', isEqualTo: 'pending')
            //.orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Bekleyen uzman başvurusu yok 👌"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),

                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),

                  title: Text(
                    doc['email'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      Text("Rol: ${doc['role']}"),
                      Text("Lisans No: ${doc['licenseNumber']}"),

                      if (doc['experience'] != null)
                        Text("Deneyim: ${doc['experience']}"),

                      if (doc['hospital'] != null)
                        Text("Kurum: ${doc['hospital']}"),
                    ],
                  ),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          doc.reference.update({'status': 'rejected'});
                        },
                      ),

                      IconButton(
                        icon: Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          await approveExpert(context, doc);
                        },
                      ),

                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpertDetailPage(doc: doc),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> approveExpert(
      BuildContext context,
      QueryDocumentSnapshot doc,
      ) async {
    try {
      final uid = doc['uid'];
      final role = doc['role'];
      final diplomaUrl = doc['documentUrl'];

      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection('users').doc(uid),
        {
          'role': role,
          'diplomaUrl': diplomaUrl,
        },
      );

      batch.update(
        doc.reference,
        {'status': 'approved'},
      );

      batch.set(
        FirebaseFirestore.instance.collection('notification').doc(),
        {
          'uid': uid,
          'title': 'Uzman Başvurun Onaylandı 🎉',
          'message': 'Artık PregNova’da uzman olarak giriş yapabilirsin.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uzman onaylandı ✅")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Onay hatası: $e")),
      );
    }
  }

}
