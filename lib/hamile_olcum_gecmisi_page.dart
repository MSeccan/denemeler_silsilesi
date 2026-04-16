import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HamileOlcumGecmisiPage extends StatelessWidget {
  const HamileOlcumGecmisiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Risk Geçmişi"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('risk_olcumleri')
                      .where('uid', isEqualTo: uid)
                      .orderBy('tarih', descending: true)
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
                          "Henüz risk kaydı yok 💗",
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

                        return Card(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 0,
                          margin:
                          const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [

                                Text(
                                  "${tarih.day}.${tarih.month}.${tarih.year}  "
                                      "${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),

                                const Divider(),

                                const Text(
                                  "Preeklampsi",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir(context,
                                  "Tansiyon",
                                  "${data['sistolik'] ?? "-"} / ${data['diastolik'] ?? "-"}",),
                                _satir(context, "Baş ağrısı",
                                    _boolText(data['basAgrisi'])),
                                _satir(context, "Görme bozukluğu",
                                    _boolText(data['gormeBozuklugu'])),
                                _satir(context, "Şişlik",
                                    _boolText(data['sislik'])),
                                _satir(context,
                                  "Risk Sonucu",
                                  data['preeklampsiRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Gestasyonel Diyabet",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir(context, "Açlık",
                                    "${data['aclikSeker'] ?? "-"}"),
                                _satir(context, "Tokluk",
                                    "${data['toklukSeker'] ?? "-"}"),
                                _satir(context,"Aşırı susama",
                                    _boolText(data['asiriSusama'])),
                                _satir(context,"Sık idrar",
                                    _boolText(data['sikIdrar'])),
                                _satir(context,
                                  "Risk Sonucu",
                                  data['diyabetRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                const Text(
                                  "Preterm Risk",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                _satir(context, "Kasılma",
                                    _boolText(data['karinKasilma'])),
                                _satir(context, "Akıntı",
                                    _boolText(data['akinti'])),
                                _satir(context, "Bel ağrısı",
                                    _boolText(data['belAgrisi'])),
                                _satir(context, "Stres",
                                    "${data['stresSeviyesi'] ?? "-"}"),
                                _satir(context,
                                  "Risk Sonucu",
                                  data['pretermRisk'] ?? "-",
                                ),

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      FirebaseFirestore.instance
                                          .collection('risk_olcumleri')
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

  Widget _satir(BuildContext context, String title, String value) {

    Color color = Theme.of(context).colorScheme.onSurface;

    if (value == "HIGH") color = Colors.red;
    if (value == "MEDIUM") color = Colors.orange;
    if (value == "LOW") color = Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _boolText(bool? value) {
    if (value == null) return "-";
    return value ? "Evet" : "Hayır";
  }
}