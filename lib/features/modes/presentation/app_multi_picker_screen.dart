import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../platform/usage_tracking_service.dart';

class AppMultiPickerScreen extends ConsumerStatefulWidget {
  const AppMultiPickerScreen({super.key, this.selected = const {}});

  final Set<String> selected;

  @override
  ConsumerState<AppMultiPickerScreen> createState() => _AppMultiPickerScreenState();
}

class _AppMultiPickerScreenState extends ConsumerState<AppMultiPickerScreen> {
  late final Set<String> _selected = {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(installedAppsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose apps')),
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
              if (q.isEmpty || a.label.toLowerCase().contains(q)) a,
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
                        itemBuilder: (context, i) {
                          final app = visible[i];
                          return CheckboxListTile(
                            value: _selected.contains(app.packageName),
                            secondary: AppIcon(packageName: app.packageName),
                            title: Text(app.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selected.add(app.packageName);
                              } else {
                                _selected.remove(app.packageName);
                              }
                            }),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop<List<InstalledApp>>(
                        context,
                        [for (final a in all) if (_selected.contains(a.packageName)) a],
                      ),
                      child: Text(_selected.isEmpty ? 'Done' : 'Done (${_selected.length})'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
