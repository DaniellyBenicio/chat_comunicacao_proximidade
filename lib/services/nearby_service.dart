import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// ============================================
/// MODEL DO DISPOSITIVO
/// ============================================
class NearbyDevice {
  final String endpointId;
  final String endpointName;
  final String displayName;
  final bool isAvailable;
  final bool isConnected;

  NearbyDevice({
    required this.endpointId,
    required this.endpointName,
    this.displayName = "",
    this.isAvailable = true,
    this.isConnected = false,
  });

  NearbyDevice copyWith({
    String? endpointName,
    String? displayName,
    bool? isAvailable,
    bool? isConnected,
  }) {
    return NearbyDevice(
      endpointId: endpointId,
      endpointName: endpointName ?? this.endpointName,
      displayName: displayName ?? this.displayName,
      isAvailable: isAvailable ?? this.isAvailable,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}

/// ============================================
/// SERVIÇO NEARBY - VERSÃO FINAL COM STREAM DE MENSAGENS
/// ============================================
class NearbyService with ChangeNotifier {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  static const String _serviceId = "com.geotalk.app";
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  String userDisplayName = "Usuário";
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final Map<String, NearbyDevice> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  final Map<String, String> _realNames = {};
  final Set<String> _connectionRequested = {};

  // STREAM PARA AS MENSAGENS RECEBIDAS (ESSA É A MÁGICA!)
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  // ============================================================
  // NOME DO DISPOSITIVO
  // ============================================================
  Future<String> _getDeviceName() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.model ?? "Usuário";
    } catch (e) {
      return "Usuário";
    }
  }

  // ============================================================
  // PERMISSÕES + INICIALIZAÇÃO
  // ============================================================
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
    ].request();

    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> initialize() async {
    if (!await requestPermissions()) {
      print("[Nearby] Permissões negadas!");
      return;
    }

    userDisplayName = await _getDeviceName();
    print("[Nearby] Meu nome: $userDisplayName");

    await startAdvertising();
    await startDiscovery();
  }

  // ============================================================
  // ADVERTISING + DISCOVERY
  // ============================================================
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
            _updateDeviceConnection(id, true);
          }
        },
        onDisconnected: (id) => _cleanupEndpoint(id),
      );
      _isAdvertising = true;
      print("[Nearby] Advertising iniciado");
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
          print("[Discovery] Encontrado: $id → $name");
          _realNames[id] = name;

          discoveredDevices[id] = NearbyDevice(
            endpointId: id,
            endpointName: name,
            displayName: _realNames[id] ?? name,
            isAvailable: true,
            isConnected: connectedEndpoints.contains(id),
          );
          notifyListeners();

          if (!connectedEndpoints.contains(id) && !_connectionRequested.contains(id)) {
            _requestConnectionOnce(id);
          }
        },
        onEndpointLost: (id) {
          if (id == null) return;
          if (!connectedEndpoints.contains(id)) {
            discoveredDevices.remove(id);
            _realNames.remove(id);
            notifyListeners();
          } else {
            final dev = discoveredDevices[id];
            if (dev != null) {
              discoveredDevices[id] = dev.copyWith(isAvailable: false);
              notifyListeners();
            }
          }
        },
      );
      _isDiscovering = true;
      print("[Nearby] Discovery iniciado");
      notifyListeners();
    } catch (e) {
      print("[Nearby] Erro discovery: $e");
    }
  }

  void _requestConnectionOnce(String endpointId) async {
    if (_connectionRequested.contains(endpointId)) return;
    _connectionRequested.add(endpointId);

    try {
      await Nearby().requestConnection(
        userDisplayName,
        endpointId,
        onConnectionInitiated: (id, info) => _onConnectionInitiated(id, info),
        onConnectionResult: (id, status) {
          _connectionRequested.remove(id);
          if (status == Status.CONNECTED) {
            connectedEndpoints.add(id);
            _updateDeviceConnection(id, true);
          }
        },
        onDisconnected: (id) => _cleanupEndpoint(id),
      );
    } catch (e) {
      _connectionRequested.remove(endpointId);
    }
  }

  // ============================================================
  // ACEITA CONEXÃO + ENVIA NOME + RECEBE MENSAGENS
  // ============================================================
  void _onConnectionInitiated(String id, ConnectionInfo info) async {
    print("[Nearby] Conexão aceita: $id");

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

        final message = String.fromCharCodes(payload.bytes!);

        // 1. Trata o nome real enviado pelo outro dispositivo
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

        // 2. Mensagem normal → DISPARA PARA A TELA DO CHAT!
        print("[Mensagem recebida] $endpointId: $message");

        _messageController.add({
          'endpointId': endpointId,
          'message': message,
          'time': DateTime.now(),
        });
      },
      onPayloadTransferUpdate: (endpointId, update) {
        if (update.status == PayloadStatus.SUCCESS) {
          print("[Payload] OK → $endpointId");
        }
      },
    );

    // Envia meu nome real
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

  // ============================================================
  // ENVIO DE MENSAGEM
  // ============================================================
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

  // ============================================================
  // LIMPEZA
  // ============================================================
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