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
  
  // Color scheme
  static const Color primaryYellow = Color(0xFFFFDE03);
  static const Color lightYellow = Color(0xFFFFF9C4);
  static const Color mediumYellow = Color(0xFFFFEE58);
  static const Color darkYellow = Color(0xFFFBC02D);
  static const Color lightBlue = Color(0xFFE3F2FD);

  Future<void> sendMessage() async {
    if (_messageController.text.isEmpty) return;

    setState(() {
      isLoading = true;
      aiResponse = "";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final response = await http.post(
        //Uri.parse("http://10.0.2.2:3000/api/recoveryCoach"),
        Uri.parse("http://192.168.57.254:3000/api/recoveryCoach"),

        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": user.uid,
          "message": _messageController.text
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => aiResponse = data['response']);
      } else {
        throw Exception("Failed to get response");
      }
    } catch (e) {
      setState(() => aiResponse = "Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recovery Companion",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: darkYellow,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Container(
        color: lightYellow,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("How can I help you today?",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Type your thoughts or question...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        maxLines: 3,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkYellow,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Get Support",
                              style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // Response Section
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                                color: primaryYellow),
                            const SizedBox(height: 15),
                            Text("Your companion is thinking...",
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontStyle: FontStyle.italic)),
                          ],
                        ),
                      )
                    : aiResponse.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: primaryYellow, width: 1.5),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.support_agent, 
                                          color: primaryYellow, size: 30),
                                      const SizedBox(width: 10),
                                      const Text("Recovery Companion",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aiResponse,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          height: 1.4,
                                          color: Colors.black87)),
                                ],
                              ),
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 100, color: Colors.grey[400]),
                                const SizedBox(height: 15),
                                const Text(
                                    "Your supportive AI companion is here to help!\n"
                                    "Ask about coping strategies, progress tracking,\n"
                                    "or general recovery support.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic)),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}