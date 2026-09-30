import 'package:flutter/material.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../core/constants/app_strings.dart';

//✅
class CanvasAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSave;

  const CanvasAppBar(
      {super.key,
      required this.selectedLanguage,
      required this.onLanguageChanged,
      required this.onSave});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(Appstrings.appName),
      actions: [
        PopupMenuButton<String>(
          initialValue: selectedLanguage,
          onSelected: (lang) => onLanguageChanged,
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: AppConstants.langArabic, child: Text(Appstrings.arabic)),
            const PopupMenuItem(
                value: AppConstants.langEnglish,
                child: Text(Appstrings.english)),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(selectedLanguage == AppConstants.langArabic
                  ? Appstrings.arabicCode
                  : Appstrings.englishCode),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: onSave,
          tooltip: Appstrings.saveDrawing,
        ),
      ],
    );
  }
}
