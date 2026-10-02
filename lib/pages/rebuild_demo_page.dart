import 'package:flutter/material.dart';

/// Shows which widgets rebuild when `setState` (or a ValueNotifier) fires.
///
/// Every [BuildBadge] counts how many times its own `build()` ran and flashes
/// when it rebuilds, so you can watch exactly what each button affects.
class RebuildDemoPage extends StatefulWidget {
  const RebuildDemoPage({super.key});

  @override
  State<RebuildDemoPage> createState() => _RebuildDemoPageState();
}

class _RebuildDemoPageState extends State<RebuildDemoPage> {
  int _pageCounter = 0;
  final _notifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    BuildBadge.resetCounts();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('setState rebuild demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Each badge shows how many times its build() ran. '
                    'It flashes when it rebuilds. Press the buttons and '
                    'watch which badges change.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. setState on the page itself.
                  _DemoCard(
                    title: '1. setState in the page',
                    explanation:
                        'Runs the whole page build() again. Every non-const '
                        'widget inside it rebuilds too.',
                    action: FilledButton(
                      onPressed: () => setState(() => _pageCounter++),
                      child: Text('Page counter: $_pageCounter'),
                    ),
                    // Not const → rebuilt every time the page rebuilds.
                    badge: BuildBadge('Page build()'),
                  ),

                  // 2. Non-const vs const children.
                  _DemoCard(
                    title: '2. Children of the page',
                    explanation:
                        'The plain child rebuilds with the page. The const '
                        'child is the exact same object every time, so '
                        'Flutter skips it.',
                    badge: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BuildBadge('Child (not const)'),
                        const SizedBox(height: 8),
                        const BuildBadge('Child (const)'),
                      ],
                    ),
                  ),

                  // 3. A separate StatefulWidget with its own setState.
                  _DemoCard(
                    title: '3. Separate StatefulWidget',
                    explanation:
                        'Its own setState rebuilds only itself, and the page '
                        'badge stays the same. When the page rebuilds, this '
                        'rebuilds too, but its counter value is kept.',
                    badge: _LocalCounter(),
                  ),

                  // 4. ValueNotifier + ValueListenableBuilder.
                  _DemoCard(
                    title: '4. ValueNotifier (no setState)',
                    explanation:
                        'Only the ValueListenableBuilder rebuilds. The page '
                        'build() does not run at all.',
                    action: OutlinedButton(
                      onPressed: () => _notifier.value++,
                      child: const Text('notifier.value++'),
                    ),
                    badge: ValueListenableBuilder<int>(
                      valueListenable: _notifier,
                      builder: (context, value, _) => BuildBadge(
                        'Listener (value: $value)',
                        id: 'listener',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalCounter extends StatefulWidget {
  @override
  State<_LocalCounter> createState() => _LocalCounterState();
}

class _LocalCounterState extends State<_LocalCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: () => setState(() => _count++),
          child: Text('Local counter: $_count'),
        ),
        BuildBadge('Local widget build()'),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.explanation,
    required this.badge,
    this.action,
  });

  final String title;
  final String explanation;
  final Widget badge;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (action != null) ...[action!, const SizedBox(height: 12)],
            badge,
          ],
        ),
      ),
    );
  }
}

/// Counts its own `build()` calls and flashes each time it rebuilds.
class BuildBadge extends StatelessWidget {
  const BuildBadge(this.label, {super.key, this.id});

  final String label;

  /// Key for the build count; defaults to [label]. Set it when the label
  /// changes between builds.
  final String? id;

  static final _counts = <String, int>{};

  static void resetCounts() => _counts.clear();

  static int countOf(String id) => _counts[id] ?? 0;

  @override
  Widget build(BuildContext context) {
    final key = id ?? label;
    final count = _counts[key] = countOf(key) + 1;
    final theme = Theme.of(context);
    final highlight = Colors.amber.withValues(alpha: 0.6);
    final base = theme.colorScheme.surfaceContainerHighest;

    // A new key restarts the animation, so the badge flashes on every build.
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 700),
      builder: (context, t, child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color.lerp(base, highlight, t),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label · built $count×',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
