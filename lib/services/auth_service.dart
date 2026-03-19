import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _rememberMeKey = 'remember_me';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  AuthService._init();

  /// Сохранение токена
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Получение токена
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Сохранение ID пользователя
  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  /// Получение ID пользователя
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Сохранение состояния "Запомнить меня"
  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
  }

  /// Проверка состояния "Запомнить меня"
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Очистка данных авторизации
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutTimeKey);
  }

  /// Проверка авторизации
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Регистрация неудачной попытки входа
  Future<void> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    await prefs.setInt(_failedAttemptsKey, attempts + 1);
    
    if (attempts + 1 >= maxFailedAttempts) {
      await prefs.setInt(
        _lockoutTimeKey,
        DateTime.now().add(lockoutDuration).millisecondsSinceEpoch,
      );
    }
  }

  /// Сброс счётчика неудачных попыток
  Future<void> resetFailedAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_failedAttemptsKey);
    await prefs.remove(_lockoutTimeKey);
  }

  /// Проверка блокировки из-за неудачных попыток
  Future<AuthLockStatus> getLockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    final lockoutTime = prefs.getInt(_lockoutTimeKey);

    if (lockoutTime != null) {
      final lockoutDateTime = DateTime.fromMillisecondsSinceEpoch(lockoutTime);
      if (DateTime.now().isBefore(lockoutDateTime)) {
        return AuthLockStatus(
          isLocked: true,
          remainingSeconds: lockoutDateTime.difference(DateTime.now()).inSeconds,
        );
      } else {
        // Время блокировки истекло, сбрасываем
        await resetFailedAttempts();
      }
    }

    return AuthLockStatus(
      isLocked: false,
      remainingAttempts: maxFailedAttempts - attempts,
    );
  }

  /// Получение токена восстановления пароля (для будущей реализации)
  Future<String?> getPasswordResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password_reset_token');
  }

  /// Сохранение токена восстановления пароля
  Future<void> savePasswordResetToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_reset_token', token);
  }

  /// Очистка токена восстановления пароля
  Future<void> clearPasswordResetToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password_reset_token');
  }
}

/// Статус блокировки входа
class AuthLockStatus {
  final bool isLocked;
  final int? remainingSeconds;
  final int? remainingAttempts;

  AuthLockStatus({
    required this.isLocked,
    this.remainingSeconds,
    this.remainingAttempts,
  });
}
