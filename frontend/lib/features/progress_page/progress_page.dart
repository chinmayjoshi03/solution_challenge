import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const ProgressPage(),
      );

  const ProgressPage({Key? key}) : super(key: key);

  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
   // Color scheme
  static const Color primaryYellow = Color(0xFFFFDE03);
  static const Color lightYellow = Color(0xFFFFF9C4);
  static const Color mediumYellow = Color(0xFFFFEE58);
  static const Color darkYellow = Color(0xFFFBC02D);
  static const Color lightBlue = Color(0xFFE3F2FD);
  
  int _currentStreak = 0;
  int _longestStreak = 0;
  double _weeklyAverage = 0;
  List<Map<String, dynamic>> _progressHistory = [];
  bool _isLoading = true;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchProgressData();
  }

  Future<void> _fetchProgressData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = "Please sign in to view progress";
        _isLoading = false;
      });
      return;
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    
    // First check if user document exists
    final userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      // Initialize user document with default progress data
      await userRef.set({
        'completedTasks': [],
        'progress': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    // Now check progress history
    final progressSnapshot = await userRef
        .collection('progressHistory')
        .orderBy('date', descending: true)
        .get();

    if (progressSnapshot.docs.isEmpty) {
      // Initialize today's progress if none exists
      final today = DateTime.now().toUtc();
      await userRef.collection('progressHistory').doc(DateFormat('yyyy-MM-dd').format(today)).set({
        'date': Timestamp.fromDate(today),
        'progress': 0,
        'completedTasks': [],
        'totalTasks': 0,
      });
      
      setState(() {
        _currentStreak = 0;
        _longestStreak = 0;
        _weeklyAverage = 0;
        _isLoading = false;
      });
      return;
    }

    _progressHistory = progressSnapshot.docs.map((doc) => doc.data()).toList();
    _calculateStreaks();
    _calculateWeeklyAverage();
    
    setState(() => _isLoading = false);

  } catch (e) {
    setState(() {
      _errorMessage = "Failed to load progress: ${e.toString()}";
      _isLoading = false;
    });
  }
}

  void _calculateStreaks() {
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime previousDate = DateTime.now().add(const Duration(days: 1)); // Future date
    
    for (var entry in _progressHistory) {
      final date = (entry['date'] as Timestamp).toDate();
      final progress = entry['progress'] as int;
      
      if (previousDate.difference(date).inDays == 1 && progress >= 100) {
        currentStreak++;
      } else {
        currentStreak = progress >= 100 ? 1 : 0;
      }
      
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      
      previousDate = date;
    }
    
    setState(() {
      _currentStreak = currentStreak;
      _longestStreak = longestStreak;
    });
  }

  void _calculateWeeklyAverage() {
    final lastWeek = _progressHistory.take(7);
    final total = lastWeek.fold(0, (sum, entry) => sum + (entry['progress'] as int));
    setState(() => _weeklyAverage = total / lastWeek.length);
  }

  

  

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recovery Progress", 
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: primaryYellow,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Container(
        color: lightYellow,
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryYellow))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(_errorMessage,
                    style: TextStyle(color: darkYellow, fontSize: 16),
                  ),
                )
              : _progressHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.insights, size: 60, color: mediumYellow),
                          const SizedBox(height: 20),
                          Text(
                            "No progress data yet",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Complete some tasks to see your progress",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _fetchProgressData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryYellow,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Refresh Data",
                              style: TextStyle(color: Colors.black87)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Stats Row
                          Row(
                            children: [
                              Expanded(child: _buildStatCard(
                                'Current Streak', 
                                '$_currentStreak days', 
                                Icons.whatshot,
                                primaryYellow
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: _buildStatCard(
                                'Longest Streak', 
                                '$_longestStreak days', 
                                Icons.star,
                                mediumYellow
                              )),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Weekly Average', 
                            '${_weeklyAverage.toStringAsFixed(1)}%', 
                            Icons.trending_up,
                            darkYellow
                          ),
                          const SizedBox(height: 24),
                          
                          // Progress Chart Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryYellow.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text('Weekly Progress',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                  )),
                                const SizedBox(height: 16),
                                _buildProgressChart(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Recent Activity Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryYellow.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text('Recent Activity',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87
                                  )),
                                const SizedBox(height: 16),
                                ..._progressHistory.take(5).map((entry) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: lightBlue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: entry['progress'] >= 100 
                                        ? Icon(Icons.check, color: primaryYellow)
                                        : Icon(Icons.circle, color: mediumYellow),
                                  ),
                                  title: Text('${entry['progress']}% Completed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: entry['progress'] >= 100 
                                        ? Colors.green 
                                        : Colors.black87
                                    )),
                                  subtitle: Text(
                                    DateFormat('MMM dd, yyyy').format(
                                      (entry['date'] as Timestamp).toDate()),
                                    style: TextStyle(color: Colors.grey[600])),
                                )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryYellow.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87
            )),
          const SizedBox(height: 6),
          Text(title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700]
            )),
        ],
      ),
    );
  }

 Widget _buildProgressChart() {
  // Filter out invalid or empty data
  final validWeeklyData = _progressHistory
      .where((entry) => entry['progress'] != null)
      .take(7)
      .toList()
      .reversed
      .toList();

  // If no valid data, show placeholder
  if (validWeeklyData.isEmpty) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: lightBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 40, color: mediumYellow),
            const SizedBox(height: 10),
            Text(
              "No progress data available",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  return SizedBox(
    height: 200,
    child: LineChart(
      LineChartData(
        minX: 0,
        maxX: validWeeklyData.length > 1 ? (validWeeklyData.length - 1).toDouble() : 1,
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= validWeeklyData.length) return const Text('');
                final date = (validWeeklyData[value.toInt()]['date'] as Timestamp).toDate();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM dd').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
              interval: 25,
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: lightBlue, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: validWeeklyData.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                (e.value['progress'] as int).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: darkYellow,
            barWidth: 3,
            shadow: Shadow(
              color: primaryYellow.withOpacity(0.3),
              blurRadius: 10,
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [mediumYellow.withOpacity(0.3), primaryYellow.withOpacity(0.1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: darkYellow,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
}