import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/recycling_point.dart';

/// Виджет интерактивной карты пунктов приёма
class MapView extends StatefulWidget {
  final List<RecyclingPoint> points;
  final List<String> selectedTypes;
  final Function(RecyclingPoint)? onPointTap;

  const MapView({
    super.key,
    required this.points,
    required this.selectedTypes,
    this.onPointTap,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  
  // Координаты центра Удмуртской Республики
  static const LatLng _udmurtiaCenter = LatLng(56.8527, 53.2041);
  static const double _initialZoom = 8.0;

  @override
  Widget build(BuildContext context) {
    final filteredPoints = _filterPoints();

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _udmurtiaCenter,
        initialZoom: _initialZoom,
        minZoom: 6.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ecotouch',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: _buildMarkers(filteredPoints),
        ),
        // Кнопка возврата к центру
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: 'centerMap',
            onPressed: () {
              _mapController.move(_udmurtiaCenter, _initialZoom);
            },
            backgroundColor: Colors.green.shade700,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
        // Индикатор количества маркеров
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${filteredPoints.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers(List<RecyclingPoint> points) {
    return points.map((point) {
      return Marker(
        point: LatLng(point.latitude, point.longitude),
        width: 50,
        height: 50,
        child: InkWell(
          onTap: () => widget.onPointTap?.call(point),
          child: _buildMarkerWidget(point),
        ),
      );
    }).toList();
  }

  Widget _buildMarkerWidget(RecyclingPoint point) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.recycling,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  List<RecyclingPoint> _filterPoints() {
    if (widget.selectedTypes.isEmpty) {
      return widget.points;
    }

    return widget.points.where((point) {
      return point.acceptedTypes.any((type) => widget.selectedTypes.contains(type));
    }).toList();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
