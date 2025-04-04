import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecoveryPlanPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const RecoveryPlanPage(),
      );

  const RecoveryPlanPage({Key? key}) : super(key: key);

  @override
  _RecoveryPlanPageState createState() => _RecoveryPlanPageState();
}

class _RecoveryPlanPageState extends State<RecoveryPlanPage> {
  Map<String, List<String>> recoveryPlan = {};
  bool isLoading = true;
  bool isDisposed = false; // ✅ Track widget disposal

  @override
  void initState() {
    super.initState();
    fetchRecoveryPlan();
  }

  @override
  void dispose() {
    isDisposed = true; // ✅ Set flag when widget is disposed
    super.dispose();
  }

 Future<void> fetchRecoveryPlan() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

  final docSnapshot = await userRef.get();

  if (docSnapshot.exists && docSnapshot.data()?['recoveryPlan'] != null) {
    if (!isDisposed) {
      setState(() {
        recoveryPlan = (docSnapshot.data()?['recoveryPlan'] as Map<String, dynamic>)
            .map<String, List<String>>(
                (String key, dynamic value) => MapEntry(key, List<String>.from(value)));
        isLoading = false;
      });
    }
  } else {
    await generateRecoveryPlan();
  }
}



 Future<void> generateRecoveryPlan() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final userId = user.uid;
  final apiUrl = "http://10.0.2.2:3000/api/recoveryPlan";
  // final apiUrl = "http://192.168.64.254:3000/api/recoveryPlan";

  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId}),
    );

    if (response.statusCode == 200) {
      if (!isDisposed) {
        setState(() {
          recoveryPlan = (jsonDecode(response.body)['recoveryPlan'] as Map<String, dynamic>)
              .map<String, List<String>>(
                  (String key, dynamic value) => MapEntry(key, List<String>.from(value)));
          isLoading = false;
        });
      }
    } else {
      throw Exception("Failed to fetch recovery plan.");
    }
  } catch (e) {
    print("❌ API Call Failed: $e");
    if (!isDisposed) {
      setState(() {
        isLoading = false;
      });
    }
  }
}



  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("7-Day Recovery Plan")),
    body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recoveryPlan.keys.length,
            itemBuilder: (context, index) {
              // ✅ Sort Days in Correct Order Before Displaying
              List<String> sortedDays = recoveryPlan.keys.toList()
                ..sort((a, b) => int.parse(a.replaceAll(RegExp(r'\D'), ''))
                    .compareTo(int.parse(b.replaceAll(RegExp(r'\D'), ''))));

              String day = sortedDays[index];
              List<String> tasks = recoveryPlan[day] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    day.toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  children: tasks.map((task) => ListTile(title: Text(task))).toList(),
                ),
              );
            },
          ),
  );
}
}