import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/bug_model.dart';
import 'package:vg_qatc/providers/bug_provider.dart';
import 'package:vg_qatc/repositories/bug_repository.dart';

class FakeBugRepository extends BugRepository {
  List<BugModel> store = [];

  @override
  Future<List<BugModel>> getBugs() async => List.from(store);

  @override
  Future<BugModel> addBug(BugModel bug) async {
    store.insert(0, bug);
    return bug;
  }

  @override
  Future<BugModel> updateBugStatus(String bugId, BugStatus status) async {
    final idx = store.indexWhere((b) => b.id == bugId);
    if (idx != -1) {
      final updated = store[idx].copyWith(status: status);
      store[idx] = updated;
      return updated;
    }
    throw 'Bug not found';
  }
}

void main() {
  group('BugProvider', () {
    late FakeBugRepository fakeRepo;
    late BugProvider provider;

    final bug1 = BugModel(
      id: 'b-1',
      ticketId: 'BUG-101',
      title: 'Crash on Logout',
      description: 'App freezes',
      testCaseCode: 'TC-101',
      severity: BugSeverity.critical,
      status: BugStatus.open,
      assignedTo: 'Lead Dev',
      reportedBy: 'QA Tester',
      createdAt: DateTime(2024, 1, 1),
    );

    setUp(() {
      fakeRepo = FakeBugRepository();
      fakeRepo.store = [bug1];
      provider = BugProvider(repository: fakeRepo);
    });

    test('loads bugs on initialization', () async {
      await provider.loadBugs();
      expect(provider.bugs.length, 1);
      expect(provider.bugs.first.ticketId, 'BUG-101');
      expect(provider.isLoading, false);
    });

    test('addBug inserts new bug at top', () async {
      await provider.loadBugs();

      final newBug = BugModel(
        id: 'b-2',
        ticketId: 'BUG-102',
        title: 'UI alignment issue',
        description: '',
        testCaseCode: 'TC-102',
        severity: BugSeverity.minor,
        status: BugStatus.open,
        assignedTo: 'Frontend',
        reportedBy: 'Tester',
        createdAt: DateTime.now(),
      );

      await provider.addBug(newBug);

      expect(provider.bugs.length, 2);
      expect(provider.bugs.first.ticketId, 'BUG-102');
    });

    test('updateBugStatus updates bug status in place', () async {
      await provider.loadBugs();

      await provider.updateBugStatus('b-1', BugStatus.resolved);

      final found = provider.bugs.firstWhere((b) => b.id == 'b-1');
      expect(found.status, BugStatus.resolved);
    });
  });
}

