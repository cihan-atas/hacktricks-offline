import 'package:flutter/material.dart';
import '../services/scratchpad_service.dart';
import '../theme/app_theme.dart';

class ScratchpadScreen extends StatefulWidget {
  const ScratchpadScreen({super.key});

  @override
  State<ScratchpadScreen> createState() => _ScratchpadScreenState();
}

class _ScratchpadScreenState extends State<ScratchpadScreen> {
  final ScratchpadService _service = ScratchpadService();

  void _openEditDialog([ScratchpadItem? item]) {
    final titleController = TextEditingController(text: item?.title ?? '');
    final contentController = TextEditingController(text: item?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text(item == null ? 'Yeni Not' : 'Notu Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık / Hedef / Servis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Komutlar, Çıktılar, Notlar...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redTeam),
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final newItem = ScratchpadItem(
                  id: item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  content: contentController.text.trim(),
                  category: 'Pentest',
                  updatedAt: DateTime.now(),
                );
                _service.saveItem(newItem);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final items = _service.items;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('Siber Güvenlik Not Defteri'),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: AppTheme.redTeam,
            onPressed: () => _openEditDialog(),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_alt_outlined, size: 64, color: AppTheme.textMuted.withAlpha(80)),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz kaydedilmiş not yok',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pentest çalışmalarınızda komut ve bulguları buraya kaydedin.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final note = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          note.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _service.deleteItem(note.id),
                        ),
                        onTap: () => _openEditDialog(note),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
