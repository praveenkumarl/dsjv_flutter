import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class DeviceInfoScreen extends StatefulWidget {
  final String deviceId;
  final int responseCode;
  const DeviceInfoScreen({
    super.key, required this.deviceId, required this.responseCode,
  });
  @override State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  String _body = 'Loading...';

  @override void initState() { super.initState(); _build(); }

  Future<void> _build() async {
    final info = await DeviceInfoPlugin().androidInfo;
	if (!mounted) return;
    final media = MediaQuery.of(context);
    final widthDp = media.size.width;
    final heightDp = media.size.height;
    final dpr = media.devicePixelRatio;
    final widthPx = (widthDp * dpr).round();
    final heightPx = (heightDp * dpr).round();
    final orientation = widthDp > heightDp ? 'Landscape' : 'Portrait';

    if (!mounted) return;
    setState(() {
      _body = '''
Key: ${widget.deviceId}
Auth HTTP Code: ${widget.responseCode}
Model: ${info.manufacturer} ${info.model}
Brand: ${info.brand}
Hardware: ${info.hardware}
Android Version: ${info.version.release} (API ${info.version.sdkInt})
Screen px: $widthPx x $heightPx
Screen dp: ${widthDp.round()} x ${heightDp.round()}
Density: $dpr
Orientation: $orientation
''';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Device Info')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: SingleChildScrollView(child: Text(_body,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)))),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ]),
    ),
  );
}
