import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/nearby_service.dart';
import 'package:chat_de_conversa/views/ChatScreen.dart';

class SearchDevices extends StatelessWidget {
  const SearchDevices({super.key});

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
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Permissões necessárias! Ative todas.",
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meu Dispositivo:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Consumer<NearbyService>(
                builder: (context, service, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    service.userDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF004E89),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 30, thickness: 1),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Consumer<NearbyService>(
              builder: (context, service, _) {
                final devices = service.discoveredDevices.values.toList();

                if (devices.isEmpty) {
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
                  itemCount: devices.length,
                  itemBuilder: (context, i) {
                    final device = devices[i];
                    final id = device.endpointId;
                    final conectado = service.connectedEndpoints.contains(id);
                    final conectando = service.isConnectingTo(id);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 3,
                      child: ListTile(
                        onTap: conectado
                            ? null
                            : () async {
                                final success = await service.connectToDevice(
                                  id,
                                );
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Não foi possível conectar com ${service.getDisplayName(id)}",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        leading: CircleAvatar(
                          backgroundColor: conectado
                              ? Colors.green
                              : (conectando ? Colors.orange : Colors.blue),
                          child: Icon(
                            conectado
                                ? Icons.wifi
                                : (conectando ? Icons.sync : Icons.wifi_find),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          service.getDisplayName(id),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          conectado
                              ? "Conectado"
                              : (conectando
                                    ? "Conectando..."
                                    : "Toque para conectar"),
                          style: TextStyle(
                            color: conectado
                                ? Colors.green
                                : (conectando ? Colors.orange : Colors.grey),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: conectado
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        deviceName: service.getDisplayName(id),
                                        endpointId: id,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.white,
                                ),
                                label: const Text("Chat"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              )
                            : conectando
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 18),
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
