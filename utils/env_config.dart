import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration manager
///
/// This class manages environment variables loaded from .env files.
/// Supports both production and staging environments.
class EnvConfig {
  /// Load environment variables from the specified file
  ///
  /// [envFile] should be either '.env_production' or '.env_staging'
  static Future<void> load({String envFile = '.env_production'}) async {
    await dotenv.load(fileName: envFile);
  }

  /// Get Firebase API Key
  static String get firebaseApiKey {
    return dotenv.get('FIREBASE_API_KEY',
        fallback: 'AIzaSyCIClNmXCrVcuK8Iboob33jel0ZTGuPNvc');
  }

  /// Get Firebase App ID
  static String get firebaseAppId {
    return dotenv.get('FIREBASE_APP_ID',
        fallback: '1:54358982445:web:97ff9d7b44be92b0505da4');
  }

  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId {
    return dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '54358982445');
  }

  /// Get Firebase Project ID
  static String get firebaseProjectId {
    return dotenv.get('FIREBASE_PROJECT_ID', fallback: 'banhanghiephung');
  }

  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain {
    return dotenv.get('FIREBASE_AUTH_DOMAIN',
        fallback: 'banhanghiephung.firebaseapp.com');
  }

  /// Get Firebase Database URL
  static String get firebaseDatabaseUrl {
    return dotenv.get('FIREBASE_DATABASE_URL',
        fallback: 'https://banhanghiephung.firebaseio.com');
  }

  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket {
    return dotenv.get('FIREBASE_STORAGE_BUCKET',
        fallback: 'banhanghiephung.appspot.com');
  }

  /// Get Firebase Measurement ID
  static String get firebaseMeasurementId {
    return dotenv.get('FIREBASE_MEASUREMENT_ID', fallback: 'G-40C4BZGLDG');
  }

  /// Check if environment is loaded
  static bool get isLoaded => dotenv.isInitialized;
}
