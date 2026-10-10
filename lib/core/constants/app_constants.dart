class AppConstants {
  AppConstants._();

  // Drawing page dimensions in scene coordinates.
  static const double pageWidth = 800;
  static const double pageHeight = 1600;

  // MyScript Cloud API
  static const String myScriptBaseUrl =
      'https://cloud.myscript.com/api/v4.0/iink';
  static const String myScriptApplicationKey =
      String.fromEnvironment('MYSCRIPT_APPLICATION_KEY');
  static const String myScriptHmacKey =
      String.fromEnvironment('MYSCRIPT_HMAC_KEY');
  // Recognition languages
  static const String langArabic = 'ar';
  static const String langEnglish = 'en_US';

  // Database
  static const String dbName = 'freenotes.db';
  static const int dbVersion = 3;

  // Content block types
  static const String blockTypeInk = 'ink';
  static const String blockTypeText = 'text';
  static const String blockTypeImage = 'image';
}
