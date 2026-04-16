import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'hamile_page.dart';
import 'admin_home_page.dart';
import 'diyetisyen_page.dart';
import 'jinekolog_page.dart';
import 'login_page.dart';
import 'app_theme.dart';

class AuthRedirect extends StatelessWidget {
  const AuthRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        // 🔄 loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final user = authSnapshot.data;

        if (user == null) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: LoginPage(),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snapshot) {

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const MaterialApp(
                debugShowCheckedModeBanner: false,
                home: Scaffold(
                  body: Center(child: Text("Kullanıcı verisi bulunamadı")),
                ),
              );
            }

            final data =
            snapshot.data!.data() as Map<String, dynamic>;

            final role = data['role'] ?? "pregnant";

            Widget homePage;

            switch (role) {

              case 'admin':
                homePage = const AdminHomePage();
                break;

              case 'dietitian':
                homePage = const DietitianHomePage();
                break;

              case 'gynecologist':
                homePage = const GynecologistHomePage();
                break;

              case 'pregnant':
              default:
                homePage = const HamileAnaSayfa();
            }

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getTheme(role),
              home: homePage,
            );
          },
        );
      },
    );
  }
}