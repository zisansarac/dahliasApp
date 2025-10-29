import 'dart:convert';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siparis_app/theme.dart';

class WomenChallengePage extends StatefulWidget {
  const WomenChallengePage({super.key});

  @override
  State<WomenChallengePage> createState() => _WomenChallengePageState();
}

class _WomenChallengePageState extends State<WomenChallengePage> {
  List<Map<String, dynamic>> _challenges = [];
  final TextEditingController _addController = TextEditingController();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 1),
  );

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  @override
  void dispose() {
    _addController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // ---------- Storage ----------
  Future<void> _loadChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('challenges_v2');
    if (saved != null) {
      final List decoded = jsonDecode(saved);
      setState(() {
        _challenges = decoded
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    }
  }

  Future<void> _saveChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('challenges_v2', jsonEncode(_challenges));
  }

  // ---------- CRUD ----------
  void _addChallenge(String title) {
    final now = DateTime.now();
    final item = {
      'id': _generateId(),
      'title': title,
      'isCompleted': false,
      'createdAt': now.toIso8601String(),
    };
    setState(() {
      _challenges.insert(0, item);
    });
    _saveChallenges();
    _confettiController.play();
  }

  void _editChallenge(int index, String title) {
    setState(() {
      _challenges[index]['title'] = title;
    });
    _saveChallenges();
  }

  void _toggleComplete(int index) {
    setState(() {
      final current = _challenges[index];
      current['isCompleted'] = !(current['isCompleted'] as bool);
    });
    _saveChallenges();
    if (_challenges[index]['isCompleted'] == true) {
      _confettiController.play();
    }
  }

  void _deleteChallenge(int index) {
    setState(() {
      _challenges.removeAt(index);
    });
    _saveChallenges();
  }

  int _generateId() =>
      DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000);

  double get _progressPercent {
    if (_challenges.isEmpty) return 0;
    final completedCount = _challenges
        .where((c) => c['isCompleted'] == true)
        .length;
    return completedCount / _challenges.length;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hedef Takibi"),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildProgressCard(),
          ),
          Expanded(child: _buildListArea()),
          Padding(padding: const EdgeInsets.all(12), child: _buildAddRow()),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 15,
              maxBlastForce: 20,
              minBlastForce: 5,
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final percent = (_progressPercent * 100).round();
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'İlerleme',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: _progressPercent,
                    minHeight: 10,
                    backgroundColor: AppTheme.inputBorderColor.withOpacity(0.4),
                  ),
                  const SizedBox(height: 6),
                  Text('$percent% tamamlandı'),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                '${_challenges.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListArea() {
    if (_challenges.isEmpty) {
      return Center(
        child: Text(
          'Görev bulunmamaktadır.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: _challenges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = _challenges[i];
        final isDone = item['isCompleted'] == true;

        return Card(
          color: isDone
              ? AppTheme.backgroundColor.withOpacity(0.06)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            title: Text(
              item['title'] ?? '',
              style: TextStyle(
                decoration: isDone ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
                color: isDone ? Colors.grey : AppTheme.textColor,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isDone ? Colors.green : AppTheme.primaryColor,
              ),
              onPressed: () => _toggleComplete(i),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteChallenge(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(int index) {
    final titleCtrl = TextEditingController(text: _challenges[index]['title']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Görevi Düzenle'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(hintText: 'Başlık'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final t = titleCtrl.text.trim();
              if (t.isNotEmpty) {
                _editChallenge(index, t);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _addController,
            decoration: InputDecoration(
              hintText: 'Yeni görev ekle...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final text = _addController.text.trim();
            if (text.isEmpty) return;
            _addChallenge(text);
            _addController.clear();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
