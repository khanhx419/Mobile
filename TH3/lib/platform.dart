import 'package:flutter/services.dart';

class SpeechPlatform {
  static const channel = MethodChannel('th3/speech');
  static Future<Map<String, dynamic>?> listen() async {
    final result = await channel.invokeMapMethod<String, dynamic>('listen');
    return result;
  }

  static Future<void> stop() => channel.invokeMethod('stop');
  static Future<void> speak(String text) =>
      channel.invokeMethod('speak', {'text': text});
  static Future<void> reminder(bool enabled, int hour, int minute) =>
      channel.invokeMethod('reminder', {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
      });
  static Future<void> testReminder() => channel.invokeMethod('testReminder');
}
