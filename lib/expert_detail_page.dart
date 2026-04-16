import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpertDetailPage extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const ExpertDetailPage({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? "pending";

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text("Başvuru Detayı"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.2),
                    blurRadius: 6,
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['email'] ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['role'] ?? "-",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 25),

            _infoCard(context, Icons.badge, "Lisans No", data['licenseNumber']),
            _infoCard(context, Icons.work, "Deneyim", data['experience']),
            _infoCard(context, Icons.phone, "Telefon", data['phone']),
            _infoCard(context, Icons.local_hospital, "Kurum", data['hospital']),
            _infoCard(context, Icons.location_city, "Şehir", data['city']),

            const SizedBox(height: 25),

            if (data['documentUrl'] != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Diplomayı Gör"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text("Diploma"),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.network(data['documentUrl']),
                            )
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 25),

            Row(
              children: [

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Reddet"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await doc.reference.update({'status': 'rejected'});

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Başvuru reddedildi ❌")),
                      );

                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Onayla"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {

                      final uid = data['uid'] ?? "";
                      if (uid.isEmpty) return;
                      final role = data['role'];
                      final diplomaUrl = data['documentUrl'];

                      final batch = FirebaseFirestore.instance.batch();

                      batch.update(
                        FirebaseFirestore.instance.collection('users').doc(uid),
                        {
                          'role': role,
                          'diplomaUrl': diplomaUrl,
                        },
                      );

                      batch.update(doc.reference, {'status': 'approved'});

                      batch.set(
                        FirebaseFirestore.instance.collection('notification').doc(),
                        {
                          'uid': uid,
                          'title': 'Uzman Başvurun Onaylandı 🎉',
                          'message':
                          'Artık PregNova’da uzman olarak giriş yapabilirsin.',
                          'isRead': false,
                          'createdAt': FieldValue.serverTimestamp(),
                        },
                      );

                      await batch.commit();
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Uzman onaylandı ✅")),
                      );

                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status == "approved"
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : status == "rejected"
                    ? Colors.red.shade100
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    status == "approved"
                        ? Icons.check_circle
                        : status == "rejected"
                        ? Icons.cancel
                        : Icons.hourglass_top,
                    color: status == "approved"
                        ? Colors.green
                        : status == "rejected"
                        ? Colors.red
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == "approved"
                        ? "Başvuru onaylandı"
                        : status == "rejected"
                        ? "Başvuru reddedildi"
                        : "Başvuru beklemede",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, IconData icon, String title, dynamic value) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(value?.toString() ?? "-"),
      ),
    );
  }
}