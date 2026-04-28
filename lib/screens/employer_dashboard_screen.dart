import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery.dart';
import '../app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/custom_app_bar.dart';

class EmployerDashboardScreen extends StatefulWidget {
  const EmployerDashboardScreen({Key? key}) : super(key: key);

  @override
  _EmployerDashboardScreenState createState() => _EmployerDashboardScreenState();
}

class _EmployerDashboardScreenState extends State<EmployerDashboardScreen> with TickerProviderStateMixin {
  List<Delivery> _deliveries = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDeliveries();
  }

  Future<void> _fetchDeliveries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final deliveries = await apiService.getEmployerDeliveries();
      setState(() {
        _deliveries = deliveries;
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
    final pending = _deliveries.where((d) => d.status == 'Pending').length;
    final completed = _deliveries.where((d) => d.status == 'Delivered').length;
    final driversUsed = _deliveries.map((d) => d.cityName).toSet().length; // Approximate drivers used by distinct cities for now
    final spentThisMonth = _deliveries.length * 15.0;
    final efficiency = _deliveries.isEmpty ? 0 : (completed / _deliveries.length * 100).round();

    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            CustomAppBar(
              title: 'Employer Portal',
              subtitle: 'Business Overview',
              onRefresh: _fetchDeliveries,
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
                                    title: 'Total Deliveries',
                                    value: _deliveries.length.toString(),
                                    icon: Icons.local_shipping_outlined,
                                    gradientColors: const [AppTheme.primary, AppTheme.secondary],
                                  ),
                                  StatCard(
                                    title: 'Pending',
                                    value: pending.toString(),
                                    icon: Icons.pending_actions_outlined,
                                    gradientColors: const [AppTheme.statusPending, Color(0xFFFF5E62)],
                                  ),
                                  StatCard(
                                    title: 'Completed',
                                    value: completed.toString(),
                                    icon: Icons.check_circle_outline,
                                    gradientColors: const [AppTheme.statusDelivered, Color(0xFF96C93D)],
                                  ),
                                  StatCard(
                                    title: 'Drivers Used',
                                    value: driversUsed.toString(),
                                    icon: Icons.people_outline,
                                    gradientColors: const [Color(0xFF5B86E5), Color(0xFF36D1DC)],
                                  ),
                                  StatCard(
                                    title: 'Spent this month',
                                    value: '${spentThisMonth.toStringAsFixed(0)} DT',
                                    icon: Icons.attach_money,
                                    gradientColors: const [Color(0xFF4481EB), Color(0xFF04BEFE)],
                                  ),
                                  StatCard(
                                    title: 'Efficiency',
                                    value: '$efficiency%',
                                    icon: Icons.timeline,
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
            onPressed: _fetchDeliveries,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
