import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/pet_report_entity.dart';

class ReportClusterItem with ClusterItem {
  ReportClusterItem(this.report);

  final PetReportEntity report;

  @override
  LatLng get location => LatLng(report.location.latitude, report.location.longitude);
}

/// Bounding box que contiene todos los puntos dados, usado para hacer zoom
/// a un cluster completo cuando el usuario lo toca.
LatLngBounds boundsFromLatLngList(List<LatLng> points) {
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;

  for (final point in points.skip(1)) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  return LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
}
