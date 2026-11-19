import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class PdfService {
  Future<bool> isPdfUrl(String srcUrl) async {
    try {
      final uri = Uri.parse(srcUrl);
      final head = await http.head(uri).timeout(const Duration(seconds: 5));
      final ct = head.headers['content-type'] ?? '';
      if (head.statusCode >= 200 && head.statusCode < 400 && ct.contains('application/pdf')) {
        return true;
      }
      final get = await http.get(uri, headers: {'Range': 'bytes=0-0'})
          .timeout(const Duration(seconds: 5));
      return (get.headers['content-type'] ?? '').contains('application/pdf');
    } catch (_) { return false; }
  }

  Future<File?> downloadPdf(String srcUrl) async {
    try {
      final resp = await http.get(Uri.parse(srcUrl),
          headers: {'User-Agent': 'DSJVApp/2.0 (Android)'})
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      return await _writeToCache(_extractName(resp.headers['content-disposition'],
          Uri.parse(srcUrl)), resp.bodyBytes);
    } catch (_) { return null; }
  }

  Future<File?> downloadPdfByPost(String endpointUrl, String body) async {
    try {
      final resp = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Accept': 'application/pdf,application/octet-stream,*/*',
          'User-Agent': 'DSJVApp/2.0 (Android)',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;
      return await _writeToCache(_extractName(resp.headers['content-disposition'],
          Uri.parse(endpointUrl)), resp.bodyBytes);
    } catch (_) { return null; }
  }

  Future<File?> generatePdfFromHtml(String html, String baseUrl) async {
    try {
      final bytes = await Printing.convertHtml(
  	format: PdfPageFormat.a4,
	html: html,
	baseUrl: baseUrl, // ✅ Correct: pass the String directly
	);
      return await _writeToCache('page.pdf', bytes);
    } catch (_) { return null; }
  }

  Future<File> _writeToCache(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  String _extractName(String? disposition, Uri uri) {
    if (disposition != null && disposition.contains('filename=')) {
      return disposition.split('filename=').last.replaceAll('"', '').trim();
    }
    final segs = uri.pathSegments;
    final last = segs.isNotEmpty ? segs.last : 'download.pdf';
    return last.isEmpty ? 'download.pdf' : last;
  }
}
