class AppConstants {
  AppConstants._();

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
  static const int dbVersion = 2; //1;

  // Content block types
  static const String blockTypeInk = 'ink';
  static const String blockTypeText = 'text';
  static const String blockTypeImage = 'image';
}
