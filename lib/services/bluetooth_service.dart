import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:chat_de_conversa/services/database_chat.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

final logger = Logger();
final DatabaseChat _dbChat = DatabaseChat();

class BluetoothService with ChangeNotifier {
  bool _isLoading = true;

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

      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.turnOn();
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        FlutterBluePlus.scanResults.listen(
          (results) {
            for (ScanResult r in results) {
              logger.i(
                'Dispositivo encontrado: ${r.device.platformName} (${r.device.remoteId})',
              );
              _saveDevice(r.device);
            }
          },
          onError: (e) {
            logger.e('Erro no scan: $e');
          },
        );
      } else {
        logger.i('Bluetooth não suportado neste dispositivo');
      }
    } catch (e) {
      logger.e('Erro durante inicialização: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveDevice(BluetoothDevice device) async {
    final db = await _dbChat.database;
    final platformName = device.platformName;
    await db.insert('users', {
      'email': 'desconhecido',
      'password': '',
      'name': 'Usuário Desconhecido',
      'bluetoothName': platformName.isNotEmpty
          ? platformName
          : 'Dispositivo Sem Nome',
      'bluetoothIdentifier': device.remoteId.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    logger.i(
      'Dispositivo salvo: ${platformName.isNotEmpty ? platformName : 'Dispositivo Sem Nome'}',
    );
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
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
