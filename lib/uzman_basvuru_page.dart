import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UzmanBasvuruPage extends StatefulWidget {
  const UzmanBasvuruPage({super.key});

  @override
  State<UzmanBasvuruPage> createState() => _UzmanBasvuruPageState();
}

class _UzmanBasvuruPageState extends State<UzmanBasvuruPage> {
  PlatformFile? selectedFile;
  String? documentUrl;
  final _formKey = GlobalKey<FormState>();

  String role = 'dietitian';
  String licenseNo = '';
  String experience = '';
  String phone = '';
  String hospital = '';
  String city = '';

  bool isLoading = false;
  String applicationStatus = 'none';

  @override
  void initState() {
    super.initState();
    checkApplicationStatus();
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  Future<String?> uploadFile() async {
    if (selectedFile == null) return null;

    final file = selectedFile!;
    final path = 'expert_documents/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

    final ref = FirebaseStorage.instance.ref().child(path);

    await ref.putData(file.bytes!);

    final url = await ref.getDownloadURL();
    return url;
  }

  Future<void> checkApplicationStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('expert_applications')
        .doc(uid)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        applicationStatus = doc['status'] ?? 'none';
      });
    }
  }

  Future<void> submitApplication() async {
    if (isLoading) return;

    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen belge yükleyin 📄"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    final docRef = FirebaseFirestore.instance
        .collection('expert_applications')
        .doc(user.uid);

    final existingDoc = await docRef.get();

    // Eğer pending ise tekrar başvuru engelle
    if (existingDoc.exists &&
        existingDoc.data() != null &&
        existingDoc['status'] == 'pending') {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zaten başvurunuz inceleniyor ⏳"),
        ),
      );
      return;
    }

    // Eğer approved ise tekrar başvuru engelle
    if (existingDoc.exists &&
        existingDoc.data() != null &&
        existingDoc['status'] == 'approved') {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Zaten uzmansınız!"),
        ),
      );
      return;
    }

    // belge yükleme
    final uploadedUrl = await uploadFile();

    Map<String, dynamic> data = {
      'uid': user.uid,
      'email': user.email,
      'fullName': user.displayName ?? '',
      'role': role,
      'licenseNumber': licenseNo,
      'experience': experience,
      'phone': phone,
      'hospital': hospital,
      'city': city,
      'documentUrl': uploadedUrl,
      'status': 'pending',
    };

    if (!existingDoc.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }

    await docRef.set(data);

    await FirebaseFirestore.instance.collection('notification').add({
      'uid': user.uid,
      'title': 'Uzman Başvurusu Alındı',
      'message': 'Başvurun alındı. Admin onayı bekleniyor ⏳',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      isLoading = false;
      applicationStatus = 'pending';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Başvurun alındı 🙏"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    Navigator.pop(context);
  }

  Widget buildStatusView() {
    if (applicationStatus == 'pending') {
      return Center(
        child: Text(
          "⏳ Başvurunuz inceleniyor...",
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (applicationStatus == 'approved') {
      return Center(
        child: Text(
          "✅ Zaten uzmansınız!",
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (applicationStatus == 'rejected') {
      return Center(
        child: Text(
          "❌ Başvurunuz reddedildi. Tekrar deneyebilirsiniz.",
          style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.primary),
        ),
      );
    }

    return const SizedBox();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Uzman Başvurusu"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: applicationStatus != 'none'
              ? buildStatusView()
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField(
                    initialValue: role,
                    items: const [
                      DropdownMenuItem(
                        value: 'dietitian',
                        child: Text("Diyetisyen"),
                      ),
                      DropdownMenuItem(
                        value: 'gynecologist',
                        child: Text("Jinekolog"),
                      ),
                    ],
                    onChanged: (val) => setState(() => role = val!),
                    decoration: buildInput(context, "Uzmanlık Alanı"),
                  ),

                  TextFormField(
                    decoration: buildInput(context, "Lisans / Sicil No"),
                    onChanged: (v) => licenseNo = v,
                    validator: (v) =>
                    v!.isEmpty ? "Zorunlu alan" : null,
                  ),

                  TextFormField(
                    decoration: buildInput(context, "Deneyim"),
                    onChanged: (v) => experience = v,
                  ),

                  TextFormField(
                    decoration: buildInput(context, "Telefon"),
                    keyboardType: TextInputType.phone,
                    onChanged: (v) => phone = v,
                  ),

                  TextFormField(
                    decoration: buildInput(context, "Çalıştığı Kurum"),
                    onChanged: (v) => hospital = v,
                  ),

                  TextFormField(
                    decoration: buildInput(context, "Şehir"),
                    onChanged: (v) => city = v,
                  ),

                  const SizedBox(height: 30),

                  ElevatedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Belge Yükle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (selectedFile != null)
                    Text(
                      "Seçilen dosya: ${selectedFile!.name}",
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        submitApplication();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 40),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Başvuruyu Gönder",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
InputDecoration buildInput(BuildContext context, String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surface,
    labelStyle: TextStyle(
      color: Theme.of(context).colorScheme.primary,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
    ),
  );
}