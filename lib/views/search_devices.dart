import 'package:flutter/material.dart';
import 'package:chat_de_conversa/services/nearby_service.dart';
import 'package:chat_de_conversa/views/ChatScreen.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchDevices extends StatelessWidget {
  const SearchDevices({super.key});

  Future<bool> _requestPermissions(BuildContext context) async {
    var statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Conexões',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
          ),
          centerTitle: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tornar-me visível',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Consumer<NearbyService>(
                builder: (context, service, _) => Switch(
                  value: service.isAdvertising,
                  onChanged: (v) async {
                    if (v) {
                      final granted = await service.requestPermissions();
                      if (!granted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Permissões necessárias! Ative todas."),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      await service.startAdvertising();
                      await service.startDiscovery();
                    } else {
                      await service.stopAdvertising();
                      await service.stopDiscovery();
                    }
                  },
                  activeColor: const Color(0xFF004E89),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Consumer<NearbyService>(
              builder: (context, service, _) {
                if (service.discoveredDevices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_find, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum dispositivo por perto...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: service.discoveredDevices.length,
                  itemBuilder: (context, i) {
                    final id = service.discoveredDevices.keys.elementAt(i);
                    final info = service.discoveredDevices[id]!;
                    final conectado = service.connectedEndpoints.contains(id);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          conectado ? Icons.wifi : Icons.wifi_find,
                          color: conectado ? Colors.green : Colors.blue,
                          size: 40,
                        ),
                        title: Text(service.getEndpointDisplayName(id)),
                        subtitle: Text(
                          conectado ? "Conectado" : "Conectando...",
                        ),
                        trailing: conectado
                            ? ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      deviceName: service.getEndpointDisplayName(id),
                                      endpointId: id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                ),
                                label: const Text("Chat"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              )
                            : const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
