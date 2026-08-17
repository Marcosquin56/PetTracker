import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
// google_maps_flutter reciente trae su propio ClusterManager/Cluster nativo;
// usamos los de google_maps_cluster_manager_2 (el algoritmo de spiderfy/zoom).
import 'package:google_maps_flutter/google_maps_flutter.dart' hide ClusterManager, Cluster;

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet_report_entity.dart';
import '../utils/status_style.dart';
import 'marker_icons.dart';
import 'report_cluster_item.dart';
import 'report_map_popup_card.dart';

/// Vista de mapa del feed: markers por reporte, agrupados en clusters cuando
/// están cerca (como Life360/Uber). Tocar un cluster hace zoom para
/// separarlo; tocar un marker individual muestra una card resumen abajo.
class ReportsMapView extends StatefulWidget {
  const ReportsMapView({required this.reports, required this.onOpenDetail, super.key});

  final List<PetReportEntity> reports;
  final ValueChanged<String> onOpenDetail;

  @override
  State<ReportsMapView> createState() => _ReportsMapViewState();
}

class _ReportsMapViewState extends State<ReportsMapView> {
  late ClusterManager<ReportClusterItem> _clusterManager;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  PetReportEntity? _selectedReport;

  @override
  void initState() {
    super.initState();
    _clusterManager = _buildClusterManager(widget.reports);
  }

  @override
  void didUpdateWidget(covariant ReportsMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.reports, widget.reports)) {
      _clusterManager.setItems(widget.reports.map(ReportClusterItem.new).toList());
    }
  }

  ClusterManager<ReportClusterItem> _buildClusterManager(List<PetReportEntity> reports) {
    return ClusterManager<ReportClusterItem>(
      reports.map(ReportClusterItem.new),
      _onMarkersUpdated,
      markerBuilder: _buildMarker,
    );
  }

  void _onMarkersUpdated(Set<Marker> markers) {
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<Marker> _buildMarker(Cluster<ReportClusterItem> cluster) async {
    if (cluster.isMultiple) {
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: await MarkerIcons.count(cluster.count, AppTheme.seed),
        onTap: () => _zoomToCluster(cluster),
      );
    }

    final report = cluster.items.first.report;
    return Marker(
      markerId: MarkerId(report.id),
      position: cluster.location,
      icon: await MarkerIcons.avatar(
        cacheKey: '${report.id}-${report.status.name}-${report.primaryPhotoUrl}',
        color: report.status.color,
        fallbackEmoji: report.species.emoji,
        photoUrl: report.primaryPhotoUrl,
      ),
      onTap: () => setState(() => _selectedReport = report),
    );
  }

  Future<void> _zoomToCluster(Cluster<ReportClusterItem> cluster) async {
    final bounds = boundsFromLatLngList(cluster.items.map((item) => item.location).toList());
    await _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = widget.reports.isNotEmpty
        ? LatLng(widget.reports.first.location.latitude, widget.reports.first.location.longitude)
        : const LatLng(4.710989, -74.072092);

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initialTarget, zoom: 12),
          markers: _markers,
          onMapCreated: (controller) {
            _mapController = controller;
            _clusterManager.setMapId(controller.mapId);
          },
          onCameraMove: _clusterManager.onCameraMove,
          onTap: (_) => setState(() => _selectedReport = null),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: _selectedReport != null ? 0 : -160,
          child: _selectedReport == null
              ? const SizedBox.shrink()
              : ReportMapPopupCard(
                  report: _selectedReport!,
                  onTap: () => widget.onOpenDetail(_selectedReport!.id),
                  onClose: () => setState(() => _selectedReport = null),
                ),
        ),
      ],
    );
  }
}
