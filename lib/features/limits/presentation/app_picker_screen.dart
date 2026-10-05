import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';

class AppPickerScreen extends ConsumerStatefulWidget {
  const AppPickerScreen({super.key, this.excluded = const {}});

  final Set<String> excluded;

  @override
  ConsumerState<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends ConsumerState<AppPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose an app')),
      body: apps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Couldn\'t load your apps',
          message: 'Go back and try again.',
        ),
        data: (all) {
          final q = _query.trim().toLowerCase();
          final visible = [
            for (final a in all)
              if (!widget.excluded.contains(a.packageName) &&
                  (q.isEmpty || a.label.toLowerCase().contains(q)))
                a,
          ];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SearchBar(
                  hintText: 'Search apps',
                  leading: const Icon(Icons.search),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No apps found',
                        message: 'Try a different search.',
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _AppTile(app: visible[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: AppSpacing.sm,
      leading: AppIcon(packageName: app.packageName),
      title: Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => Navigator.pop(context, app),
    );
  }
}
