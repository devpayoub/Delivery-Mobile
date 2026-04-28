import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/driver.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({Key? key}) : super(key: key);

  @override
  _DriversScreenState createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  List<Driver> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final drivers = await apiService.getDrivers();
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({Driver? driver}) async {
    final nameController = TextEditingController(text: driver?.name ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final idNumberController = TextEditingController(text: driver?.idNumber ?? '');
    final licenseNumberController = TextEditingController(text: driver?.licenseNumber ?? '');
    final passwordController = TextEditingController();
    String? idPicBase64;
    String? licensePicBase64;
    final isEditing = driver != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'Edit Driver' : 'Add Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: licenseNumberController,
                  decoration: const InputDecoration(labelText: 'License Number *', border: OutlineInputBorder()),
                ),
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage((base64) {
                          setDialogState(() => idPicBase64 = base64);
                        }),
                        icon: const Icon(Icons.badge),
                        label: Text(idPicBase64 != null ? 'ID Selected' : 'Upload ID Pic'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage((base64) {
                          setDialogState(() => licensePicBase64 = base64);
                        }),
                        icon: const Icon(Icons.card_membership),
                        label: Text(licensePicBase64 != null ? 'License Selected' : 'Upload License'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty || 
                    idNumberController.text.isEmpty || licenseNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                  return;
                }
                final data = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'id_number': idNumberController.text,
                  'license_number': licenseNumberController.text,
                  if (!isEditing) 'password': passwordController.text,
                  if (idPicBase64 != null) 'id_pic_base64': idPicBase64,
                  if (licensePicBase64 != null) 'license_pic_base64': licensePicBase64,
                };
                bool success;
                if (isEditing) {
                  success = await apiService.updateDriver(driver.id, data);
                } else {
                  success = await apiService.createDriver(data);
                }
                Navigator.pop(context, success);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _fetchDrivers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success'), backgroundColor: Colors.green));
    }
  }

void _pickImage(Function(String) onPick) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final base64 = base64Encode(bytes);
      onPick(base64);
    }
  }

  void _confirmDelete(Driver driver) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Driver?'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.deleteDriver(driver.id);
              Navigator.pop(context, success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _fetchDrivers();
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
              title: 'Drivers',
              subtitle: 'Manage drivers',
              onRefresh: _fetchDrivers,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _drivers.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _drivers.length,
                              itemBuilder: (context, index) {
                                final driver = _drivers[index];
                                return _buildDriverTile(driver);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverTile(Driver driver) {
    Widget leadingWidget;
    if (driver.idPic != null && driver.idPic!.isNotEmpty) {
      if (driver.idPic!.startsWith('http')) {
        leadingWidget = CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          backgroundImage: NetworkImage(driver.idPic!),
        );
      } else {
        try {
          leadingWidget = CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            backgroundImage: MemoryImage(base64Decode(driver.idPic!)),
          );
        } catch (e) {
          leadingWidget = CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          );
        }
      }
    } else {
      leadingWidget = CircleAvatar(
        backgroundColor: AppTheme.primary.withOpacity(0.1),
        child: Text(
          driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      );
    }

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
        leading: leadingWidget,
        title: Text(driver.name, style: AppTheme.title.copyWith(fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(driver.phone, style: AppTheme.subtitle),
            Text('ID: ${driver.idNumber}', style: AppTheme.caption),
            Text('License: ${driver.licenseNumber}', style: AppTheme.caption),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showAddEditDialog(driver: driver),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(driver),
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
          Icon(Icons.delivery_dining, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No drivers found', style: AppTheme.subtitle),
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
            onPressed: _fetchDrivers,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}