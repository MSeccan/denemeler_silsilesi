import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'kisisel_bilgi_goruntule.dart';

class KisiselBilgilerPage extends StatefulWidget {
  const KisiselBilgilerPage({super.key});

  @override
  State<KisiselBilgilerPage> createState() => _KisiselBilgilerPageState();
}

class _KisiselBilgilerPageState extends State<KisiselBilgilerPage> {

  final _formKey = GlobalKey<FormState>();

  final yasController = TextEditingController();
  final kiloController = TextEditingController();
  final haftaController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  bool chronicHypertension = false;
  bool diabetes = false;
  bool thyroidDisease = false;
  bool previousPreterm = false;
  bool multiplePregnancy = false;
  bool smoker = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    yasController.dispose();
    kiloController.dispose();
    haftaController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final data = snapshot.data();

      if (data != null) {
        yasController.text = data['yas']?.toString() ?? '';
        kiloController.text = data['kilo']?.toString() ?? '';
        haftaController.text = data['hafta']?.toString() ?? '';

        chronicHypertension = data['chronicHypertension'] ?? false;
        diabetes = data['diabetes'] ?? false;
        thyroidDisease = data['thyroidDisease'] ?? false;
        previousPreterm = data['previousPreterm'] ?? false;
        multiplePregnancy = data['multiplePregnancy'] ?? false;
        smoker = data['smoker'] ?? false;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> kaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'yas': int.tryParse(yasController.text.trim()) ?? 0,
        'kilo': double.tryParse(kiloController.text.trim()) ?? 0,
        'hafta': int.tryParse(haftaController.text.trim()) ?? 0,

        'chronicHypertension': chronicHypertension,
        'diabetes': diabetes,
        'thyroidDisease': thyroidDisease,
        'previousPreterm': previousPreterm,
        'multiplePregnancy': multiplePregnancy,
        'smoker': smoker,

        'profilTamamlandi': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bilgiler güncellendi ✅"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hata oluştu: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isSaving = false);
  }

  Widget buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Bu alan boş bırakılamaz";
          }
          return null;
        },
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.primary,
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildCheckbox(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Kişisel Bilgiler"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
        color: Theme.of(context).colorScheme.primary,
      ))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                buildInputField(
                  controller: yasController,
                  label: "Yaş",
                  icon: Icons.person,
                  type: TextInputType.number,
                ),

                buildInputField(
                  controller: kiloController,
                  label: "Güncel Kilo (kg)",
                  icon: Icons.monitor_weight,
                  type: TextInputType.number,
                ),

                buildInputField(
                  controller: haftaController,
                  label: "Hamilelik Haftası",
                  icon: Icons.calendar_today,
                  type: TextInputType.number,
                ),

                const SizedBox(height: 10),
                Divider(
                  color: Theme.of(context).dividerColor,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Risk Faktörleri",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                ),

                const SizedBox(height: 10),

                buildCheckbox("Kronik Hipertansiyon", chronicHypertension,
                        (val) => setState(() => chronicHypertension = val!)),

                buildCheckbox("Diyabet", diabetes,
                        (val) => setState(() => diabetes = val!)),

                buildCheckbox("Tiroid Hastalığı", thyroidDisease,
                        (val) => setState(() => thyroidDisease = val!)),

                buildCheckbox("Önceki Preterm", previousPreterm,
                        (val) => setState(() => previousPreterm = val!)),

                buildCheckbox("Çoğul Gebelik", multiplePregnancy,
                        (val) => setState(() => multiplePregnancy = val!)),

                buildCheckbox("Sigara", smoker,
                        (val) => setState(() => smoker = val!)),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSaving
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Kaydet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}