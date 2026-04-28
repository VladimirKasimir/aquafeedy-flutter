import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../services/openai_service.dart';
import '../services/user_service.dart';

class AiAgentPage extends StatefulWidget {
  const AiAgentPage({super.key});

  @override
  State<AiAgentPage> createState() => _AiAgentPageState();
}

class _AiAgentPageState extends State<AiAgentPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool loading = false;

  Future<void> send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || loading) return;

    _controller.clear();
    await ChatService.save('user', text);

    setState(() => loading = true);
    _scrollDown();

    try {
      final user = await UserService.getProfile();
      final reply = await OpenAIService.ask(prompt: text, user: user);
      await ChatService.save('assistant', reply);
    } catch (e) {
      await ChatService.save(
        'assistant',
        'Maaf, terjadi kesalahan. Coba lagi ya 🙏',
      );
    }

    setState(() => loading = false);
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      appBar: AppBar(
        title: const Text('Aqua AI 🐟'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService.stream(),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final isUser = d['role'] == 'user';

                    return _ChatBubble(
                      message: d['message'],
                      isUser: isUser,
                    );
                  },
                );
              },
            ),
          ),

          if (loading) const _TypingIndicator(),

          _InputArea(
            controller: _controller,
            loading: loading,
            onSend: send,
          ),
        ],
      ),
    );
  }
}

/* ===========================
   CHAT BUBBLE
=========================== */
class _ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const _ChatBubble({
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2EC4F1),
              child: Icon(Icons.water, color: Colors.white, size: 18),
            ),

          const SizedBox(width: 8),

          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF2EC4F1), Color(0xFF1BA4D6)],
                    )
                  : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                )
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===========================
   TYPING INDICATOR
=========================== */
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFF2EC4F1),
            child: Icon(Icons.water, size: 14, color: Colors.white),
          ),
          SizedBox(width: 8),
          Text(
            "Aqua AI sedang berpikir...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/* ===========================
   INPUT AREA
=========================== */
class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 8, color: Colors.black12),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !loading,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Tanya soal ikan / akuarium...',
                  filled: true,
                  fillColor: const Color(0xFFF3F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Color(0xFF2EC4F1)),
              onPressed: loading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
