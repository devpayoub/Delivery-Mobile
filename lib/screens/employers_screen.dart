import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/employer.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class EmployersScreen extends StatefulWidget {
  const EmployersScreen({Key? key}) : super(key: key);

  @override
  _EmployersScreenState createState() => _EmployersScreenState();
}

class _EmployersScreenState extends State<EmployersScreen> {
  List<Employer> _employers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployers();
  }

  Future<void> _fetchEmployers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final employers = await apiService.getEmployers();
      setState(() {
        _employers = employers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({Employer? employer}) async {
    final nameController = TextEditingController(text: employer?.name ?? '');
    final phoneController = TextEditingController(text: employer?.phone ?? '');
    final idNumberController = TextEditingController(text: employer?.idNumber ?? '');
    final passwordController = TextEditingController();
    String? idPicBase64;
    final isEditing = employer != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(isEditing ? 'Edit Employer' : 'Add Employer'),
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
                if (!isEditing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage((base64) {
                      setDialogState(() => idPicBase64 = base64);
                    }),
                    icon: const Icon(Icons.badge),
                    label: Text(idPicBase64 != null ? 'ID Pic Selected' : 'Upload ID Pic'),
                  ),
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
                if (nameController.text.isEmpty || phoneController.text.isEmpty || idNumberController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All fields are required')));
                  return;
                }
                final data = {
                  'name': nameController.text,
                  'phone': phoneController.text,
                  'id_number': idNumberController.text,
                  if (!isEditing) 'password': passwordController.text,
                  if (idPicBase64 != null) 'id_pic_base64': idPicBase64,
                };
                bool success;
                if (isEditing) {
                  success = await apiService.updateEmployer(employer.id, data);
                } else {
                  success = await apiService.createEmployer(data);
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
      _fetchEmployers();
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

  void _confirmDelete(Employer employer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Employer?'),
        content: Text('Are you sure you want to delete ${employer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.deleteEmployer(employer.id);
              Navigator.pop(context, success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _fetchEmployers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
    }
  }

  Widget _buildAvatar(Employer employer) {
    if (employer.idPic != null && employer.idPic!.isNotEmpty) {
      if (employer.idPic!.startsWith('http')) {
        return CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          backgroundImage: NetworkImage(employer.idPic!),
        );
      } else {
        try {
          return CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            backgroundImage: MemoryImage(base64Decode(employer.idPic!)),
          );
        } catch (e) {
          return CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(
              employer.name.isNotEmpty ? employer.name[0].toUpperCase() : 'E',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
          );
        }
      }
    } else {
      return CircleAvatar(
        backgroundColor: AppTheme.primary.withOpacity(0.1),
        child: Text(
          employer.name.isNotEmpty ? employer.name[0].toUpperCase() : 'E',
          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
        ),
      );
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
              title: 'Employers',
              subtitle: 'Manage employers',
              onRefresh: _fetchEmployers,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _employers.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _employers.length,
                              itemBuilder: (context, index) {
                                final employer = _employers[index];
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
                                    leading: _buildAvatar(employer),
                                    title: Text(employer.name, style: AppTheme.title.copyWith(fontSize: 16)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(employer.phone, style: AppTheme.subtitle),
                                        Text('ID: ${employer.idNumber}', style: AppTheme.caption),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                                          onPressed: () => _showAddEditDialog(employer: employer),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () => _confirmDelete(employer),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
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
          Icon(Icons.people_outline, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No employers found', style: AppTheme.subtitle),
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
            onPressed: _fetchEmployers,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}