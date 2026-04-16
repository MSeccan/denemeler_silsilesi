import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'uzman_basvuru_page.dart';
import 'kisisel_bilgi_page.dart';
import 'kisisel_bilgi_goruntule.dart';
import 'sifre_degistir_page.dart';
import 'hamile_olcum_gecmisi_page.dart';
import 'hamile_besin_gecmisi_page.dart';

class HesabimPage extends StatefulWidget {
  const HesabimPage({super.key});

  @override
  State<HesabimPage> createState() => _HesabimPageState();
}

class _HesabimPageState extends State<HesabimPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hesabım",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Hesap ayarlarını buradan yönetebilirsin",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              hesapButonu(
                "👤 Kişisel Bilgiler",
                kisiselBilgiKontrol,
              ),

              hesapButonu(
                "📊 Ölçüm Geçmişi",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HamileOlcumGecmisiPage(),
                    ),
                  );
                },
              ),

              hesapButonu(
                "🍽️ Besin Analizi Geçmişi",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HamileBesinGecmisiPage(),
                    ),
                  );
                },
              ),

              hesapButonu(
                "🔒 Şifre Değiştir",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SifreDegistirPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              Divider(
                color: Theme.of(context).dividerColor,
              ),

              hesapButonu(
                "🩺 Uzman Olarak Başvur",
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UzmanBasvuruPage()),
                  );
                },
                color: Theme.of(context).colorScheme.primary,
              ),

              const Spacer(),

              hesapButonu(
                "🚪 Çıkış Yap",
                signOut,
                color: Colors.red.shade500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> kisiselBilgiKontrol() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = snapshot.data();

    if (data != null && data['profilTamamlandi'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const KisiselBilgilerGoruntulePage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const KisiselBilgilerPage()),
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
    );
  }

  Widget hesapButonu(String text, VoidCallback onTap,
      {Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}