import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyHelpPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const EmergencyHelpPage(),
      );

  const EmergencyHelpPage({Key? key}) : super(key: key);

  @override
  _EmergencyHelpPageState createState() => _EmergencyHelpPageState();
}

class _EmergencyHelpPageState extends State<EmergencyHelpPage> {
  void _showCopingStrategies() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Coping Strategies"),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text("• Take deep, slow breaths."),
                Text("• Find a quiet, safe space."),
                Text("• Reach out to a trusted friend or sponsor."),
                Text("• Engage in a distracting activity (e.g., a walk or music)."),
                Text("• Remind yourself of your recovery goals."),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
            TextButton(
              onPressed: () async {
                const emergencyNumber = "tel:911"; // Replace with your local emergency number.
                if (await canLaunch(emergencyNumber)) {
                  await launch(emergencyNumber);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Unable to call emergency services.")),
                  );
                }
              },
              child: const Text("Call Emergency Services", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Help"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button icon
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "If you're feeling overwhelmed or triggered, please take a moment to calm down.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: _showCopingStrategies,
                child: const Text("I'm Feeling Triggered"),
              ),
              const SizedBox(height: 20),
              const Text(
                "Remember, it's okay to seek help. You are not alone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
