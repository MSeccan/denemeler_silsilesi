import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UzmanAraPage extends StatefulWidget {
  const UzmanAraPage({super.key});

  @override
  State<UzmanAraPage> createState() => _UzmanAraPageState();
}

class _UzmanAraPageState extends State<UzmanAraPage> {
  String selectedRole = 'all';
  late Stream<QuerySnapshot> expertsStream;

  @override
  void initState() {
    super.initState();
    expertsStream = _createStream();
  }

  Stream<QuerySnapshot> _createStream() {
    final ref = FirebaseFirestore.instance.collection('users');

    if (selectedRole == 'dietitian') {
      return ref.where('role', isEqualTo: 'dietitian').snapshots();
    }

    if (selectedRole == 'gynecologist') {
      return ref.where('role', isEqualTo: 'gynecologist').snapshots();
    }

    return ref
        .where('role', whereIn: ['dietitian', 'gynecologist'])
        //.where('isApproved', isEqualTo: true)
        .snapshots();
  }

  void _updateFilter(String value) {
    setState(() {
      selectedRole = value;
      expertsStream = _createStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Uzman Ara 🔍",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Size uygun uzmanı seçin",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _filterChip("Tümü", "all"),
                    _filterChip("Diyetisyen", "dietitian"),
                    _filterChip("Jinekolog", "gynecologist"),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: expertsStream,
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text(
                        "Bir hata oluştu 😢",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Uygun uzman bulunamadı 😔",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    final experts = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: experts.length,
                      itemBuilder: (context, index) {

                        final doc = experts[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final role = data['role'] ?? '';
                        final email = data['email'] ?? "Uzman";

                        final name = data['name'] ?? "Uzman";
                        final hospital = data['hospital'] ?? "Kurum bilgisi yok";

                        final isClient = data['clients'] != null &&
                            (data['clients'] as List).contains(currentUserId);

                        return Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surface,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),

                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: const Icon(
                                Icons.medical_services,
                                color: Colors.white,
                              ),
                            ),

                            title: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                  color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),

                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role == 'dietitian'
                                      ? "Diyetisyen"
                                      : "Jinekolog",
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  hospital,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),

                            trailing: SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isClient
                                    ? null
                                    : () async {

                                  final requestId = "${currentUserId}_${doc.id}";
                                  final docRef = FirebaseFirestore.instance
                                      .collection("expert_requests")
                                      .doc(requestId);

                                  final existingDoc = await docRef.get();

                                  if (!mounted) return;

                                  if (existingDoc.exists) {
                                    final status = existingDoc['status'];

                                    if (status == "pending") {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("Zaten istek gönderdiniz ⏳")),
                                      );
                                      return;
                                    }

                                    if (status == "approved") {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text("Zaten danışansınız ✅")),
                                      );
                                      return;
                                    }
                                  }

                                  await docRef.set({
                                    "clientId": currentUserId,
                                    "expertId": doc.id,
                                    "status": "pending",
                                    "createdAt": FieldValue.serverTimestamp(),
                                  });

                                  if (!mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text("İstek gönderildi ✅"),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                },
                                child: Text(
                                  isClient ? "Danışan" : "İstek",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = selectedRole == value;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
      onSelected: (_) => _updateFilter(value),
    );
  }
}