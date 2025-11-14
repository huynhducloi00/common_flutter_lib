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
    return dotenv.get('FIREBASE_API_KEY', fallback: '');
  }

  /// Get Firebase App ID
  static String get firebaseAppId {
    return dotenv.get('FIREBASE_APP_ID', fallback: '');
  }

  /// Get Firebase Messaging Sender ID
  static String get firebaseMessagingSenderId {
    return dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');
  }

  /// Get Firebase Project ID
  static String get firebaseProjectId {
    return dotenv.get('FIREBASE_PROJECT_ID', fallback: '');
  }

  /// Get Firebase Auth Domain
  static String get firebaseAuthDomain {
    return dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: '');
  }

  /// Get Firebase Database URL
  static String get firebaseDatabaseUrl {
    return dotenv.get('FIREBASE_DATABASE_URL', fallback: '');
  }

  /// Get Firebase Storage Bucket
  static String get firebaseStorageBucket {
    return dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: '');
  }

  /// Get Firebase Measurement ID
  static String get firebaseMeasurementId {
    return dotenv.get('FIREBASE_MEASUREMENT_ID', fallback: '');
  }

  /// Check if environment is loaded
  static bool get isLoaded => dotenv.isInitialized;
}

