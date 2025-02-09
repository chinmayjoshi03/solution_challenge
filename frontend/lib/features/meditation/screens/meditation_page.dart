import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeditationPage extends StatefulWidget {
  static route() => MaterialPageRoute(
        builder: (context) => const MeditationPage(),
      );

  const MeditationPage({Key? key}) : super(key: key);

  @override
  _MeditationPageState createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      // Replace this with your actual meditation audio URL or asset file.
      await _audioPlayer.play(UrlSource("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"));
    }

    setState(() {
      isPlaying = !isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Guided Meditation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Breathe In, Breathe Out",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🔹 Breathing Animation
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.5),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(
                    end: 1.5,
                    duration: 4.seconds,
                    curve: Curves.easeInOut,
                  ),
            ),

            const SizedBox(height: 40),

            // 🔹 Play / Pause Meditation Button
            ElevatedButton.icon(
              onPressed: _togglePlayPause,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(isPlaying ? "Pause Meditation" : "Start Meditation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Listen to this guided meditation to help you stay calm and focused.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
