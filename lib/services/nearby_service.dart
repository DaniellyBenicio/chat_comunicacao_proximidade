import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:chat_de_conversa/components/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/nearby_device.dart';
import '../models/chat_conversation.dart';
import '../models/message.dart';
import '../services/database_chat.dart';

class NearbyService with ChangeNotifier {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal() {
    _initDeviceName();
    _loadSavedConversations();
  }

  static const String _serviceId = "com.geotalk.app";
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  String userDisplayName = "";
  bool _isAdvertising = false;
  bool _isDiscovering = false;

  final Map<String, NearbyDevice> discoveredDevices = {};
  final Set<String> connectedEndpoints = {};
  final Map<String, String> _realNames = {};
  final Set<String> _connectionRequested = {};

  final List<ChatConversation> _savedConversations = [];
  List<ChatConversation> get savedConversations =>
      List.unmodifiable(_savedConversations);

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isAdvertising => _isAdvertising;
  bool get isDiscovering => _isDiscovering;

  final DatabaseChat _db = DatabaseChat();

  Future<void> _initDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    final loginName = prefs.getString('userDisplayName');
    if (loginName != null && loginName.isNotEmpty && loginName != "Usuário") {
      userDisplayName = loginName;
    } else {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        userDisplayName = androidInfo.model ?? "Usuário";
      } catch (e) {
        userDisplayName = "Usuário";
      }
      await prefs.setString('userDisplayName', userDisplayName);
    }
    notifyListeners();
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
      permissions.add(Permission.notification);
    }

    final statuses = await permissions.request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
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
    } catch (e) {}
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
    } catch (e) {}
  }

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
      return false;
    }
  }

  bool isConnectingTo(String endpointId) =>
      _connectionRequested.contains(endpointId);

  void _onConnectionInitiated(String id, ConnectionInfo info) async {
    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) async {
        if (payload.type != PayloadType.BYTES || payload.bytes == null) return;

        final messageText = String.fromCharCodes(payload.bytes!);

        if (messageText.startsWith("@@NAME@@:")) {
          final realName = messageText.substring(9);
          _realNames[endpointId] = realName;
          final dev = discoveredDevices[endpointId];
          if (dev != null) {
            discoveredDevices[endpointId] = dev.copyWith(displayName: realName);
            notifyListeners();
          }
          return;
        }

        final receivedMessage = Message(
          sender: 'them',
          content: messageText,
          timestamp: DateTime.now(),
        );

        await _db.insertMessage(receivedMessage, endpointId);

        updateConversation(
          endpointId: endpointId,
          displayName: getDisplayName(endpointId),
          message: messageText,
          isFromMe: false,
        );

        _messageController.add({
          'endpointId': endpointId,
          'message': messageText,
          'time': DateTime.now(),
        });

        // Mostra notificação **sempre**
        NotificationService.showNotification(
          getDisplayName(endpointId),
          messageText,
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 400));
    try {
      await Nearby().sendBytesPayload(
        id,
        Uint8List.fromList(("@@NAME@@:$userDisplayName").codeUnits),
      );
    } catch (e) {
      debugPrint("Erro ao enviar nome do usuário: $e");
    }

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
      final sentMessage = Message(
        sender: 'me',
        content: message,
        timestamp: DateTime.now(),
      );
      await _db.insertMessage(sentMessage, endpointId);
      updateConversation(
        endpointId: endpointId,
        displayName: getDisplayName(endpointId),
        message: message,
        isFromMe: true,
      );
    } catch (e) {
      debugPrint("Erro ao enviar: $e");
    }
  }

  Future<void> _loadSavedConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('saved_conversations');
    if (data != null) {
      final List jsonList = jsonDecode(data);
      _savedConversations.addAll(
        jsonList.map((e) => ChatConversation.fromJson(e)).toList(),
      );
      _savedConversations.sort(
        (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
      );
      notifyListeners();
    }
  }

  Future<void> _saveConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      _savedConversations.map((c) => c.toJson()).toList(),
    );
    await prefs.setString('saved_conversations', jsonString);
  }

  void updateConversation({
    required String endpointId,
    required String displayName,
    required String message,
    required bool isFromMe,
  }) {
    final now = DateTime.now();
    final index = _savedConversations.indexWhere(
      (c) => c.endpointId == endpointId,
    );
    if (index >= 0) {
      final old = _savedConversations[index];
      final newUnreadCount = isFromMe ? 0 : old.unreadCount + 1;

      _savedConversations[index] = old.copyWith(
        lastMessage: message,
        lastMessageTime: now,
        unreadCount: newUnreadCount,
      );
    } else {
      _savedConversations.add(
        ChatConversation(
          endpointId: endpointId,
          displayName: displayName,
          lastMessage: message,
          lastMessageTime: now,
          unreadCount: isFromMe ? 0 : 1,
        ),
      );
    }
    _savedConversations.sort(
      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
    );
    _saveConversations();
    notifyListeners();
  }

  void markAsRead(String endpointId) {
    final index = _savedConversations.indexWhere(
      (c) => c.endpointId == endpointId,
    );
    if (index >= 0 && _savedConversations[index].unreadCount > 0) {
      final conv = _savedConversations[index];
      _savedConversations[index] = conv.copyWith(unreadCount: 0);
      _saveConversations();
      notifyListeners();
    }
  }

  String getDisplayName(String endpointId) {
    return _realNames[endpointId] ??
        discoveredDevices[endpointId]?.displayName ??
        discoveredDevices[endpointId]?.endpointName ??
        "Dispositivo";
  }

  void removeConversation(String endpointId) {
    _savedConversations.removeWhere((c) => c.endpointId == endpointId);
    _saveConversations();
    notifyListeners();
  }

  Future<void> disposeService() async {
    await Nearby().stopAllEndpoints();
    await stopAdvertising();
    await stopDiscovery();
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
}
