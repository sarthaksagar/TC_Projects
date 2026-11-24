import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/bug_model.dart';

void main() {
  group('BugModel', () {
    // ─── fromJson ───────────────────────────────────────────────────────────

    group('fromJson', () {
      test('parses a fully populated JSON map', () {
        final json = {
          'id': 'bug-001',
          'ticket_id': 'BUG-402',
          'title': 'Login button unresponsive',
          'description': 'Button does not respond on first tap',
          'test_case_code': 'TC-005',
          'severity': 'critical',
          'status': 'open',
          'assigned_to': 'Dev Team',
          'reported_by': 'Alice',
          'created_at': '2024-02-10T08:30:00.000Z',
        };

        final model = BugModel.fromJson(json);

        expect(model.id, 'bug-001');
        expect(model.ticketId, 'BUG-402');
        expect(model.title, 'Login button unresponsive');
        expect(model.severity, BugSeverity.critical);
        expect(model.status, BugStatus.open);
        expect(model.assignedTo, 'Dev Team');
        expect(model.reportedBy, 'Alice');
      });

      test('handles missing optional fields with defaults', () {
        final json = {
          'id': 'bug-002',
          'title': 'Crash on startup',
          'description': '',
        };

        final model = BugModel.fromJson(json);

        expect(model.id, 'bug-002');
        expect(model.assignedTo, 'Unassigned');
        expect(model.reportedBy, 'QA Tester');
        expect(model.severity, BugSeverity.minor);
        expect(model.status, BugStatus.open);
        expect(model.testCaseCode.startsWith('TC-'), true);
      });

      test('parses all BugSeverity values', () {
        final severities = {
          'blocker': BugSeverity.blocker,
          'critical': BugSeverity.critical,
          'major': BugSeverity.major,
          'minor': BugSeverity.minor,
          'unknown': BugSeverity.minor,
          null: BugSeverity.minor,
        };

        for (final entry in severities.entries) {
          final json = {'id': 'x', 'title': 'T', 'description': '', 'severity': entry.key};
          final model = BugModel.fromJson(json);
          expect(model.severity, entry.value);
        }
      });

      test('parses all BugStatus values', () {
        final statuses = {
          'open': BugStatus.open,
          'in_progress': BugStatus.inProgress,
          'inprogress': BugStatus.inProgress,
          'resolved': BugStatus.resolved,
          'closed': BugStatus.closed,
          'rejected': BugStatus.rejected,
          'other': BugStatus.open,
          null: BugStatus.open,
        };

        for (final entry in statuses.entries) {
          final json = {'id': 'x', 'title': 'T', 'description': '', 'status': entry.key};
          final model = BugModel.fromJson(json);
          expect(model.status, entry.value);
        }
      });

      test('falls back to default date when created_at is null', () {
        final before = DateTime.now().subtract(const Duration(seconds: 1));
        final json = {'id': 'x', 'title': 'T', 'description': ''};
        final model = BugModel.fromJson(json);
        expect(model.createdAt.isAfter(before), true);
      });
    });

    // ─── toJson ─────────────────────────────────────────────────────────────

    group('toJson', () {
      test('serializes all fields correctly', () {
        final date = DateTime(2024, 3, 1, 12, 0);
        final model = BugModel(
          id: 'bug-01',
          ticketId: 'BUG-100',
          title: 'Null pointer',
          description: 'NPE on login',
          testCaseCode: 'TC-010',
          severity: BugSeverity.blocker,
          status: BugStatus.open,
          assignedTo: 'Backend',
          reportedBy: 'QA',
          createdAt: date,
        );

        final json = model.toJson();

        expect(json['id'], 'bug-01');
        expect(json['ticket_id'], 'BUG-100');
        expect(json['severity'], 'blocker');
        expect(json['status'], 'open');
        expect(json['created_at'], date.toIso8601String());
      });

      test('round-trips through toJson → fromJson', () {
        final original = BugModel(
          id: 'trip-001',
          ticketId: 'BUG-999',
          title: 'Round trip',
          description: 'Testing round-trip',
          testCaseCode: 'TC-001',
          severity: BugSeverity.major,
          status: BugStatus.resolved,
          assignedTo: 'Jane',
          reportedBy: 'Joe',
          createdAt: DateTime(2024, 7, 4),
        );

        final json = original.toJson();
        final restored = BugModel.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.ticketId, original.ticketId);
        expect(restored.severity, original.severity);
        expect(restored.status, original.status);
      });
    });

    // ─── copyWith ───────────────────────────────────────────────────────────

    group('copyWith', () {
      final base = BugModel(
        id: 'base',
        ticketId: 'BUG-001',
        title: 'Base bug',
        description: '',
        testCaseCode: 'TC-001',
        severity: BugSeverity.minor,
        status: BugStatus.open,
        assignedTo: 'A',
        reportedBy: 'B',
        createdAt: DateTime(2024),
      );

      test('returns updated status copy', () {
        final updated = base.copyWith(status: BugStatus.resolved);
        expect(updated.status, BugStatus.resolved);
        expect(updated.id, base.id);
      });

      test('original is immutable after copyWith', () {
        base.copyWith(status: BugStatus.closed);
        expect(base.status, BugStatus.open);
      });
    });

    // ─── Enum coverage ───────────────────────────────────────────────────────

    test('BugSeverity has 4 values', () {
      expect(BugSeverity.values.length, 4);
    });

    test('BugStatus has 5 values', () {
      expect(BugStatus.values.length, 5);
    });
  });
}
