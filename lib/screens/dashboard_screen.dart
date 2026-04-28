import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/delivery_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
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

  Future<void> _updateStatus(Delivery delivery) async {
    String selectedStatus = delivery.status;
    final validStatuses = ['Pending', 'Delivered', 'Cancelled'];
    if (!validStatuses.contains(selectedStatus)) {
      selectedStatus = 'Pending';
    }

    String reasonText = delivery.reason ?? '';
    final reasonController = TextEditingController(text: reasonText);
    String? localError;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Update Delivery Status', style: AppTheme.title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (localError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(localError!, style: AppTheme.body1.copyWith(color: Colors.red)),
                      ),
                    Text('Status', style: AppTheme.caption.copyWith(color: AppTheme.lightText)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.nearlyWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedStatus,
                          items: validStatuses.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: AppTheme.body1),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setStateModal(() {
                              selectedStatus = newValue!;
                              if (selectedStatus != 'Cancelled') {
                                localError = null;
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    if (selectedStatus == 'Cancelled') ...[
                      const SizedBox(height: 16),
                      Text('Reason for Failure', style: AppTheme.caption.copyWith(color: AppTheme.lightText)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Explain why it was cancelled...',
                          hintStyle: AppTheme.body1.copyWith(color: AppTheme.lightText.withOpacity(0.5)),
                          filled: true,
                          fillColor: AppTheme.nearlyWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                          ),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: AppTheme.subtitle.copyWith(color: AppTheme.lightText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedStatus == 'Cancelled' && reasonController.text.trim().isEmpty) {
                      setStateModal(() => localError = 'Reason is REQUIRED when status is "Cancelled"');
                      return;
                    }
                    reasonText = reasonController.text.trim();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirm != true) return;

    final success = await apiService.updateDeliveryStatus(
      delivery.id, 
      selectedStatus, 
      reason: selectedStatus == 'Cancelled' ? reasonText : null
    );
    
    if (success) {
      _fetchDeliveries();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery updated successfully'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _deliveries.where((d) => d.status == 'Pending').length;
    final completed = _deliveries.where((d) => d.status == 'Delivered').length;
    final failed = _deliveries.where((d) => d.status == 'Cancelled').length;
    final earnings = completed * 20.0;
    final successRate = _deliveries.isEmpty ? 0 : (completed / _deliveries.length * 100).round();

    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            CustomAppBar(
              title: 'Driver Portal',
              subtitle: 'Today\'s Routes',
              onRefresh: _fetchDeliveries,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.4,
                                  children: [
                                    StatCard(
                                      title: 'Assigned',
                                      value: _deliveries.length.toString(),
                                      icon: Icons.assignment_outlined,
                                      gradientColors: const [AppTheme.primary, AppTheme.secondary],
                                    ),
                                    StatCard(
                                      title: 'Earnings',
                                      value: '${earnings.toStringAsFixed(0)} DT',
                                      icon: Icons.payments_outlined,
                                      gradientColors: const [Color(0xFF4481EB), Color(0xFF04BEFE)],
                                    ),
                                    StatCard(
                                      title: 'Pending',
                                      value: pending.toString(),
                                      icon: Icons.pending_actions_outlined,
                                      gradientColors: const [AppTheme.statusPending, Color(0xFFFF5E62)],
                                    ),
                                    StatCard(
                                      title: 'Success',
                                      value: '$successRate%',
                                      icon: Icons.timeline,
                                      gradientColors: const [AppTheme.statusDelivered, Color(0xFF96C93D)],
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text("Active Shipments", style: AppTheme.title.copyWith(fontSize: 20)),
                              ),
                              const SizedBox(height: 16),
                              _deliveries.isEmpty
                                  ? _buildEmptyState()
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                                      itemCount: _deliveries.length,
                                      itemBuilder: (context, index) {
                                        final delivery = _deliveries[index];
                                        return DeliveryCard(
                                          delivery: delivery,
                                          onTap: () => _updateStatus(delivery),
                                        );
                                      },
                                    ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomSummaryBar(),
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    if (_deliveries.isEmpty || _isLoading) return const SizedBox.shrink();

    double totalAmount = 0;
    double restToGet = 0;

    for (var d in _deliveries) {
      totalAmount += d.totalPrice;
      if (d.status != 'Delivered') {
        restToGet += d.totalPrice;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(0, -4),
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem('Total Amount', '${totalAmount.toStringAsFixed(2)} DT', AppTheme.primary),
          _buildSummaryItem('Rest to Get', '${restToGet.toStringAsFixed(2)} DT', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.caption.copyWith(color: AppTheme.lightText)),
        Text(
          value,
          style: AppTheme.title.copyWith(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.inbox_outlined, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
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
          Icon(Icons.error_outline, size: 80, color: Colors.red.withOpacity(0.5)),
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
