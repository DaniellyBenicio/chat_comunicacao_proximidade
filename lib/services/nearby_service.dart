import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService with ChangeNotifier {
  String userDisplayName = "Usuário";
  
  void setUserName(String name) async {
    final newName = name.trim().isEmpty ? "Usuário" : name;
    if (userDisplayName == newName) return;

    userDisplayName = newName;

    if (_isAdvertising) {
      await stopAdvertising();
      if (_isDiscovering) await stopDiscovery();
      await startAdvertising();
      await startDiscovery();
    }

    for (final endpointId in Set.from(connectedEndpoints)) {
      sendMessage(endpointId, "@@NAME@@:$userDisplayName");
    }

    notifyListeners();
  }

  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  static const String _serviceId = "com.geotalk.app";
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final Map<String, ConnectionInfo> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  
  final Map<String, String> _endpointNames = {};

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  String getEndpointDisplayName(String endpointId) {
    return _endpointNames[endpointId] ?? "Conectando...";
  }

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every(
      (s) => s.isGranted || s.isLimited || s.isRestricted,
    );
  }

  Future<void> initialize() async {
    if (!await requestPermissions()) return;
    await startAdvertising();
    await startDiscovery();
  }

  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    try {
      await Nearby().startAdvertising(
        userDisplayName,
        _strategy,
        onConnectionInitiated: (id, info) => _onConnectionInitiated(id, info),
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) => _cleanupEndpoint(id),
        serviceId: _serviceId,
      );
      _isAdvertising = true;
      print("[Nearby] Advertising como: $userDisplayName");
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro advertising: $e");
    }
  }

  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;
    await Nearby().stopAdvertising();
    _isAdvertising = false;
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    try {
      await Nearby().startDiscovery(
        userDisplayName,
        _strategy,
        onEndpointFound: (id, name, serviceId) async {
          if (id == null) return;

          print("[Discovery] Encontrado endpoint: $id (nome temporário: $name)");

          if (!_endpointNames.containsKey(id) || _endpointNames[id] == name) {
            _endpointNames[id] = name;
          }

          discoveredDevices[id] = ConnectionInfo(id, _endpointNames[id]!, true);
          notifyListeners();

          if (!connectedEndpoints.contains(id)) {
            await Nearby().requestConnection(
              userDisplayName,
              id,
              onConnectionInitiated: (endpointId, info) => _onConnectionInitiated(endpointId, info),
              onConnectionResult: (endpointId, status) {
                if (status == Status.CONNECTED) {
                  connectedEndpoints.add(endpointId);
                  notifyListeners();
                }
              },
              onDisconnected: (endpointId) {
                if (endpointId != null) _cleanupEndpoint(endpointId);
              },
            );
          }
        },
        onEndpointLost: (id) {
          if (id != null) _cleanupEndpoint(id);
        },
        serviceId: _serviceId,
      );
      _isDiscovering = true;
      print("[Nearby] Discovery iniciado");
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro discovery: $e");
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    await Nearby().stopDiscovery();
    _isDiscovering = false;
    notifyListeners();
  }

  void _onConnectionInitiated(String id, ConnectionInfo info) async {
    print("[Nearby] Conexão iniciada com $id");

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final message = String.fromCharCodes(payload.bytes!);

          if (message.startsWith("@@NAME@@:")) {
            final realName = message.substring(9);
            _endpointNames[endpointId] = realName;
            print("[Nearby] Nome real recebido: $realName");
            notifyListeners();
            return;
          }

          print("[Payload] Mensagem de $endpointId: $message");
        }
      },
      onPayloadTransferUpdate: (endpointId, update) {
        if (update.status == PayloadStatus.SUCCESS) {
          print("[Payload] Transferência concluída: $endpointId");
        }
      },
    );

    await Future.delayed(const Duration(milliseconds: 600));
    sendMessage(id, "@@NAME@@:$userDisplayName");

    connectedEndpoints.add(id);
    notifyListeners();
  }

  void _cleanupEndpoint(String id) {
    connectedEndpoints.remove(id);
    discoveredDevices.remove(id);
    _endpointNames.remove(id);
    notifyListeners();
  }

  Future<void> sendMessage(String endpointId, String message) async {
    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(message.codeUnits),
      );
    } catch (e) {
      print("[Payload] Erro ao enviar: $e");
    }
  }

  void disposeService() {
    Nearby().stopAllEndpoints();
    stopAdvertising();
    stopDiscovery();
    discoveredDevices.clear();
    connectedEndpoints.clear();
    _endpointNames.clear();
  }
}