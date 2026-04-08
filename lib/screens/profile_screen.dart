import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../utils/validators.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _emailController;
  TextEditingController? _phoneController;
  String? _avatarPath;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  final ImagePicker _picker = ImagePicker();

  void _ensureInitialized() {
    if (_isInitialized) return;
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user != null) {
      _nameController = TextEditingController(text: user.name);
      _emailController = TextEditingController(text: user.email);
      _phoneController = TextEditingController(text: user.phone ?? '');
      _avatarPath = user.avatarPath;
    } else {
      _nameController = TextEditingController();
      _emailController = TextEditingController();
      _phoneController = TextEditingController();
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _emailController?.dispose();
    _phoneController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _isLoading = true);
        final appDir = await getApplicationDocumentsDirectory();
        final userDir = Directory('${appDir.path}/avatars');
        if (!await userDir.exists()) {
          await userDir.create(recursive: true);
        }
        final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedFile = File(pickedFile.path);
        final copiedFile = await savedFile.copy('${userDir.path}/$fileName');
        setState(() {
          _avatarPath = copiedFile.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки изображения: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить аватар', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _avatarPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProvider>();
    setState(() => _isLoading = true);
    final success = await authProvider.updateProfile(
      name: _nameController!.text.trim(),
      phone: _phoneController!.text.trim().isEmpty ? null : _phoneController!.text.trim(),
      avatarPath: _avatarPath,
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль обновлён'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Ошибка обновления'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pop(context);
              if (mounted) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Удаление аккаунта'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вы уверены? Это действие нельзя отменить.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Будут удалены:'),
            const SizedBox(height: 8),
            _buildDeleteItem('Все заметки и напоминания'),
            _buildDeleteItem('История посещённых пунктов'),
            _buildDeleteItem('Личные данные и аватар'),
            const SizedBox(height: 16),
            const Text(
              'Для подтверждения введите "УДАЛИТЬ":',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: 'Введите "УДАЛИТЬ"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (confirmController.text != 'УДАЛИТЬ') {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите "УДАЛИТЬ" для подтверждения'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (!context.mounted) return;
              Navigator.pop(context);

              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final success = await authProvider.deleteAccount();

              if (!context.mounted) return;
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Аккаунт удалён'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      authProvider.error ?? 'Ошибка удаления аккаунта',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Смена пароля'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Текущий пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureCurrent = !obscureCurrent);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(() => obscureNew = !obscureNew);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) => setDialogState(() {}),
                ),
                // Индикатор сложности пароля
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final strength = auth.getPasswordStrength(
                      newPasswordController.text,
                    );
                    return _buildPasswordStrengthIndicatorInDialog(
                      strength,
                      setDialogState,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setDialogState(
                            () => obscureConfirm = !obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                // Валидация
                if (currentPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Введите текущий пароль'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text.length < 8) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Минимум 8 символов'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (!newPasswordController.text.contains(RegExp(r'\d'))) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Пароль должен содержать цифру'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Пароли не совпадают'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                final authProvider =
                    Provider.of<AuthProvider>(dialogContext, listen: false);
                final success = await authProvider.changePassword(
                  oldPassword: currentPasswordController.text,
                  newPassword: newPasswordController.text,
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Пароль успешно изменён'
                          : authProvider.error ?? 'Ошибка смены пароля',
                    ),
                    backgroundColor:
                        success ? Colors.green : Colors.red,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicatorInDialog(
    PasswordStrength strength,
    void Function(void Function()) setDialogState,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildStrengthSegment(
                  filled: strength.index >= 0,
                  color: Color(strength.getColorValue()),
                ),
                const SizedBox(width: 4),
                _buildStrengthSegment(
                  filled: strength.index >= 1,
                  color: Color(strength.getColorValue()),
                ),
                const SizedBox(width: 4),
                _buildStrengthSegment(
                  filled: strength.index >= 2,
                  color: Color(strength.getColorValue()),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            strength.label,
            style: TextStyle(
              fontSize: 12,
              color: Color(strength.getColorValue()),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSegment({required bool filled, required Color color}) {
    return Expanded(
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: filled ? color : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
    return '${date.day} ${months[date.month - 1]} ${date.year} г.';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarCard(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _showImageSourceDialog : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.green.shade100,
                    backgroundImage: _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                    child: _avatarPath == null ? Icon(Icons.person, size: 60, color: Colors.green.shade700) : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              Text('Нажмите на аватар для изменения', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileForm(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Личные данные', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Введите email';
                  if (!value.contains('@') || !value.contains('.')) return 'Некорректный email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(User user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.calendar_today, 'Дата регистрации', _formatDate(user.createdAt)),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge, 'ID пользователя', '#${user.id ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: Provider.of<AuthProvider>(context, listen: false).getUserStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final totalNotes = stats['totalNotes'] ?? 0;
        final completedNotes = stats['completedNotes'] ?? 0;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        Icons.note,
                        '$totalNotes',
                        'всего заметок',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        Icons.check_circle,
                        '$completedNotes',
                        'выполнено',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Управление аккаунтом', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.notifications, color: Colors.blue.shade700)),
              title: const Text('Уведомления'),
              subtitle: const Text('Настройка уведомлений'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки уведомлений'))),
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.security, color: Colors.purple.shade700)),
              title: const Text('Безопасность'),
              subtitle: const Text('Смена пароля'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showChangePasswordDialog,
            ),
            const Divider(height: 24),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.logout, color: Colors.orange.shade700)),
              title: const Text('Выйти из аккаунта'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _confirmLogout,
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.delete_forever, color: Colors.red.shade700)),
              title: const Text('Удалить аккаунт', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.chevron_right, color: Colors.red),
              onTap: _confirmDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitialized();
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Профиль'),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              if (!_isEditing)
                IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true), tooltip: 'Редактировать')
              else ...[
                IconButton(icon: const Icon(Icons.close), onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController!.text = user.name;
                    _emailController!.text = user.email;
                    _phoneController!.text = user.phone ?? '';
                    _avatarPath = user.avatarPath;
                  });
                }, tooltip: 'Отмена'),
                IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile, tooltip: 'Сохранить'),
              ],
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildAvatarCard(user),
                    const SizedBox(height: 16),
                    _buildProfileForm(user),
                    const SizedBox(height: 16),
                    _buildInfoCard(user),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildAccountSettingsCard(),
                  ],
                ),
        );
      },
    );
  }
}
