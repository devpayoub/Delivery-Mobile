import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/driver.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class AssignCityScreen extends StatefulWidget {
  const AssignCityScreen({Key? key}) : super(key: key);

  @override
  _AssignCityScreenState createState() => _AssignCityScreenState();
}

class _AssignCityScreenState extends State<AssignCityScreen> {
  List<Driver> _drivers = [];
  List<City> _cities = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final drivers = await apiService.getDrivers();
      final cities = await apiService.getCities();
      setState(() {
        _drivers = drivers;
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

  void _showAssignDialog(Driver driver) {
    String? selectedCityId = driver.cityId;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text('Assign ${driver.name}', style: AppTheme.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select a city for this driver:'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCityId,
                        hint: const Text('Not Assigned'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Not Assigned'),
                          ),
                          ..._cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.id,
                              child: Text(city.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedCityId = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final success = await apiService.assignDriverToCity(driver.id, selectedCityId ?? '');
                    if (success) {
                      Navigator.pop(context);
                      _loadData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Driver city updated successfully'), backgroundColor: Colors.green),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            CustomAppBar(
              title: 'Assign City',
              subtitle: 'Manage Driver Territories',
              onRefresh: _loadData,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _drivers.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final driver = _drivers[index];
                            final cityName = _cities.firstWhere(
                              (c) => c.id == driver.cityId,
                              orElse: () => City(id: '', name: 'Not Assigned', createdAt: DateTime.now()),
                            ).name;
                            
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    offset: const Offset(0, 4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: AppTheme.primary),
                                ),
                                title: Text(driver.name, style: AppTheme.title.copyWith(fontSize: 16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(driver.phone, style: AppTheme.subtitle),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: driver.cityId != null ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        cityName,
                                        style: TextStyle(
                                          color: driver.cityId != null ? Colors.green : Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_location_alt_outlined, color: AppTheme.primary),
                                  onPressed: () => _showAssignDialog(driver),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Failed to load data', style: AppTheme.body1),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
