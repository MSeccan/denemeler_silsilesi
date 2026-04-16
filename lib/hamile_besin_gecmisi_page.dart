import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HamileBesinGecmisiPage extends StatelessWidget {
  const HamileBesinGecmisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Besin & Takviye Geçmişi",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('besin_analizleri')
                      .where('uid', isEqualTo: uid)
                      .orderBy('tarih', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "Henüz kayıt yok 💗",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {

                        final data =
                        docs[index].data() as Map<String, dynamic>;

                        final tarih =
                        (data['tarih'] as Timestamp).toDate();

                        final formattedDate =
                        DateFormat("dd MMMM yyyy - HH:mm", "tr_TR")
                            .format(tarih);

                        final List besinler =
                            data['besinler'] ?? [];

                        final List takviyeler =
                            data['takviyeler'] ?? [];

                        final List consumed = data['consumedNutrients'] ?? [];

                        final List missing = data['missingNutrients'] ?? [];

                        final List excess =
                            data['excessNutrients'] ?? [];

                        return Card(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),

                                const Divider(),

                                if (besinler.isNotEmpty) ...[
                                  Text(
                                    "Besinler",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...besinler.map((b) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            b['ad'],
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "${b['miktar']} ${b['format']}",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 10),
                                ],

                                if (takviyeler.isNotEmpty) ...[
                                  Text(
                                    "Takviyeler",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...takviyeler.map((t) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 3),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            t['ad'],
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          Text(
                                            "${t['miktar']} ${t['format']}",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],

                                const SizedBox(height: 10),

                                if (consumed.isNotEmpty) ...[
                                  Text(
                                    "Alınan Besin Öğeleri",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...consumed.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }),

                                  const SizedBox(height: 10),
                                ],

                                if (missing.isNotEmpty) ...[
                                  Text(
                                    "Eksik Besin Öğeleri",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...missing.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.warning,
                                            color: Colors.orange, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }),
                                ],

                                if (excess.isNotEmpty) ...[
                                  Text(
                                    "Fazla Besin Öğeleri",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  ...excess.map((n) {
                                    return Row(
                                      children: [
                                        const Icon(Icons.arrow_upward,
                                            color: Colors.red, size: 18),
                                        const SizedBox(width: 6),
                                        Text(n),
                                      ],
                                    );
                                  }),
                                ],

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('besin_analizleri')
                                          .doc(docs[index].id)
                                          .delete();
                                    },
                                  ),
                                ),
                              ],
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
}