import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/nearby_service.dart';
import '../models/chat_conversation.dart';
import '../services/database_chat.dart';
import 'package:chat_de_conversa/views/ChatScreen.dart';

class Conversations extends StatefulWidget {
  const Conversations({super.key});

  @override
  State<Conversations> createState() => _ConversationsState();
}

class _ConversationsState extends State<Conversations> {
  String searchText = "";

  Future<bool?> _deleteConversation(
    BuildContext context,
    String endpointId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir conversa?'),
        content: const Text(
          'Todas as mensagens serão apagadas permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = DatabaseChat();
      final database = await db.database;
      await database.delete(
        'messages',
        where: 'endpointId = ?',
        whereArgs: [endpointId],
      );

      final nearbyService = Provider.of<NearbyService>(context, listen: false);
      nearbyService.removeConversation(endpointId);

      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<NearbyService>(context).userDisplayName;
    final isOnline =
        Provider.of<NearbyService>(context).isAdvertising &&
        Provider.of<NearbyService>(context).isDiscovering;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004E89),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 2,
        toolbarHeight: 90,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF004E89),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Usuário' : userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOnline ? Colors.green[200] : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.wifi_tethering, size: 28),
          ),
        ],
      ),

      body: Consumer<NearbyService>(
        builder: (context, nearbyService, child) {
          final conversations = nearbyService.savedConversations;

          final filtered = conversations.where((c) {
            if (searchText.isEmpty) return true;
            return c.displayName.toLowerCase().contains(
                  searchText.toLowerCase(),
                ) ||
                c.lastMessage.toLowerCase().contains(searchText.toLowerCase());
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
                child: TextField(
                  onChanged: (value) {
                    setState(() => searchText = value);
                  },
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: "Buscar conversas...",
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF4A4A4A),
                        width: 1.3,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(
                        color: Color(0xFF004E89),
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma conversa',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final conversation = filtered[index];
                          final isConnected = nearbyService.connectedEndpoints
                              .contains(conversation.endpointId);

                          return Dismissible(
                            key: Key(conversation.endpointId),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete_forever,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            confirmDismiss: (_) => _deleteConversation(
                              context,
                              conversation.endpointId,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 90),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF004E89),
                                      child: Text(
                                        conversation.displayName.isNotEmpty
                                            ? conversation.displayName[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (isConnected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  conversation.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  conversation.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat(
                                        'HH:mm',
                                      ).format(conversation.lastMessageTime),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    if (conversation.unreadCount > 0)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF004E89),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${conversation.unreadCount}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        deviceName: conversation.displayName,
                                        endpointId: conversation.endpointId,
                                      ),
                                    ),
                                  );
                                  nearbyService.markAsRead(
                                    conversation.endpointId,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
