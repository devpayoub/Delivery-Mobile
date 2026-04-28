import 'package:flutter/material.dart';
import '../models/delivery.dart';
import '../app_theme.dart';

class DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  final VoidCallback? onTap;
  final bool showUpdateButton;
  final VoidCallback? onUpdatePressed;
  final bool showEmployerActions;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onEditPressed;

  const DeliveryCard({
    Key? key,
    required this.delivery,
    this.onTap,
    this.showUpdateButton = false,
    this.onUpdatePressed,
    this.showEmployerActions = false,
    this.onDeletePressed,
    this.onEditPressed,
  }) : super(key: key);

  void _showCancelReason(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Cancellation Reason'),
        content: SingleChildScrollView(
          child: Text(
            delivery.reason ?? 'No reason provided',
            style: AppTheme.body1,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(delivery.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: delivery.status == 'Cancelled' 
              ? () => _showCancelReason(context) 
              : onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        delivery.status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    if (showEmployerActions)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary), 
                            onPressed: onEditPressed,
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.statusCancelled), 
                            onPressed: onDeletePressed,
                            tooltip: 'Delete',
                          ),
                        ],
                      )
                    else
                      Text(
                        "${delivery.totalPrice} DT",
                        style: AppTheme.title.copyWith(color: AppTheme.primary, fontSize: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(delivery.clientName, style: AppTheme.title.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.lightText),
                    const SizedBox(width: 4),
                    Expanded(child: Text(delivery.address ?? 'No address', style: AppTheme.subtitle.copyWith(fontSize: 14))),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Text(delivery.phone, style: AppTheme.body1),
                    const Spacer(),
                    if (showUpdateButton)
                      ElevatedButton(
                        onPressed: onUpdatePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('Update Status', style: TextStyle(color: Colors.white, fontSize: 12)),
                      )
                    else if (!showEmployerActions)
                      const Icon(Icons.chevron_right, color: AppTheme.grey),
                    if (showEmployerActions)
                      Text(
                        "${delivery.totalPrice} DT",
                        style: AppTheme.title.copyWith(color: AppTheme.primary, fontSize: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending': return AppTheme.statusPending;
      case 'Picked Up': return AppTheme.accent;
      case 'In Transit': return AppTheme.statusTransit;
      case 'Delivered': return AppTheme.statusDelivered;
      case 'Cancelled': return AppTheme.statusCancelled;
      default: return AppTheme.grey;
    }
  }
}
