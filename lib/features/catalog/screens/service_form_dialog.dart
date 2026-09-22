import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/image_picker_box.dart';
import '../models/service_item.dart';
import '../providers/catalog_provider.dart';

class ServiceFormDialog extends ConsumerStatefulWidget {
  final ServiceItem? service;

  const ServiceFormDialog({super.key, this.service});

  @override
  ConsumerState<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends ConsumerState<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  late TextEditingController _descController;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name ?? '');
    _categoryController = TextEditingController(text: widget.service?.category ?? 'Treatment');
    _priceController = TextEditingController(text: widget.service?.price.toString() ?? '');
    _durationController = TextEditingController(text: widget.service?.durationMinutes.toString() ?? '60');
    _descController = TextEditingController(text: widget.service?.description ?? '');
    _imageUrl = widget.service?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveService() {
    if (_formKey.currentState!.validate()) {
      final newService = ServiceItem(
        id: widget.service?.id,
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        durationMinutes: int.parse(_durationController.text.trim()),
        description: _descController.text.trim(),
        imageUrl: _imageUrl,
        createdAt: widget.service?.createdAt ?? DateTime.now().toIso8601String(),
      );

      if (widget.service == null) {
        ref.read(servicesProvider.notifier).addService(newService);
      } else {
        ref.read(servicesProvider.notifier).updateService(newService);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 460,
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.service == null ? 'Tambah Jasa Treatment' : 'Edit Jasa Treatment',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ImagePickerBox(
                  imageUrl: _imageUrl,
                  label: 'Foto Treatment (Opsional)',
                  placeholderIcon: Icons.spa_outlined,
                  onImageSelected: (url) {
                    setState(() => _imageUrl = url);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Jasa / Treatment', prefixIcon: Icon(Icons.spa_outlined, size: 20)),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: 'Kategori (contoh: Facial, Massage)', prefixIcon: Icon(Icons.category_outlined, size: 20)),
                  validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Tarif (Rp)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(labelText: 'Durasi (Menit)'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty ? 'Wajib' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Deskripsi Singkat (Opsional)', prefixIcon: Icon(Icons.description_outlined, size: 20)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveService,
                    child: const Text('Simpan Treatment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
