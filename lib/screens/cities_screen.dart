import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({Key? key}) : super(key: key);

  @override
  _CitiesScreenState createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  List<City> _cities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCities();
  }

  Future<void> _fetchCities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final cities = await apiService.getCities();
      setState(() {
        _cities = cities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _showAddEditDialog({City? city}) async {
    final nameController = TextEditingController(text: city?.name ?? '');
    final isEditing = city != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Edit City' : 'Add City'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'City Name', border: OutlineInputBorder()),
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
                success = await apiService.updateCity(city.id, data);
              } else {
                success = await apiService.createCity(data);
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
      _fetchCities();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Success'), backgroundColor: Colors.green));
    }
  }

  void _confirmDelete(City city) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete City?'),
        content: Text('Are you sure you want to delete ${city.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.deleteCity(city.id);
              Navigator.pop(context, success);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _fetchCities();
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
              title: 'Cities',
              subtitle: 'Manage cities',
              onRefresh: _fetchCities,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _cities.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _cities.length,
                              itemBuilder: (context, index) {
                                final city = _cities[index];
                                return _buildCityTile(city);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTile(City city) {
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
          child: const Icon(Icons.location_city, color: AppTheme.primary),
        ),
        title: Text(city.name, style: AppTheme.title.copyWith(fontSize: 16)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
              onPressed: () => _showAddEditDialog(city: city),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(city),
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
          Icon(Icons.location_city, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No cities found', style: AppTheme.subtitle),
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
            onPressed: _fetchCities,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}