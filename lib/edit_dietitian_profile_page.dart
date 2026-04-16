import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditDietitianProfilePage extends StatefulWidget {
  const EditDietitianProfilePage({super.key});

  @override
  State<EditDietitianProfilePage> createState() =>
      _EditDietitianProfilePageState();
}

class _EditDietitianProfilePageState
    extends State<EditDietitianProfilePage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final expertiseController = TextEditingController();
  final experienceController = TextEditingController();
  final institutionController = TextEditingController();

  bool uploading = false;
  String? diplomaUrl;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final data = doc.data();

    if (data != null) {
      nameController.text = data["name"] ?? "";
      emailController.text = data["email"] ?? ""; // 💣
      expertiseController.text = data["expertise"] ?? "";
      experienceController.text = data["experience"] ?? "";
      institutionController.text = data["institution"] ?? "";
      diplomaUrl = data["diploma"];
    }
  }

  Future<void> saveData() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    // 💣 EMAIL DEĞİŞTİ Mİ?
    final newEmail = emailController.text.trim();
    final oldEmail = user.email;

    try {

      // 🔐 Eğer email değiştiyse re-auth iste
      if (newEmail != oldEmail) {

        String password = "";

        // 🔥 ŞİFRE DİALOG
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final passController = TextEditingController();

            return AlertDialog(
              title: const Text("Güvenlik Doğrulama"),
              content: TextField(
                controller: passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Şifrenizi girin",
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    password = passController.text;
                    Navigator.pop(context);
                  },
                  child: const Text("Onayla"),
                ),
              ],
            );
          },
        );

        if (password.isEmpty) return;

        // 🔥 RE-AUTH
        final credential = EmailAuthProvider.credential(
          email: oldEmail!,
          password: password,
        );

        await user.reauthenticateWithCredential(credential);

        // 🔥 AUTH EMAIL UPDATE
        await user.updateEmail(newEmail);
      }

      // 💣 FIRESTORE UPDATE
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({
        "name": nameController.text,
        "email": newEmail,
        "expertise": expertiseController.text,
        "experience": experienceController.text,
        "institution": institutionController.text,
        "diploma": diplomaUrl,
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Bilgiler güncellendi ✅"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? "Email güncellenemedi"),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Beklenmeyen hata"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> pickDiploma() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result == null) return;

    final fileBytes = result.files.first.bytes;
    final fileName = result.files.first.name;

    if (fileBytes == null) return;

    setState(() => uploading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final ref = FirebaseStorage.instance
          .ref()
          .child("diplomas")
          .child("$uid-$fileName");

      await ref.putData(fileBytes);

      final url = await ref.getDownloadURL();

      setState(() {
        diplomaUrl = url;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diploma yüklendi ✅")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yükleme hatası ❌")),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  Widget buildField(String title, TextEditingController controller,
      {bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: "$title gir...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Bilgileri Düzenle"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            buildField("İsim Soyisim", nameController),
            buildField("Email", emailController),
            buildField("Uzmanlık", expertiseController),
            buildField("Deneyim", experienceController),
            buildField("Kurum", institutionController),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: uploading ? null : pickDiploma,
              icon: const Icon(Icons.upload_file),
              label: Text(uploading ? "Yükleniyor..." : "Diploma Yükle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 10),

            if (diplomaUrl != null)
              Text(
                "Diploma yüklendi ✅",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}