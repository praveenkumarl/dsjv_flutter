import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class BaseUrlService {
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(AppConfig.prefBaseUrlOverride);
    final url = (override != null && override.trim().isNotEmpty)
        ? override.trim()
        : AppConfig.defaultBaseUrl;
    return url.endsWith('/') ? url : '$url/';
  }

  Future<void> setOverride(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.trim().isEmpty) {
      await prefs.remove(AppConfig.prefBaseUrlOverride);
    } else {
      await prefs.setString(AppConfig.prefBaseUrlOverride, url.trim());
    }
  }
}
