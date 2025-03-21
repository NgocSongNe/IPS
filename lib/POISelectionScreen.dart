import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class POISelectionScreen extends StatefulWidget {
  @override
  _POISelectionScreenState createState() => _POISelectionScreenState();
}

class _POISelectionScreenState extends State<POISelectionScreen> {
  String? startPOI;
  String? endPOI;

  final List<Map<String, dynamic>> poiList = [
    {
      //
      "name": "TV3,4",
      "coordinates": LatLng(11.957103446948263, 108.4451276943349)
    },
    {
      //
      "name": "Cửa chính",
      "coordinates": LatLng(11.95722012378778, 108.44507513707596)
    },
    {
      //
      "name": "Hội trường thư viện",
      "coordinates": LatLng(11.957369760112835, 108.445010451218806)
    },
    {
      "name": "Lối lên TV 3-4",
      "coordinates": LatLng(11.957142339233695, 108.445089287107209)
    },
    {
      "name": "Lối tới  2",
      "coordinates": LatLng(11.957153215888788, 108.44508389661911)
    },
    {
      "name": "Cầu thang 3",
      "coordinates": LatLng(11.957270222302304, 108.445032013171186)
    },
    {
      "name": "Cầu thang 4",
      "coordinates": LatLng(11.957285713288467, 108.44502527506107)
    },
    {
      "name": "Khu vực tự học 1",
      "coordinates": LatLng(11.957136406512548, 108.445076821603479)
    },
    //
    {
      "name": "Căn tin",
      "coordinates": LatLng(11.95730021548748, 108.445016852423421)
    },
    {
      "name": "Cầu thang 5",
      "coordinates": LatLng(11.957142009638083, 108.445051553690533)
    },
    {
      "name": "Cầu thang 6",
      "coordinates": LatLng(11.957201336842447, 108.445021232195003)
    },
    {
      "name": "Khu vực tự học 2",
      "coordinates": LatLng(11.957109050074482, 108.445044815580403)
    },
    {
      "name": "Khu vực tự học 3",
      "coordinates": LatLng(11.957155193462402, 108.445022579817007)
    },
    {
      "name": "Khu vực tự học 4",
      "coordinates": LatLng(11.957235614776819, 108.44498821545541)
    },
    {
      "name": "Khu vực tự học 5",
      "coordinates": LatLng(11.95728109895226, 108.44496867493605)
    },
    {
      "name": "Hành lang 1",
      "coordinates": LatLng(11.957078068081035, 108.445036729848269)
    },
    {
      "name": "Hành lang 2",
      "coordinates": LatLng(11.957319332021353, 108.444932289141406)
    },
    {
      "name": "Khu vực tự học 6",
      "coordinates": LatLng(11.957143328020546, 108.444986194022377)
    },
    {
      "name": "Cầu thang 7",
      "coordinates": LatLng(11.957182220300242, 108.444970022558081)
    },
    {
      "name": "Cầu thang 8",
      "coordinates": LatLng(11.957113005222325, 108.444984172589329)
    },
    {
      "name": "Cầu thang 9",
      "coordinates": LatLng(11.957246821023652, 108.444925551031275)
    },
    {
      "name": "Khu vực đọc 1",
      "coordinates": LatLng(11.957058292338679, 108.44498821545541)
    },
    {
      "name": "Khu vực tự học 7",
      "coordinates": LatLng(11.957084000803459, 108.444975413046166)
    },
    {
      "name": "Khu vực tự học 8",
      "coordinates": LatLng(11.957269892706845, 108.444893881913728)
    },
    {
      "name": "Khu vực đọc 2",
      "coordinates": LatLng(11.957298237914936, 108.444882427126515)
    },
    {
      "name": "Khu vực đọc 3",
      "coordinates": LatLng(11.957134099343184, 108.44496665350303)
    },
    {
      "name": "Khu vực đọc 4",
      "coordinates": LatLng(11.957215179854931, 108.444926224842291)
    },
    {
      "name": "Cầu thang 10",
      "coordinates": LatLng(11.957170354859571, 108.444936332007458)
    },
    {
      "name": "Cầu thang 11",
      "coordinates": LatLng(11.957100480587288, 108.444947786794671)
    },
    {
      "name": "Khu vực đọc 5",
      "coordinates": LatLng(11.957124211474238, 108.444937005818488)
    },
    {
      "name": "Khu vực đọc 6",
      "coordinates": LatLng(11.957205291988943, 108.444901967645862)
    },
    {
      "name": "Cầu thang 12",
      "coordinates": LatLng(11.957234296394807, 108.444889839047647)
    },
    {
      "name": "Cầu thang tầng 2 1",
      "coordinates": LatLng(11.957073453741282, 108.444920834354193)
    },
    {
      "name": "Cửa ra vào 2",
      "coordinates": LatLng(11.957085978377572, 108.444913422433075)
    },
    {
      "name": "Khu vực tự học 9",
      "coordinates": LatLng(11.957109709265794, 108.444904662889911)
    },
    {
      "name": "Bàn thủ thư",
      "coordinates": LatLng(11.95716376294754, 108.44487939497695)
    },
    {
      "name": "Khu vực tự học 10",
      "coordinates": LatLng(11.957194744931497, 108.444864908040202)
    },
    {
      "name": "Phòng tạp chí",
      "coordinates": LatLng(11.957220453383307, 108.444854127064005)
    },
    {
      "name": "Cầu thang tầng 2 2",
      "coordinates": LatLng(11.957236933158825, 108.444848062764891)
    },
  ];
  List<LatLng> selectedRoute = [];

  void _drawRoute() {
    if (startPOI != null && endPOI != null) {
      final start =
          poiList.firstWhere((poi) => poi['name'] == startPOI)['coordinates'];
      final end =
          poiList.firstWhere((poi) => poi['name'] == endPOI)['coordinates'];
      setState(() {
        selectedRoute = [start, end];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn Địa Điểm")),
      body: Column(
        children: [
          DropdownButton<String>(
            hint: Text("Chọn điểm bắt đầu"),
            value: startPOI,
            onChanged: (value) {
              setState(() {
                startPOI = value;
              });
            },
            items: poiList.map((poi) {
              return DropdownMenuItem<String>(
                value: poi['name'] as String,
                child: Text(poi['name'] as String),
              );
            }).toList(),
          ),
          DropdownButton<String>(
            hint: Text("Chọn điểm kết thúc"),
            value: endPOI,
            onChanged: (value) {
              setState(() {
                endPOI = value;
              });
            },
            items: poiList.map((poi) {
              return DropdownMenuItem<String>(
                value: poi['name'] as String,
                child: Text(poi['name'] as String),
              );
            }).toList(),
          ),
          ElevatedButton(
            onPressed: _drawRoute,
            child: Text("Vẽ đường"),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(11.957103446948263, 108.4451276943349),
                zoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                if (selectedRoute.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: selectedRoute,
                        color: Colors.red,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
