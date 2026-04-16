import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SifreDegistirPage extends StatefulWidget {
  const SifreDegistirPage({super.key});

  @override
  State<SifreDegistirPage> createState() => _SifreDegistirPageState();
}

class _SifreDegistirPageState extends State<SifreDegistirPage> {
  final _formKey = GlobalKey<FormState>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _obscure3 = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        throw Exception("Kullanıcı bulunamadı.");
      }

      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Şifre başarıyla değiştirildi ✅"),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      String message = "Bir hata oluştu.";

      if (e.code == 'wrong-password') {
        message = "Mevcut şifre yanlış.";
      } else if (e.code == 'weak-password') {
        message = "Yeni şifre çok zayıf.";
      } else if (e.code == 'requires-recent-login') {
        message = "Lütfen tekrar giriş yapın.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  InputDecoration buildInputDecoration(
      BuildContext context,
      String label,
      bool obscure,
      VoidCallback toggle) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility : Icons.visibility_off,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: toggle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Şifre Değiştir"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [

                TextFormField(
                  controller: currentPasswordController,
                  obscureText: _obscure1,
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? "Mevcut şifre giriniz"
                      : null,
                  decoration: buildInputDecoration(
                    context,
                    "Mevcut Şifre",
                    _obscure1,
                        () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: newPasswordController,
                  obscureText: _obscure2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Yeni şifre giriniz";
                    }
                    if (value.length < 6) {
                      return "Şifre en az 6 karakter olmalı";
                    }
                    return null;
                  },
                  decoration: buildInputDecoration(context,
                    "Yeni Şifre",
                    _obscure2,
                        () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscure3,
                  validator: (value) {
                    if (value != newPasswordController.text) {
                      return "Şifreler eşleşmiyor";
                    }
                    return null;
                  },
                  decoration: buildInputDecoration(context,
                    "Yeni Şifre (Tekrar)",
                    _obscure3,
                        () => setState(() => _obscure3 = !_obscure3),
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Şifreyi Güncelle",
                      style: TextStyle(
                        fontSize: 16,
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