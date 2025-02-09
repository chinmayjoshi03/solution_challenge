import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecoveryCoachPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const RecoveryCoachPage(),
      );

  const RecoveryCoachPage({Key? key}) : super(key: key);

  @override
  _RecoveryCoachPageState createState() => _RecoveryCoachPageState();
}

class _RecoveryCoachPageState extends State<RecoveryCoachPage> {
  final TextEditingController _messageController = TextEditingController();
  String aiResponse = "";
  bool isLoading = false;

  Future<void> sendMessage() async {
    setState(() {
      isLoading = true;
      aiResponse = "";
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User not logged in");
      return;
    }

    final userId = user.uid;
    final apiUrl = "http://10.0.2.2:3000/api/recoveryCoach"; // For Android Emulator

    try {
      print("🔹 Sending message to API: ${_messageController.text}");

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "message": _messageController.text}),
      );

      print("🔹 API Response Status Code: ${response.statusCode}");
      print("🔹 API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        String reply = jsonDecode(response.body)['response'];

        setState(() {
          aiResponse = reply;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to get AI response.");
      }
    } catch (e) {
      print("❌ API Call Failed: $e");
      setState(() {
        aiResponse = "Could not retrieve AI response.";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Recovery Coach")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ask the AI Recovery Coach:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Type your question here...",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: sendMessage,
              child: const Text("Get Advice"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : aiResponse.isNotEmpty
                    ? Text("🤖 AI Coach: $aiResponse",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
