

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_event_planner/event_model.dart';
import 'package:my_event_planner/create_event.dart'; // Diperlukan untuk navigasi ke halaman edit (CreateEventPage)
import 'package:video_player/video_player.dart';


// Asumsi: main.dart memiliki class _MainScreenState dengan _deleteEntry dan _addNewEntry


/// Halaman untuk menampilkan detail lengkap dari satu entri.
class EventDetailPage extends StatelessWidget {
  final Event entry;
  final Function(Event) onSave;
  final Function(String) onDelete;

  const EventDetailPage({super.key, required this.entry, required this.onSave, required this.onDelete});


  /// Menampilkan dialog konfirmasi sebelum menghapus data.
  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Apakah Anda yakin ingin menghapus acara ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: <Widget>[
          TextButton(child: const Text('Batal'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text('Hapus', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
  // Use the provided callbacks (onSave/onDelete) to modify data in MainScreen
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE, d MMM yyyy', 'id_ID').format(entry.createdAt),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          // PopupMenuButton untuk Edit/Hapus (Kriteria Context Menu)
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                final bool? confirm = await _showDeleteConfirmation(context);
                if (confirm == true) {
                  onDelete(entry.id);
                  Navigator.pop(context); // Kembali ke halaman utama setelah hapus
                }
              } else if (value == 'edit') {
                // Navigasi ke halaman edit dan gunakan onSave callback
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => CreateEventPage(
                      onSave: onSave,
                      initialEntry: entry,
                    ),
                  ),
                ).then((_) {
                  // Tutup halaman detail setelah navigasi ke Edit
                  Navigator.pop(context);
                });
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'edit', child: Text('Edit Acara')),
              const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Acara')),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Judul
            if (entry.title.isNotEmpty)
              Text(
                entry.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 16),
            // (Media tidak tersimpan di dalam model Event). Gunakan tab Media untuk mengakses foto dan video.


            // 3. Deskripsi Acara
            if (entry.note.isNotEmpty)
              Text(
                entry.note,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            const SizedBox(height: 16),
            // 3.5 Media preview (images/videos) if any
            if (entry.mediaPaths != null && entry.mediaPaths!.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.mediaPaths!.map((path) {
                  final lower = path.toLowerCase();
                  if (lower.endsWith('.mp4')) {
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoFile: File(path)))),
                      child: Container(width: 120, height: 80, color: Colors.black12, child: const Icon(Icons.videocam, size: 40)),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () => showDialog(context: context, builder: (_) => Dialog(child: Image.file(File(path)))),
                      child: Image.file(File(path), width: 120, height: 80, fit: BoxFit.cover),
                    );
                  }
                }).toList(),
              ),
           
            // 4. Metadata
            Text(
              'Dicatat pada: ${DateFormat('HH:mm', 'id_ID').format(entry.createdAt)} • Kategori: ${entry.category}',
              style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}


class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  const VideoPlayerScreen({super.key, required this.videoFile});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}



