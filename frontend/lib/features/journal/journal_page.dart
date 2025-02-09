import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class JournalPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const JournalPage(),
      );

  const JournalPage({Key? key}) : super(key: key);

  @override
  _JournalPageState createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final TextEditingController _entryController = TextEditingController();
  int _moodRating = 5;
  bool isLoading = false;
  String aiInsights = "";

  Future<void> saveJournalEntry() async {
    setState(() {
      isLoading = true;
      aiInsights = "";
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User not logged in");
      return;
    }

    final userId = user.uid;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('journalEntries')
        .doc(today);

    final journalEntry = {
      "mood": _moodRating,
      "entry": _entryController.text,
    };

    // Store mood & journal entry in Firestore
    await userRef.set(journalEntry, SetOptions(merge: true));

    try {
      print("🔹 Sending API request to: http://10.0.2.2:3000/api/journalInsights");
      print("🔹 Request Body: ${jsonEncode({"userId": userId, "mood": _moodRating, "entry": _entryController.text})}");

      final response = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/journalInsights"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "mood": _moodRating, "entry": _entryController.text}),
      );

      print("🔹 API Response Status Code: ${response.statusCode}");
      print("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        String insights = jsonDecode(response.body)['ai_insights'];
        await userRef.update({"ai_insights": insights});

        setState(() {
          aiInsights = insights;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to get AI insights.");
      }
    } catch (e) {
      print("❌ API Call Failed: $e");
      setState(() {
        aiInsights = "Could not retrieve AI insights.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Journal & Mood Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("How are you feeling today?", style: TextStyle(fontSize: 18)),
            Slider(
              value: _moodRating.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _moodRating.toString(),
              onChanged: (value) {
                setState(() {
                  _moodRating = value.toInt();
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _entryController,
              decoration: const InputDecoration(labelText: "Write your thoughts..."),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: saveJournalEntry,
              child: const Text("Save Entry"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : aiInsights.isNotEmpty
                    ? Text("🔍 AI Insight: $aiInsights",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
