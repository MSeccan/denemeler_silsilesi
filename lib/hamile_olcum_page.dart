import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'risk_engine.dart';

class RiskTakipFormuPage extends StatefulWidget {
  const RiskTakipFormuPage({super.key});

  @override
  State<RiskTakipFormuPage> createState() => _RiskTakipFormuPageState();
}

class _RiskTakipFormuPageState extends State<RiskTakipFormuPage> {
  final _formKey = GlobalKey<FormState>();

  final sistolikController = TextEditingController();
  final diastolikController = TextEditingController();
  final aclikSekerController = TextEditingController();
  final toklukSekerController = TextEditingController();
  final kiloController = TextEditingController();

  bool basAgrisi = false;
  bool gormeBozuklugu = false;
  bool sislik = false;

  bool asiriSusama = false;
  bool sikIdrar = false;

  bool karinKasilma = false;
  bool akinti = false;
  bool belAgrisi = false;

  double stresSeviyesi = 1;

  bool _loading = false;

  @override
  void dispose() {
    sistolikController.dispose();
    diastolikController.dispose();
    aclikSekerController.dispose();
    toklukSekerController.dispose();
    kiloController.dispose();
    super.dispose();
  }

  Future<void> kaydet() async {
    try {
      if (!_formKey.currentState!.validate()) return;

      setState(() => _loading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final userData = userDoc.data() ?? {};
      final sistolik = int.tryParse(sistolikController.text) ?? 0;
      final diastolik = int.tryParse(diastolikController.text) ?? 0;

      if (diastolik >= sistolik) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Küçük tansiyon büyükten küçük olmalıdır"),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        return;
      }

      final aclik = double.tryParse(aclikSekerController.text);
      final tokluk = double.tryParse(toklukSekerController.text);

      final preeklampsiRisk = await RiskEngine.calculatePreeklampsi(
        uid: uid,
        sistolik: sistolik,
        diastolik: diastolik,
        gormeBozuklugu: gormeBozuklugu,
        basAgrisi: basAgrisi,
        sislik: sislik,
        chronicHypertension: userData["chronicHypertension"] ?? false,
      );
      final diyabetRisk = RiskEngine.calculateDiyabet(
        aclik: aclik,
        tokluk: tokluk,
        asiriSusama: asiriSusama,
        sikIdrar: sikIdrar,
        diabetes: userData["diabetes"] ?? false,
      );
      final pretermRisk = RiskEngine.calculatePreterm(
        karinKasilma: karinKasilma,
        akinti: akinti,
        belAgrisi: belAgrisi,
        stresSeviyesi: stresSeviyesi,
        previousPreterm: userData["previousPreterm"] ?? false,
        multiplePregnancy: userData["multiplePregnancy"] ?? false,
      );

      String overallRisk = "low";

      if (preeklampsiRisk == "HIGH" ||
          diyabetRisk == "HIGH" ||
          pretermRisk == "HIGH") {
        overallRisk = "high";
      }
      else if (preeklampsiRisk == "MEDIUM" ||
          diyabetRisk == "MEDIUM" ||
          pretermRisk == "MEDIUM") {
        overallRisk = "medium";
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({
        "riskLevel": overallRisk,
      }, SetOptions(merge: true));

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Preeklampsi",
        riskLevel: preeklampsiRisk,
      );

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Gestasyonel Diyabet",
        riskLevel: diyabetRisk,
      );

      await RiskEngine.sendRiskNotification(
        uid: uid,
        riskType: "Preterm Doğum",
        riskLevel: pretermRisk,
      );

      await showDialog(
        context: context,
        builder: (context){
          Color color(String risk){
            if (risk == "HIGH") return Colors.red;
            if (risk == "MEDIUM") return Colors.orange;
            return Colors.green;
          }
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text("Risk Sonucu"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _riskRow("Preeklampsi", preeklampsiRisk, color),
                _riskRow("Diyabet", diyabetRisk, color),
                _riskRow("Preterm", pretermRisk, color),
              ],
            ),
            actions: [
              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Text("Tamam"),
              )
            ],
          );
        },
      );

      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .set({
        "kilo": double.tryParse(kiloController.text),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('risk_olcumleri').add({
        'uid': uid,
        'tarih': Timestamp.now(),
        'kilo': double.tryParse(kiloController.text),

        'sistolik': int.tryParse(sistolikController.text),
        'diastolik': int.tryParse(diastolikController.text),
        'basAgrisi': basAgrisi,
        'gormeBozuklugu': gormeBozuklugu,
        'sislik': sislik,

        'aclikSeker': aclik,
        'toklukSeker': tokluk,
        'asiriSusama': asiriSusama,
        'sikIdrar': sikIdrar,

        'karinKasilma': karinKasilma,
        'akinti': akinti,
        'belAgrisi': belAgrisi,
        'stresSeviyesi': stresSeviyesi,

        'preeklampsiRisk': preeklampsiRisk,
        'diyabetRisk': diyabetRisk,
        'pretermRisk': pretermRisk,
      });
      if (mounted) {
        setState(() => _loading = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Risk verileri kaydedildi 💗"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _riskRow(String title, String risk, Color Function(String) color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Risk Takip Formu"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              _textInput("Güncel Kilo (kg)", kiloController),

              const SizedBox(height: 20),

              _sectionTitle("Preeklampsi Takibi"),

              _textInput("Sistolik (Örnek: 120)", sistolikController),
              _textInput("Diastolik (Örnek: 80)", diastolikController),

              _switchTile("Şiddetli baş ağrısı", basAgrisi,
                      (v) => setState(() => basAgrisi = v)),

              _switchTile("Görme bozukluğu", gormeBozuklugu,
                      (v) => setState(() => gormeBozuklugu = v)),

              _switchTile("El/Yüz şişmesi", sislik,
                      (v) => setState(() => sislik = v)),

              const SizedBox(height: 20),

              _sectionTitle("Gestasyonel Diyabet"),

              _textInput("Açlık kan şekeri", aclikSekerController),
              _textInput("Tokluk kan şekeri", toklukSekerController),

              _switchTile("Aşırı susama", asiriSusama,
                      (v) => setState(() => asiriSusama = v)),

              _switchTile("Sık idrar", sikIdrar,
                      (v) => setState(() => sikIdrar = v)),

              const SizedBox(height: 20),

              _sectionTitle("Preterm Riski"),

              _switchTile("Karın kasılması", karinKasilma,
                      (v) => setState(() => karinKasilma = v)),

              _switchTile("Akıntı artışı", akinti,
                      (v) => setState(() => akinti = v)),

              _switchTile("Bel ağrısı", belAgrisi,
                      (v) => setState(() => belAgrisi = v)),

              const SizedBox(height: 10),

              const Text("Stres Seviyesi"),

              Slider(
                value: stresSeviyesi,
                min: 1,
                max: 5,
                divisions: 4,
                label: stresSeviyesi.round().toString(),
                onChanged: (value) {
                  setState(() => stresSeviyesi = value);
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : kaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                      : const Text("Kaydet"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Bu alan boş bırakılamaz";
          }

          final v = int.tryParse(value);
          if (v == null) {
            return "Geçerli sayı giriniz";
          }

          if (label.contains("Sistolik")) {
            if (v < 80 || v > 250) {
              return "Geçerli bir değer giriniz (örn: 120)";
            }
          }

          if (label.contains("Diastolik")) {
            if (v < 50 || v > 150) {
              return "Geçerli biir değer giriniz (örn: 80)";
            }
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value,
      title: Text(title),
      activeThumbColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
    );
  }
}