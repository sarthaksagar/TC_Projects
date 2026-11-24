import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/forgot_password_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/test_cases/list_page.dart';
import 'pages/test_cases/edit_page.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(name: 'login', path: '/login', builder: (c, s) => const LoginPage()),
    GoRoute(name: 'register', path: '/register', builder: (c, s) => const RegisterPage()),
    GoRoute(name: 'forgot_password', path: '/forgot', builder: (c, s) => const ForgotPasswordPage()),
    GoRoute(name: 'dashboard', path: '/dashboard', builder: (c, s) => const DashboardPage()),
    GoRoute(name: 'test_cases', path: '/test-cases', builder: (c, s) => const TestCaseListPage()),
    GoRoute(name: 'test_case_create', path: '/test-cases/create', builder: (c, s) => TestCaseEditPage()),
    GoRoute(name: 'test_case_edit', path: '/test-cases/:id', builder: (c, s) => TestCaseEditPage(id: s.pathParameters['id'])),
    // Additional routes (test_plans, bugs, users, settings) can be added similarly
  ],
);
