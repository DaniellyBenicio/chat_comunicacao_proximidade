import 'package:chat_de_conversa/views/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// O widget principal (Conversations) será usado como a ABA 0 do menu.
// Ele precisa ser um StatefulWidget para gerenciar o estado do Bluetooth.
class Conversations extends StatefulWidget {
  final String userName;

  const Conversations({super.key, required this.userName});

  @override
  State<Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  bool _bluetoothOn = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothStatus();
    FlutterBluetoothSerial.instance.onStateChanged().listen((
      BluetoothState state,
    ) {
      setState(() {
        _bluetoothOn = state == BluetoothState.STATE_ON;
      });
    });
  }

  Future<void> _checkBluetoothStatus() async {
    bool isOn = await FlutterBluetoothSerial.instance.isEnabled ?? false;
    setState(() {
      _bluetoothOn = isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Retorna APENAS o corpo e o AppBar, SEM o Scaffold.
    // O Scaffold será fornecido pelo BottomNavBar.

    return Column( // Use Column como o widget principal, pois é o conteúdo do Body
      children: [
        // Adiciona o AppBar como um widget regular, mas com um Container para estilizá-lo
        AppBar(
          title: const Text('Tela Inicial'),
          automaticallyImplyLeading: false,
        ),
        
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seu código de Avatar/Status/Busca aqui
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      child: Text(
                        widget.userName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF004E89),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _bluetoothOn ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _bluetoothOn
                                  ? 'Disponível via Bluetooth'
                                  : 'Bluetooth desligado',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Buscar minhas conexões...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Login()),
                      );
                    },
                    child: const Text('Sair'),
                  ),
                ),
                // O restante do conteúdo da aba de conversas
              ],
            ),
          ),
        ),
      ],
    );
  }
}