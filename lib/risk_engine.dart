import 'package:cloud_firestore/cloud_firestore.dart';

class RiskLevel {
  static const low = "LOW";
  static const medium = "MEDIUM";
  static const high = "HIGH";
}

class RiskResult {
  final String preeklampsi;
  final String diyabet;
  final String preterm;

  RiskResult({
    required this.preeklampsi,
    required this.diyabet,
    required this.preterm,
  });
}

class RiskEngine {
  static Future<String> calculatePreeklampsi({
    required String uid,
    required int sistolik,
    required int diastolik,
    required bool gormeBozuklugu,
    required bool basAgrisi,
    required bool sislik,
    required bool chronicHypertension,
  }) async {

    if (sistolik >= 160 || diastolik >= 110) {
      return RiskLevel.high;
    }

    int score = 0;

    if (sistolik >= 140) score += 2;
    if (diastolik >= 90) score += 2;
    if (basAgrisi) score += 1;
    if (gormeBozuklugu) score += 1;
    if (sislik) score += 1;
    if (chronicHypertension) score += 2;

    String risk;

    if (score <= 2) {
      risk = RiskLevel.low;
    } else if (score <= 5) {
      risk = RiskLevel.medium;
    } else {
      risk = RiskLevel.high;
    }

    final query = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: uid)
        .orderBy("tarih", descending: true)
        .limit(3)
        .get();

    if (query.docs.length == 3) {
      int abnormalCount = 0;

      for (var doc in query.docs) {
        final data = doc.data();
        final s = data["sistolik"] ?? 0;
        final d = data["diastolik"] ?? 0;

        if (s >= 140 || d >= 90) {
          abnormalCount++;
        }
      }

      if (abnormalCount == 3) {
        if (risk == RiskLevel.low) risk = RiskLevel.medium;
        if (risk == RiskLevel.medium) risk = RiskLevel.high;
      }
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .set({
      "riskLevel": risk.toLowerCase(),
    }, SetOptions(merge: true));

    return risk;
  }

  static String calculateDiyabet({
    required double? aclik,
    required double? tokluk,
    required bool asiriSusama,
    required bool sikIdrar,
    required bool diabetes,
  }) {

    if ((aclik != null && aclik >= 126) ||
        (tokluk != null && tokluk >= 200)) {
      return RiskLevel.high;
    }

    int score = 0;

    if ((aclik ?? 0) >= 100) score += 2;
    if ((tokluk ?? 0) >= 140) score += 2;
    if (asiriSusama) score += 1;
    if (sikIdrar) score += 1;
    if (diabetes) score += 2;

    if (score <= 2) return RiskLevel.low;
    if (score <= 5) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static String calculatePreterm({
    required bool karinKasilma,
    required bool akinti,
    required bool belAgrisi,
    required double stresSeviyesi,
    required bool previousPreterm,
    required bool multiplePregnancy,
  }) {

    int score = 0;

    if (karinKasilma) score += 2;
    if (akinti) score += 1;
    if (belAgrisi) score += 1;

    if (stresSeviyesi == 5) {
      score += 3;
    } else if (stresSeviyesi >= 4) {
      score += 2;
    }

    if (previousPreterm) score += 2;
    if (multiplePregnancy) score += 2;

    if (score <= 2) return RiskLevel.low;
    if (score <= 5) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static Future<void> sendRiskNotification({
    required String uid,
    required String riskType,
    required String riskLevel,
  }) async {

    if (riskLevel != RiskLevel.high) return;

    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) return;

    final doctorId = userData["assignedDoctor"];
    if (doctorId == null) return;

    final patientName =
    (userData["name"] ?? "").toString().isEmpty
        ? "Bilinmeyen hasta"
        : userData["name"];

    final existing = await FirebaseFirestore.instance
        .collection("notification")
        .where("uid", isEqualTo: doctorId)
        .where("type", isEqualTo: "risk_alert")
        .where("riskType", isEqualTo: riskType)
        .orderBy("createdAt", descending: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final last = existing.docs.first.data();
      final time = last["createdAt"];

      if (time != null && time is Timestamp) {
        final diff = DateTime.now().difference(time.toDate());

        if (diff.inMinutes < 30) return;
      }
    }

    String fieldName = "";
    if (riskType == "Preeklampsi") fieldName = "preeklampsiRisk";
    if (riskType == "Gestasyonel Diyabet") fieldName = "diyabetRisk";
    if (riskType == "Preterm Doğum") fieldName = "pretermRisk";

    final lastRisk = await FirebaseFirestore.instance
        .collection("risk_olcumleri")
        .where("uid", isEqualTo: uid)
        .orderBy("tarih", descending: true)
        .limit(1)
        .get();

    if (lastRisk.docs.isNotEmpty && fieldName.isNotEmpty) {
      final prev = lastRisk.docs.first.data();

      if (prev[fieldName] == RiskLevel.high) {
        return;
      }
    }

    await FirebaseFirestore.instance.collection("notification").add({
      "uid": uid,
      "type": "risk_alert",
      "riskType": riskType,
      "title": "Risk Uyarısı",
      "message":
      "$riskType riski yüksek tespit edildi. Lütfen doktorunuzla iletişime geçiniz.",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("notification").add({
      "uid": doctorId,
      "type": "risk_alert",
      "riskType": riskType,
      "title": "Riskli Hasta",
      "message":
      "$patientName için $riskType riski yüksek tespit edildi.",
      "isRead": false,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
}