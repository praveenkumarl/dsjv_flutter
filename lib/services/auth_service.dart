import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthResult {
  final int responseCode;
  final String activeBaseUrl;
  AuthResult(this.responseCode, this.activeBaseUrl);
}

class AuthService {
  static const _timeout = Duration(seconds: 5);

  Future<AuthResult> authenticate(String deviceId, String baseUrl) async {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final candidates = <String>[base];
    if (base.contains('10.0.2.2')) {
      candidates.add(base.replaceFirst('10.0.2.2', '127.0.0.1'));
    }
    for (final b in candidates) {
      try {
        final uri = Uri.parse('$b${AppConfig.authEndpoint}?key=$deviceId');
        final resp = await http.get(uri).timeout(_timeout);
        if (resp.statusCode > 0) {
          return AuthResult(resp.statusCode, b);
        }
      } catch (_) {}
    }
    return AuthResult(0, base);
  }
}
