import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RoleLoaderPage());
}

class MyApp extends StatelessWidget {
  final String role;

  const MyApp({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.getTheme(role),

      home: const WelcomePage(),
    );
  }
}
class RoleLoaderPage extends StatefulWidget {
  const RoleLoaderPage({super.key});

  @override
  State<RoleLoaderPage> createState() => _RoleLoaderPageState();
}

class _RoleLoaderPageState extends State<RoleLoaderPage> {
  String? role;

  @override
  void initState() {
    super.initState();
    loadRole();
  }

  Future<void> loadRole() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        role = "pregnant";
      });
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();

    final data = doc.data();

    setState(() {
      role = data?["role"] ?? "pregnant";
    });
  }

  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getTheme("pregnant"), // geçici
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          ),
        ),
      );
    }

    return MyApp(role: role!);
  }
}