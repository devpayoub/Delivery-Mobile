import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/delivery_card.dart';
import '../widgets/delivery_form.dart';

class DeliveriesScreen extends StatefulWidget {
  final bool isDriver;
  const DeliveriesScreen({Key? key, this.isDriver = false}) : super(key: key);

  @override
  _DeliveriesScreenState createState() => _DeliveriesScreenState();
}

class _DeliveriesScreenState extends State<DeliveriesScreen> {
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
      final deliveries = await apiService.getDeliveries();
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

  void _showAddEditForm({Delivery? delivery}) async {
    final Map<String, dynamic>? initialData = delivery != null ? {
      'client_name': delivery.clientName,
      'phone': delivery.phone,
      'address': delivery.address,
      'total_price': delivery.totalPrice,
      'city_id': delivery.cityId,
      'product_type_id': delivery.productTypeId,
    } : null;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryForm(
        initialData: initialData,
        deliveryId: delivery?.id,
      ),
    );

    if (result == true) {
      _fetchDeliveries();
    }
  }

  void _confirmDelete(Delivery delivery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Delivery?'),
        content: Text('Are you sure you want to delete the delivery for ${delivery.clientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final success = await apiService.deleteDelivery(delivery.id);
              Navigator.pop(context);
              if (success) {
                _fetchDeliveries();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delivery deleted')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
              title: widget.isDriver ? 'My Deliveries' : 'Deliveries',
              subtitle: 'Manage active shipments',
              onRefresh: _fetchDeliveries,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _deliveries.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 80),
                              itemCount: _deliveries.length,
                              itemBuilder: (context, index) {
                                final delivery = _deliveries[index];
                                return DeliveryCard(
                                  delivery: delivery,
                                  showEmployerActions: !widget.isDriver,
                                  onEditPressed: () => _showAddEditForm(delivery: delivery),
                                  onDeletePressed: () => _confirmDelete(delivery),
                                  onTap: () {
                                    if (widget.isDriver) {
                                      // Driver tap logic
                                    }
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
        floatingActionButton: !widget.isDriver ? FloatingActionButton(
          onPressed: () => _showAddEditForm(),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ) : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No shipments found', style: AppTheme.subtitle),
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
          Text(_errorMessage ?? 'Failed to load deliveries', style: AppTheme.body1),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDeliveries,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
