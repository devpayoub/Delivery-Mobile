class LogEntry {
  final String id;
  final String role;
  final String action;
  final String details;
  final DateTime timestamp;

  LogEntry({
    required this.id,
    required this.role,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'] ?? '',
      role: json['role'] ?? '',
      action: json['action'] ?? '',
      details: json['details'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    );
  }
}