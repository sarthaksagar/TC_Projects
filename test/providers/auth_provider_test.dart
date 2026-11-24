import 'package:flutter_test/flutter_test.dart';
import 'package:vg_qatc/models/user_model.dart';
import 'package:vg_qatc/providers/auth_provider.dart';
import 'package:vg_qatc/repositories/auth_repository.dart';

// Fake repository for testing without hitting Supabase network
class FakeAuthRepository extends AuthRepository {
  bool shouldFailLogin = false;
  bool shouldThrowRateLimit = false;
  bool shouldThrowUnconfirmedEmail = false;
  UserModel? mockUser;

  @override
  bool get isAuthenticated => mockUser != null;

  @override
  UserModel? get currentUser => mockUser;

  @override
  Future<UserModel> login(String email, String password) async {
    if (shouldFailLogin) {
      throw 'Invalid login credentials';
    }
    if (shouldThrowUnconfirmedEmail) {
      throw 'Email not confirmed';
    }
    mockUser = UserModel(
      id: 'mock-user-id',
      name: 'Test Tester',
      email: email,
      role: 'QA Lead',
      avatarUrl: 'https://avatar.test',
      isActive: true,
      createdAt: DateTime.now(),
    );
    return mockUser!;
  }

  @override
  Future<void> signUp(String email, String password, {String? fullName, String? role}) async {
    if (shouldThrowRateLimit) {
      throw 'over_email_send_rate_limit';
    }
    mockUser = UserModel(
      id: 'mock-new-id',
      name: fullName ?? 'New User',
      email: email,
      role: role ?? 'QA Team Member',
      avatarUrl: 'https://avatar.test',
      isActive: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {
    mockUser = null;
  }
}

void main() {
  group('AuthProvider', () {
    late FakeAuthRepository fakeRepo;
    late AuthProvider authProvider;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      authProvider = AuthProvider(authRepository: fakeRepo);
    });

    test('initial state is unauthenticated and not loading', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, null);
      expect(authProvider.currentUser, null);
    });

    group('login flow', () {
      test('login success authenticates user and clears error', () async {
        final result = await authProvider.login('qa.lead@company.com', 'Password123!');

        expect(result, true);
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.currentUser != null, true);
        expect(authProvider.currentUser!.email, 'qa.lead@company.com');
        expect(authProvider.errorMessage, null);
        expect(authProvider.isLoading, false);
      });

      test('login failure with invalid credentials sets user-friendly error message', () async {
        fakeRepo.shouldFailLogin = true;

        final result = await authProvider.login('wrong@company.com', 'bad_pass');

        expect(result, false);
        expect(authProvider.isAuthenticated, false);
        expect(authProvider.errorMessage != null, true);
        expect(authProvider.errorMessage!.contains('Invalid email or password'), true);
        expect(authProvider.isLoading, false);
      });

      test('login failure with unconfirmed email prompts user to verify inbox', () async {
        fakeRepo.shouldThrowUnconfirmedEmail = true;

        final result = await authProvider.login('unconfirmed@company.com', 'Password123!');

        expect(result, false);
        expect(authProvider.errorMessage!.contains('Email address not confirmed yet'), true);
      });
    });

    group('signUp flow', () {
      test('signUp success sets user and authenticates', () async {
        final result = await authProvider.signUp(
          'new.tester@company.com',
          'SecurePass2024!',
          fullName: 'Jane Tester',
          role: 'QA Team Member',
        );

        expect(result, true);
        expect(authProvider.isAuthenticated, true);
        expect(authProvider.errorMessage, null);
      });

      test('signUp failure on rate limit sets helpful message', () async {
        fakeRepo.shouldThrowRateLimit = true;

        final result = await authProvider.signUp(
          'rate.limited@company.com',
          'SecurePass2024!',
        );

        expect(result, false);
        expect(authProvider.errorMessage!.contains('rate limit exceeded'), true);
      });
    });

    group('logout flow', () {
      test('logout clears authenticated session', () async {
        await authProvider.login('qa@company.com', 'Pass123!');
        expect(authProvider.isAuthenticated, true);

        await authProvider.logout();

        expect(authProvider.isAuthenticated, false);
        expect(authProvider.currentUser, null);
        expect(authProvider.isLoading, false);
      });
    });
  });
}

