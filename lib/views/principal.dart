import 'package:chat_de_conversa/views/login.dart';
import 'package:flutter/material.dart';

class TelaTeste extends StatelessWidget {
  final String userName;

  const TelaTeste({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela Inicial')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo(a),',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              child: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}
