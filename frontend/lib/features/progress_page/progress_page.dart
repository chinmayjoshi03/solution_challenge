import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const ProgressPage(),
      );

  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int progress = 0;
  int streak = 0;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    fetchProgressFromFirestore();
  }

  Future<void> fetchProgressFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = "User not logged in.";
        });
        return;
      }

      final userId = user.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final docSnapshot = await userRef.get();

      if (docSnapshot.exists) {
        setState(() {
          progress = docSnapshot.data()?['progress'] ?? 0;
          streak = docSnapshot.data()?['streak'] ?? 0;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "No progress data found.";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Progress")),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage.isNotEmpty
                ? Text(errorMessage)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Daily Progress: $progress%",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 10,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Current Streak: $streak days 🔥",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
      ),
    );
  }
}
