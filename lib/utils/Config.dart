class AppConfig {
  // Base URL for the backend
  static const String baseUrl = 'http://localhost:8080';

  // API Endpoints
  static const String loginEndpoint = '$baseUrl/api/auth/login';
  static const String userInfoEndpoint = '$baseUrl/api/user/info';
  static const String registerEndpoint = '$baseUrl/api/users/register';
  static const String bookmark = '$baseUrl/api/bookmark/createBookmark';
  static const String removeBookmark = '$baseUrl/api/bookmark/removeBookmark';

  // Additional configuration
  static const int requestTimeout = 5000; // Timeout duration in milliseconds

  List<String> categories = [
    'Sports',
    'Tech',
    'Health',
    'Entertainment',
    'Politics',
    'Business',
    'Science',
    'Travel',
    'Education',
  ];
}