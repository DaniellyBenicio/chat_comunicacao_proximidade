

import 'package:flutter/material.dart';

class TelaTeste extends StatelessWidget {
  final String userName;

  const TelaTeste({
    super.key,
    required this.userName, // Recebe o nome do usuário
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela de Teste'),
        automaticallyImplyLeading: false, // Opcional: Remove a seta de voltar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo(a),',
              style: TextStyle(fontSize: 24, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            // Exibe o nome do usuário que foi passado
            Text(
              userName,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 40),
            // Botão de exemplo para sair
            ElevatedButton(
              onPressed: () {
                // Navega de volta para a tela de login (ou para o início)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Sair / Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}