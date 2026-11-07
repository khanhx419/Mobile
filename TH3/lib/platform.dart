import 'package:flutter/services.dart';

class SpeechPlatform {
  static const channel = MethodChannel('th3/speech');
  static void observe(void Function(String)? onState) {
    channel.setMethodCallHandler(
      onState == null
          ? null
          : (call) async {
              if (call.method == 'speechState' && call.arguments is String) {
                onState(call.arguments as String);
              }
            },
    );
  }

  static Future<void> cancel() => channel.invokeMethod('cancel');
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
