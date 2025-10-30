import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:chat_de_conversa/services/database_chat.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

final logger = Logger();
final DatabaseChat _dbChat = DatabaseChat();

class BluetoothService with ChangeNotifier {
  bool _isLoading = true;
  bool _isEnabled = false;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothService() {
    initialize();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _requestPermissions();
      await _dbChat.database;
      logger.i('Banco de dados inicializado com sucesso');

      _isEnabled = await _bluetooth.isEnabled ?? false;
      if (!_isEnabled) {
        logger.i('Bluetooth desligado, tentando ativar...');
        await _bluetooth.requestEnable();
      }

      List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();
      for (BluetoothDevice device in bondedDevices) {
        logger.i('Dispositivo pareado: ${device.name} (${device.address})');
        await _saveDevice(device);
      }

      _bluetooth
          .startDiscovery()
          .listen((discovery) async {
            logger.i(
              'Encontrado: ${discovery.device.name} (${discovery.device.address})',
            );
            await _saveDevice(discovery.device);
          })
          .onError((error) {
            logger.e('Erro durante descoberta: $error');
          });
    } catch (e) {
      logger.e('Erro durante inicialização: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDevice(BluetoothDevice device) async {
    final db = await _dbChat.database;
    await db.insert('users', {
      'email': 'desconhecido',
      'password': '',
      'name': device.name ?? 'Usuário Desconhecido',
      'bluetoothName': device.name ?? 'Sem Nome',
      'bluetoothIdentifier': device.address,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    logger.i('Dispositivo salvo: ${device.name ?? 'Sem Nome'}');
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      //Permission.location,
    ].request();

    if (statuses.values.any((status) => !status.isGranted)) {
      logger.w('Algumas permissões não foram concedidas');
    }
  }

  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _dbChat.close();
    super.dispose();
  }
}
