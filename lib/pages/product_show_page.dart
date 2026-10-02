import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import 'cart_page.dart';
import 'rebuild_demo_page.dart';

const _desktopBreakpoint = 1000.0;

const _narrowMaxWidth = 640.0;

const _wideMaxWidth = 1200.0;

class ProductShowPage extends StatefulWidget {
  const ProductShowPage({super.key, required this.product, required this.cart});

  final Product product;
  final Cart cart;

  @override
  State<ProductShowPage> createState() => _ProductShowPageState();
}

class _ProductShowPageState extends State<ProductShowPage> {
  int _imageIndex = 0;
  int _colorIndex = 0;
  int? _sizeIndex;
  int _quantity = 1;
  bool _isFavorite = false;
  bool _descriptionExpanded = false;

  Product get product => widget.product;

  void _addToCart() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (_sizeIndex == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a size first')),
      );
      return;
    }
    final color = product.colors[_colorIndex];
    final size = product.sizes[_sizeIndex!];
    widget.cart.add(product, color, size, quantity: _quantity);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$_quantity × ${product.name} '
          '(${color.name}, EU $size) added to cart',
        ),
        action: SnackBarAction(label: 'View cart', onPressed: _openCart),
      ),
    );
  }

  void _openCart() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => CartPage(cart: widget.cart)));
  }

  Widget _buildCartButton({required bool circle}) {
    return ListenableBuilder(
      listenable: widget.cart,
      builder: (context, _) {
        final count = widget.cart.count;
        final button = circle
            ? _CircleIconButton(
                icon: Icons.shopping_cart_outlined,
                tooltip: 'View cart',
                onPressed: _openCart,
              )
            : IconButton(
                tooltip: 'View cart',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: _openCart,
              );
        return Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: button,
        );
      },
    );
  }

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  void _openRebuildDemo() =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const RebuildDemoPage()));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return width >= _desktopBreakpoint
        ? _buildWideLayout(theme)
        : _buildNarrowLayout(theme);
  }

  Widget _buildNarrowLayout(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildGallerySliver(),
          SliverToBoxAdapter(
            child: _Constrained(
              maxWidth: _narrowMaxWidth,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDetailSections(theme),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildWideLayout(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${product.brand}  /  ${product.category}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share (opens rebuild demo)',
            icon: const Icon(Icons.share_outlined),
            onPressed: _openRebuildDemo,
          ),
          IconButton(
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : null,
            ),
            onPressed: _toggleFavorite,
          ),
          _buildCartButton(circle: false),
          const SizedBox(width: 16),
        ],
      ),
      body: _Constrained(
        maxWidth: _wideMaxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 11,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 16, 24, 32),
                child: _ProductGallery(
                  color: product.colors[_colorIndex].color,
                  index: _imageIndex,
                  onIndexChanged: (i) => setState(() => _imageIndex = i),
                  discountPercent: product.discountPercent,
                  showControls: true,
                ),
              ),
            ),
            Expanded(
              flex: 9,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildDetailSections(theme, inlinePurchase: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailSections(
    ThemeData theme, {
    bool inlinePurchase = false,
  }) {
    return [
      _buildHeader(theme),
      const SizedBox(height: 16),
      _buildPrice(theme),
      const SizedBox(height: 24),
      _buildHighlights(theme),
      const SizedBox(height: 28),
      _buildColorPicker(theme),
      const SizedBox(height: 24),
      _buildSizePicker(theme),
      if (inlinePurchase) ...[
        const SizedBox(height: 28),
        _buildPurchaseRow(theme),
      ],
      const SizedBox(height: 28),
      _buildDescription(theme),
      const SizedBox(height: 24),
      _buildPerks(theme),
    ];
  }

  Widget _buildGallerySliver() {
    final color = product.colors[_colorIndex].color;

    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      stretch: true,
      backgroundColor: color.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: _CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      actions: [
        _CircleIconButton(
          icon: Icons.share_outlined,
          onPressed: _openRebuildDemo,
        ),
        const SizedBox(width: 8),
        _CircleIconButton(
          icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
          iconColor: _isFavorite ? Colors.redAccent : null,
          onPressed: _toggleFavorite,
        ),
        const SizedBox(width: 8),
        _buildCartButton(circle: true),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _ProductGallery(
          color: color,
          index: _imageIndex,
          onIndexChanged: (i) => setState(() => _imageIndex = i),
          discountPercent: product.discountPercent,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${product.brand.toUpperCase()} · ${product.category}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          product.name,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final icon = product.rating >= i + 1
                    ? Icons.star_rounded
                    : product.rating >= i + 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded;
                return Icon(icon, size: 20, color: Colors.amber);
              }),
            ),
            const SizedBox(width: 2),
            Text(
              product.rating.toStringAsFixed(1),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '(${product.reviewCount} reviews)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrice(ThemeData theme) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 10,
          children: [
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            if (product.oldPrice != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '\$${product.oldPrice!.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text(
                'In stock',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights(ThemeData theme) {
    const spacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 340 ? 2 : 4;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in product.highlights.entries)
              Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      entry.value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.key,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildColorPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Color', trailing: product.colors[_colorIndex].name),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(product.colors.length, (i) {
            final selected = i == _colorIndex;
            final c = product.colors[i].color;
            return Tooltip(
              message: product.colors[i].name,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setState(() => _colorIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: c,
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSizePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          'Size (EU)',
          trailing: 'Size guide',
          trailingColor: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(product.sizes.length, (i) {
            final selected = i == _sizeIndex;
            return ChoiceChip(
              label: SizedBox(
                width: 28,
                child: Text(product.sizes[i], textAlign: TextAlign.center),
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _sizeIndex = i),
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDescription(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Description'),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: Text(
            product.description,
            maxLines: _descriptionExpanded ? null : 3,
            overflow: _descriptionExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                setState(() => _descriptionExpanded = !_descriptionExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _descriptionExpanded ? 'Show less' : 'Read more',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerks(ThemeData theme) {
    const perks = [
      (Icons.local_shipping_outlined, 'Free delivery', 'Arrives in 2–4 days'),
      (Icons.autorenew_rounded, 'Free returns', 'Within 30 days'),
      (Icons.verified_user_outlined, '1-year warranty', 'Official product'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (final (icon, title, subtitle) in perks)
            ListTile(
              leading: Icon(icon, color: theme.colorScheme.primary),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(subtitle),
              dense: true,
            ),
        ],
      ),
    );
  }

  Widget _buildPurchaseRow(ThemeData theme) {
    final total = product.price * _quantity;

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Decrease quantity',
                icon: const Icon(Icons.remove),
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Text(
                '$_quantity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                tooltip: 'Increase quantity',
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton.icon(
            onPressed: _addToCart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Add to cart · \$${total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _Constrained(
          maxWidth: _narrowMaxWidth - 40,
          child: _buildPurchaseRow(theme),
        ),
      ),
    );
  }
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({
    required this.color,
    required this.index,
    required this.onIndexChanged,
    this.discountPercent,
    this.showControls = false,
  });

  static const icons = [
    Icons.directions_run_rounded,
    Icons.hiking_rounded,
    Icons.sports_rounded,
  ];

  final Color color;
  final int index;
  final ValueChanged<int> onIndexChanged;
  final int? discountPercent;

  final bool showControls;

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  late final _controller = PageController(initialPage: widget.index);

  int get _count => _ProductGallery.icons.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int i) => _controller.animateToPage(
    i,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final stage = _buildStage(context);
    if (!widget.showControls) return stage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: stage,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_count, _buildThumbnail),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context) {
    final color = widget.color;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        ScrollConfiguration(
          behavior: ScrollConfiguration.of(context)
              .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
          child: PageView.builder(
            controller: _controller,
            itemCount: _count,
            onPageChanged: widget.onIndexChanged,
            itemBuilder: (context, i) => LayoutBuilder(
              builder: (context, constraints) => Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _ProductGallery.icons[i],
                    key: ValueKey('$i-${color.toARGB32()}'),
                    size: constraints.biggest.shortestSide * 0.5,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.discountPercent != null)
          Positioned(
            left: 20,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '-${widget.discountPercent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          left: 0,
          bottom: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_count, (i) {
              final active = i == widget.index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? color : color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        if (widget.showControls && widget.index > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _CircleIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous image',
                onPressed: () => _goTo(widget.index - 1),
              ),
            ),
          ),
        if (widget.showControls && widget.index < _count - 1)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _CircleIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next image',
                onPressed: () => _goTo(widget.index + 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnail(int i) {
    final selected = i == widget.index;
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _goTo(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(_ProductGallery.icons[i], size: 36, color: color),
        ),
      ),
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.maxWidth, required this.child});

  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing, this.trailingColor});

  final String title;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (trailing != null)
          Text(
            trailing!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: trailingColor ?? theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.iconColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 1,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 20, color: iconColor ?? Colors.black87),
        onPressed: onPressed,
      ),
    );
  }
}
