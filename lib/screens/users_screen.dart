import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/toast_utils.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User & Role Management',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage team access privileges, roles, and active accounts',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showInviteUserDialog(context),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Invite Team Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.users.length,
                    itemBuilder: (context, index) {
                      final user = provider.users[index];
                      return _buildUserTile(context, user, provider, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, UserModel user, UserProvider provider, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(user.avatarUrl),
          onBackgroundImageError: (_, __) {},
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Text(
              user.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                user.role,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            user.email,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        trailing: Switch.adaptive(
          value: user.isActive,
          activeTrackColor: AppColors.passed,
          onChanged: (val) async {
            await provider.toggleUserStatus(user.id);
            if (context.mounted) {
              ToastUtils.showInfo(
                context,
                '${user.name} account ${val ? "activated" : "deactivated"}',
              );
            }
          },
        ),
      ),
    );
  }

  void _showInviteUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final roleController = TextEditingController(text: 'QA Engineer');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite New Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role Designation'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) return;
                final newUser = UserModel(
                  id: 'u-${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  role: roleController.text.trim(),
                  avatarUrl: 'https://i.pravatar.cc/150?u=${DateTime.now().millisecondsSinceEpoch}',
                  isActive: true,
                  createdAt: DateTime.now(),
                );
                await Provider.of<UserProvider>(context, listen: false).addUser(newUser);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ToastUtils.showSuccess(context, 'Invitation email sent!');
                }
              },
              child: const Text('Send Invitation'),
            ),
          ],
        );
      },
    );
  }
}
