

import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:my_event_planner/event_model.dart'; // Import model Event
import 'package:path/path.dart' as p;


/// Kelas utilitas untuk mengelola operasi I/O file persisten.
/// Ini adalah inti dari kriteria Penyimpanan Data (25% Bobot).
class EventStorage {
  // Nama file penyimpanan data event
  static const String _fileName = 'event_data.json';


  /// Mendapatkan objek [File] yang merujuk ke lokasi penyimpanan data permanen.
  Future<File> get _localFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    return File('$path/$_fileName');
  }
 
  /// Salin file media (gambar/video) ke folder aplikasi dan kembalikan path baru.
  Future<String> saveMediaFile(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(directory.path, 'media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final baseName = p.basename(file.path);
    final filename = '${DateTime.now().millisecondsSinceEpoch}_$baseName';
    final newPath = p.join(mediaDir.path, filename);
    final newFile = await file.copy(newPath);
    return newFile.path;
  }
 
  // (Media helper removed) Previously contained utilities to copy images
  // to permanent storage. Media upload/preview was removed from the UI,
  // so the helper has been removed as well. Keep file persistence functions
  // (save/load events) below.
 
  /// Menyimpan daftar [Event] saat ini ke file persisten.
  Future<void> saveEvents(List<Event> events) async {
    final file = await _localFile;
   
    // Konversi List<Event> menjadi List<Map> dan kemudian JSON String
    final jsonList = events.map((entry) => entry.toJson()).toList();
    final jsonString = jsonEncode(jsonList);


    // Menulis String JSON ke file
    await file.writeAsString(jsonString);
  }


  /// Memuat daftar [Event] dari file persisten.
  Future<List<Event>> loadEvents() async {
    try {
      final file = await _localFile;
     
      final String contents = await file.readAsString();
     
      if (contents.isEmpty) return [];


      // Konversi JSON String kembali menjadi List<dynamic>
      final List<dynamic> jsonList = jsonDecode(contents);
     
      // Mengubah setiap item JSON menjadi objek Event
      final events = jsonList.map((json) => Event.fromJson(json)).toList();
     
      return events;
    } catch (e) {
      return [];
    }
  }
}



