import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freenotes_app/core/constants/app_colors.dart';
import 'features/notes/presentation/pages/home_page.dart';

class FreeNotesApp extends StatelessWidget {
  const FreeNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'FreeNotes',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.seedColor,
          ),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
