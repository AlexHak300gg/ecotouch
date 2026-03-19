import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/crypto_service.dart';
import '../utils/validators.dart';

class AuthProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final AuthService _auth = AuthService.instance;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _rememberMe = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get rememberMe => _rememberMe;

  /// Инициализация провайдера
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Загружаем состояние "Запомнить меня"
      _rememberMe = await _auth.getRememberMe();

      final userId = await _auth.getUserId();
      if (userId != null) {
        _currentUser = await _db.getUserById(userId);
      }
    } catch (e) {
      _error = 'Ошибка инициализации: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Регистрация нового пользователя
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Валидация данных
      final emailError = Validators.validateEmail(email);
      if (emailError != null) {
        _error = emailError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final passwordError = Validators.validatePassword(password);
      if (passwordError != null) {
        _error = passwordError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final nameError = Validators.validateName(name);
      if (nameError != null) {
        _error = nameError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final phoneError = Validators.validatePhone(phone);
      if (phoneError != null) {
        _error = phoneError;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Проверка существующего пользователя
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        _error = 'Пользователь с таким email уже существует';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Создание пользователя
      final passwordHash = CryptoService.hashPassword(password);
      final user = User(
        email: email,
        passwordHash: passwordHash,
        name: name,
        phone: phone,
      );

      final userId = await _db.createUser(user);
      final token = CryptoService.generateToken();

      await _auth.saveToken(token);
      await _auth.saveUserId(userId);
      await _auth.setRememberMe(_rememberMe);

      _currentUser = user.copyWith(id: userId);
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка регистрации: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Вход в систему
  Future<bool> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Проверка блокировки
      final lockStatus = await _auth.getLockStatus();
      if (lockStatus.isLocked) {
        _error = 'Слишком много неудачных попыток. '
            'Попробуйте через ${lockStatus.remainingSeconds} сек.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final user = await _db.getUserByEmail(email);
      if (user == null) {
        await _auth.recordFailedAttempt();
        _error = 'Пользователь не найден';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!CryptoService.verifyPassword(password, user.passwordHash)) {
        await _auth.recordFailedAttempt();
        _error = 'Неверный пароль';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Успешный вход - сбрасываем счётчик попыток
      await _auth.resetFailedAttempts();

      final token = CryptoService.generateToken();
      await _auth.saveToken(token);
      await _auth.saveUserId(user.id!);
      await _auth.setRememberMe(rememberMe);
      _rememberMe = rememberMe;

      _currentUser = user;
      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка входа: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    await _auth.clearAuth();
    _currentUser = null;
    _error = null;
    _rememberMe = false;
    notifyListeners();
  }

  /// Обновление профиля
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatarPath,
  }) async {
    if (_currentUser == null) return false;

    try {
      final updatedUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        avatarPath: avatarPath,
      );

      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка обновления профиля: $e';
      notifyListeners();
      return false;
    }
  }

  /// Смена пароля
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_currentUser == null) return false;

    try {
      // Проверка старого пароля
      if (!CryptoService.verifyPassword(oldPassword, _currentUser!.passwordHash)) {
        _error = 'Неверный текущий пароль';
        notifyListeners();
        return false;
      }

      // Валидация нового пароля
      final passwordError = Validators.validatePassword(newPassword);
      if (passwordError != null) {
        _error = passwordError;
        notifyListeners();
        return false;
      }

      // Обновление пароля
      final newPasswordHash = CryptoService.hashPassword(newPassword);
      final updatedUser = _currentUser!.copyWith(passwordHash: newPasswordHash);
      await _db.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Ошибка смены пароля: $e';
      notifyListeners();
      return false;
    }
  }

  /// Удаление аккаунта
  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    try {
      final userId = _currentUser!.id!;
      // Удаляем пользователя из БД (заметки удалятся по FOREIGN KEY)
      await _db.deleteUser(userId);
      // Очищаем авторизацию
      await logout();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления аккаунта: $e';
      notifyListeners();
      return false;
    }
  }

  /// Получение статистики пользователя
  Future<Map<String, int>> getUserStats() async {
    if (_currentUser == null) return {};

    try {
      return await _db.getUserStats(_currentUser!.id!);
    } catch (e) {
      _error = 'Ошибка получения статистики: $e';
      notifyListeners();
      return {};
    }
  }

  /// Установка состояния "Запомнить меня"
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Получение оставшихся попыток входа
  Future<int> getRemainingAttempts() async {
    final lockStatus = await _auth.getLockStatus();
    return lockStatus.remainingAttempts ?? 0;
  }

  /// Проверка сложности пароля
  PasswordStrength getPasswordStrength(String password) {
    return Validators.checkPasswordStrength(password);
  }
}
