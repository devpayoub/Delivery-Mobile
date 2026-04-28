import 'package:flutter/material.dart';
import '../app_theme.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  title,
                  style: AppTheme.display1.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
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
                icon: const Icon(Icons.refresh, color: AppTheme.primary),
                onPressed: onRefresh,
              ),
            )
          ],
        ),
      ),
    );
  }
}
