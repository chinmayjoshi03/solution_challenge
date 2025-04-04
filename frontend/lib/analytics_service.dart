import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Track screen views
  static Future<void> trackScreen(String screenName) async {
    await _analytics.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': screenName},
    );
  }

  // Track custom events (e.g., button clicks)
  static Future<void> trackEvent(String eventName, {Map<String, Object>? params}) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: params, // Now uses Map<String, Object>?
    );
  }
}