import 'package:flutter/material.dart';
import 'package:patient_management_app/data/models/user_model.dart';

class UserListTile extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.photoUrl ?? ''),
        child: user.photoUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.name ?? ''),
      subtitle: Text(user.email),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}