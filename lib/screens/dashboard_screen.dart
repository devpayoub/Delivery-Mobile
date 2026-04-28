import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/delivery.dart';
import '../app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  List<Delivery> _deliveries = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1000), vsync: this);
    _fetchDeliveries();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(Delivery delivery) async {
    String selectedStatus = delivery.status;
    // Map backend statuses to valid UI options
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
                          enabledBorder: OutlineInputBorder(
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
                    backgroundColor: const Color(0xFF4A00E0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Save', style: AppTheme.subtitle.copyWith(color: Colors.white)),
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
      _fetchDeliveries(); // Refresh list to get animation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery updated', style: AppTheme.body1.copyWith(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status', style: AppTheme.body1.copyWith(color: Colors.white)),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        body: Column(
          children: <Widget>[
            _getAppBarUI(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A00E0)))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _deliveries.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(top: 16, bottom: 80),
                              itemCount: _deliveries.length,
                              itemBuilder: (BuildContext context, int index) {
                                final int count = _deliveries.length > 10 ? 10 : _deliveries.length;
                                final Animation<double> animation =
                                    Tween<double>(begin: 0.0, end: 1.0).animate(
                                        CurvedAnimation(
                                            parent: _animationController,
                                            curve: Interval(
                                                (1 / count) * index, 1.0,
                                                curve: Curves.fastOutSlowIn)));
                                _animationController.forward();
                                return _buildDeliveryCard(_deliveries[index], animation);
                              },
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
          _buildSummaryItem('Total Amount', '\$${totalAmount.toStringAsFixed(2)}', const Color(0xFF4A00E0)),
          _buildSummaryItem('Rest to Get', '\$${restToGet.toStringAsFixed(2)}', Colors.orange),
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
          Icon(Icons.inbox_outlined, size: 80, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No Deliveries Found',
            style: AppTheme.title.copyWith(color: AppTheme.darkText.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no pending deliveries in your city.',
            style: AppTheme.body1.copyWith(color: AppTheme.lightText),
          ),
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
          Text(
            'Oops!',
            style: AppTheme.title.copyWith(color: AppTheme.darkText),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Something went wrong.',
            style: AppTheme.body1.copyWith(color: AppTheme.lightText),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchDeliveries,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A00E0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _getAppBarUI() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32.0),
          bottomRight: Radius.circular(32.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 16.0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            left: 24,
            right: 24,
            bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Deliveries',
                  style: AppTheme.display1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Today\'s Routes',
                  style: AppTheme.subtitle.copyWith(color: AppTheme.lightText),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.nearlyWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4A00E0)),
                onPressed: _fetchDeliveries,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Delivery delivery, Animation<double> animation) {
    final isCompleted = delivery.status == 'Delivered';

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? child) {
        return FadeTransition(
          opacity: animation,
          child: Transform(
            transform: Matrix4.translationValues(
                0.0, 50 * (1.0 - animation.value), 0.0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    offset: const Offset(0, 8),
                    blurRadius: 24.0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.0),
                  onTap: () => _updateStatus(delivery),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                delivery.clientName,
                                style: AppTheme.title.copyWith(fontSize: 20),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? Colors.green.withOpacity(0.15)
                                    : const Color(0xFF4A00E0).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                delivery.status.toUpperCase(),
                                style: AppTheme.subtitle.copyWith(
                                  color: isCompleted ? Colors.green.shade700 : const Color(0xFF4A00E0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.phone_android, delivery.phone),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_city, delivery.cityName),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.category_outlined, delivery.productTypeName),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Payment',
                                  style: AppTheme.caption.copyWith(color: AppTheme.lightText),
                                ),
                                Text(
                                  '\$${delivery.totalPrice.toStringAsFixed(2)}',
                                  style: AppTheme.title.copyWith(
                                    color: const Color(0xFF4A00E0),
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.lightText.withOpacity(0.5)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.nearlyWhite,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppTheme.lightText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.body1.copyWith(color: AppTheme.darkText.withOpacity(0.8)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
