import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stuck_coach_provider.dart';
import '../theme/app_theme.dart';

class StuckCoachScreen extends StatefulWidget {
  const StuckCoachScreen({Key? key}) : super(key: key);

  @override
  State<StuckCoachScreen> createState() => _StuckCoachScreenState();
}

class _StuckCoachScreenState extends State<StuckCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<StuckCoachProvider>().sendMessage(_messageController.text);
      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    // Listen for changes in the provider to scroll down when new messages arrive
    final provider = context.read<StuckCoachProvider>();
    provider.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    context.read<StuckCoachProvider>().removeListener(_scrollToBottom);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach'),
        centerTitle: false,
        titleTextStyle: Theme.of(context).textTheme.headlineLarge,
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return Consumer<StuckCoachProvider>(
      builder: (context, provider, child) {
        if (provider.messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Feeling stuck? Tell me what\'s on your mind.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: provider.messages.length,
          itemBuilder: (context, index) {
            final message = provider.messages[index];
            return _buildChatBubble(message);
          },
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser ? AppTheme.primary : AppTheme.surface;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: alignment,
      child: Card(
        color: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: isUser ? const Radius.circular(AppRadius.lg) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(AppRadius.lg),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
} 