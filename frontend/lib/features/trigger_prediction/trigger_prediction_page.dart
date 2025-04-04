import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TriggerPredictionPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const TriggerPredictionPage(),
      );

  const TriggerPredictionPage({Key? key}) : super(key: key);

  @override
  _TriggerPredictionPageState createState() => _TriggerPredictionPageState();
}

class _TriggerPredictionPageState extends State<TriggerPredictionPage> {
  Map<String, dynamic> triggerPrediction = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTriggerPrediction();
  }

  Future<void> fetchTriggerPrediction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    final docSnapshot = await userRef.get();

    if (docSnapshot.exists && docSnapshot.data()?['triggerPrediction'] != null) {
      setState(() {
        triggerPrediction = docSnapshot.data()?['triggerPrediction'];
        isLoading = false;
      });
    } else {
      await generateTriggerPrediction();
    }
  }

  Future<void> generateTriggerPrediction() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
   // final apiUrl = "http://10.0.2.2:3000/api/triggerPrediction";
      final apiUrl = "http://192.168.57.254:3000/api/triggerPrediction";


    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          triggerPrediction = jsonDecode(response.body)['triggerPrediction'];
          isLoading = false;
        });
      } else {
        throw Exception("Failed to fetch trigger prediction.");
      }
    } catch (e) {
      print("❌ API Call Failed: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Trigger Prediction")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Predicted High-Risk Triggers:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...?triggerPrediction['predictedTriggers']?.map((trigger) => ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: Text(trigger),
                      )),

                  const SizedBox(height: 20),
                  Text(
                    "Risk Level: ${triggerPrediction['riskLevel'] ?? 'Unknown'}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (triggerPrediction['riskLevel'] == "High") ? Colors.red : Colors.orange,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Suggested Coping Strategies:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...?triggerPrediction['suggestedCopingStrategies']?.map((strategy) => ListTile(
                        leading: const Icon(Icons.lightbulb, color: Colors.green),
                        title: Text(strategy),
                      )),
                ],
              ),
            ),
    );
  }
}
