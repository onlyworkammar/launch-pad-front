import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';

class TopNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final String? searchQuery;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onMenuPressed;
  final String? userName;

  const TopNavigationBar({
    super.key,
    this.searchQuery,
    this.onSearchChanged,
    this.onMenuPressed,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed ?? () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: const Text('ALORA'),
      actions: [
        // Search bar
        if (onSearchChanged != null)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
        // User menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.person),
          onSelected: (value) async {
            if (value == 'logout') {
              final apiService = ApiService();
              await apiService.removeToken();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          itemBuilder: (context) => [
            if (userName != null)
              PopupMenuItem(
                value: 'profile',
                child: Text('Profile: $userName'),
              ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


