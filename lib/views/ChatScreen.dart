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

  Color? _customBackground;

  @override
  void initState() {
    super.initState();
    _db = DatabaseChat();
    _loadMessages();

    final service = Provider.of<NearbyService>(context, listen: false);
    service.messageStream.listen((data) {
      if (data['endpointId'] != widget.endpointId) return;

      final text = data['message'] as String;

      final jaExiste = _messages.any(
        (m) =>
            m.content == text &&
            m.sender == 'them' &&
            DateTime.now().difference(m.timestamp).inSeconds.abs() < 5,
      );

      if (!jaExiste && mounted) {
        final novaMsg = Message(
          sender: 'them',
          content: text,
          timestamp: DateTime.now(),
        );
        setState(() => _messages.add(novaMsg));
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    final loaded = await _db.getMessagesByEndpoint(widget.endpointId);
    if (mounted) {
      setState(() => _messages = loaded);
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();
    final service = Provider.of<NearbyService>(context, listen: false);

    final minhaMensagem = Message(
      sender: 'me',
      content: text,
      timestamp: DateTime.now(),
    );

    service.sendMessage(widget.endpointId, text);

    setState(() {
      _messages.add(minhaMensagem);
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final hoje = DateTime(now.year, now.month, now.day);
    final ontem = hoje.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == hoje) return "Hoje";
    if (d == ontem) return "Ontem";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text("Mudar fundo do chat"),
            onTap: () {
              Navigator.pop(context);
              _chooseBackground();
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: Text("Usar tema padrão"),
            onTap: () {
              setState(() => _customBackground = null);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _chooseBackground() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Fundo do chat"),
        content: SizedBox(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorOption(const Color(0xFF1A1A1A)),
              _colorOption(const Color(0xFFE8F0FE)),
              _colorOption(const Color(0xFFFFF3E0)),
              _colorOption(const Color(0xFFE8F5E8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _customBackground = color);
        Navigator.pop(context);
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: _customBackground == color
            ? const Icon(Icons.check, color: Colors.white)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = _customBackground ?? theme.scaffoldBackgroundColor;

    final inicial = widget.deviceName.isNotEmpty
        ? widget.deviceName[0].toUpperCase()
        : "?";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004E89),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                inicial,
                style: const TextStyle(
                  color: Color(0xFF004E89),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(widget.deviceName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _openMenu,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        "Nenhuma mensagem ainda.\nComece o papo!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final msg = _messages[i];
                        final souEu = msg.sender == 'me';
                        final mostrarData = i == 0 ||
                            !_isSameDay(msg.timestamp, _messages[i - 1].timestamp);

                        return Column(
                          children: [
                            if (mostrarData)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.dividerColor.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatDayHeader(msg.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: souEu ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                decoration: BoxDecoration(
                                  color: souEu
                                      ? const Color(0xFF004E89)
                                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: souEu ? const Radius.circular(18) : const Radius.circular(4),
                                    bottomRight: souEu ? const Radius.circular(4) : const Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: souEu ? Colors.white : (isDark ? Colors.white : Colors.black87),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('HH:mm').format(msg.timestamp),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: souEu
                                            ? Colors.white70
                                            : (isDark ? Colors.white70 : Colors.black54),
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        maxLines: null,
                        minLines: 1,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: "Digite uma mensagem...",
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
                          hintStyle: TextStyle(color: theme.hintColor),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: theme.dividerColor,
                              width: 1.4,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFF004E89),
                              width: 1.8,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      mini: true,
                      backgroundColor: const Color(0xFF004E89),
                      onPressed: _sendMessage,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
