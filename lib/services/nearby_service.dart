import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService with ChangeNotifier {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  bool _isAdvertising = false;
  bool _isDiscovering = false;
  final String _serviceId =
      "com.geotalk.app";

  final Map<String, ConnectionInfo> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  final Map<String, String> _endpointNames = {};

  bool get isAdvertising => _isAdvertising;

  Future<void> initialize() async {
    await _requestPermissions();
    await startAdvertising();
    await startDiscovery();
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    try {
      await Nearby().startAdvertising(
        "GeoTalk_${DateTime.now().millisecondsSinceEpoch % 10000}",
        Strategy.P2P_STAR, 
        onConnectionInitiated: (id, info) => _acceptConnection(id, info),
        onConnectionResult: (id, status) {
          print("[Advertising] Connection result: $id => $status");
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) {
          print("[Advertising] Disconnected: $id");
          connectedEndpoints.remove(id);
          discoveredDevices.remove(id);
          _endpointNames.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
      _isAdvertising = true;
      print("[Advertising] Started");
      notifyListeners();
    } catch (e) {
      print("[Advertising] Error: $e");
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await Nearby().stopAdvertising();
    _isAdvertising = false;
    notifyListeners();
    print("[Advertising] Stopped");
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    try {
      await Nearby().startDiscovery(
        "GeoTalk_",
        Strategy.P2P_STAR,
        onEndpointFound: (id, name, serviceId) async {
          print("[Discovery] Endpoint found: $name ($id)");
          _endpointNames[id] = name;
          discoveredDevices[id] = ConnectionInfo(id, name, true);
          notifyListeners();

          await Nearby().requestConnection(
            "GeoTalk_User",
            id,
            onConnectionInitiated: (id, info) => _acceptConnection(id, info),
            onConnectionResult: (id, status) {
              print("[Discovery] Connection result: $id => $status");
              if (status == Status.CONNECTED) {
                connectedEndpoints.add(id);
                notifyListeners();
              }
            },
            onDisconnected: (id) {
              print("[Discovery] Disconnected: $id");
              connectedEndpoints.remove(id);
              discoveredDevices.remove(id);
              notifyListeners();
            },
          );
        },
        onEndpointLost: (id) {
          print("[Discovery] Endpoint lost: $id");
          discoveredDevices.remove(id);
          _endpointNames.remove(id);
          notifyListeners();
        },
        serviceId: _serviceId,
      );
      _isDiscovering = true;
      print("[Discovery] Started");
      notifyListeners();
    } catch (e) {
      print("[Discovery] Error: $e");
    }
  }

  void _acceptConnection(String id, ConnectionInfo info) {
    print("[Connection] Accepting: $id");
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (eid, payload) {
        if (payload.type == PayloadType.BYTES) {
          final msg = String.fromCharCodes(payload.bytes!);
          print("[Payload] Received: $msg");
        }
      },
    );
    connectedEndpoints.add(id);
    notifyListeners();
  }

  Future<void> sendMessage(String endpointId, String message) async {
    await Nearby().sendBytesPayload(
      endpointId,
      Uint8List.fromList(message.codeUnits),
    );
    print("[Payload] Sent: $message to $endpointId");
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
  }

  void disposeService() {
    Nearby().stopAllEndpoints();
    Nearby().stopAdvertising();
    Nearby().stopDiscovery();
    _isAdvertising = false;
    _isDiscovering = false;
    print("[Service] Disposed");
  }
}
