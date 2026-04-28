import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery.dart';
import '../models/employer.dart';
import '../models/driver.dart';
import '../models/product_type.dart';
import '../app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_app_bar.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({Key? key}) : super(key: key);

  @override
  _OwnerDashboardScreenState createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> with TickerProviderStateMixin {
  List<Delivery> _deliveries = [];
  List<Employer> _employers = [];
  List<Driver> _drivers = [];
  List<City> _cities = [];
  List<ProductType> _productTypes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final deliveries = await apiService.getDeliveries();
      final employers = await apiService.getEmployers();
      final drivers = await apiService.getDrivers();
      final cities = await apiService.getCities();
      final productTypes = await apiService.getProductTypes();
      setState(() {
        _deliveries = deliveries;
        _employers = employers;
        _drivers = drivers;
        _cities = cities;
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

  @override
  Widget build(BuildContext context) {
    final cancelled = _deliveries.where((d) => d.status == 'Cancelled').length;

    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            CustomAppBar(
              title: 'Owner Portal',
              subtitle: 'Admin Dashboard',
              onRefresh: _fetchData,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Statistics", style: AppTheme.title.copyWith(fontSize: 20)),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 1.1,
                                children: [
                                  StatCard(
                                    title: 'Total Employers',
                                    value: _employers.length.toString(),
                                    icon: Icons.people_outlined,
                                    gradientColors: const [AppTheme.primary, AppTheme.secondary],
                                  ),
                                  StatCard(
                                    title: 'Total Drivers',
                                    value: _drivers.length.toString(),
                                    icon: Icons.delivery_dining,
                                    gradientColors: const [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                                  ),
                                  StatCard(
                                    title: 'Total Cities',
                                    value: _cities.length.toString(),
                                    icon: Icons.location_city_outlined,
                                    gradientColors: const [AppTheme.statusDelivered, Color(0xFF96C93D)],
                                  ),
                                  StatCard(
                                    title: 'Product Types',
                                    value: _productTypes.length.toString(),
                                    icon: Icons.category_outlined,
                                    gradientColors: const [AppTheme.statusPending, Color(0xFFFF5E62)],
                                  ),
                                  StatCard(
                                    title: 'Total Deliveries',
                                    value: _deliveries.length.toString(),
                                    icon: Icons.local_shipping_outlined,
                                    gradientColors: const [Color(0xFF4481EB), Color(0xFF04BEFE)],
                                  ),
                                  StatCard(
                                    title: 'Cancelled',
                                    value: cancelled.toString(),
                                    icon: Icons.cancel_outlined,
                                    gradientColors: const [Color(0xFFF093FB), Color(0xFFF5576C)],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text("Recent Activity", style: AppTheme.title.copyWith(fontSize: 20)),
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _deliveries.length > 5 ? 5 : _deliveries.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final delivery = _deliveries[index];
                                  return _buildSimpleDeliveryTile(delivery);
                                },
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleDeliveryTile(Delivery delivery) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), offset: const Offset(0, 4), blurRadius: 8),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primary, size: 20),
        ),
        title: Text(delivery.clientName, style: AppTheme.title.copyWith(fontSize: 16)),
        subtitle: Text(delivery.status, style: AppTheme.subtitle.copyWith(color: AppTheme.lightText)),
        trailing: Text("${delivery.totalPrice} DT", style: AppTheme.title.copyWith(color: AppTheme.primary, fontSize: 16)),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppTheme.statusCancelled.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Something went wrong.', style: AppTheme.body1),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}