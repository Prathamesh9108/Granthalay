class AppConstants {
  static const String appNameMr = 'ग्रंथालय';
  static const String appNameEn = 'Granthalay';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keySelectedLanguage = 'selected_language';
  static const String keyApiBaseUrl = 'api_base_url';
  static const String keyIsDemoMode = 'is_demo_mode';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUsername = 'logged_in_username';

  // Default API configuration for Spring Boot backend
  static const String defaultApiBaseUrl = 'http://192.168.1.46:8080/api'; // Real device - PC Wi-Fi IP
  static const String defaultLocalhostUrl = 'http://localhost:8080/api'; // USB debugging (adb reverse)
  static const String emulatorUrl = 'http://10.0.2.2:8080/api'; // Android Emulator only

  // Categories for Marathi & English
  static const List<String> bookCategories = [
    'कादंबरी (Novel)',
    'कथासंग्रह (Short Stories)',
    'चरित्र / आत्मचरित्र (Biography)',
    'इतिहास (History)',
    'विज्ञान व तंत्रज्ञान (Science & Tech)',
    'कविता / काव्य (Poetry)',
    'स्पर्धा परीक्षा (Competitive Exams)',
    'बालसाहित्य (Children Literature)',
    'धार्मिक व अध्यात्म (Spiritual)',
    'संदर्भ ग्रंथ (Reference Books)',
  ];
}
