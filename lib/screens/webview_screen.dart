import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../services/base_url_service.dart';
import '../services/device_id_service.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_action_overlay.dart';
import 'device_info_screen.dart';
import 'device_migration_screen.dart';
import '../config/app_theme.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final _baseUrlService = BaseUrlService();
  final _authService = AuthService();
  final _deviceIdService = DeviceIdService();
  final _pdfService = PdfService();

  String? _deviceId;
  int _lastAuthCode = -1;
  String _currentUrl = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => _onUrlChanged(url),
        onPageFinished: (url) => _onUrlChanged(url),
        onNavigationRequest: (req) { _onUrlChanged(req.url); return NavigationDecision.navigate; },
        onWebResourceError: (err) => debugPrint('WebView error: ${err.description}'),
      ));
    _applyAndroidSettings();
    _authenticateAndLoad();
  }

  Future<void> _applyAndroidSettings() async {
    if (_controller.platform is AndroidWebViewController) {
      final android = _controller.platform as AndroidWebViewController;
      await android.setUseWideViewPort(true);
      await android.setMediaPlaybackRequiresUserGesture(false);
      if (kDebugMode) {
        await AndroidWebViewController.enableDebugging(true); // ✅ static call
      }
    }
  }

  // Inside your WebViewScreen's _authenticateAndLoad method (or similar)

  Future<void> _authenticateAndLoad() async {
    setState(() => _loading = true);
    _deviceId ??= await _deviceIdService.getAndroidId();
    final base = await _baseUrlService.getBaseUrl();
    
    final result = await _authService.authenticate(_deviceId!, base);
    _lastAuthCode = result.responseCode;

    if (!mounted) return;

    final baseUrl = result.activeBaseUrl.endsWith('/')
        ? result.activeBaseUrl
        : '${result.activeBaseUrl}/';

    // ---- 200 / 201 : existing user, load site ----
    if (result.responseCode == 200 || result.responseCode == 201) {
      if (mounted) setState(() => _loading = false);
      
      // 👇 SHOW A FRIENDLY SUCCESS MESSAGE INSTEAD OF THE HTTP CODE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authenticated successfully! Welcome back.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await _controller.loadRequest(
        Uri.parse('$baseUrl${AppConfig.indexEndpoint}?key=$_deviceId'),
      );
      return;
    }

    // ---- 202 : unknown device -> offer migration ----
    if (result.responseCode == 202) {
      if (mounted) setState(() => _loading = false);

      if (!mounted) return;
      final migrated = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => DeviceMigrationScreen(
            newDeviceId: _deviceId!,
            baseUrl: baseUrl,
          ),
        ),
      );

      if (migrated == true) {
        await _authenticateAndLoad();
      } else if (mounted) {
        await _controller.loadRequest(
          Uri.parse('$baseUrl${AppConfig.registerEndpoint}?key=$_deviceId'),
        );
      }
      return;
    }

    // ---- Anything else: error page ----
    if (mounted) setState(() => _loading = false);
    await _controller.loadRequest(
      Uri.parse('$baseUrl${AppConfig.errorEndpoint}'),
    );
  }

  void _onUrlChanged(String url) {
    debugPrint('[WEBVIEW NAV] $url'); // Prints to your flutter run terminal
    if (mounted) setState(() => _currentUrl = url);
  }

  bool get _showPdfOverlay => _currentUrl.toLowerCase().contains('pdf');

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppConfig.appName),
          backgroundColor: const Color(0xFF0B1B3A),
          foregroundColor: Colors.white,
          actions: [
            PopupMenuButton<String>(
			  icon: const Icon(Icons.more_vert, color: AppTheme.sky),
              onSelected: (v) {
                if (v == 'help') {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DeviceInfoScreen(
                      deviceId: _deviceId ?? '', responseCode: _lastAuthCode,
                    ),
                  ));
                } else if (v == 'env') {
                  _showEnvironmentDialog();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'help', child: Text('Help / Device Info')),
                PopupMenuItem(value: 'env',  child: Text('Environment')),
              ],
            ),
          ],
        ),
        body: Stack(children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator(
            color: AppTheme.pink, // 👈 Pink loading spinner
          )),
          if (_showPdfOverlay)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: PdfActionOverlay(onDownload: _downloadPdf, onShare: _sharePdf),
            ),
        ]),
      ),
    );
  }

  Future<void> _showEnvironmentDialog() async {
	if (!mounted) return;
    final choice = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Environment'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 0), child: const Text('Use configured base URL')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 1), child: const Text('Production')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 2), child: const Text('Custom...')),
          SimpleDialogOption(onPressed: () => Navigator.pop(context, 3), child: const Text('Clear override')),
        ],
      ),
    );
    if (choice == null) return;
	if (!mounted) return;
    switch (choice) {
      case 0:
      case 3:
        await _baseUrlService.setOverride(null);
        break;
      case 1:
        await _baseUrlService.setOverride(AppConfig.productionBaseUrl);
        break;
      case 2:
		if (!mounted) return;
        final controller = TextEditingController();
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Custom base URL'),
            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'https://.../')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('OK')),
            ],
          ),
        );
        if (ok == true && controller.text.trim().isNotEmpty) {
          await _baseUrlService.setOverride(controller.text.trim());
        }
    }
    if (mounted) _authenticateAndLoad();
  }

  Future<void> _downloadPdf() async {
    final file = await _resolvePdf();
	if (!mounted) return;
    if (file == null) { _toast('Failed to create/download PDF'); return; }
    _toast('Saved: ${file.path}');
  }

  Future<void> _sharePdf() async {
    final file = await _resolvePdf();
    if (file == null) { _toast('Failed to create/download PDF'); return; }
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
        subject: 'DSJV App 2.0 PDF');
  }

  Future<File?> _resolvePdf() async {
    final url = await _controller.currentUrl() ?? _currentUrl; // ✅ awaited
    if (url.isEmpty) return null;

    if (_looksLikePdfUrl(url)) return _pdfService.downloadPdf(url);

    try {
      final js =
          "(function(){var f=document.forms['${AppConfig.pdfFormName}'];"
          "if(!f) return ''; var action=f.action||'${AppConfig.pdfEndpoint}';"
          "var fd=new FormData(f); var p=[];"
          "for (var e of fd.entries()) p.push(encodeURIComponent(e[0])+'='+encodeURIComponent(e[1]));"
          "return action+'|||'+p.join('&');})();";
      final raw = await _controller.runJavaScriptReturningResult(js);
      final s = raw is String ? raw : raw.toString();
      if (s.isNotEmpty && s != 'null' && s != '""') {
        final parts = s.replaceAll(RegExp(r'^"|"$'), '').split('|||');
        final action = parts.first;
        final body = parts.length > 1 ? parts[1] : '';
        if (body.isNotEmpty) {
          final target = Uri.parse(url).resolve(action).toString();
          final file = await _pdfService.downloadPdfByPost(target, body);
          if (file != null) return file;
        }
      }
    } catch (_) {}

    if (await _pdfService.isPdfUrl(url)) return _pdfService.downloadPdf(url);

    final html = await _controller.runJavaScriptReturningResult('document.documentElement.outerHTML');
    final htmlStr = html is String ? html : html.toString();
    return _pdfService.generatePdfFromHtml(htmlStr, url);
  }

  bool _looksLikePdfUrl(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.pdf') || u.contains('.pdf?') ||
           u.contains('download=') || u.contains('content-type=application/pdf');
  }

  void _toast(String msg) {
	  if (!mounted) return;
	  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
	}
}
