import 'dart:async';
import 'package:flutter/material.dart';
import 'helpers/chatservice.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final int senderKorisnikId;
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.senderKorisnikId,
    required this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;

  Timer? _poller; // (opcionalno) lagano osvježavanje

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // svake 5s lagano osvježi (možeš maknuti ako ne treba)
    _poller = Timer.periodic(
        const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  @override
  void dispose() {
    _poller?.cancel();
    _controller.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    final msgs =
        await ChatServiceHelper.instance.fetchMessages(widget.conversationId);
    // Očekujem da svaka poruka ima 'created_at' (ISO string) i 'sender_korisnik_id' i 'body'
    msgs.sort((a, b) {
      final ad = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
          DateTime.now();
      final bd = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
          DateTime.now();
      return ad.compareTo(bd);
    });

    if (!mounted) return;
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollDown();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    await ChatServiceHelper.instance.sendMessage(
      conversationId: widget.conversationId,
      senderKorisnikId: widget.senderKorisnikId,
      body: text,
    );

    await _loadMessages(silent: true);
    setState(() => _sending = false);
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ───────────────────────── UI helpers ─────────────────────────

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year}.';
  }

  bool _isNewDay(DateTime prev, DateTime curr) {
    return prev.year != curr.year ||
        prev.month != curr.month ||
        prev.day != curr.day;
  }

  Widget _dateChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
          ),
          child:
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _bubble({
    required bool isMine,
    required String text,
    required DateTime time,
  }) {
    final bg = isMine ? const Color(0xFF1A73E8) : Colors.grey.shade200;
    final fg = isMine ? Colors.white : Colors.black87;
    final align = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          decoration:
              BoxDecoration(color: bg, borderRadius: radius, boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(text,
                  style: TextStyle(color: fg, fontSize: 15, height: 1.25)),
              const SizedBox(height: 4),
              Text(_formatTime(time),
                  style: TextStyle(color: fg.withOpacity(0.8), fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────── BUILD ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(widget.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _loadMessages(silent: true),
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.only(top: 10, bottom: 12),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final isMine = msg['sender_korisnik_id'] ==
                            widget.senderKorisnikId;
                        final body = (msg['body'] ?? '').toString();
                        final ts = DateTime.tryParse(
                                msg['created_at']?.toString() ?? '') ??
                            DateTime.now();

                        // date separator
                        if (i == 0) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _dateChip(_formatDate(ts)),
                              _bubble(isMine: isMine, text: body, time: ts),
                            ],
                          );
                        } else {
                          final prev = DateTime.tryParse(
                                  _messages[i - 1]['created_at']?.toString() ??
                                      '') ??
                              ts;
                          final needChip = _isNewDay(prev, ts);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (needChip) _dateChip(_formatDate(ts)),
                              _bubble(isMine: isMine, text: body, time: ts),
                            ],
                          );
                        }
                      },
                    ),
                  ),
          ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: const InputDecoration(
                          hintText: 'Upiši poruku…',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      onPressed: _sending || _controller.text.trim().isEmpty
                          ? null
                          : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: _sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
