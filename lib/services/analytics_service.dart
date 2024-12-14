import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analyticsInstance = FirebaseAnalytics.instance;

  Future<void> register(String username, String signUpMethod) async {
    await _analyticsInstance.logSignUp(
      signUpMethod: signUpMethod,
      parameters: {
        'username': username,
      },
    ).then((value) => print("User ${username} registered for the first time using their ${signUpMethod}"));
  }

  Future<void> login(String username, String loginMethod) async {
    await _analyticsInstance.logLogin(
      loginMethod: loginMethod,
      parameters: {
        'username': username,
      },
    ).then((value) => print("User ${username} logged in using their ${loginMethod}"));
  }

  Future<void> subscribeToChannel(String channelId, String username) async {
    await _analyticsInstance.logEvent(
      name: 'join_channel',
      parameters: {
        'channel_id': channelId,
        'username': username,
      },
    ).then((value) => print("User ${username} joined the channel with id ${channelId}"));
  }

  Future<void> unsubscribe(String channelId, String username) async {
    await _analyticsInstance.logEvent(
      name: 'leave_channel',
      parameters: {
        'channel_id': channelId,
        'username': username,
      },
    ).then((value) => print("User ${username} left the channel with id ${channelId}"));
  }
}
