import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/cooking_assistant_controller.dart';
import '../models/chat_message.dart';
import '../models/recipe.dart';

class CookingAssistantView extends StatefulWidget {
  final Recipe recipe;

  const CookingAssistantView({super.key, required this.recipe});

  @override
  State<CookingAssistantView> createState() => _CookingAssistantViewState();
}

class _CookingAssistantViewState extends State<CookingAssistantView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CookingAssistantController>().initializeChat(widget.recipe);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    context.read<CookingAssistantController>().sendMessage(text);
    _textController.clear();
    
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('요리 도우미'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRecipeInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CookingAssistantController>(
              builder: (context, controller, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final message = controller.messages[index];
                    return _MessageBubble(message: message);
                  },
                );
              },
            ),
          ),
          _buildQuickQuestions(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final questions = [
      '이 재료 대신 뭘 써도 돼?',
      '조리 시간을 줄이려면?',
      '양을 2배로 늘리려면?',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(questions[index]),
            onPressed: () {
              context.read<CookingAssistantController>()
                  .addQuickQuestion(questions[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<CookingAssistantController>(
      builder: (context, controller, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '궁금한 점을 물어보세요...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !controller.isLoading,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: controller.isLoading ? null : _sendMessage,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: controller.isLoading
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
        );
      },
    );
  }

  void _showRecipeInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text('조리시간: ${widget.recipe.durationMinutes}분'),
            if (widget.recipe.servings != null)
              Text('인분: ${widget.recipe.servings}'),
            if (widget.recipe.difficulty != null)
              Text('난이도: ${widget.recipe.difficulty}'),
            const SizedBox(height: 16),
            const Text('재료:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...widget.recipe.ingredients.map((i) => Text('• $i')),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;
    final colorScheme = Theme.of(context).colorScheme;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? colorScheme.primaryContainer
                : message.isError
                    ? colorScheme.errorContainer
                    : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: isUser
                  ? colorScheme.onPrimaryContainer
                  : message.isError
                      ? colorScheme.onErrorContainer
                      : colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
