import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/main.dart';
import 'package:project/pages/rebuild_demo_page.dart';

Future<void> _pumpAtSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
}

void main() {
  testWidgets('Product show page renders and updates quantity',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Air Runner Pro'), findsOneWidget);
    expect(find.text('Add to cart · \$89.99'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Add to cart · \$179.98'), findsOneWidget);
  });

  // Layout overflows throw in tests, so rendering at each size is the check.
  for (final (name, size) in [
    ('small phone', const Size(320, 640)),
    ('phone', const Size(390, 844)),
    ('tablet', const Size(800, 1100)),
    ('desktop', const Size(1440, 900)),
  ]) {
    testWidgets('renders without overflow on $name', (tester) async {
      await _pumpAtSize(tester, size);
      expect(find.text('Air Runner Pro'), findsOneWidget);
    });
  }

  testWidgets('desktop uses two columns with gallery controls',
      (tester) async {
    await _pumpAtSize(tester, const Size(1440, 900));

    // Gallery and details sit side by side.
    final gallery = tester.getCenter(find.byIcon(Icons.chevron_right_rounded));
    final title = tester.getCenter(find.text('Air Runner Pro'));
    expect(title.dx, greaterThan(gallery.dx));

    // No previous arrow on the first image; next arrow advances.
    expect(find.byIcon(Icons.chevron_left_rounded), findsNothing);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
  });

  testWidgets('added items show in the cart and can be changed',
      (tester) async {
    await _pumpAtSize(tester, const Size(390, 1600));

    // Empty cart.
    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
    await tester.tap(find.text('Continue shopping'));
    await tester.pumpAndSettle();

    // Add 2 × size 42, then 1 more of the same → merged into one line of 3.
    await tester.tap(find.text('42'));
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    await tester.tap(find.text('Add to cart · \$179.98'));
    await tester.pump();
    expect(find.text('View cart'), findsOneWidget); // SnackBar action
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.tap(find.text('Add to cart · \$179.98'));
    await tester.pump();

    // Badge shows 3 units.
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isTrue);
    expect((badge.label! as Text).data, '3');

    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart (3)'), findsOneWidget);
    expect(find.text('Air Runner Pro'), findsOneWidget);
    expect(find.text('Coral · EU 42'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('cart-total'))).data,
      '\$269.97',
    );

    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(find.text('Your cart (4)'), findsOneWidget);

    // Step down to 1, then the minus becomes Remove.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byTooltip('Decrease quantity'));
      await tester.pump();
    }
    await tester.tap(find.byTooltip('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Your cart is empty'), findsOneWidget);
  });

  testWidgets('cart page renders without overflow on small phone',
      (tester) async {
    await _pumpAtSize(tester, const Size(320, 640));
    await tester.ensureVisible(find.text('39'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('39'));
    await tester.pump();
    await tester.tap(find.textContaining('Add to cart ·'));
    await tester.pump();
    await tester.tap(find.byTooltip('View cart'));
    await tester.pumpAndSettle();
    expect(find.text('Coral · EU 39'), findsOneWidget);
  });

  testWidgets('share opens the rebuild demo and counts rebuilds correctly',
      (tester) async {
    await _pumpAtSize(tester, const Size(390, 1600));

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
    expect(find.text('setState rebuild demo'), findsOneWidget);

    // Page setState: page + non-const children rebuild, const child doesn't.
    await tester.tap(find.text('Page counter: 0'));
    await tester.pumpAndSettle();
    expect(BuildBadge.countOf('Page build()'), 2);
    expect(BuildBadge.countOf('Child (not const)'), 2);
    expect(BuildBadge.countOf('Child (const)'), 1);
    expect(BuildBadge.countOf('Local widget build()'), 2);
    expect(BuildBadge.countOf('listener'), 2);

    // Local setState: only the local widget rebuilds.
    await tester.tap(find.text('Local counter: 0'));
    await tester.pumpAndSettle();
    expect(BuildBadge.countOf('Local widget build()'), 3);
    expect(BuildBadge.countOf('Page build()'), 2);

    // ValueNotifier: only the listener rebuilds.
    await tester.tap(find.text('notifier.value++'));
    await tester.pumpAndSettle();
    expect(BuildBadge.countOf('listener'), 3);
    expect(BuildBadge.countOf('Page build()'), 2);
    expect(find.text('Listener (value: 1) · built 3×'), findsOneWidget);
  });
}
