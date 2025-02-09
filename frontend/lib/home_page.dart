import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solution_challenge/features/auth/screens/login_page.dart';
import 'package:solution_challenge/features/progress_page/progress_page.dart';
import 'package:solution_challenge/features/journal/journal_page.dart';
import 'package:solution_challenge/features/recovery_coach/recovery_coach_page.dart';
import 'package:solution_challenge/features/emergency_page/emergency_help_page.dart';
import 'package:solution_challenge/features/recovery_coach/recovery_plan_page.dart';
import 'package:solution_challenge/features/meditation/screens/meditation_page.dart';
import 'package:solution_challenge/features/trigger_prediction/trigger_prediction_page.dart';
import 'package:solution_challenge/features/community_chat/community_chat_page.dart';

class HomePage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const HomePage(),
      );

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> tasks = [];
  List<bool> taskCompletion = [];
  bool isLoading = true;
  String errorMessage = "";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchDailyTaskFromAPI();
  }

  // ✅ Fetch daily tasks directly from API
  Future<void> _fetchDailyTaskFromAPI() async {
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
      const String apiUrl = "http://10.0.2.2:3000/api/dailyTask"; // Change for production

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> fetchedTasks = _parseTasks(data['dailyTask']); // ✅ Now this function exists!

        // Fetch completed tasks from Firestore
        final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final docSnapshot = await userRef.get();
        List<String> completedTasks = List<String>.from(docSnapshot.data()?['completedTasks'] ?? []);

        setState(() {
          tasks = fetchedTasks;
          taskCompletion = tasks.map((task) => completedTasks.contains(task)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to load daily tasks.";
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

  // ✅ Added _parseTasks method to correctly format tasks
  List<String> _parseTasks(String taskText) {
    return taskText
        .split('\n') // Split by new line
        .map((task) => task.trim()) // Trim spaces
        .where((task) => task.isNotEmpty) // Remove empty lines
        .toList();
  }

  // ✅ Toggle Task Completion and Update Firestore
  void _toggleTaskCompletion(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    setState(() {
      taskCompletion[index] = !taskCompletion[index];
    });

    // ✅ Update Completed Tasks List
    List<String> completedTasks = [];
    for (int i = 0; i < tasks.length; i++) {
      if (taskCompletion[i]) {
        completedTasks.add(tasks[i]);
      }
    }

    // ✅ Calculate Progress
    int progress = tasks.isNotEmpty ? (completedTasks.length / tasks.length * 100).toInt() : 0;

    // ✅ Save Progress & Completed Tasks to Firestore
    await userRef.set({
      "completedTasks": completedTasks,
      "progress": progress,
    }, SetOptions(merge: true));
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, LoginPage.route());
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, ProgressPage.route());
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recovery Journey")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menu', style: TextStyle(fontSize: 24, color: Colors.white)),
            ),
            _buildDrawerItem(Icons.home, "Home", () => Navigator.pop(context)),
            _buildDrawerItem(Icons.show_chart, "Progress", () => Navigator.push(context, ProgressPage.route())),
            _buildDrawerItem(Icons.book, "Journal & Mood", () => Navigator.push(context, JournalPage.route())),
            _buildDrawerItem(Icons.smart_toy, "AI Recovery Coach", () => Navigator.push(context, RecoveryCoachPage.route())),
            _buildDrawerItem(Icons.warning, "Emergency Help", () => Navigator.push(context, EmergencyHelpPage.route())),
            _buildDrawerItem(Icons.calendar_today, "AI Recovery Plan", () => Navigator.push(context, RecoveryPlanPage.route())),
            _buildDrawerItem(Icons.self_improvement, "Guided Meditation", () => Navigator.push(context, MeditationPage.route())),
            _buildDrawerItem(Icons.warning_amber_rounded, "AI Trigger Prediction", () => Navigator.push(context, TriggerPredictionPage.route())),
            _buildDrawerItem(Icons.chat, "Community Chat", () => Navigator.push(context, CommunityChatPage.route())),
            _buildDrawerItem(Icons.logout, "Logout", () => _signOut(context), iconColor: Colors.red),
          ],
        ),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage.isNotEmpty
                ? Text(errorMessage)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Checkbox(
                            value: taskCompletion[index],
                            onChanged: (bool? newValue) {
                              _toggleTaskCompletion(index);
                            },
                          ),
                          title: Text(tasks[index]),
                        ),
                      );
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color? iconColor}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black),
      title: Text(title),
      onTap: onTap,
    );
  }
}
