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
   static const Color primaryBlue = Color(0xFF2A4F7E);
  static const Color secondaryBlue = Color(0xFF5B8FB9);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color lightBlue = Color(0xFFE8F4FD);
  static const Color backgroundWhite = Color(0xFFF8F9FA);
  static const Color darkBlue = Color(0xFF1A365D);

  
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
       // Uri.parse("http://10.0.2.2:3000/api/journalInsights"),
        Uri.parse("http://192.168.57.254:3000/api/journalInsights"),
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
      appBar: AppBar(
        title: const Text("Journal & Mood Tracker", 
                style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryBlue,  // Changed to blue
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: backgroundWhite,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoodSection(),
              const SizedBox(height: 25),
              _buildJournalEntryField(),
              const SizedBox(height: 30),
              _buildSaveButton(),
              const SizedBox(height: 30),
              _buildInsightsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Mood Rating",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue)),  // Blue text
            const SizedBox(height: 15),
            Row(
              children: [
                Icon(Icons.sentiment_very_dissatisfied, 
                     color: secondaryBlue, size: 30),  // Blue icon
                Expanded(
                  child: Slider(
                    value: _moodRating.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: accentYellow,  // Yellow track
                    inactiveColor: lightBlue,   // Light blue track
                    thumbColor: primaryBlue,     // Blue thumb
                    label: _moodRating.toString(),
                    onChanged: (value) => setState(() => _moodRating = value.toInt()),
                  ),
                ),
                Icon(Icons.sentiment_very_satisfied, 
                     color: secondaryBlue, size: 30),  // Blue icon
              ],
            ),
            Center(
              child: Text("Current Rating: $_moodRating",
                  style: TextStyle(
                      color: primaryBlue,  // Blue text
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntryField() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Journal Entry",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue)),  // Blue text
            const SizedBox(height: 15),
            TextField(
              controller: _entryController,
              maxLines: 6,
              decoration: InputDecoration(
                filled: true,
                fillColor: lightBlue.withOpacity(0.2),  // Subtle blue background
                hintText: "Write your thoughts here...",
                hintStyle: TextStyle(color: Colors.grey[600]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: secondaryBlue)),  // Blue border
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryBlue, width: 2)),  // Dark blue focus
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: ElevatedButton(
        onPressed: saveJournalEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,  // Blue button
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25)),
          elevation: 4,
          shadowColor: accentYellow.withOpacity(0.3),  // Yellow shadow
        ),
        child: const Text("Save Entry",
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : aiInsights.isNotEmpty
              ? Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  color: lightBlue,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, 
                                 color: darkBlue, size: 24),  // Dark blue icon
                            const SizedBox(width: 10),
                            Text("AI Insights",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: darkBlue)),  // Dark blue text
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(aiInsights,
                            style: TextStyle(
                                fontSize: 16,
                                height: 1.4,
                                color: primaryBlue)),  // Blue text
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
    );
  }
}