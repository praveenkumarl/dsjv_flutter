import 'dart:io';
import 'package:android_id/android_id.dart';

class DeviceIdService {
  Future<String> getAndroidId() async {
    if (!Platform.isAndroid) throw UnsupportedError('Android only');
    
    // This gets the exact same ID as Settings.Secure.ANDROID_ID in your Java app
    final androidId = await const AndroidId().getId();
    return androidId ?? '';
  }
}