import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/theme.dart';
import 'package:siparis_app/services/api_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final TextEditingController _messageController = TextEditingController();
  final Map<int, TextEditingController> _commentControllers = {};
  List<dynamic> posts = [];
  Map<int, List<dynamic>> commentsMap = {};
  Map<int, bool> isCommentsVisible = {};
  Set<int> postingCommentIds = {};
  int?
  currentUserId; // Kullanıcının kendi ID'si (Sadece UI kontrolü için tutulacak)
  bool isPostingMessage = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    loadUserAndPosts();
  }

  void showSnackBar(String message, {Color? bgColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: bgColor ?? AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> loadUserAndPosts() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getInt('user_id');
    await fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response = await _apiService.get('api/community');

    if (response.statusCode == 200) {
      setState(() {
        posts = json.decode(response.body);
        commentsMap.clear();
      });
    } else {
      // Bu hata kodu 401 veya 500 olabilir.
      // Hatanın detayını alıp göstermek, teşhisi kolaylaştırır.
      String errorDetail = 'Bilinmeyen Hata';
      try {
        final data = json.decode(response.body);
        errorDetail = data['error'] ?? data['message'] ?? 'Sunucu Hatası';
      } catch (_) {}

      showSnackBar(
        'Postlar yüklenemedi. Hata: ${response.statusCode} (${errorDetail})',
        bgColor: Colors.red,
      );
    }
  }

  Future<void> fetchComments(int postId) async {
    final response = await _apiService.get('api/community/$postId/comments');

    if (response.statusCode == 200) {
      setState(() {
        commentsMap[postId] = json.decode(response.body);
      });
    }
  }

  Future<void> postMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => isPostingMessage = true);

    final response = await _apiService.post(
      'api/community',
      {'body': message}, // 'message' yerine 'body' gönderildi
    );

    setState(() => isPostingMessage = false);

    if (response.statusCode == 201) {
      _messageController.clear();
      await fetchPosts();
      showSnackBar('Mesaj gönderildi!');
    } else {
      showSnackBar(
        'Mesaj gönderilemedi! Hata: ${response.statusCode}',
        bgColor: Colors.red,
      );
    }
  }

  Future<void> toggleLike(int postId) async {
    final response = await _apiService.post(
      'api/community/$postId/like',
      {}, // Boş body gönderilir
    );

    if (response.statusCode == 200) {
      final liked = json.decode(response.body)['liked'];
      setState(() {
        final index = posts.indexWhere((p) => p['id'] == postId);
        if (index != -1) {
          posts[index]['isLiked'] = liked ? 1 : 0;
          posts[index]['like_count'] =
              (posts[index]['like_count'] ?? 0) + (liked ? 1 : -1);
        }
      });
    } else {
      showSnackBar('Beğeni işlemi başarısız!', bgColor: Colors.red);
    }
  }

  Future<void> editPost(int postId, String oldBody) async {
    final controller = TextEditingController(text: oldBody);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Mesajı Düzenle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(hintText: 'Yeni mesaj'),
        ),
        actions: [
          TextButton(
            child: Text('İptal', style: Theme.of(context).textTheme.bodyMedium),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Kaydet'),
            onPressed: () async {
              final newBody = controller.text.trim();
              if (newBody.isNotEmpty) {
                final response = await _apiService.put('api/community/$postId', {
                  'body': newBody,
                  // Backend'in beklediği diğer alanları mevcut posttan alıp gönderiyoruz:
                  'title':
                      posts.firstWhere((p) => p['id'] == postId)['title'] ?? '',
                  'is_public':
                      posts.firstWhere((p) => p['id'] == postId)['is_public'] ??
                      1,
                  'image_url':
                      posts.firstWhere((p) => p['id'] == postId)['image_url'] ??
                      null,
                });
                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  await fetchPosts();
                  showSnackBar('Mesaj güncellendi!');
                } else {
                  showSnackBar('Güncelleme başarısız!', bgColor: Colors.red);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deletePost(int postId) async {
    print('DEBUG: Silme çağrısı yapılıyor Post ID: $postId');
    final response = await _apiService.delete('api/community/$postId');

    if (response.statusCode == 200) {
      await fetchPosts();
      showSnackBar('Mesaj silindi!');
    } else {
      showSnackBar('Silme yetkiniz yok veya hata oluştu.', bgColor: Colors.red);
    }
  }

  Future<void> postComment(int postId) async {
    final content = _commentControllers[postId]?.text.trim();
    if (content == null || content.isEmpty) return;

    setState(() => postingCommentIds.add(postId));

    final response = await _apiService.post('api/community/$postId/comment', {
      'content': content,
    });

    if (response.statusCode == 201) {
      _commentControllers[postId]?.clear();
      await fetchComments(postId);
      showSnackBar('Yorum eklendi!');
    } else {
      showSnackBar('Yorum eklenemedi!', bgColor: Colors.red);
    }

    setState(() => postingCommentIds.remove(postId));
  }

  Future<void> editComment(int commentId, int postId, String oldContent) async {
    final controller = TextEditingController(text: oldContent);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Yorumu Düzenle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(hintText: 'Yeni yorum'),
        ),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Kaydet'),
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                // Backend endpoint: /api/community/:postId/comments/:commentId
                final response = await _apiService.put(
                  'api/community/$postId/comments/$commentId',
                  {
                    'content':
                        newContent, // Backend'e sadece content gönderilir
                  },
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  await fetchComments(postId); // Yorumları yeniden yükle
                  showSnackBar('Yorum güncellendi!');
                } else {
                  showSnackBar(
                    'Düzenleme yetkiniz yok veya hata oluştu.',
                    bgColor: Colors.red,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> deleteComment(int commentId, int postId) async {
    final response = await _apiService.delete(
      'api/community/comment/$commentId',
    );

    if (response.statusCode == 200) {
      await fetchComments(postId);
      showSnackBar('Yorum silindi!');
    } else {
      showSnackBar(
        'Yorum silme yetkiniz yok veya hata oluştu.',
        bgColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Topluluk",
          style: textTheme.titleLarge?.copyWith(color: Colors.white),
        ),

        backgroundColor: theme.primaryColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final post = posts[index];
                final postId = post['id'];
                _commentControllers.putIfAbsent(
                  postId,
                  () => TextEditingController(),
                );

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kullanıcı adı + düzenle/sil
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            child: Text(
                              post['author_name'] ?? 'Misafir',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          if (post['user_id'] == currentUserId)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 18,
                                    color: theme.iconTheme.color,
                                  ),
                                  onPressed: () =>
                                      editPost(postId, post['body']),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    size: 18,
                                    color: theme.iconTheme.color,
                                  ),
                                  onPressed: () => deletePost(postId),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(post['body'] ?? '', style: textTheme.bodyMedium),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: IconButton(
                              key: ValueKey(post['isLiked']),
                              icon: Icon(
                                post['isLiked'] == 1
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: post['isLiked'] == 1
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () => toggleLike(postId),
                            ),
                          ),
                          Text(
                            '${post['like_count'] ?? 0}',
                            style: textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              if (isCommentsVisible[postId] == true) {
                                setState(
                                  () => isCommentsVisible[postId] = false,
                                );
                              } else {
                                await fetchComments(postId);
                                setState(
                                  () => isCommentsVisible[postId] = true,
                                );
                              }
                            },
                            child: Text(
                              isCommentsVisible[postId] == true
                                  ? 'Yorumları Gizle'
                                  : 'Yorumlar',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child:
                            (commentsMap[postId] != null &&
                                (isCommentsVisible[postId] ?? false))
                            ? Column(
                                children: [
                                  const Divider(),
                                  ...commentsMap[postId]!.map((comment) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.comment, size: 16),
                                          const SizedBox(width: 6),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                RichText(
                                                  text: TextSpan(
                                                    style: textTheme.bodyMedium,
                                                    children: [
                                                      TextSpan(
                                                        text:
                                                            '${comment['author_name'] ?? 'Misafir'}: ',
                                                        style: textTheme
                                                            .bodyMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                      ),
                                                      TextSpan(
                                                        text:
                                                            comment['content'],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (comment['user_id'] ==
                                                    currentUserId)
                                                  Row(
                                                    children: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            deleteComment(
                                                              comment['id'],
                                                              postId,
                                                            ),
                                                        child: const Text(
                                                          "Sil",
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            editComment(
                                                              comment['id'],
                                                              postId,
                                                              comment['content'],
                                                            ),
                                                        child: const Text(
                                                          "Düzenle",
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller:
                                              _commentControllers[postId],
                                          style: textTheme.bodyMedium,
                                          decoration: InputDecoration(
                                            hintText: 'Yorum yaz...',
                                            hintStyle: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: theme.hintColor,
                                                ),
                                            filled: true,
                                            fillColor: theme.cardColor,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: postingCommentIds.contains(postId)
                                            ? SizedBox(
                                                height: 18,
                                                width: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.send,
                                                color: AppTheme.primaryColor,
                                              ),
                                        onPressed:
                                            postingCommentIds.contains(postId)
                                            ? null
                                            : () => postComment(postId),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Mesaj yazma kutusu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Bir şeyler yaz...',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: AppTheme.primaryColor),
                  onPressed: isPostingMessage ? null : postMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
