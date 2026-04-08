import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recycling_points_provider.dart';
import '../models/recycling_point.dart';

class RecyclingPointFormScreen extends StatefulWidget {
  final RecyclingPoint? point;

  const RecyclingPointFormScreen({super.key, this.point});

  @override
  State<RecyclingPointFormScreen> createState() =>
      _RecyclingPointFormScreenState();
}

class _RecyclingPointFormScreenState
    extends State<RecyclingPointFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _workingHoursController;
  late Set<String> _selectedTypes;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.point != null;
    _nameController = TextEditingController(text: widget.point?.name ?? '');
    _addressController =
        TextEditingController(text: widget.point?.address ?? '');
    _latitudeController = TextEditingController(
      text: widget.point != null ? widget.point!.latitude.toString() : '',
    );
    _longitudeController = TextEditingController(
      text: widget.point != null ? widget.point!.longitude.toString() : '',
    );
    _descriptionController =
        TextEditingController(text: widget.point?.description ?? '');
    _phoneController = TextEditingController(text: widget.point?.phone ?? '');
    _workingHoursController =
        TextEditingController(text: widget.point?.workingHours ?? '');
    _selectedTypes = widget.point?.acceptedTypes != null
        ? Set<String>.from(widget.point!.acceptedTypes)
        : {};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _workingHoursController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<RecyclingPointsProvider>();

    final success = _isEditing
        ? await provider.updatePoint(
            id: widget.point!.id!,
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            latitude: double.tryParse(_latitudeController.text.trim()),
            longitude: double.tryParse(_longitudeController.text.trim()),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            workingHours: _workingHoursController.text.trim().isEmpty
                ? null
                : _workingHoursController.text.trim(),
            acceptedTypes: _selectedTypes.toList(),
          )
        : await provider.addPoint(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            latitude: double.parse(_latitudeController.text.trim()),
            longitude: double.parse(_longitudeController.text.trim()),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            workingHours: _workingHoursController.text.trim().isEmpty
                ? null
                : _workingHoursController.text.trim(),
            acceptedTypes: _selectedTypes.toList(),
          );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Пункт обновлён' : 'Пункт добавлен',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Ошибка сохранения'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактирование' : 'Новый пункт'),
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
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название *',
                prefixIcon: const Icon(Icons.business),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Адрес *',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите адрес';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Широта *',
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Некорректно';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Долгота *',
                      prefixIcon: const Icon(Icons.straighten),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Некорректно';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Описание',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Телефон',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _workingHoursController,
              decoration: InputDecoration(
                labelText: 'Время работы',
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Например: Пн-Пт: 9:00-18:00',
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Типы вторсырья *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: RecyclingType.all.map((type) {
                final isSelected = _selectedTypes.contains(type.id);
                return FilterChip(
                  label: Text('${type.icon} ${type.name}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTypes.add(type.id);
                      } else {
                        _selectedTypes.remove(type.id);
                      }
                    });
                  },
                  selectedColor: Colors.green.shade700,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            if (_selectedTypes.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Выберите хотя бы один тип',
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Сохранить' : 'Добавить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
