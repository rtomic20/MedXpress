import 'package:flutter/material.dart';
import 'helpers/chatservice.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  final int pacijentId;
  final String filterRole;
  final String title;

  const ChatListPage({
    super.key,
    required this.pacijentId,
    required this.filterRole,
    required this.title,
  });

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Map<String, dynamic>>> _fetch() {
    return ChatServiceHelper.instance.listConversationsByRole(
      pacijentId: widget.pacijentId,
      role: widget.filterRole,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetch());
    await _future;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            final convs = snapshot.data ?? const [];
            if (convs.isEmpty) {
              return const Center(child: Text('Nema razgovora.'));
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: convs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final conv = convs[i];
                final title = (conv['title'] ?? 'Nepoznato').toString();
                final convId = (conv['id'] as num).toInt();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(_initials(title)),
                  ),
                  title: Text(title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          conversationId: convId,
                          senderKorisnikId: widget.pacijentId,
                          title: title,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
