import 'package:chat_de_conversa/styles/message_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// VIEW: BLUETOOTH DESLIGADO
class BluetoothOffView extends StatelessWidget {
  const BluetoothOffView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bluetooth_disabled, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            'Bluetooth desligado!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Ative o Bluetooth para procurar dispositivos próximos.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// VIEW: BLUETOOTH LIGADO
class BluetoothOnView extends StatefulWidget {
  const BluetoothOnView({super.key});

  @override
  State<BluetoothOnView> createState() => _BluetoothOnViewState();
}

class _BluetoothOnViewState extends State<BluetoothOnView> {
  List<BluetoothDiscoveryResult> _devicesList = [];
  bool _isDiscovering = false;
  String? _pairingDeviceAddress;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    setState(() {
      _devicesList.clear();
      _isDiscovering = true;
    });

    FlutterBluetoothSerial.instance
        .startDiscovery()
        .listen((result) {
          setState(() {
            final index = _devicesList.indexWhere(
              (e) => e.device.address == result.device.address,
            );
            if (index >= 0) {
              _devicesList[index] = result;
            } else {
              _devicesList.add(result);
            }
          });
        })
        .onDone(() {
          setState(() => _isDiscovering = false);
        });
  }

  Future<void> _pairDevice(BuildContext context, BluetoothDevice device) async {
    setState(() => _pairingDeviceAddress = device.address);

    try {
      final bonded =
          (await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
            device.address,
          )) ??
          false;

      if (bonded) {
        showCustomSnackBar(
          context,
          'Pareamento bem-sucedido com ${device.name ?? "dispositivo"}',
        );
      } else {
        showCustomSnackBar(
          context,
          'Falha ao parear com ${device.name ?? "dispositivo"}',
          isError: true,
        );
      }
    } catch (e) {
      showCustomSnackBar(context, 'Erro ao tentar parear: $e', isError: true);
    } finally {
      setState(() => _pairingDeviceAddress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nome do meu dispositivo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String?>(
            future: FlutterBluetoothSerial.instance.name,
            builder: (context, snapshot) {
              final localName = snapshot.data ?? "Desconhecido";
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(localName, style: const TextStyle(fontSize: 18)),
                    const Icon(Icons.bluetooth, color: Colors.blue),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dispositivos próximos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_isDiscovering)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _devicesList.isEmpty && !_isDiscovering
                ? const Center(
                    child: Text(
                      'Nenhum dispositivo encontrado.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _devicesList.length,
                    itemBuilder: (context, index) {
                      final result = _devicesList[index];
                      return DeviceTile(
                        result: result,
                        isPairing:
                            _pairingDeviceAddress == result.device.address,
                        onPair: () => _pairDevice(context, result.device),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDiscovering ? null : _startDiscovery,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004E89),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Atualizar',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class DeviceTile extends StatelessWidget {
  final BluetoothDiscoveryResult result;
  final bool isPairing;
  final VoidCallback onPair;

  const DeviceTile({
    super.key,
    required this.result,
    required this.isPairing,
    required this.onPair,
  });

  @override
  Widget build(BuildContext context) {
    final device = result.device;

    Color statusColor;
    String statusText;

    if (device.isConnected == true) {
      statusColor = Colors.green;
      statusText = 'Conectado';
    } else if (device.isBonded) {
      statusColor = Colors.blue;
      statusText = 'Pareado';
    } else {
      statusColor = Colors.grey;
      statusText = 'Não pareado';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.devices, color: statusColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.name ?? "Sem nome",
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            if (isPairing)
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Pareando...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text('${device.address}\n$statusText'),
        isThreeLine: true,
        onTap: device.isBonded ? null : onPair,
      ),
    );
  }
}


class SearchDevices extends StatefulWidget {
  const SearchDevices({super.key});

  @override
  State<SearchDevices> createState() => _SearchDevicesState();
}

class _SearchDevicesState extends State<SearchDevices> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  @override
  void initState() {
    super.initState();
    _getBluetoothState();
    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      setState(() => _bluetoothState = state);
    });
  }

  Future<void> _getBluetoothState() async {
    final state = await FlutterBluetoothSerial.instance.state;
    setState(() => _bluetoothState = state);
  }

  Future<void> _toggleBluetooth(bool value) async {
    if (value) {
      await FlutterBluetoothSerial.instance.requestEnable();
    } else {
      _showDisableAlert();
    }
  }

  void _showDisableAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desligar Bluetooth'),
        content: const Text(
          'Por segurança, o app não pode desligar o Bluetooth automaticamente.\n\n'
          'Desligue manualmente nas configurações do dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBluetoothOn = _bluetoothState == BluetoothState.STATE_ON;
    final body = isBluetoothOn
        ? const BluetoothOnView()
        : const BluetoothOffView();

    return Column(
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Conexões',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
          ),
          centerTitle: true,
          elevation: 2,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bluetooth',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Switch(
                value: isBluetoothOn,
                onChanged: _toggleBluetooth,
                activeColor: const Color(0xFF004E89),
              ),
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
