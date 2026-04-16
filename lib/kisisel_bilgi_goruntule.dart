import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'kisisel_bilgi_page.dart';

class KisiselBilgilerGoruntulePage extends StatelessWidget {
  const KisiselBilgilerGoruntulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kişisel Bilgiler"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
        ),
        child: SafeArea(
          child: Column(
            children: [

              Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.centerLeft,
                child: Text(
                  "Kişisel Bilgiler",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              Expanded(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return Center(
                          child: CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.primary,
                          ));
                    }

                    final data =
                    snapshot.data!.data() as Map<String, dynamic>?;

                    if (data == null) {
                      return Center(
                          child: Text(
                            "Veri bulunamadı",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ));
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [

                          bilgiKart(context,
                            "Kronik Hipertansiyon",
                            (data['chronicHypertension'] ?? false) ? "Var" : "Yok",
                            Icons.monitor_heart,
                          ),

                          bilgiKart(context,
                            "Diyabet",
                            (data['diabetes'] ?? false) ? "Var" : "Yok",
                            Icons.bloodtype,
                          ),

                          bilgiKart(context,
                            "Tiroid Hastalığı",
                            (data['thyroidDisease'] ?? false) ? "Var" : "Yok",
                            Icons.health_and_safety,
                          ),

                          bilgiKart(context,
                            "Önceki Preterm",
                            (data['previousPreterm'] ?? false) ? "Var" : "Yok",
                            Icons.warning,
                          ),

                          bilgiKart(context,
                            "Çoğul Gebelik",
                            (data['multiplePregnancy'] ?? false) ? "Var" : "Yok",
                            Icons.groups,
                          ),

                          bilgiKart(context,
                            "Sigara",
                            (data['smoker'] ?? false) ? "Var" : "Yok",
                            Icons.smoking_rooms,
                          ),

                          const Spacer(),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const KisiselBilgilerPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                "Bilgileri Düzenle",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
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

  Widget bilgiKart(BuildContext context, String title, String value, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          value.isEmpty ? "Belirtilmemiş" : value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          )
        ),
      ),
    );
  }
}