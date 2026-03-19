import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notes_provider.dart';
import '../providers/auth_provider.dart';
import '../models/note.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? note;
  final DateTime? selectedDate;

  const NoteFormScreen({super.key, this.note, this.selectedDate});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late DateTime _selectedDate;
  TimeOfDay? _reminderTime;
  bool _isEditing = false;
  String? _selectedCategory;
  NotePriority _selectedPriority = NotePriority.normal;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController =
        TextEditingController(text: widget.note?.content ?? '');
    _selectedDate = widget.note?.date ?? widget.selectedDate ?? DateTime.now();
    if (widget.note?.reminderTime != null) {
      _reminderTime = TimeOfDay.fromDateTime(widget.note!.reminderTime!);
    }
    if (widget.note != null) {
      _selectedCategory = widget.note!.category;
      _selectedPriority = widget.note!.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final notesProvider = context.read<NotesProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id!;

    DateTime? reminderDateTime;
    if (_reminderTime != null) {
      reminderDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _reminderTime!.hour,
        _reminderTime!.minute,
      );
    }

    final success = _isEditing
        ? await notesProvider.updateNote(
            id: widget.note!.id!,
            userId: userId,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            date: _selectedDate,
            reminderTime: reminderDateTime,
            isCompleted: widget.note!.isCompleted,
            category: _selectedCategory,
            priority: _selectedPriority,
          )
        : await notesProvider.createNote(
            userId: userId,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            date: _selectedDate,
            reminderTime: reminderDateTime,
            category: _selectedCategory,
            priority: _selectedPriority,
          );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Заметка обновлена' : 'Заметка создана',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notesProvider.error ?? 'Ошибка сохранения'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Новая заметка'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: 'Сохранить',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Карточка с основной информацией
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Заголовок',
                        prefixIcon: const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите заголовок';
                        }
                        if (value.length < 3) {
                          return 'Минимум 3 символа';
                        }
                        if (value.length > 100) {
                          return 'Максимум 100 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: 'Содержимое',
                        prefixIcon: const Icon(Icons.notes),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Карточка с датой и напоминанием
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Дата и напоминание',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Colors.green.shade700),
                            const SizedBox(width: 16),
                            Text(
                              DateFormat('dd MMMM yyyy', 'ru_RU')
                                  .format(_selectedDate),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _selectTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _reminderTime != null
                                  ? Icons.alarm
                                  : Icons.alarm_add,
                              color: _reminderTime != null
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _reminderTime != null
                                  ? 'Напоминание: ${_reminderTime!.format(context)}'
                                  : 'Добавить напоминание',
                              style: TextStyle(
                                fontSize: 16,
                                color: _reminderTime != null
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            if (_reminderTime != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => _reminderTime = null);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Карточка с категорией и приоритетом
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Категория и приоритет',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Выбор категории
                    const Text(
                      'Категория:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: NoteCategory.all.map((category) {
                        final isSelected = _selectedCategory == category.id;
                        return ChoiceChip(
                          label: Text('${category.icon} ${category.name}'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category.id : null;
                            });
                          },
                          selectedColor: Color(category.colorValue),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Выбор приоритета
                    const Text(
                      'Приоритет:',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriorityChip(
                            NotePriority.low,
                            Icons.arrow_downward,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityChip(
                            NotePriority.normal,
                            Icons.remove,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPriorityChip(
                            NotePriority.high,
                            Icons.arrow_upward,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Кнопка сохранения
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Сохранить' : 'Создать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Кнопка отметки о выполнении (только для редактирования)
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _toggleCompleted(),
                  icon: Icon(
                    widget.note!.isCompleted
                        ? Icons.undo
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    widget.note!.isCompleted
                        ? 'Отметить как невыполненное'
                        : 'Отметить как выполненное',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(NotePriority priority, IconData icon) {
    final isSelected = _selectedPriority == priority;
    final color = Color(priority.getColorValue());

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              priority.label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleCompleted() async {
    final notesProvider = context.read<NotesProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser!.id!;

    await notesProvider.updateNote(
      id: widget.note!.id!,
      userId: userId,
      isCompleted: !widget.note!.isCompleted,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.note!.isCompleted
                ? 'Заметка отмечена как невыполненная'
                : 'Заметка выполнена!',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
