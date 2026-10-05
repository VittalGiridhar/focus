import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

class AppIcon extends ConsumerWidget {
  const AppIcon({super.key, required this.packageName, this.size = 40});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final icon = ref.watch(appIconProvider(packageName));
    final bytes = icon.valueOrNull;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: bytes == null
            ? Icon(Icons.apps, size: size * 0.7)
            : ClipRRect(
                borderRadius: BorderRadius.circular(size * 0.22),
                child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
              ),
      ),
    );
  }
}
