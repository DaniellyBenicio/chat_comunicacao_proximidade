import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/nearby_service.dart';
import '../services/database_chat.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String deviceName;
  final String endpointId;

  const ChatScreen({
    super.key,
    required this.deviceName,
    required this.endpointId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  late final DatabaseChat _db;

  Color chatBackground = Colors.white;

  @override
  void initState() {
    super.initState();
    _db = DatabaseChat();
    _loadMessages();

    final service = Provider.of<NearbyService>(context, listen: false);

    service.messageStream.listen((data) {
      if (data['endpointId'] == widget.endpointId) {
        final msg = Message(
          sender: 'them',
          content: data['message'] as String,
          timestamp: data['time'] as DateTime? ?? DateTime.now(),
        );
        _addMessage(msg);
      }
    });
  }

  Future<void> _loadMessages() async {
    final loaded = await _db.getMessagesByEndpoint(widget.endpointId);
    if (mounted) {
      setState(() => _messages = loaded);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _addMessage(Message message) async {
    if (!mounted) return;

    setState(() => _messages.add(message));
    await _db.insertMessage(message, widget.endpointId);

    _scrollToBottom();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    final service = Provider.of<NearbyService>(context, listen: false);

    final message = Message(
      sender: 'me',
      content: text,
      timestamp: DateTime.now(),
    );

    service.sendMessage(widget.endpointId, text);
    _addMessage(message);
    _controller.clear();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return "Hoje";
    if (msgDate == yesterday) return "Ontem";

    return DateFormat('dd/MM/yyyy').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Mudar fundo do chat"),
                onTap: () {
                  Navigator.pop(context);
                  _selectBackgroundColor();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectBackgroundColor() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Escolha o fundo"),
          content: SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _colorOption(Colors.white),
                _colorOption(const Color(0xFFE8F0FE)),
                _colorOption(const Color(0xFFFFF8E1)),
                _colorOption(const Color(0xFFE0F7FA)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => chatBackground = color);
        Navigator.pop(context);
      },
      child: CircleAvatar(radius: 24, backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String initial = widget.deviceName.isNotEmpty
        ? widget.deviceName[0].toUpperCase()
        : "?";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF004E89),
        foregroundColor: Colors.white,

        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Color(0xFF004E89),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.deviceName),
          ],
        ),

        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _openMenu),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: Container(
              color: chatBackground,
              child: _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma mensagem ainda.\nComece o papo!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final current = _messages[index];
                        final isMe = current.sender == 'me';

                        Message? previous;
                        if (index > 0) previous = _messages[index - 1];

                        final showHeader =
                            previous == null ||
                            !_isSameDay(current.timestamp, previous.timestamp);

                        return Column(
                          children: [
                            if (showHeader)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Center(
                                  child: Text(
                                    _formatDayHeader(current.timestamp),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                            Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF004E89)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      current.content,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(current.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),

          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Digite uma mensagem...",
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    mini: true,
                    backgroundColor: const Color(0xFF004E89),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
