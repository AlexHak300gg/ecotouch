/// Валидаторы для форм авторизации и регистрации
class Validators {
  /// Минимальная длина пароля
  static const int minPasswordLength = 8;

  /// Проверка email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите email';
    }

    // Базовая проверка формата
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Введите корректный email';
    }

    return null;
  }

  /// Проверка пароля с усиленными требованиями
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }

    if (value.length < minPasswordLength) {
      return 'Минимум $minPasswordLength символов';
    }

    // Проверка на наличие цифр
    if (!value.contains(RegExp(r'\d'))) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }

    // Проверка на наличие буквы
    if (!value.contains(RegExp(r'[a-zA-Z]'))) {
      return 'Пароль должен содержать хотя бы одну букву';
    }

    return null;
  }

  /// Проверка сложности пароля (возвращает уровень сложности)
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;

    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'\d'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }

  /// Проверка имени
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите имя';
    }

    if (value.length < 2) {
      return 'Имя должно содержать минимум 2 символа';
    }

    if (value.length > 50) {
      return 'Имя не должно превышать 50 символов';
    }

    return null;
  }

  /// Проверка телефона
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Телефон необязательный
    }

    // Удаляем все нецифровые символы кроме +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.length < 10) {
      return 'Введите корректный номер телефона';
    }

    return null;
  }

  /// Проверка подтверждения пароля
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Подтвердите пароль';
    }

    if (value != password) {
      return 'Пароли не совпадают';
    }

    return null;
  }

  /// Проверка согласия с условиями
  static String? validateAgreement(bool? agreed) {
    if (agreed != true) {
      return 'Необходимо принять условия';
    }
    return null;
  }
}

/// Уровень сложности пароля
enum PasswordStrength {
  weak,
  medium,
  strong,
}

extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return 'Слабый';
      case PasswordStrength.medium:
        return 'Средний';
      case PasswordStrength.strong:
        return 'Надёжный';
    }
  }

  /// Цвет для индикатора сложности
  // ignore: deprecated_member_use
  int getColorValue() {
    switch (this) {
      case PasswordStrength.weak:
        return 0xFFFF5252; // Red
      case PasswordStrength.medium:
        return 0xFFFFC107; // Amber
      case PasswordStrength.strong:
        return 0xFF4CAF50; // Green
    }
  }
}
