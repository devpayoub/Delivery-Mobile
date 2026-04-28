import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_type.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class ProductTypesScreen extends StatefulWidget {
  const ProductTypesScreen({Key? key}) : super(key: key);

  @override
  _ProductTypesScreenState createState() => _ProductTypesScreenState();
}

class _ProductTypesScreenState extends State<ProductTypesScreen> {
  List<ProductType> _productTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProductTypes();
  }

  Future<void> _fetchProductTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final productTypes = await apiService.getProductTypes();
      setState(() {
        _productTypes = productTypes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({ProductType? productType}) async {
    final nameController = TextEditingController(text: productType?.name ?? '');
    final isEditing = productType != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit Product Type' : 'Add Product Type'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Product Type Name', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                return;
              }
              final data = {'name': nameController.text};
              bool success;
              if (isEditing) {
                success = await apiService.updateProductType(productType.id, data);
              } else {
                success = await apiService.createProductType(data);
              }
              Navigator.pop(context, success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      _fetchProductTypes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success'), backgroundColor: Colors.green));
    }
  }

  void _confirmDelete(ProductType productType) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Product Type?'),
        content: Text('Are you sure you want to delete ${productType.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.deleteProductType(productType.id);
              Navigator.pop(context, success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _fetchProductTypes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Column(
          children: [
            CustomAppBar(
              title: 'Product Types',
              subtitle: 'Manage product types',
              onRefresh: _fetchProductTypes,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _productTypes.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _productTypes.length,
                              itemBuilder: (context, index) {
                                final productType = _productTypes[index];
                                return _buildProductTypeTile(productType);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeTile(ProductType productType) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), offset: const Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: const Icon(Icons.category, color: AppTheme.primary),
        ),
        title: Text(productType.name, style: AppTheme.title.copyWith(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showAddEditDialog(productType: productType),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(productType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No product types found', style: AppTheme.subtitle),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Failed to load', style: AppTheme.body1),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchProductTypes,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}