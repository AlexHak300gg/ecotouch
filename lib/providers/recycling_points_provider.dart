import 'package:flutter/foundation.dart';
import '../models/recycling_point.dart';
import '../services/database_service.dart';

class RecyclingPointsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<RecyclingPoint> _allPoints = [];
  List<RecyclingPoint> _filteredPoints = [];
  final List<String> _selectedTypes = [];
  bool _isLoading = false;
  String? _error;

  List<RecyclingPoint> get allPoints => _allPoints;
  List<RecyclingPoint> get filteredPoints => _filteredPoints;
  List<String> get selectedTypes => _selectedTypes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPoints() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allPoints = await _db.getAllRecyclingPoints();
      _applyFilters();
    } catch (e) {
      _error = 'Ошибка загрузки пунктов: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleTypeFilter(String typeId) {
    if (_selectedTypes.contains(typeId)) {
      _selectedTypes.remove(typeId);
    } else {
      _selectedTypes.add(typeId);
    }
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _selectedTypes.clear();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    if (_selectedTypes.isEmpty) {
      _filteredPoints = _allPoints;
    } else {
      _filteredPoints = _allPoints.where((point) {
        return point.acceptedTypes.any((type) => _selectedTypes.contains(type));
      }).toList();
    }
  }

  Future<bool> addPoint({
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? description,
    String? phone,
    String? workingHours,
    required List<String> acceptedTypes,
  }) async {
    try {
      final point = RecyclingPoint(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        phone: phone,
        workingHours: workingHours,
        acceptedTypes: acceptedTypes,
      );

      await _db.createRecyclingPoint(point);
      await loadPoints();
      return true;
    } catch (e) {
      _error = 'Ошибка добавления пункта: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePoint({
    required int id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    String? phone,
    String? workingHours,
    List<String>? acceptedTypes,
  }) async {
    try {
      final existingPoint = _allPoints.where((p) => p.id == id).firstOrNull;
      if (existingPoint == null) {
        _error = 'Пункт приёма не найден';
        notifyListeners();
        return false;
      }

      final updatedPoint = existingPoint.copyWith(
        name: name,
        address: address,
        latitude: latitude,
        longitude: longitude,
        description: description,
        phone: phone,
        workingHours: workingHours,
        acceptedTypes: acceptedTypes,
      );

      await _db.updateRecyclingPoint(updatedPoint);
      await loadPoints();
      return true;
    } catch (e) {
      _error = 'Ошибка обновления пункта: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePoint(int id) async {
    try {
      await _db.deleteRecyclingPoint(id);
      await loadPoints();
      return true;
    } catch (e) {
      _error = 'Ошибка удаления пункта: $e';
      notifyListeners();
      return false;
    }
  }

  RecyclingPoint? getPointById(int id) {
    return _allPoints.where((p) => p.id == id).firstOrNull;
  }
}
