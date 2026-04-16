import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'food_units.dart';
import 'nutrition_engine.dart';

class HamileBesinPage extends StatefulWidget {
  const HamileBesinPage({super.key});

  @override
  State<HamileBesinPage> createState() => _HamileBesinPageState();
}

class _HamileBesinPageState extends State<HamileBesinPage> {
  final List<Map<String, dynamic>> besinListesi = [];
  final List<Map<String, dynamic>> takviyeListesi = [];

  final _besinAdiController = TextEditingController();
  final _besinMiktarController = TextEditingController();
  String _besinFormat = 'tane';

  final _takviyeAdiController = TextEditingController();
  final _takviyeMiktarController = TextEditingController();
  String _takviyeFormat = 'ölçek';

  final List<String> formatlar = [
    'tane', 'tabak', 'bardak', 'fincan',
    'kaşık', 'gram', 'ml', 'ölçek'
  ];

  bool _loading = false;

  @override
  void dispose() {
    _besinAdiController.dispose();
    _besinMiktarController.dispose();
    _takviyeAdiController.dispose();
    _takviyeMiktarController.dispose();
    super.dispose();
  }

  void besinEkle() {
    if (_besinAdiController.text.isEmpty ||
        _besinMiktarController.text.isEmpty) {
      return;
    }

    setState(() {
      besinListesi.add({
        'ad': _besinAdiController.text,
        'format': _besinFormat,
        'miktar': _besinMiktarController.text,
      });
      _besinAdiController.clear();
      _besinMiktarController.clear();
    });
  }

  void takviyeEkle() {
    if (_takviyeAdiController.text.isEmpty ||
        _takviyeMiktarController.text.isEmpty) {
      return;
    }

    setState(() {
      takviyeListesi.add({
        'ad': _takviyeAdiController.text,
        'format': _takviyeFormat,
        'miktar': _takviyeMiktarController.text,
      });
      _takviyeAdiController.clear();
      _takviyeMiktarController.clear();
    });
  }

  Future<void> kaydetAnaliz() async {

    try {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("KULLANICI YOK");
        return;
      }

      if (besinListesi.isEmpty && takviyeListesi.isEmpty) {
        print("LİSTE BOŞ");
        return;
      }

      setState(() {
        _loading = true;
      });

      List<Map<String, dynamic>> foodsForAnalysis = [];

      for (var item in besinListesi) {

        double unitGram =
            FoodUnits.units[item["format"]] ?? 0;

        double miktar =
            double.tryParse(item["miktar"]) ?? 0;

        double totalGram = unitGram * miktar;

        foodsForAnalysis.add({
          "name": item["ad"],
          "amount": totalGram
        });
      }

      List<Map<String, dynamic>> supplementsForAnalysis = [];

      for (var item in takviyeListesi) {

        supplementsForAnalysis.add({
          "name": item["ad"],
          "amount": item["miktar"]
        });
      }

      final analiz = NutritionEngine.analyzeFoods(
          foodsForAnalysis,
          supplementsForAnalysis,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final dietitianId = userDoc["assignedDietitian"];
      if (dietitianId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Henüz diyetisyen atanmadı ❗"),
          ),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('besin_analizleri')
          .add({

        'uid': user.uid,
        'dietitianId': dietitianId,
        'tarih': Timestamp.now(),

        'besinler': besinListesi,
        'takviyeler': takviyeListesi,

        'kalori': analiz["totalCalories"] ?? 0,

        'foodDetails': analiz["foodDetails"],
        'consumedNutrients': analiz["consumedNutrients"],
        'missingNutrients': analiz["missingNutrients"]

      });

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text("Besin Analizi"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text("Alınan Besin Öğeleri"),

              const SizedBox(height: 8),

              ...analiz["consumedNutrients"]
                  .map<Widget>((n) => Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(n),
                ],
              ))
                  .toList(),

              const SizedBox(height: 20),

              const Text("Eksik Besin Öğeleri"),

              const SizedBox(height: 10),

              ...analiz["missingNutrients"]
                  .map<Widget>((n) => Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(n),
                ],
              )).toList(),
              const SizedBox(height: 20),

              const Text("Fazla Besin Öğeleri"),

              const SizedBox(height: 10),

              ...analiz["excessNutrients"]
                  .map<Widget>((n) => Text("⬆ $n"))
                  .toList(),
            ],
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Kaydedildi 💗"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      setState(() {
        besinListesi.clear();
        takviyeListesi.clear();
        _loading = false;
      });

    } catch (e) {

      print("HATA VAR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );

      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text("Besin ve Takviye Analizi"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSectionTitle("📌 Besin Girişi"),
            _buildTextField("Besin Adı", _besinAdiController),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    _besinFormat,
                        (v) => setState(() => _besinFormat = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField("Miktar", _besinMiktarController),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _pinkButton("Besin Ekle", besinEkle),

            const SizedBox(height: 25),

            _buildSectionTitle("💊 Takviye Girişi"),
            _buildTextField("Takviye Adı", _takviyeAdiController),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    _takviyeFormat,
                        (v) => setState(() => _takviyeFormat = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTextField("Miktar", _takviyeMiktarController),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _pinkButton("Takviye Ekle", takviyeEkle),

            const SizedBox(height: 30),

            _buildList("📝 Girilen Besinler", besinListesi),
            const SizedBox(height: 20),
            _buildList("📝 Girilen Takviyeler", takviyeListesi),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: _loading ? null : kaydetAnaliz,
              child: _loading
                  ? CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
              )
                  : const Text("Günü Kaydet",
                  style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: formatlar
          .map((f) => DropdownMenuItem(
        value: f,
        child: Text(f),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _pinkButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(double.infinity, 45),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _buildList(String title, List<Map<String, dynamic>> liste) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (liste.isEmpty)
            Text(
              "Henüz ekleme yok",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ...liste.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Expanded(
                  child: Text(
                    "- ${item['ad']} (${item['miktar']} ${item['format']})",
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      liste.remove(item);
                    });
                  },
                ),

              ],
            ),
          )),
        ],
      ),
    );
  }
}