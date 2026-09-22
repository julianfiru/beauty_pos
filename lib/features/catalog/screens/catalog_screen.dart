import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_format.dart';
import '../../../core/widgets/flat_badge.dart';
import '../../../core/widgets/interactive_card.dart';
import '../../../core/widgets/modern_tab_bar.dart';
import '../../../core/widgets/app_image_view.dart';
import '../providers/catalog_provider.dart';
import 'product_form_dialog.dart';
import 'service_form_dialog.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Katalog Salon'),
      ),
      body: Column(
        children: [
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
                    hintText: 'Cari di katalog...',
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
          Expanded(
            child: _selectedTabIndex == 0 ? _buildProductsTab() : _buildServicesTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedTabIndex == 0) {
            showDialog(context: context, builder: (_) => const ProductFormDialog());
          } else {
            showDialog(context: context, builder: (_) => const ServiceFormDialog());
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _selectedTabIndex == 0 ? 'Tambah Produk' : 'Tambah Treatment',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    final productsState = ref.watch(productsProvider);

    return productsState.when(
      data: (products) {
        final filtered = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Tidak ada produk fisik.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final product = filtered[index];
            final isLowStock = product.stock < 5;

            return InteractiveCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AppImageView(
                    imageUrl: product.imageUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: Icons.inventory_2_outlined,
                    fallbackColor: AppColors.primaryDark,
                    fallbackBackgroundColor: AppColors.secondary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormat.toIdr(product.price),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(width: 10),
                            FlatBadge(
                              label: 'Stok: ${product.stock}',
                              color: isLowStock ? AppColors.error : AppColors.textSecondary,
                              backgroundColor: isLowStock ? AppColors.errorBg : AppColors.background,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => showDialog(context: context, builder: (_) => ProductFormDialog(product: product)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDeleteProduct(context, product.id!, product.name),
                      ),
                    ],
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

  Widget _buildServicesTab() {
    final servicesState = ref.watch(servicesProvider);

    return servicesState.when(
      data: (services) {
        final filtered = services.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa_outlined, size: 56, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Tidak ada jasa treatment.', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final service = services[index];

            return InteractiveCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AppImageView(
                    imageUrl: service.imageUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(12),
                    fallbackIcon: Icons.spa_outlined,
                    fallbackColor: AppColors.accentPinkDark,
                    fallbackBackgroundColor: AppColors.accentPink.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              CurrencyFormat.toIdr(service.price),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            const SizedBox(width: 10),
                            FlatBadge(
                              label: '${service.durationMinutes} menit',
                              icon: Icons.timer_outlined,
                              color: AppColors.accentPinkDark,
                              backgroundColor: AppColors.accentPinkLight,
                              fontSize: 11,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        onPressed: () => showDialog(context: context, builder: (_) => ServiceFormDialog(service: service)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        onPressed: () => _confirmDeleteService(context, service.id!, service.name),
                      ),
                    ],
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

  void _confirmDeleteProduct(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(productsProvider.notifier).deleteProduct(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteService(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Jasa'),
        content: Text('Yakin ingin menghapus "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(servicesProvider.notifier).deleteService(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
