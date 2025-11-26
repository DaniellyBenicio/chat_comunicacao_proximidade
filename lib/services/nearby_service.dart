import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nearby_device.dart';

class NearbyService with ChangeNotifier {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal() {
    _initDeviceName();
  }

  static const String _serviceId = "com.geotalk.app";
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  String userDisplayName = "";
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final Map<String, NearbyDevice> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  final Map<String, String> _realNames = {};
  final Set<String> _connectionRequested =
      {}; 

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  Future<bool> connectToDevice(String endpointId) async {
    if (connectedEndpoints.contains(endpointId)) return true;
    if (_connectionRequested.contains(endpointId)) return false;

    _connectionRequested.add(endpointId);
    notifyListeners();

    try {
      await Nearby().requestConnection(
        userDisplayName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          _connectionRequested.remove(id);
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            _updateDeviceConnection(id, true);
          }
          notifyListeners();
        },
        onDisconnected: _cleanupEndpoint,
      );
      return true;
    } catch (e) {
      _connectionRequested.remove(endpointId);
      notifyListeners();
      print("[Nearby] Erro ao conectar com $endpointId: $e");
      return false;
    }
  }

  bool isConnectingTo(String endpointId) =>
      _connectionRequested.contains(endpointId);

  Future<void> _initDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userDisplayName');
    if (savedName != null && savedName.isNotEmpty) {
      userDisplayName = savedName;
    } else {
      userDisplayName = await _getDeviceName();
      await prefs.setString('userDisplayName', userDisplayName);
    }
    notifyListeners();
  }

  Future<String> _getDeviceName() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.model ?? "Usuário";
    } catch (e) {
      return "Usuário";
    }
  }

  Future<bool> requestPermissions() async {
    final permissions = [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ];

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if ((androidInfo.version.sdkInt ?? 0) >= 33) {
      permissions.add(Permission.nearbyWifiDevices);
    }

    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> initialize() async {
    if (!await requestPermissions()) {
      print("[Nearby] Permissões negadas!");
      return;
    }
    if (userDisplayName.isEmpty) await _initDeviceName();

    await startAdvertising();
    await startDiscovery();
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    try {
      await Nearby().startAdvertising(
        userDisplayName,
        _strategy,
        serviceId: _serviceId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            _updateDeviceConnection(id, true);
          }
        },
        onDisconnected: _cleanupEndpoint,
      );
      _isAdvertising = true;
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro advertising: $e");
    }
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    try {
      await Nearby().startDiscovery(
        userDisplayName,
        _strategy,
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) {
          if (id == null) return;
          _realNames[id] = name;

          discoveredDevices[id] = NearbyDevice(
            endpointId: id,
            endpointName: name,
            displayName: _realNames[id] ?? name,
            isAvailable: true,
            isConnected: connectedEndpoints.contains(id),
          );
          notifyListeners();

        },
        onEndpointLost: (id) {
          if (id == null) return;
          if (!connectedEndpoints.contains(id)) {
            discoveredDevices.remove(id);
            _realNames.remove(id);
          } else {
            final dev = discoveredDevices[id];
            if (dev != null) {
              discoveredDevices[id] = dev.copyWith(isAvailable: false);
            }
          }
          notifyListeners();
        },
      );
      _isDiscovering = true;
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro discovery: $e");
    }
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) async {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

        final message = String.fromCharCodes(payload.bytes!);

        if (message.startsWith("@@NAME@@:")) {
          final realName = message.substring(9);
          _realNames[endpointId] = realName;
          final dev = discoveredDevices[endpointId];
          if (dev != null) {
            discoveredDevices[endpointId] = dev.copyWith(displayName: realName);
            notifyListeners();
          }
          return;
        }

        _messageController.add({
          'endpointId': endpointId,
          'message': message,
          'time': DateTime.now(),
        });
      },
      onPayloadTransferUpdate: (endpointId, update) {},
    );

    await Future.delayed(const Duration(milliseconds: 400));
    sendMessage(id, "@@NAME@@:$userDisplayName");

    connectedEndpoints.add(id);
    _updateDeviceConnection(id, true);
  }

  void _updateDeviceConnection(String id, bool connected) {
    final dev = discoveredDevices[id];
    if (dev != null) {
      discoveredDevices[id] = dev.copyWith(isConnected: connected);
      notifyListeners();
    }
  }

  void _cleanupEndpoint(String id) {
    connectedEndpoints.remove(id);
    _connectionRequested.remove(id);
    _updateDeviceConnection(id, false);
  }

  Future<void> sendMessage(String endpointId, String message) async {
    if (!connectedEndpoints.contains(endpointId)) return;
    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(message.codeUnits),
      );
    } catch (e) {
      print("[Erro envio] $e");
    }
  }

  void disposeService() {
    Nearby().stopAllEndpoints();
    stopAdvertising();
    stopDiscovery();
    discoveredDevices.clear();
    connectedEndpoints.clear();
    _realNames.clear();
    _connectionRequested.clear();
    _messageController.close();
  }

  @override
  void dispose() {
    disposeService();
    super.dispose();
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await Nearby().stopAdvertising();
    _isAdvertising = false;
    notifyListeners();
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    await Nearby().stopDiscovery();
    _isDiscovering = false;
    notifyListeners();
  }

  String getDisplayName(String endpointId) {
    return _realNames[endpointId] ??
        discoveredDevices[endpointId]?.displayName ??
        discoveredDevices[endpointId]?.endpointName ??
        "Dispositivo";
  }
}
