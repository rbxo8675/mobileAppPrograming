import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../data/repositories/feed_repository.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({super.key, required this.postId, required this.initialCommentCount});
  final String postId;
  final int initialCommentCount;

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  final _feedRepo = FeedRepository();
  final _textController = TextEditingController();
  List<Comment> _comments = [];
  bool _loading = true;
  Comment? _editingComment;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final comments = await _feedRepo.getComments(widget.postId);
      setState(() {
        _comments = comments;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글을 불러오는데 실패했습니다')),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      final comment = await _feedRepo.addComment(widget.postId, text);
      setState(() {
        _comments.add(comment);
        _textController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 작성에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _updateComment(Comment comment) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await _feedRepo.updateComment(comment.id, text);
      setState(() {
        final idx = _comments.indexWhere((c) => c.id == comment.id);
        if (idx != -1) {
          _comments[idx] = comment.copyWith(text: text);
        }
        _editingComment = null;
        _textController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 수정에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await _feedRepo.deleteComment(comment.id);
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('댓글 삭제에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _reportComment(Comment comment) async {
    try {
      await _feedRepo.reportComment(comment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고에 실패했습니다')),
        );
      }
    }
  }

  void _startEdit(Comment comment) {
    setState(() {
      _editingComment = comment;
      _textController.text = comment.text;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingComment = null;
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('댓글 ${_comments.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? const Center(child: Text('첫 댓글을 작성해보세요'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final comment = _comments[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(comment.userName.characters.first),
                            ),
                            title: Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(comment.text),
                                const SizedBox(height: 4),
                                Text(comment.timeAgo, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            trailing: comment.isMine
                                ? PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('수정'),
                                        onTap: () => _startEdit(comment),
                                      ),
                                      PopupMenuItem(
                                        child: const Text('삭제'),
                                        onTap: () => _deleteComment(comment),
                                      ),
                                    ],
                                  )
                                : PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('신고'),
                                        onTap: () => _reportComment(comment),
                                      ),
                                    ],
                                  ),
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_editingComment != null) ...[
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _cancelEdit,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: _editingComment != null ? '댓글 수정...' : '댓글 작성...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_editingComment != null) {
                        _updateComment(_editingComment!);
                      } else {
                        _addComment();
                      }
                    },
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
