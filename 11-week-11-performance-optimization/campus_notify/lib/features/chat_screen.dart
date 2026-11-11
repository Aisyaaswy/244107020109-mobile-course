import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ai_chat/domain/entities/chat_message.dart';
import 'ai_chat/presentation/providers/ai_chat_provider.dart';

/// Halaman Chat Asisten AI Kampus yang telah dioptimasi performanya:
/// 1. Granular state listening dengan Riverpod `select`
/// 2. Ekstraksi Widget ke class StatelessWidget mandiri dengan `const` constructors
/// 3. RepaintBoundary pada indikator animasi loading chat untuk mengisolasi rendering GPU
/// 4. Tear-offs pada handler callback untuk menghindari pembuatan closure baru tiap frame build
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  static const List<String> _quickPrompts = [
    '📅 Jadwal kuliah semester ini',
    '📝 Tips persiapan ujian UTS/UAS',
    '💡 Cara membuat catatan efektif',
    '🏛️ Lokasi perpustakaan kampus',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend([String? presetText]) async {
    final text = presetText ?? _textController.text;
    if (text.trim().isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    _scrollToBottom();
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    _scrollToBottom();

    // Tampilkan fallback dialog jika ada error
    final currentState = ref.read(aiChatProvider);
    if (currentState.errorMessage != null && mounted) {
      _showFallbackDialog(currentState.errorMessage!);
    }
  }

  void _showFallbackDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Layanan AI Sibuk'),
          ],
        ),
        content: Text(
          'Gagal menghubungi API AI: $error\n\nAplikasi secara otomatis beralih ke Mode Offline untuk memberikan panduan lokal kampus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Gunakan Mode Offline'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showApiKeyDialog();
            },
            child: const Text('Cek API Key'),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final keyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.vpn_key, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Pengaturan API Key'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Google Gemini API Key Anda. Kunci akan disimpan secara aman di Flutter Secure Storage perangkat Anda.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKey = keyController.text.trim();
              if (newKey.isNotEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);
                await ref.read(aiChatProvider.notifier).saveApiKey(newKey);
                if (mounted) {
                  nav.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'API Key berhasil disimpan di Secure Storage!',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _handleClearChat() {
    ref.read(aiChatProvider.notifier).clearChat();
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod select: hanya rebuild jika status hasApiKey berubah
    final hasApiKey = ref.watch(aiChatProvider.select((s) => s.hasApiKey));

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asisten AI Kampus', style: TextStyle(fontSize: 18)),
            Text(
              'Gemini 1.5 Flash • Polinema Assistant',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan API Key',
            icon: Icon(
              hasApiKey ? Icons.vpn_key : Icons.vpn_key_outlined,
              color: hasApiKey ? Colors.lightGreenAccent : null,
            ),
            onPressed: _showApiKeyDialog,
          ),
          IconButton(
            tooltip: 'Bersihkan Percakapan',
            icon: const Icon(Icons.delete_outline),
            onPressed: _handleClearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasApiKey)
            Container(
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'API Key Gemini belum disetel. Jawaban akan menggunakan fallback FAQ offline.',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: _showApiKeyDialog,
                    child: const Text('Setel'),
                  ),
                ],
              ),
            ),

          // Suggested quick prompts: diisolasi agar hanya membaca isLoading
          QuickPromptsBar(
            prompts: _quickPrompts,
            onPromptSelected: _handleSend,
          ),

          const Divider(height: 1),

          // Chat messages list: diisolasi ke widget terpisah
          Expanded(
            child: ChatMessagesListView(
              scrollController: _scrollController,
            ),
          ),

          const Divider(height: 1),

          // Input field: diisolasi agar tidak rebuild saat pesan baru masuk
          ChatInputField(
            textController: _textController,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}

/// Widget barisan chip rekomendasi prompt yang diisolasi
class QuickPromptsBar extends ConsumerWidget {
  const QuickPromptsBar({
    super.key,
    required this.prompts,
    required this.onPromptSelected,
  });

  final List<String> prompts;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod select: hanya rebuild saat status loading berubah
    final isLoading = ref.watch(aiChatProvider.select((s) => s.isLoading));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: prompts.map((prompt) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(prompt, style: const TextStyle(fontSize: 12)),
              onPressed: isLoading ? null : () => onPromptSelected(prompt),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Widget ListView pesan chat yang diisolasi dengan Consumer
class ChatMessagesListView extends ConsumerWidget {
  const ChatMessagesListView({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod select: hanya watch messages dan isLoading
    final messages = ref.watch(aiChatProvider.select((s) => s.messages));
    final isLoading = ref.watch(aiChatProvider.select((s) => s.isLoading));

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          final message = messages[index];
          return ChatMessageBubble(message: message);
        } else {
          // RepaintBoundary: mengisolasi animasi indikator loading AI
          // agar frame berkedip tidak me-repaint seluruh chat history
          return const RepaintBoundary(
            child: ChatLoadingBubble(),
          );
        }
      },
    );
  }
}

/// Ekstraksi Widget Bubble Pesan Chat dengan StatelessWidget mandiri
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isError
                  ? Colors.red.shade100
                  : Colors.indigo.shade100,
              child: Icon(
                message.isError ? Icons.warning_amber : Icons.smart_toy,
                size: 18,
                color: message.isError ? Colors.red : Colors.indigo,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : message.isError
                        ? Colors.red.shade50
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: message.isError
                    ? Border.all(color: Colors.red.shade300)
                    : null,
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isUser
                      ? Colors.white
                      : message.isError
                          ? Colors.red.shade900
                          : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.person, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ekstraksi Widget Indikator Loading Berpikir AI
class ChatLoadingBubble extends StatelessWidget {
  const ChatLoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.indigo.shade100,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.indigo),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'Asisten AI sedang berpikir...',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ekstraksi Widget Input Teks yang diisolasi
class ChatInputField extends ConsumerWidget {
  const ChatInputField({
    super.key,
    required this.textController,
    required this.onSend,
  });

  final TextEditingController textController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod select: hanya perhatikan perubahan status isLoading tombol kirim
    final isLoading = ref.watch(aiChatProvider.select((s) => s.isLoading));

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Tanyakan sesuatu ke AI kampus...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isLoading ? null : onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
