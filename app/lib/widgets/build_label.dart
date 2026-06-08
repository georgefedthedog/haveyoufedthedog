import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Small "v0.1.0+1" label, read from the bundled package info. Lives at the
/// bottom of every screen with a Scaffold so we can spot stale builds.
class BuildLabel extends StatefulWidget {
  const BuildLabel({super.key});

  @override
  State<BuildLabel> createState() => _BuildLabelState();
}

class _BuildLabelState extends State<BuildLabel> {
  String? _label;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _label = 'v${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        _label ?? '',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
      ),
    );
  }
}
