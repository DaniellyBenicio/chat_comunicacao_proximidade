import 'package:flutter/material.dart';
import 'package:chat_de_conversa/views/conversations.dart';

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
      Conversations(userName: widget.userName),
      const Placeholder(), // Bluetooth
      const Placeholder(), // Configurações
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
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF004E89),
        unselectedItemColor: Colors.grey,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Bluetooth',
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
