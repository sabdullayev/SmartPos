import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/product_image.dart';
import '../../domain/entities/product.dart';
import 'barcode_scanner_modal.dart';

class ProductFormDialog extends StatefulWidget {
  final Product? product;

  const ProductFormDialog({super.key, this.product});

  static Future<Product?> show(BuildContext context, {Product? product}) {
    return showDialog<Product>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ProductFormDialog(product: product),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _minQtyController = TextEditingController(text: '5');
  String? _imagePath;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _barcodeController.text = p.barcode ?? '';
      _costPriceController.text = p.costPrice > 0 ? p.costPrice.toStringAsFixed(0) : '';
      _sellPriceController.text = p.sellPrice.toStringAsFixed(0);
      _stockQtyController.text = p.stockQty.toStringAsFixed(0);
      _minQtyController.text = p.minQty.toStringAsFixed(0);
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellPriceController.dispose();
    _stockQtyController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Сделать фото камерой'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Удалить фото', style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _imagePath = null);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
        });
      }
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await BarcodeScannerModal.show(context);
    if (scanned != null && scanned.isNotEmpty) {
      setState(() {
        _barcodeController.text = scanned;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final costPrice = double.tryParse(_costPriceController.text.trim()) ?? 0.0;
    final sellPrice = double.tryParse(_sellPriceController.text.trim()) ?? 0.0;
    final stockQty = double.tryParse(_stockQtyController.text.trim()) ?? 0.0;
    final minQty = double.tryParse(_minQtyController.text.trim()) ?? 5.0;
    final barcode = _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim();

    final product = Product(
      id: widget.product?.id ?? const Uuid().v4(),
      shopId: widget.product?.shopId ?? AppConstants.defaultShopId,
      name: _nameController.text.trim(),
      barcode: barcode,
      costPrice: costPrice,
      sellPrice: sellPrice,
      stockQty: stockQty,
      minQty: minQty,
      isDeleted: widget.product?.isDeleted ?? false,
      updatedAt: DateTime.now(),
      imagePath: _imagePath,
    );

    Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header (Protected against overflow with Expanded)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Редактировать товар' : 'Новый товар',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image picker tile
                  Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          ProductImage(
                            imagePath: _imagePath,
                            width: 100,
                            height: 100,
                            borderRadius: 16,
                            defaultIcon: Icons.add_a_photo_outlined,
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0F766E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      _imagePath != null ? 'Нажмите для изменения фото' : 'Добавить фото товара',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Название товара *',
                      hintText: 'например, Круассан',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Введите название товара';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Barcode with scanner button
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: const InputDecoration(
                            labelText: 'Штрихкод',
                            hintText: 'Код или QR',
                            prefixIcon: Icon(Icons.barcode_reader),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _scanBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                        tooltip: 'Сканировать',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Prices
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _sellPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Цена продажи *',
                            suffixText: AppConstants.currency,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Укажите цену';
                            if (double.tryParse(val.trim()) == null) return 'Неверно';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _costPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Себестоимость',
                            suffixText: AppConstants.currency,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quantities
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Остаток *',
                            hintText: '0',
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Остаток';
                            if (double.tryParse(val.trim()) == null) return 'Неверно';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _minQtyController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Мин. остаток',
                            hintText: '5',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons (Protected against overflow with Expanded)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            isEditing ? 'Сохранить' : 'Добавить',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
