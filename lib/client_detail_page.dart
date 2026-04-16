import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'besin_analiz_detay_page.dart';

class ChartData {
  final List<FlSpot> spots;
  final List<DateTime> dates;

  ChartData(this.spots, this.dates);
}

class ClientDetailPage extends StatelessWidget {
  final String clientId;

  const ClientDetailPage({super.key, required this.clientId});

  Future<ChartData> getWeightSpots() async {
    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: clientId)
        .get();

    final docs = query.docs;

    if (docs.isEmpty) return ChartData([], []);

    docs.sort((a, b) {
      final ta = a["tarih"] as Timestamp?;
      final tb = b["tarih"] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    for (int i = 0; i < docs.length; i++) {

      final rawKilo = docs[i]["kilo"];

      final kilo = (rawKilo is int)
          ? rawKilo.toDouble()
          : (rawKilo is double)
          ? rawKilo
          : 0.0;

      final date = (docs[i]["tarih"] as Timestamp).toDate();

      spots.add(FlSpot(i.toDouble(), kilo));
      dates.add(date);
    }

    return ChartData(spots, dates);
  }

  Future<ChartData> getCalorieSpots() async {

    print("CLIENT ID: $clientId");

    final query = await FirebaseFirestore.instance
        .collection("besin_analizleri")
        .where("uid", isEqualTo: clientId)
        .get();

    final docs = query.docs;

    print("DOC COUNT: ${docs.length}");

    if (docs.isEmpty) return ChartData([], []);

    docs.sort((a, b) {
      final ta = a["tarih"] as Timestamp?;
      final tb = b["tarih"] as Timestamp?;
      if (ta == null || tb == null) return 0;
      return ta.compareTo(tb);
    });

    List<FlSpot> spots = [];
    List<DateTime> dates = [];

    for (int i = 0; i < docs.length; i++) {

      final data = docs[i].data();

      print("DOC UID: ${data["uid"]}");
      print("KALORI RAW: ${data["kalori"]}");

      double kalori = (data["kalori"] ?? 0).toDouble();

      print("KALORI FINAL: $kalori");

      final date = (data["tarih"] as Timestamp).toDate();

      spots.add(FlSpot(i.toDouble(), kalori));
      dates.add(date);
    }

    return ChartData(spots, dates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Danışan Detayı"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(clientId)
            .get(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(
              child: Text("Danışan bulunamadı"),
            );
          }

          final name = data["name"] ?? "";
          final surname = data["surname"] ?? "";
          final hafta = data["hafta"] ?? "-";
          final kilo = data["kilo"] ?? "-";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.2),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "$name $surname",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        Text("Gebelik Haftası: $hafta"),
                        const SizedBox(height: 10),
                        Text("Güncel Kilo: $kilo kg"),

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "Kilo Grafiği",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<ChartData>(
                  future: getWeightSpots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final chartData = snapshot.data;
                    final spots = chartData?.spots ?? [];
                    final dates = chartData?.dates ?? [];

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: spots.isEmpty
                          ? const Center(
                        child: Text("Henüz kilo ölçümü girilmemiş"),
                      )
                          : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(value.toInt().toString());
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {

                                  int index = value.toInt();

                                  if (index >= dates.length) return const SizedBox();

                                  final date = dates[index];

                                  const days = ["Pzt","Sal","Çar","Per","Cum","Cmt","Paz"];

                                  return Text(
                                    days[date.weekday - 1],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {

                                  final index = spot.x.toInt();
                                  final date = dates[index];

                                  return LineTooltipItem(
                                    "${date.day}/${date.month}/${date.year}\n${spot.y.toStringAsFixed(1)} kg",
                                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                  );

                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  "Günlük Kalori Alımı",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                FutureBuilder<ChartData>(
                  future: getCalorieSpots(),
                  builder: (context, snapshot) {

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final chartData = snapshot.data;
                    final spots = chartData?.spots ?? [];
                    final dates = chartData?.dates ?? [];

                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: spots.isEmpty
                          ? const Center(
                        child: Text("Henüz kalori verisi girilmemiş"),
                      )
                          : LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(

                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 500,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),

                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (value, meta) {

                                  int index = value.toInt();

                                  if (index >= dates.length) {
                                    return const SizedBox();
                                  }

                                  final date = dates[index];

                                  const days = [
                                    "Pzt","Sal","Çar","Per","Cum","Cmt","Paz"
                                  ];

                                  return Text(
                                    days[date.weekday - 1],
                                    style: const TextStyle(fontSize: 10),
                                  );
                                },
                              ),
                            ),

                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),

                          borderData: FlBorderData(show: true),

                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Theme.of(context).colorScheme.primary,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                            ),
                          ],

                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {

                                  final index = spot.x.toInt();
                                  final date = dates[index];

                                  return LineTooltipItem(
                                    "${date.day}/${date.month}/${date.year}\n${spot.y.toInt()} kcal",
                                    TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                  );

                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  "Analiz Geçmişi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 20),

                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("besin_analizleri")
                      .where("uid", isEqualTo: clientId)
                      .orderBy("tarih", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Text("Henüz analiz yok");
                    }

                    return Column(
                      children: docs.map((doc) {

                        final data = doc.data() as Map<String, dynamic>;

                        final tarih = data["tarih"] != null
                            ? (data["tarih"] as Timestamp).toDate()
                            : null;

                        final takviyeler = data["takviyeler"] ?? [];

                        return _BesinCard(
                          tarih: tarih,
                          takviyeler: takviyeler,
                          kalori: (data["kalori"] ?? 0).toDouble(),
                          docId: doc.id,
                          missingNutrients: data["missingNutrients"] ?? [],
                        );

                      }).toList(),
                    );
                  },
                ),

              ],
            ),
          );
        },
      ),
    );
  }
}
class _BesinCard extends StatelessWidget {
  final DateTime? tarih;
  final List<dynamic> takviyeler;
  final double kalori;
  final String docId;
  final List<dynamic> missingNutrients;


  const _BesinCard({
    required this.tarih,
    required this.takviyeler,
    required this.kalori,
    required this.docId,
    required this.missingNutrients,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BesinAnalizDetayPage(docId: docId),
          ),
        );
      },

      child: Container(
        width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
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

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Text(
              tarih != null
                  ? "${tarih!.day}/${tarih!.month}/${tarih!.year}"
                  : "Tarih Yok",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Toplam Kalori: ${kalori.toInt()} kcal",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 10),

            ...missingNutrients.take(3).map((m) {
              return Row(
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    m,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }),

            ...takviyeler.take(3).map((t) {
              final name = t["ad"] ?? "";

              return Row(
                children: [
                  Icon(Icons.check, color: Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              );
            }),


            if (takviyeler.length > 3)
              const Text("..."),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BesinAnalizDetayPage(docId: docId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Detaylı İncele",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}