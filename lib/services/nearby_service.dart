import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyService with ChangeNotifier {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  static const String _serviceId = "com.geotalk.app";
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  String userDisplayName = "Usuário";

  void setUserName(String name) {
    final newName = name.trim().isEmpty ? "Usuário" : name.trim();
    if (userDisplayName == newName) return;

    userDisplayName = newName;

    for (final id in List.from(connectedEndpoints)) {
      sendMessage(id, "@@NAME@@:$newName");
    }

    if (_isAdvertising) {
      stopAdvertising().then(
        (_) =>
            Future.delayed(const Duration(milliseconds: 400), startAdvertising),
      );
    }

    notifyListeners();
  }

  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final Map<String, ConnectionInfo> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  final Map<String, String> _endpointNames = {};
  final Set<String> _pendingConnections = {};

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  String getEndpointDisplayName(String endpointId) {
    return _endpointNames[endpointId] ?? "Conectando...";
  }

  bool isConnectionPending(String endpointId) {
    return _pendingConnections.contains(endpointId);
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
        serviceId: _serviceId,
        onConnectionInitiated: (id, info) => _onConnectionInitiated(id, info),
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            notifyListeners();
          }
        },
        onDisconnected: (id) => _cleanupEndpoint(id),
      );
      _isAdvertising = true;
      print("[Nearby] Anunciando como: $userDisplayName");
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
        serviceId: _serviceId,
        onEndpointFound: (id, name, serviceId) async {
          if (id == null) return;

          if (!_endpointNames.containsKey(id)) {
            _endpointNames[id] = "Dispositivo Desconhecido"; 
          }

          discoveredDevices[id] = ConnectionInfo(id, _endpointNames[id]!, true);
          notifyListeners();
        },
        onEndpointLost: (id) => _cleanupEndpoint(id),
      );
      _isDiscovering = true;
      print("[Nearby] Buscando dispositivos...");
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro discovery: $e");
    }
  }

  Future<void> _connectTo(String endpointId) async {
    if (connectedEndpoints.contains(endpointId) ||
        isConnectionPending(endpointId))
      return;

    try {
      _pendingConnections.add(endpointId);
      _endpointNames[endpointId] = "Aguardando conexão...";
      notifyListeners();

      await Nearby().requestConnection(
        userDisplayName,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: (id, status) {
          _pendingConnections.remove(id);
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            sendMessage(id, "@@NAME@@:$userDisplayName");
            notifyListeners();
          } else {
            _endpointNames[id] = "Dispositivo Desconhecido";
            notifyListeners();
          }
        },
        onDisconnected: _cleanupEndpoint,
      );
    } catch (e) {
      print("[Nearby] Erro ao conectar: $e");
      _pendingConnections.remove(endpointId);
      _endpointNames[endpointId] = "Dispositivo Desconhecido";
      notifyListeners();
    }
  }

  Future<void> initiateConnection(String endpointId) async {
    await _connectTo(endpointId);
  }

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    print("[Nearby] Conexão aceita com $endpointId");

    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (eid, payload) {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;
        final msg = String.fromCharCodes(payload.bytes!);

        if (msg.startsWith("@@NAME@@:")) {
          final realName = msg.substring(9).trim();
          if (_endpointNames[eid] != realName) {
            _endpointNames[eid] = realName;
            print("[Nearby] Nome recebido: $realName");
            notifyListeners(); 
          }
          return;
        }

        print("[Chat] $eid: $msg");
      },
    );

    _pendingConnections.remove(endpointId);
    connectedEndpoints.add(endpointId);
    _endpointNames[endpointId] ??=
        "Conectando..."; 
    notifyListeners();

    sendMessage(endpointId, "@@NAME@@:$userDisplayName");
  }

  void _cleanupEndpoint(String? id) {
    if (id == null) return;
    connectedEndpoints.remove(id);
    discoveredDevices.remove(id);
    _endpointNames.remove(id);
    _pendingConnections.remove(id);
    notifyListeners();
  }

  Future<void> sendMessage(String endpointId, String message) async {
    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(message.codeUnits),
      );
    } catch (e) {
      print("[Nearby] Erro ao enviar: $e");
    }
  }

  Future<void> stopDiscovery() async {
    if (!_isDiscovering) return;
    await Nearby().stopDiscovery();
    _isDiscovering = false;
    notifyListeners();
  }

  void disposeService() {
    Nearby().stopAllEndpoints();
    stopAdvertising();
    stopDiscovery();
    discoveredDevices.clear();
    connectedEndpoints.clear();
    _endpointNames.clear();
    _pendingConnections.clear();
  }
}
