// lib/widgets/map_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng userPositionCoordinates;
  final double zoomLevel;
  final List<Marker> poiMarkers;

  MapWidget({
    required this.mapController,
    required this.userPositionCoordinates,
    required this.zoomLevel,
    required this.poiMarkers,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: userPositionCoordinates,
        zoom: zoomLevel,
        minZoom: 17.0,
        maxZoom: 23.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
              "https://api.mapbox.com/styles/v1/mapbox/outdoors-v11/tiles/{z}/{x}/{y}?access_token={accessToken}",
          subdomains: ['a', 'b', 'c'],
          additionalOptions: {
            'accessToken': 'your_mapbox_access_token_here',
          },
        ),
        MarkerLayer(
          markers: poiMarkers,
        ),
      ],
    );
  }
}
