import 'package:flutter/material.dart';
import 'package:patient_management_app/ui/theme/app_theme.dart';
import 'package:patient_management_app/services/auth_service.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double elevation;
  final Color? backgroundColor;
  final bool showDrawer;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.elevation = 4.0,
    this.backgroundColor,
    this.showDrawer = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      elevation: elevation,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      )
          : showDrawer
          ? Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      )
          : null,
      actions: actions ?? [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications coming soon')),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile coming soon')),
              );
            },
            child: CircleAvatar(
              backgroundColor: AppTheme.accentColor,
              radius: 16,
              child: _buildAvatarContent(currentUser),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(User? currentUser) {
    if (currentUser == null) {
      return const Text('U', style: TextStyle(color: Colors.white));
    }

    if (currentUser.photoUrl != null && currentUser.photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          currentUser.photoUrl!,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitials(currentUser);
          },
        ),
      );
    }

    return _buildInitials(currentUser);
  }

  Widget _buildInitials(User user) {
    final name = user.name?.trim() ?? '';
    final initials = name.isNotEmpty
        ? name[0].toUpperCase()
        : (user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U');

    return Text(
      initials,
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}