import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/log_entry.dart';
import '../app_theme.dart';
import '../widgets/custom_app_bar.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final logs = await apiService.getLogs();
      setState(() {
        _logs = logs;
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
    return Container(
      color: AppTheme.nearlyWhite,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            CustomAppBar(
              title: 'Logs',
              subtitle: 'System activity logs',
              onRefresh: _fetchLogs,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _logs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                return _buildLogTile(log);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(LogEntry log) {
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
          child: Icon(
            _getActionIcon(log.action),
            color: AppTheme.primary,
            size: 20,
          ),
        ),
        title: Text(log.action, style: AppTheme.title.copyWith(fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.details, style: AppTheme.subtitle.copyWith(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(log.timestamp),
              style: AppTheme.caption.copyWith(color: AppTheme.lightText),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(log.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            log.role.toUpperCase(),
            style: TextStyle(
              color: _getRoleColor(log.role),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActionIcon(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit_outlined;
      case 'delete':
        return Icons.delete_outline;
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      default:
        return Icons.history;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return Colors.purple;
      case 'employer':
        return Colors.blue;
      case 'driver':
        return Colors.green;
      default:
        return AppTheme.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: AppTheme.lightText.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No logs found', style: AppTheme.subtitle),
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
            onPressed: _fetchLogs,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}