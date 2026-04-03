import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';

class ProductUploadScreen extends StatefulWidget {
  const ProductUploadScreen({super.key});

  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameJaController = TextEditingController();
  final _nameZhController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '野菜';
  String _selectedUnit = '個';
  final List<String> _images = [];

  final categories = ['野菜', '精肉', '鮮魚', '果物'];
  final units = ['個', 'kg', 'g', '袋', '箱', '束', '本'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadCategories();
    });
  }

  Future<void> _pickImage() async {
    if (_images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最大5枚まで選択できます')),
      );
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _images.add(image.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final productProvider = context.read<ProductProvider>();

    try {
      await productProvider.uploadProduct(
        code: _codeController.text,
        nameJa: _nameJaController.text,
        nameZh: _nameZhController.text.isEmpty ? null : _nameZhController.text,
        categoryId: _getCategoryId(_selectedCategory),
        unit: _selectedUnit,
        purchasePrice: int.parse(_purchasePriceController.text),
        stock: int.parse(_stockController.text),
        descriptionJa: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        images: _images.isEmpty ? null : _images,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('提出しました'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _codeController.clear();
        _nameJaController.clear();
        _nameZhController.clear();
        _purchasePriceController.clear();
        _stockController.clear();
        _descriptionController.clear();
        setState(() {
          _images.clear();
          _selectedCategory = '野菜';
          _selectedUnit = '個';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提出に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getCategoryId(String categoryName) {
    final categories = context.read<ProductProvider>().categories;
    final category = categories.firstWhere(
      (c) => c.nameJa == categoryName,
      orElse: () => throw Exception('Category not found: $categoryName'),
    );
    return category.id;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameJaController.dispose();
    _nameZhController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品アップロード'),
        backgroundColor: const Color(0xFF3ECF8E),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Upload
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF3ECF8E), style: BorderStyle.solid, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: _images.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Color(0xFF3ECF8E)),
                          SizedBox(height: 8),
                          Text('写真を追加 (最大5枚)', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : Center(child: Text('${_images.length}枚選択', style: const TextStyle(color: Color(0xFF3ECF8E)))),
              ),
            ),
            const SizedBox(height: 16),

            // Product Code
            TextFormField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: '商品コード *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) => value?.isEmpty ?? true ? '必須' : null,
            ),
            const SizedBox(height: 16),

            // Product Name (Japanese)
            TextFormField(
              controller: _nameJaController,
              decoration: InputDecoration(
                labelText: '商品名(日) *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (value) => value?.isEmpty ?? true ? '必須' : null,
            ),
            const SizedBox(height: 16),

            // Product Name (Chinese)
            TextFormField(
              controller: _nameZhController,
              decoration: InputDecoration(
                labelText: '商品名(中)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Category & Unit
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(labelText: '分類 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: InputDecoration(labelText: '単位 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _selectedUnit = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price & Stock
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchasePriceController,
                    decoration: InputDecoration(labelText: '仕入価格 *', prefixText: '¥', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return '必須';
                      if (int.tryParse(value!) == null) return '数値を入力';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(labelText: '在庫 *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return '必須';
                      if (int.tryParse(value!) == null) return '数値を入力';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: '説明', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: productProvider.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3ECF8E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: productProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('提出する', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
