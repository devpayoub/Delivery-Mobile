import 'package:flutter/material.dart';
import '../models/product_type.dart';
import '../models/driver.dart';
import '../services/api_service.dart';
import '../app_theme.dart';

class DeliveryForm extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final String? deliveryId;

  const DeliveryForm({Key? key, this.initialData, this.deliveryId}) : super(key: key);

  @override
  _DeliveryFormState createState() => _DeliveryFormState();
}

class _DeliveryFormState extends State<DeliveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedCityId;
  String? _selectedProductTypeId;
  
  List<City> _cities = [];
  List<ProductType> _productTypes = [];
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _clientNameController.text = widget.initialData!['client_name']?.toString() ?? '';
      _phoneController.text = widget.initialData!['phone']?.toString() ?? '';
      _addressController.text = widget.initialData!['address']?.toString() ?? '';
      final price = widget.initialData!['total_price'];
      _priceController.text = price != null ? price.toString() : '';
      _selectedCityId = widget.initialData!['city_id']?.toString();
      _selectedProductTypeId = widget.initialData!['product_type_id']?.toString();
    }
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);
    try {
      final cities = await apiService.getCities();
      final productTypes = await apiService.getProductTypes();
      setState(() {
        _cities = cities;
        _productTypes = productTypes;
        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('Error loading form data: $e');
      setState(() => _isLoadingData = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final priceText = _priceController.text.trim();
    final price = priceText.isNotEmpty ? double.tryParse(priceText) : null;
    
    setState(() => _isSaving = true);
    
    final data = {
      'client_name': _clientNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city_id': _selectedCityId,
      'product_type_id': _selectedProductTypeId,
      if (price != null) 'total_price': price,
    };

    bool success;
    if (widget.deliveryId != null) {
      success = await apiService.updateDelivery(widget.deliveryId!, data);
    } else {
      success = await apiService.createDelivery(data);
    }

    setState(() => _isSaving = false);
    
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save delivery'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      child: _isLoadingData 
          ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 24),
                    Text(widget.deliveryId == null ? 'Create New Delivery' : 'Edit Delivery', style: AppTheme.title.copyWith(fontSize: 24)),
                    const SizedBox(height: 24),
                    _buildTextField(_clientNameController, 'Client Name', Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildTextField(_addressController, 'Full Address', Icons.location_on_outlined, maxLines: 2),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdown<String>(_cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(), 'City', _selectedCityId, (val) => setState(() => _selectedCityId = val))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDropdown<String>(_productTypes.map((pt) => DropdownMenuItem(value: pt.id, child: Text(pt.name))).toList(), 'Product', _selectedProductTypeId, (val) => setState(() => _selectedProductTypeId = val))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_priceController, 'Total Price (DT)', Icons.money, keyboardType: TextInputType.number),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(widget.deliveryId == null ? 'Create Delivery' : 'Save Changes', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDropdown<T>(List<DropdownMenuItem<T>> items, String label, T? value, Function(T?) onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: (val) => val == null ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
