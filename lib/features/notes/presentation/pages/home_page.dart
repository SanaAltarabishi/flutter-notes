import 'package:flutter/material.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import '../books/books_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.edit_note,
              size: 80,
              color: AppColors.seedColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'FreeNotes',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Handwriting note-taking app'),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () =>{},
                  //  Navigator.push(
                  //   context,
                  //   MaterialPageRoute(builder: (_) => const CanvasPage(pageId: ,)),
                  // ),
                  icon: const Icon(Icons.edit),
                  label: const Text('Quick Note'),
                ),
                const SizedBox(width: 30),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BooksPage()),
                  ),
                  icon: const Icon(Icons.book),
                  label: const Text('My Books'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
