import 'package:flutter/material.dart';
import 'package:chat_de_conversa/services/nearby_service.dart';
import 'package:chat_de_conversa/views/ChatScreen.dart';
import 'package:provider/provider.dart';

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
          backgroundColor: const Color(0xFF004E89),
          foregroundColor: Colors.white,
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
                builder: (context, service, child) => Switch(
                  value: service.isAdvertising,
                  onChanged: (v) async {
                    if (v) {
                      if (!await service.requestPermissions()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Permissões necessárias!"),
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
              builder: (context, service, child) {
                if (service.discoveredDevices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_find, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Nenhum dispositivo por perto...",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: service.discoveredDevices.length,
                  itemBuilder: (context, i) {
                    final id = service.discoveredDevices.keys.elementAt(i);
                    final name = service.getEndpointDisplayName(id);
                    final isConnected = service.connectedEndpoints.contains(id);
                    final isPending = service.isConnectionPending(id);

                    String statusText;
                    Widget? trailingWidget;
                    Color iconColor;

                    if (isConnected) {
                      statusText = "Conectado";
                      iconColor = Colors.green;
                      trailingWidget = ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(deviceName: name, endpointId: id),
                          ),
                        ),
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text("Chat"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else if (isPending) {
                      statusText = "Aguardando conexão...";
                      iconColor = Colors.orange;
                      trailingWidget = const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      );
                    } else {
                      statusText = "Tocar para conectar";
                      iconColor = Colors.blue;
                      trailingWidget = ElevatedButton(
                        onPressed: () => service.initiateConnection(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Conectar"),
                      );
                    }

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isConnected ? Icons.wifi : Icons.wifi_find,
                          color: iconColor,
                          size: 40,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Text(statusText),
                        trailing: trailingWidget,
                        onTap: isConnected || isPending
                            ? null
                            : () => service.initiateConnection(id),
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
