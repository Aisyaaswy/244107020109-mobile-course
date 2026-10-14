import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';

class AnnouncementPage extends StatelessWidget {
  final String id;

  const AnnouncementPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pengumuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go(AppRoutes.home);
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Menampilkan Pengumuman ID: $id',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}