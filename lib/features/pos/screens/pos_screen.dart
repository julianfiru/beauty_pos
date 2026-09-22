import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/interactive_card.dart';
import '../../../core/widgets/modern_tab_bar.dart';
import '../../../core/widgets/flat_badge.dart';
import '../../../core/widgets/app_image_view.dart';
import '../providers/pos_provider.dart';
import 'checkout_dialog.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  int _selectedTabIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildCatalogSection(),
            ),
            Container(width: 1, color: AppColors.border),
            Expanded(
              flex: 2,
              child: _buildCartSection(context, isBottomSheet: false),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kasir POS'),
      ),
      body: _buildCatalogSection(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 4,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(child: _buildCartSection(context, isBottomSheet: true)),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        label: Consumer(
          builder: (context, ref, child) {
            final cart = ref.watch(cartProvider);
            final total = ref.read(cartProvider.notifier).cartTotal;
            return Text(
              '${cart.length} Item • ${CurrencyFormat.toIdr(total)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCatalogSection() {
    return Column(
      children: [
        // Top Toolbar (Tabs & Search)
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ModernSegmentedControl(
                      selectedIndex: _selectedTabIndex,
                      items: const ['Produk Fisik', 'Jasa Treatment'],
                      icons: const [Icons.inventory_2_outlined, Icons.spa_outlined],
                      onItemSelected: (index) => setState(() => _selectedTabIndex = index),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cari produk atau nama treatment...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  fillColor: AppColors.background,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        // Grid View Area
        Expanded(
          child: _selectedTabIndex == 0 ? _buildProductGrid() : _buildServiceGrid(),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    final productsAsync = ref.watch(availableProductsProvider);

    return productsAsync.when(
      data: (products) {
        final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Tidak ada produk ditemukan', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.74,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            final isOutOfStock = product.stock <= 0;

            return InteractiveCard(
              onTap: isOutOfStock ? null : () => ref.read(cartProvider.notifier).addProduct(product),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImageView(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                            fallbackIcon: Icons.inventory_2_outlined,
                            fallbackIconSize: 34,
                            fallbackColor: AppColors.primaryDark,
                            fallbackBackgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FlatBadge(
                              label: 'Stok: ${product.stock}',
                              color: isOutOfStock ? AppColors.error : AppColors.textPrimary,
                              backgroundColor: isOutOfStock
                                  ? AppColors.errorBg
                                  : Colors.white.withValues(alpha: 0.94),
                              fontSize: 10.5,
                            ),
                          ),
                          if (isOutOfStock)
                            Container(
                              color: Colors.black.withValues(alpha: 0.45),
                              child: const Center(
                                child: FlatBadge(
                                  label: 'HABIS',
                                  color: Colors.white,
                                  backgroundColor: AppColors.error,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormat.toIdr(product.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildServiceGrid() {
    final servicesAsync = ref.watch(availableServicesProvider);

    return servicesAsync.when(
      data: (services) {
        final filtered = services.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Tidak ada treatment ditemukan', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 0.74,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final service = filtered[index];

            return InteractiveCard(
              onTap: () => ref.read(cartProvider.notifier).addService(service),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AppImageView(
                            imageUrl: service.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                            fallbackIcon: Icons.spa_outlined,
                            fallbackIconSize: 34,
                            fallbackColor: AppColors.accentPinkDark,
                            fallbackBackgroundColor: AppColors.accentPink.withValues(alpha: 0.35),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: FlatBadge(
                              label: '${service.durationMinutes} mnt',
                              icon: Icons.timer_outlined,
                              color: AppColors.secondaryDark,
                              backgroundColor: Colors.white.withValues(alpha: 0.94),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    service.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormat.toIdr(service.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildCartSection(BuildContext context, {required bool isBottomSheet}) {
    final cart = ref.watch(cartProvider);
    final total = ref.read(cartProvider.notifier).cartTotal;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          if (!isBottomSheet) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Keranjang Transaksi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (cart.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                      child: const Text('Kosongkan', style: TextStyle(color: AppColors.error, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text('Keranjang masih kosong', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Klik barang di samping untuk menambahkan', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      final isProduct = item.itemType == 'PRODUCT';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            AppImageView(
                              imageUrl: item.imageUrl,
                              width: 44,
                              height: 44,
                              borderRadius: BorderRadius.circular(10),
                              fallbackIcon: isProduct ? Icons.inventory_2_outlined : Icons.spa_outlined,
                              fallbackColor: isProduct ? AppColors.primaryDark : AppColors.accentPinkDark,
                              fallbackBackgroundColor: isProduct ? AppColors.secondary.withValues(alpha: 0.3) : AppColors.accentPink.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormat.toIdr(item.price),
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => ref.read(cartProvider.notifier).decreaseQty(item),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.remove, size: 16, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${item.qty}',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => ref.read(cartProvider.notifier).increaseQty(item),
                                    child: const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: Icon(Icons.add, size: 16, color: AppColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              CurrencyFormat.toIdr(total),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: cart.isEmpty
                          ? null
                          : () {
                              if (isBottomSheet) Navigator.pop(context);
                              showDialog(
                                context: context,
                                builder: (context) => CheckoutDialog(totalAmount: total),
                              );
                            },
                      child: const Text('Proses Pembayaran (Checkout)'),
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
