import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe; // Para saber se a mensagem é enviada por 'mim' (remetente)

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Alinha o balão de mensagem para a esquerda (destinatário) ou direita (remetente)
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          // Define a cor do balão: azul claro para o remetente, cinza claro para o destinatário
          color: isMe ? const Color(0xFFC5E1F5) : const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            // Cantos de baixo diferentes para dar o "bico" do balão
            bottomLeft: !isMe ? const Radius.circular(3) : const Radius.circular(15),
            bottomRight: isMe ? const Radius.circular(3) : const Radius.circular(15),
          ),
        ),
        // Adiciona a hora e o checkmark de envio
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    // Formato HH:mm com zero padding
                    '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', 
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10.0,
                    ),
                  ),
                  if (isMe) // Apenas remetente tem o checkmark
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.done_all, // Dois checks
                        size: 14.0,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ChatScreen extends StatefulWidget {
  final String deviceName;

  const ChatScreen({super.key, required this.deviceName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();


  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        messages.add({'text': _controller.text, 'isMe': true});
        _controller.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0, 
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _buildInputBar() {
    final isTextEmpty = _controller.text.isEmpty;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attachment_rounded, color: Colors.grey),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        setState(() {}); 
                      },
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor, 
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                isTextEmpty ? Icons.mic : Icons.send, 
                color: Colors.white,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          '09/10/2025',
          style: TextStyle(color: Colors.black54, fontSize: 12.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Botão de voltar (leading)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Título com ícone de perfil e nome
        title: Row(
          children: [
            // Ícone de Perfil 
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
            // Nome do Contato
            Text(
              widget.deviceName, 
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
        ],
      ),
      body: Column(
        children: [
          _buildDateSeparator(), 
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true, 
              padding: const EdgeInsets.only(bottom: 5.0), 
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final int messageIndex = messages.length - 1 - index;
                final messageData = messages[messageIndex];

                return MessageBubble(
                  message: messageData['text'],
                  isMe: messageData['isMe'],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}