import 'package:flutter/material.dart';
import 'package:chat_de_conversa/views/conversations.dart';
import 'package:chat_de_conversa/views/bluetooth_device.dart';
import 'package:chat_de_conversa/views/settings.dart';

class BottomNavBar extends StatefulWidget {
  final String userName;
  const BottomNavBar({super.key, required this.userName});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _indiceAtual = 0;

  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    _telas = [
      // ABA 0: Tela de Conversas
      Conversations(userName: widget.userName),
      // ABA 1: Tela de Bluetooth (Procurar)
      const SearchDevices(), 
      // ABA 2: Configurações
      const SettingsScreen(), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _indiceAtual, children: _telas),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual,
        onTap: (indice) {
          setState(() {
            _indiceAtual = indice;
          });
        },
        selectedItemColor: const Color(0xFF004E89),
        unselectedItemColor: Colors.grey,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Conversas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching),
            label: 'Procurar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}