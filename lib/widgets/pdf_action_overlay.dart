import 'package:flutter/material.dart';

class PdfActionOverlay extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onShare;
  const PdfActionOverlay({super.key, required this.onDownload, required this.onShare});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      TextButton.icon(
        onPressed: onDownload,
        icon: const Icon(Icons.download, color: Colors.white),
        label: const Text('Download PDF', style: TextStyle(color: Colors.white)),
      ),
      TextButton.icon(
        onPressed: onShare,
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text('Share PDF', style: TextStyle(color: Colors.white)),
      ),
    ]),
  );
}
