import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_olcum_page.dart';
import 'hamile_besin_page.dart';
import 'login_page.dart';
import 'hesabim_page.dart';
import 'notification_page.dart';
import 'message_page.dart';
import 'uzman_ara_page.dart';
import 'hamile_info_page.dart';
import 'hamile_olcum_gecmisi_page.dart';
import 'hamile_besin_gecmisi_page.dart';

class HamileAnaSayfa extends StatefulWidget {
  const HamileAnaSayfa({super.key});

  @override
  State<HamileAnaSayfa> createState() => _HamileAnaSayfaState();
}

class _HamileAnaSayfaState extends State<HamileAnaSayfa> {
  int? userWeek;
  int _selectedIndex = 2;
  late final List<Widget> pages;

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  void initState() {
    super.initState();

    pages = [
      const MessagePage(),
      const UzmanAraPage(),
      Container(),
      isLoggedIn ? HesabimPage() : const LoginPage(),
    ];

    loadUserWeek();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showBilgiFormuDialog();
    });
  }

  Future<void> loadUserWeek() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    final week = data['hafta'];

    final parsedWeek = (week is int)
        ? week
        : int.tryParse(week.toString()) ?? 1;

    setState(() {
      userWeek = parsedWeek;
    });

    await haftalikBildirimKontrol();
  }

  Future<void> haftalikBildirimKontrol() async {
    if (userWeek == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final week = userWeek!;

    final query = await FirebaseFirestore.instance
        .collection('notification')
        .where('uid', isEqualTo: uid)
        .where('week', isEqualTo: week)
        .get();

    if (query.docs.isNotEmpty) return;

    await FirebaseFirestore.instance.collection('notification').add({
      'uid': uid,
      'week': week,
      'title': 'Hafta $week Bilgilendirmesi',
      'message':
      'Bu haftada demir ve protein ihtiyacın artıyor. Beslenmene dikkat et 💕',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> showBilgiFormuDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
    if (data == null) return;

    if (data['profilTamamlandi'] == true || data['infoLater'] == true) {
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Gebelik Bilgileri"),
        content: const Text(
          "Gebelik bilgilerini doldurmak ister misin?\n\n"
              "Bu bilgiler sana daha doğru öneriler sunmamızı sağlar 💕",
        ),
        actions: [
          TextButton(
            child: const Text("Daha Sonra"),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'infoLater': true});
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text("Şimdi Doldur"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HamileBilgiFormuPage(uid: uid),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("PregNova"),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => isLoggedIn
                          ? const NotificationPanel()
                          : const LoginPage(),
                    ),
                  );
                },
              ),

              if (isLoggedIn)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('notification')
                      .where('uid',
                      isEqualTo:
                      FirebaseAuth.instance.currentUser!.uid)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return const SizedBox();
                    }

                    return const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                          radius: 5, backgroundColor: Colors.red),
                    );
                  },
                ),
            ],
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const MessagePage(),
          const UzmanAraPage(),
          _buildHomeContent(), // ✅ ARTIK BURADA
          isLoggedIn ? HesabimPage() : const LoginPage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .snapshots(),
              builder: (context, snapshot) {

                int unreadCount = 0;

                if (snapshot.hasData) {
                  final uid = FirebaseAuth.instance.currentUser!.uid;

                  unreadCount = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["isRead"] == false &&
                        data["senderId"] != uid;
                  }).length;
                }

                return Stack(
                  children: [
                    const Icon(Icons.chat_bubble_outline),

                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? "99+" : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: "Mesajlar",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Ara",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Ana Sayfa",
          ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Hesabım",
          ),
        ],
      ),
    );
  }

  Widget gridButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,),
          ),
        ]),
      ),
    );
  }
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Hoş geldin anne 💕",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Sağlık ve beslenme takibini kolayca yapabilirsin.",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.baby_changing_station,
                    color: Colors.white, size: 40),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Şu an",
                        style: TextStyle(color: Colors.white70)),

                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {

                        if (!snapshot.hasData) {
                          return const Text(
                            "Yükleniyor...",
                            style: TextStyle(color: Colors.white),
                          );
                        }

                        final data =
                        snapshot.data!.data() as Map<String, dynamic>;

                        final week = data['hafta'] ?? 1;

                        return Text(
                          "$week. Hafta",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          riskDashboard(),

          gridButton(
            title: "Risk Ölçüm",
            icon: Icons.health_and_safety,
            color: Colors.deepPurple.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => RiskTakipFormuPage()),
            ),
          ),

          gridButton(
            title: "Besin Analizi",
            icon: Icons.restaurant_menu,
            color: Colors.indigo.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HamileBesinPage()),
            ),
          ),

          gridButton(
            title: "Son Ölçüm Geçmişi",
            icon: Icons.history,
            color: Colors.deepPurple.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const HamileOlcumGecmisiPage()),
            ),
          ),

          gridButton(
            title: "Besin & Takviye Geçmişi",
            icon: Icons.medication,
            color: Colors.indigo.shade400,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const HamileBesinGecmisiPage()),
            ),
          ),
        ],
      ),
    );
  }
}

Widget riskDashboard() {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return const SizedBox();

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: uid)
        .orderBy("tarih", descending: true)
        .limit(1)
        .snapshots(),
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox();
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const SizedBox();
      }

      final data =
      snapshot.data!.docs.first.data() as Map<String, dynamic>;

      Color riskColor(String risk) {
        if (risk == "HIGH") return Colors.red;
        if (risk == "MEDIUM") return Colors.orange;
        return Colors.green;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.2), blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Son Risk Durumu",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            riskRow(context, "Preeklampsi",
                data["preeklampsiRisk"] ?? "LOW", riskColor),
            riskRow(context, "Diyabet",
                data["diyabetRisk"] ?? "LOW", riskColor),
            riskRow(context, "Preterm",
                data["pretermRisk"] ?? "LOW", riskColor),
          ],
        ),
      );
    },
  );
}

Widget riskRow(BuildContext context,
    String title, String risk, Color Function(String) color) {
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
          risk,
          style: TextStyle(
            color: color(risk),
            fontWeight: FontWeight.bold,
          ),
        )
      ],
    ),
  );
}