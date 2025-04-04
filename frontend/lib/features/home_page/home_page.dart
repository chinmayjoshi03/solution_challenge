import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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
import 'package:solution_challenge/features/home_page/all_tasks_page.dart';
import 'package:solution_challenge/features/home_page/session_card.dart';
import 'package:solution_challenge/features/home_page/task_item.dart';
import 'package:solution_challenge/analytics_service.dart';

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
  String userName = "Andrew";
  String _currentPage = "Home";

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackScreen('HomePage');
    _fetchDailyTaskFromAPI();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && userDoc.data()!.containsKey('name')) {
          setState(() {
            userName = userDoc.data()!['name'];
          });
        }
      }
    } catch (e) {
      // Silently handle error
    }
  }

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
      const String apiUrl = "http://192.168.57.254:3000/api/dailyTask";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<String> fetchedTasks = _parseTasks(data['dailyTask']);

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

  List<String> _parseTasks(String taskText) {
    return taskText
        .split('\n')
        .map((task) => task.trim())
        .where((task) => task.isNotEmpty)
        .toList();
  }

  void _toggleTaskCompletion(int index) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please sign in to track progress")),
        );
        return;
      }

      final userId = user.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      setState(() {
        taskCompletion[index] = !taskCompletion[index];
      });

      List<String> completedTasks = [];
      for (int i = 0; i < tasks.length; i++) {
        if (taskCompletion[i]) {
          completedTasks.add(tasks[i]);
        }
      }
      int progress = tasks.isNotEmpty ? (completedTasks.length / tasks.length * 100).toInt() : 0;

      final batch = FirebaseFirestore.instance.batch();
      
      batch.set(userRef, {
        "completedTasks": completedTasks,
        "progress": progress,
        "lastUpdated": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final progressDocRef = userRef.collection('progressHistory').doc(_formatDate(today));
      batch.set(progressDocRef, {
        'date': Timestamp.fromDate(today),
        'progress': progress,
        'completedTasks': completedTasks,
        'totalTasks': tasks.length,
      }, SetOptions(merge: true));

      await batch.commit();

      if (progress == 100) {
        await _updateStreaks(userId);
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating progress: ${e.toString()}")),
      );
      setState(() {
        taskCompletion[index] = !taskCompletion[index];
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _updateStreaks(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    final yesterdayDoc = await userRef.collection('progressHistory')
        .doc(_formatDate(yesterday))
        .get();

    if (yesterdayDoc.exists && (yesterdayDoc.data()?['progress'] ?? 0) >= 100) {
      await userRef.update({
        'currentStreak': FieldValue.increment(1),
        'longestStreak': FieldValue.increment(1),
      });
    } else {
      await userRef.update({
        'currentStreak': 1,
        'longestStreak': FieldValue.increment(1),
      });
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, LoginPage.route());
  }

  void _openAllTasksPage() {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => AllTasksPage(
          tasks: tasks,
          taskCompletion: taskCompletion,
          onToggleTask: _toggleTaskCompletion,
        ),
      ),
    );
  }

  void _navigateToPage(String pageName, Widget page) {
    setState(() {
      _currentPage = pageName;
    });
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryYellow = Color(0xFFFFDE03);
    const Color lightYellow = Color(0xFFFFF9C4);
    const Color mediumYellow = Color(0xFFFFEE58);
    const Color darkYellow = Color(0xFFFBC02D);
    const Color lightBlue = Color(0xFFE3F2FD);

    return Scaffold(
      backgroundColor: lightYellow,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_rounded, color: Colors.red),
            onPressed: () => _navigateToPage("Emergency Help", EmergencyHelpPage()),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          children: [
            _buildDrawerItem(
              Icons.psychology,
              "AI Mentor",
              () => _navigateToPage("AI Coach", RecoveryCoachPage()),
              iconColor: Colors.indigo,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.mood_outlined,
              "Mood Tracker",
              () => _navigateToPage("Journal", JournalPage()),
              iconColor: Colors.teal,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.home,
              "Dashboard",
              () => _navigateToPage("Home", const HomePage()),
              isSelected: _currentPage == "Home",
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.bar_chart,
              "Stats",
              () => _navigateToPage("Progress", ProgressPage()),
              iconColor: Colors.orange,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.chat,
              "Community",
              () => _navigateToPage("Community Chat", CommunityChatPage()),
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.warning_amber_rounded,
              "AI Trigger Prediction",
              () => _navigateToPage("AI Trigger Prediction", TriggerPredictionPage()),
              iconColor: Colors.amber,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.self_improvement,
              "Meditate",
              () => _navigateToPage("Meditation", MeditationPage()),
              iconColor: Colors.purple,
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              Icons.assignment_turned_in,
              "Recovery Plan",
              () => _navigateToPage("Recovery Plan", RecoveryPlanPage()),
              iconColor: Colors.green,
            ),
            const SizedBox(height: 20),

            
            Divider(color: Colors.grey[300]),
            _buildDrawerItem(
              Icons.logout,
              "Log Out",
              () => _signOut(context),
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryYellow))
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            "Hello,\n$userName",
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "👋",
                            style: TextStyle(fontSize: 30),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: SessionCard(
                              title: "AI\nCoach",
                              onTap: () {
                                _navigateToPage("AI Coach", RecoveryCoachPage());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SessionCard(
                              title: "Your\nProgress",
                              onTap: () {
                                _navigateToPage("Progress", ProgressPage());
                              },
                              isProgressCard: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: darkYellow,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Today's Action",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _openAllTasksPage,
                              child: const Row(
                                children: [
                                  Text(
                                    "See All",
                                    style: TextStyle(color: Colors.black87),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.black87),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryYellow.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: tasks.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("No tasks for today. Check back later!"),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length > 4 ? 4 : tasks.length,
                                itemBuilder: (context, index) {
                                  return TaskItem(
                                    task: tasks[index],
                                    isCompleted: taskCompletion[index],
                                    onToggle: () => _toggleTaskCompletion(index),
                                  );
                                },
                              ),
                      ),
                      if (tasks.length > 4)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: _openAllTasksPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryYellow,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text(
                                "View All Tasks",
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback? onTap, {
    Color? iconColor,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.black, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}