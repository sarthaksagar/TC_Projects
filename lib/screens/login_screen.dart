import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/toast_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSignUpMode = false;
  String _selectedRole = 'QA Lead';

  void _quickFillCredentials(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  @override
  void initState() {
    super.initState();
    StorageService().read('remember_email').then((emailVal) {
      if (emailVal != null && emailVal is String && emailVal.isNotEmpty) {
        _emailController.text = emailVal;
        setState(() {
          _rememberMe = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final emailRegex =
        RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter your password';
    if (_isSignUpMode && password.length < 8)
      return 'Password must be at least 8 characters';
    if (!_isSignUpMode && password.length < 6)
      return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_rememberMe) {
      await StorageService()
          .save('remember_email', _emailController.text.trim());
    } else {
      await StorageService().remove('remember_email');
    }

    if (_isSignUpMode) {
      final success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      );
      if (mounted) {
        if (success) {
          ToastUtils.showSuccess(context,
              'Account created as $_selectedRole! Please sign in to continue.');
          setState(() {
            _isSignUpMode = false;
            _fullNameController.clear();
            _passwordController.clear();
          });
          if (mounted) {
            context.go('/login');
          }
        } else {
          ToastUtils.showError(
            context,
            authProvider.errorMessage ?? 'Sign up failed. Try again.',
          );
        }
      }
    } else {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ToastUtils.showSuccess(
              context, 'Successfully authenticated. Welcome back!');
          context.go('/dashboard');
        } else {
          ToastUtils.showError(
            context,
            authProvider.errorMessage ??
                'Authentication failed. Check credentials.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & App Name
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isSignUpMode
                        ? 'Create a new QA Account'
                        : 'Select Role or enter credentials to sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Role Selector Pill
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _quickFillCredentials('QA Lead'),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'QA Lead'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 16,
                                    color: _selectedRole == 'QA Lead'
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'QA Lead',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: _selectedRole == 'QA Lead'
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: _selectedRole == 'QA Lead'
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _quickFillCredentials('QA Team Member'),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'QA Team Member'
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.groups_rounded,
                                    size: 16,
                                    color: _selectedRole == 'QA Team Member'
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'QA Team Member',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          _selectedRole == 'QA Team Member'
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      color: _selectedRole == 'QA Team Member'
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_isSignUpMode) ...[
                    Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      validator: (val) {
                        final name = val?.trim() ?? '';
                        if (_isSignUpMode && name.isEmpty) {
                          return 'Please enter your full name';
                        }
                        if (_isSignUpMode && name.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.person_outline_rounded, size: 20),
                        hintText: 'e.g. John Smith',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  Text(
                    'Email Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _emailValidator,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                      hintText: 'user@vg-qatc.com',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleAuth(),
                    validator: _passwordValidator,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 20),
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Remember Me + Forgot Password
                  if (!_isSignUpMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) {
                                    final isChecked = v ?? false;
                                    setState(() => _rememberMe = isChecked);
                                    if (!isChecked) {
                                      StorageService().remove('remember_email');
                                    }
                                  },
                                ),
                                const SizedBox(width: 4),
                                const Text('Remember Me'),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/forgot'),
                          child: const Text('Forgot Password?'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isSignUpMode ? 'Create Account' : 'Login',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Login / Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignUpMode
                            ? 'Already have an account?'
                            : "Don't have an account?",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUpMode = !_isSignUpMode;
                          });
                        },
                        child: Text(
                          _isSignUpMode ? 'Sign In' : 'Create Account',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Theme Toggle Quick Link
                  Center(
                    child: TextButton.icon(
                      onPressed: () => themeProvider.toggleTheme(),
                      icon: Icon(
                        isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
