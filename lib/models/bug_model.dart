enum BugSeverity { blocker, critical, major, minor }
enum BugStatus { open, inProgress, resolved, closed, rejected }

class BugModel {
  final String id;
  final String ticketId; // BUG-402
  final String title;
  final String description;
  final String testCaseCode;
  final BugSeverity severity;
  final BugStatus status;
  final String assignedTo;
  final String reportedBy;
  final DateTime createdAt;

  const BugModel({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.description,
    required this.testCaseCode,
    required this.severity,
    required this.status,
    required this.assignedTo,
    required this.reportedBy,
    required this.createdAt,
  });

  factory BugModel.fromJson(Map<String, dynamic> json) {
    BugSeverity parseSeverity(String? s) {
      switch (s?.toLowerCase()) {
        case 'blocker': return BugSeverity.blocker;
        case 'critical': return BugSeverity.critical;
        case 'major': return BugSeverity.major;
        default: return BugSeverity.minor;
      }
    }

    BugStatus parseStatus(String? s) {
      switch (s?.toLowerCase()) {
        case 'in_progress':
        case 'inprogress': return BugStatus.inProgress;
        case 'resolved': return BugStatus.resolved;
        case 'closed': return BugStatus.closed;
        case 'rejected': return BugStatus.rejected;
        default: return BugStatus.open;
      }
    }

    return BugModel(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id'] ?? json['ticketId'] ?? 'BUG-${json['id']?.toString().substring(0, 3) ?? '101'}',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      testCaseCode: json['test_case_code'] ?? json['testCaseCode'] ?? 'TC-101',
      severity: parseSeverity(json['severity']?.toString()),
      status: parseStatus(json['status']?.toString()),
      assignedTo: json['assigned_to'] ?? json['assignedTo'] ?? 'Unassigned',
      reportedBy: json['reported_by'] ?? json['reportedBy'] ?? 'QA Tester',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'title': title,
      'description': description,
      'test_case_code': testCaseCode,
      'severity': severity.name,
      'status': status.name,
      'assigned_to': assignedTo,
      'reported_by': reportedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BugModel copyWith({
    String? id,
    String? ticketId,
    String? title,
    String? description,
    String? testCaseCode,
    BugSeverity? severity,
    BugStatus? status,
    String? assignedTo,
    String? reportedBy,
    DateTime? createdAt,
  }) {
    return BugModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      title: title ?? this.title,
      description: description ?? this.description,
      testCaseCode: testCaseCode ?? this.testCaseCode,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      reportedBy: reportedBy ?? this.reportedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
