import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'gynecologist_patient_detail_page.dart';
import 'login_page.dart';
import 'notification_page.dart';
import 'expert_chat_list_page.dart';
import 'son_olcumler_page.dart';

class GynecologistHomePage extends StatefulWidget {
  const GynecologistHomePage({super.key});

  @override
  State<GynecologistHomePage> createState() =>
      _GynecologistHomePageState();
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}

class _GynecologistHomePageState
    extends State<GynecologistHomePage> {

  Future<int> getApprovedCount() async {
    final query = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: uid)
        .where("status", isEqualTo: "approved")
        .get();

    return query.docs.length;
  }

  Future<int> getPendingCount() async {
    final query = await FirebaseFirestore.instance
        .collection("expert_requests")
        .where("expertId", isEqualTo: uid)
        .where("status", isEqualTo: "pending")
        .get();

    return query.docs.length;
  }

  Future<int> getHighRiskCount() async {
    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("preeklampsiRisk", isEqualTo: "HIGH")
        .get();

    final uniquePatients = <String>{};

    for (var doc in query.docs) {
      final data = doc.data();
      final uid = data["uid"];

      if (uid != null) {
        uniquePatients.add(uid);
      }
    }

    return uniquePatients.length;
  }

  Future<Map<String, int>> getActiveThisWeek() async {
    final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("tarih", isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    final uniquePatients = <String>{};

    for (var doc in query.docs) {
      final data = doc.data();
      final uid = data["uid"];

      if (uid != null) {
        uniquePatients.add(uid);
      }
    }

    return {
      "measurements": query.docs.length,
      "patients": uniquePatients.length,
    };
  }
  Future<Map<String, int>> getRiskDistribution() async {

    final normal = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "normal")
        .get();

    final medium = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "medium")
        .get();

    final high = await FirebaseFirestore.instance
        .collection("users")
        .where("assignedDoctor", isEqualTo: uid)
        .where("riskLevel", isEqualTo: "high")
        .get();

    return {
      "normal": normal.docs.length,
      "medium": medium.docs.length,
      "high": high.docs.length,
    };

  }
  Widget _buildRecentActivity() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("risk_olcumleri")
          .orderBy("tarih", descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Text("Henüz aktivite yok");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: docs.map((doc) {

            final data = doc.data() as Map<String, dynamic>;
            final tarih = data["tarih"];
            final uid = data["uid"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .get(),
              builder: (context, userSnap) {

                if (!userSnap.hasData) {
                  return const SizedBox();
                }

                final userData =
                userSnap.data!.data() as Map<String, dynamic>?;

                final name = userData?["name"] ?? "";
                final surname = userData?["surname"] ?? "";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.2),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timeline, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$name $surname yeni ölçüm gönderdi",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeAgo(tarih),
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
  Widget _buildHighRiskBanner() {
    return FutureBuilder<int>(
      future: getHighRiskCount(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final count = snapshot.data!;

        if (count == 0) {
          return const SizedBox();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$count Yüksek Riskli Hasta Var",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _selectedIndex = 0;
  late final String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,

      appBar: AppBar(
        title: const Text("PregNova"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notification")
                .where("uid", isEqualTo: uid)
                .where("isRead", isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {

              bool hasNotif =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationPanel(),
                        ),
                      );
                    },
                  ),

                  if (hasNotif)
                    const Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: Colors.red,
                      ),
                    )

                ],
              );
            },
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Ana Sayfa"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.people), label: "Danışanlar"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.pending), label: "İstekler"),

          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("messages")
                  .snapshots(),
              builder: (context, snapshot) {

                int unreadCount = 0;

                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data["isRead"] == false &&
                        data["receiverId"] == uid;
                  }).length;
                }

                return Stack(
                  children: [
                    const Icon(Icons.message),

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
              icon: Icon(Icons.person), label: "Hesap"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomePage();

      case 1:
        return _buildPatientsPage();

      case 2:
        return _buildRequestsPage();

      case 3:
        return _buildMessagesPage();

      case 4:
        return _buildAccountPage();

      default:
        return _buildHomePage();
    }
  }
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHighRiskBanner(),

          Text(
            "Jinekolog Paneli",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 25),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [

              FutureBuilder<int>(
                future: getApprovedCount(),
                builder: (context, snapshot) {
                  return _premiumStatCard(
                    "Danışan",
                    snapshot.data?.toString() ?? "...",
                    Colors.pink,
                    Icons.people,
                        () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  );
                },
              ),

              FutureBuilder<int>(
                future: getPendingCount(),
                builder: (context, snapshot) {
                  return _premiumStatCard(
                    "Bekleyen",
                    snapshot.data?.toString() ?? "...",
                    Colors.orange,
                    Icons.pending,
                        () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  );
                },
              ),

              FutureBuilder<int>(
                future: getHighRiskCount(),
                builder: (context, snapshot) {
                  return _premiumStatCard(
                    "Yüksek Risk",
                    snapshot.data?.toString() ?? "...",
                    Colors.red,
                    Icons.warning,
                    null,
                  );
                },
              ),

              FutureBuilder<Map<String, int>>(
                future: getActiveThisWeek(),
                builder: (context, snapshot) {

                  final data = snapshot.data;

                  final text = data == null
                      ? "..."
                      : "${data["measurements"]} ölçüm\n${data["patients"]} hasta";

                  return _premiumStatCard(
                    "Son 7 Gün",
                    text,
                    Colors.green,
                    Icons.timeline,
                    (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SonOlcumlerPage(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildRiskChart(),

          const SizedBox(height: 30),

          Text(
            "Danışma İstekleri",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 10),

          _buildPatientRequests(),

          const SizedBox(height: 30),

          Text(
            "Son Aktiviteler",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 15),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildPatientsPage() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expert_requests")
          .where("expertId", isEqualTo: uid)
          .where("status", isEqualTo: "approved")
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
              "Henüz danışan bulunmuyor",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {

            final clientId = docs[index]["clientId"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(clientId)
                  .get(),
              builder: (context, userSnapshot) {

                if (!userSnapshot.hasData) {
                  return const SizedBox();
                }

                final data =
                userSnapshot.data!.data()
                as Map<String, dynamic>?;

                final name = data?["name"] ?? "";
                final surname = data?["surname"] ?? "";
                final hafta = data?["hafta"] ?? "-";
                final risk = data?["riskLevel"] ?? "normal";

                Color riskColor;
                String riskText;

                if (risk == "high") {
                  riskColor = Colors.red;
                  riskText = "Yüksek Risk";
                } else if (risk == "medium") {
                  riskColor = Colors.orange;
                  riskText = "Orta Risk";
                } else {
                  riskColor = Colors.green;
                  riskText = "Normal";
                }

                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),

                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: riskColor,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),

                    title: Text(
                      "$name $surname",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text("Gebelik Haftası: $hafta"),
                        const SizedBox(height: 4),
                        Text(
                          "Risk Durumu: $riskText",
                          style: TextStyle(
                              color: riskColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HastaDetayPage(
                            clientId: clientId,
                            name: name,
                            surname: surname,
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

  Widget _buildMessagesPage() {
    return const ExpertChatListPage();
  }

  Widget _buildAccountPage() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(user!.uid)
          .get(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data =
        snapshot.data!.data() as Map<String, dynamic>?;

        final name = data?["name"] ?? "";
        final email = user.email ?? "";

        final license = data?["licenseNumber"] ?? "-";
        final experience = data?["experience"] ?? "-";
        final hospital = data?["hospital"] ?? "-";

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.2), blurRadius: 6)
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dr. $name",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(email),
                        Text(
                          "Jinekolog",
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Uzmanlık Bilgileri",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _infoCard("Lisans No", license),
              _infoCard("Deneyim", experience),
              _infoCard("Çalıştığı Kurum", hospital),

              const SizedBox(height: 25),

              _accountTile(
                Icons.description,
                "Diploma / Belgeler",
                    () {
                  // Diploma sayfası buraya
                },
              ),

              const SizedBox(height: 25),

              const Text(
                "Ayarlar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              _accountTile(
                Icons.lock,
                "Şifre Değiştir",
                    () {
                  // şifre sayfası
                },
              ),

              _accountTile(
                Icons.logout,
                "Çıkış Yap",
                    () async {
                  await FirebaseAuth.instance.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginPage(),
                    ),
                        (route) => false,
                  );
                },
                color: Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _infoCard(String title, String value) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  Widget _accountTile(
      IconData icon,
      String title,
      VoidCallback onTap,
      {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }


  Widget _buildRequestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildPatientRequests(),
    );
  }

  Widget _premiumStatCard(
      String title,
      String value,
      Color color,
      IconData icon,
      VoidCallback? onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskChart() {
    return FutureBuilder<Map<String, int>>(
      future: getRiskDistribution(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final normal = data["normal"]!.toDouble();
        final medium = data["medium"]!.toDouble();
        final high = data["high"]!.toDouble();

        final total = normal + medium + high;

        if (total == 0) {
          return const SizedBox.shrink(); // 💣 tamamen yok
        }

        return Column(
          children: [
            Text(
              "Risk Dağılımı",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(color: Colors.green, value: normal),
                    PieChartSectionData(color: Colors.orange, value: medium),
                    PieChartSectionData(color: Colors.red, value: high),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Widget _buildPatientRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("expert_requests")
          .where("expertId", isEqualTo: uid)
          .where("status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Text("Bekleyen istek yok."),
          );
        }

        return Column(
          children: docs.map((doc) {

            final clientId = doc["clientId"];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(clientId)
                  .get(),
              builder: (context, userSnapshot) {

                if (!userSnapshot.hasData) return const SizedBox();

                final data = userSnapshot.data!.data() as Map<String, dynamic>?;

                final name = data?["name"] ?? "";
                final surname = data?["surname"] ?? "";
                final hafta = data?["hafta"] ?? "-";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text("$name $surname - Hafta $hafta"),

                      const SizedBox(height: 10),

                      Row(
                        children: [

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () async {

                              final doctorUid =
                                  FirebaseAuth.instance.currentUser!.uid;

                              await FirebaseFirestore.instance
                                  .collection("expert_requests")
                                  .doc(doc.id)
                                  .update({"status": "approved"});

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(clientId)
                                  .update({
                                "assignedDoctor": doctorUid,
                              });

                              print("ASSIGNED DOCTOR: $doctorUid to $clientId");
                            },
                            child: const Text("Kabul"),
                          ),

                          const SizedBox(width: 10),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () async {

                              await FirebaseFirestore.instance
                                  .collection("expert_requests")
                                  .doc(doc.id)
                                  .update({"status": "rejected"});
                            },
                            child: const Text("Reddet"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).shadowColor.withOpacity(0.2),
          blurRadius: 6,
        )
      ],
    );
  }
  String timeAgo(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
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
