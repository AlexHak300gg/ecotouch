import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recycling_points_provider.dart';
import '../models/recycling_point.dart';
import '../widgets/map_view.dart';
import 'recycling_point_form_screen.dart';
import 'recycling_point_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _isMapView = true; // Переключатель: карта/список

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта пунктов приёма'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          // Переключатель вида
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
            tooltip: _isMapView ? 'Показать список' : 'Показать карту',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Фильтр',
          ),
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => _navigateToAddPoint(context),
            tooltip: 'Добавить пункт',
          ),
        ],
      ),
      body: Consumer<RecyclingPointsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.allPoints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Пункты приёма не найдены',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToAddPoint(context),
                    icon: const Icon(Icons.add_location),
                    label: const Text('Добавить первый пункт'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return _isMapView
              ? _buildMapView(context, provider)
              : _buildListView(context, provider);
        },
      ),
    );
  }

  Widget _buildMapView(
    BuildContext context,
    RecyclingPointsProvider provider,
  ) {
    return Stack(
      children: [
        MapView(
          points: provider.allPoints,
          selectedTypes: provider.selectedTypes,
          onPointTap: (point) => _navigateToPointDetail(context, point),
        ),
        // Панель фильтров внизу
        if (provider.selectedTypes.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _buildFilterChips(provider),
          ),
      ],
    );
  }

  Widget _buildListView(
    BuildContext context,
    RecyclingPointsProvider provider,
  ) {
    return Column(
      children: [
        // Панель фильтров
        if (provider.selectedTypes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            color: Colors.green.shade50,
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: provider.selectedTypes
                          .map((typeId) {
                            final type = RecyclingType.all
                                .firstWhere((t) => t.id == typeId);
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(type.icon),
                                  const SizedBox(width: 4),
                                  Text(
                                    type.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () =>
                                        provider.toggleTypeFilter(typeId),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: provider.clearFilters,
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),
        // Список пунктов
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.filteredPoints.length,
            itemBuilder: (context, index) {
              final point = provider.filteredPoints[index];
              return _buildPointCard(context, point);
            },
          ),
        ),
        // Информация о количестве
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.location_on,
                '${provider.filteredPoints.length}',
                'пунктов',
              ),
              _buildStatItem(
                Icons.category,
                '${RecyclingType.all.length}',
                'типов',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(RecyclingPointsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Активные фильтры:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.selectedTypes.map((typeId) {
              final type = RecyclingType.all.firstWhere((t) => t.id == typeId);
              return Chip(
                label: Text(
                  '${type.icon} ${type.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.green.shade700,
                deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                onDeleted: () => provider.toggleTypeFilter(typeId),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Очистить все'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointCard(BuildContext context, dynamic point) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToPointDetail(context, point),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.recycling,
                      color: Colors.green.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          point.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                point.address,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              if (point.description != null && point.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  point.description!,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: point.acceptedTypes
                    .take(5)
                    .map((typeId) {
                      final type = RecyclingType.fromId(typeId);
                      if (type == null) return const SizedBox.shrink();
                      return Chip(
                        label: Text(
                          '${type.icon} ${type.name}',
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        backgroundColor: Colors.green.shade600,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      );
                    })
                    .toList(),
              ),
              if (point.acceptedTypes.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  'Ещё ${point.acceptedTypes.length - 5} типов...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (point.workingHours != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      point.workingHours!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<RecyclingPointsProvider>(
        builder: (context, provider, _) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтр по типам вторсырья',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RecyclingType.all.map((type) {
                    final isSelected = provider.selectedTypes.contains(type.id);
                    return ChoiceChip(
                      label: Text('${type.icon} ${type.name}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        provider.toggleTypeFilter(type.id);
                      },
                      selectedColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Сбросить фильтры'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToAddPoint(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecyclingPointFormScreen()),
    );
  }

  void _navigateToPointDetail(BuildContext context, dynamic point) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecyclingPointDetailScreen(point: point),
      ),
    );
  }
}
