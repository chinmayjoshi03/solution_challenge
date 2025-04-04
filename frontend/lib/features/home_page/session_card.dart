import 'package:flutter/material.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool isProgressCard; // To differentiate between AI Coach and Daily Progress cards

  const SessionCard({
    Key? key,
    required this.title,
    required this.onTap,
    this.isProgressCard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFDE03).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEE58), // Medium yellow
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isProgressCard ? Icons.arrow_forward : Icons.smart_toy, // Use arrow for progress, AI icon for coach
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}