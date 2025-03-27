import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.locationAlways,
    Permission.bluetoothScan, // Nếu cần Bluetooth
    Permission.bluetoothConnect, // Nếu cần Bluetooth
    Permission.bluetooth, // Nếu dùng BLE
  ].request();

  if (statuses[Permission.location]?.isGranted == true &&
      statuses[Permission.locationWhenInUse]?.isGranted == true) {
    debugPrint("Quyền vị trí được cấp!");
  } else {
    debugPrint("Quyền vị trí bị từ chối!");
  }

  if (statuses[Permission.bluetoothScan]?.isGranted == true) {
    debugPrint("Quyền Bluetooth được cấp!");
  }

 
}
Future<void> checkPermissions() async {
  if (await Permission.location.isPermanentlyDenied) {
    openAppSettings();
  }
}
