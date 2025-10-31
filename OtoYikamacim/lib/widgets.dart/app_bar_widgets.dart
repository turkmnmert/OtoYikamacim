import 'package:flutter/material.dart';

PreferredSizeWidget buildCustomAppBar({
  required String title,
  IconData? actionIcon,
  VoidCallback? onActionTap,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.5,
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    actions: [
      IconButton(
        icon: Icon(
          actionIcon,
          color: const Color(0xFF7E57C2),
        ),
        onPressed: onActionTap,
      ),
      const SizedBox(width: 12),
    ],
  );
}