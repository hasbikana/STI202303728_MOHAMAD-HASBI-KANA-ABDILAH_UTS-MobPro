// lib/main.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:my_event_planner/event_model.dart';
import 'package:my_event_planner/event_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:my_event_planner/create_event.dart';
import 'package:my_event_planner/event_detail.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Event Planner',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF764BA2)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


// Kerangka Utama Aplikasi
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {
  // Tabs: 0 = Daftar Event, 1 = Tambah Event, 2 = Media
  List<Event> _allEvents = [];
  final EventStorage _storage = EventStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataOnInit();
  }


  // Memuat data dari File I/O untuk persistensi
  void _loadDataOnInit() async {
    setState(() {
      _isLoading = true;
    });
    List<Event> loadedEvents = await _storage.loadEvents();

    // Mark past pending events as missed and add result note
    final now = DateTime.now();
    bool changed = false;
    final updated = loadedEvents.map((e) {
      if (e.createdAt.isBefore(now) && e.status == 'pending') {
        changed = true;
        return e.copyWith(status: 'missed', result: 'Tidak terlaksana');
      }
      return e;
    }).toList();

    if (changed) {
      // persist migration
      await _storage.saveEvents(updated);
    }

    setState(() {
      _allEvents = updated;
      _isLoading = false;
    });
  }


  // Menyimpan entri baru ATAU mengupdate entri lama (untuk mode Edit)
  void _addNewEntry(Event newEntry) {
    setState(() {
      final existingIndex = _allEvents.indexWhere((entry) => entry.id == newEntry.id);
     
      if (existingIndex != -1) {
        _allEvents[existingIndex] = newEntry; // Update
      } else {
        _allEvents.add(newEntry); // Create
      }
    });
    _storage.saveEvents(_allEvents);
  }


  // Menghapus entri
  void _deleteEntry(String entryId) {
    setState(() {
      _allEvents.removeWhere((entry) => entry.id == entryId);
    });
    _storage.saveEvents(_allEvents);
  }


  // Navigation handled by TabBar; legacy _onItemTapped removed.


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      _isLoading
        ? const Center(child: CircularProgressIndicator())
        : EventListPage(events: _allEvents, onDelete: _deleteEntry, onEdit: _addNewEntry),
      CreateEventPage(onSave: _addNewEntry),
      PastEventsPage(events: _allEvents, onDelete: _deleteEntry, onEdit: _addNewEntry),
    ];


    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          title: const Text('My Event Planner'),
          centerTitle: false,
          backgroundColor: const Color(0xFFF2F3F4),
          elevation: 0,
          titleTextStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F3F4), Color(0xFFDED1C6)]),
          ),
          child: TabBarView(children: pages),
        ),
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey[700],
            indicatorColor: Colors.transparent,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'Daftar Event'),
              Tab(icon: Icon(Icons.add), text: 'Tambah Event'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
      ),
    );
  }


  // Navigation handled by TabBar; legacy helper removed.
}


// --- Halaman Daftar Event (List & Edit/Hapus) ---
class EventListPage extends StatefulWidget {
  final List<Event> events;
  final Function(String) onDelete;
  final Function(Event) onEdit;

  EventListPage({super.key, required this.events, required this.onDelete, required this.onEdit});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  String _filter = 'Terdekat'; // Terdekat, Paling Lama, Semua
  String _categoryFilter = 'Semua';
  static const List<String> _categories = ['Semua', 'Kerja ', 'Lembur', 'Kuliah', 'Lainnya'];

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

  String _computeNearestEventDate(List<Event> events) {
    if (events.isEmpty) return '-';
    final now = DateTime.now();

    final upcoming = events.where((e) => !e.createdAt.isBefore(now) && e.status != 'missed').toList();
    if (upcoming.isNotEmpty) {
      upcoming.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return DateFormat('d MMM', 'id_ID').format(upcoming.first.createdAt);
    }

    final past = events.where((e) => e.createdAt.isBefore(now)).toList();
    if (past.isEmpty) return '-';
    past.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return DateFormat('d MMM', 'id_ID').format(past.first.createdAt);
  }

  List<Event> _applyFilters() {
    final now = DateTime.now();
    // Only show pending events in the main list
    List<Event> items = widget.events.where((e) => e.status == 'pending').toList();
    if (_categoryFilter != 'Semua') {
      items = items.where((e) => e.category == _categoryFilter).toList();
    }

    if (_filter == 'Terdekat') {
      // nearest upcoming first, then by date
      items.sort((a, b) {
        final aDiff = a.createdAt.difference(now).inSeconds;
        final bDiff = b.createdAt.difference(now).inSeconds;
        // prefer non-negative and smaller difference
        if ((aDiff >= 0) && (bDiff < 0)) return -1;
        if ((aDiff < 0) && (bDiff >= 0)) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });
    } else if (_filter == 'Paling Lama') {
      items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else {
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.events;
    // --- Statistik ---
    int totalWords = 0;
    Set<DateTime> uniqueDays = {};

    for (var entry in events) {
      final noteText = entry.note.trim();
      if (noteText.isNotEmpty) {
        totalWords += noteText.split(RegExp(r'\s+')).length;
      }
      uniqueDays.add(DateUtils.dateOnly(entry.createdAt));
    }

  int totalDays = uniqueDays.length;
  int streak = totalDays;

    final displayed = _applyFilters();

    // Use displayed count for dynamic total events
    final totalEntries = displayed.length;

    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RekorCard(streak: streak, wordCount: totalWords, dayCount: totalEntries, nearestDate: _computeNearestEventDate(events)),

          // Filters: sort and category
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
            child: Row(children: [
              const Text('Filter:', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              DropdownButton<String>(value: _filter, items: <String>['Terdekat', 'Paling Lama', 'Semua'].map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(), onChanged: (v) { if (v != null) setState(() { _filter = v; }); }),
              const SizedBox(width: 32),
              const Text('Kategori:', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              DropdownButton<String>(value: _categoryFilter, items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) { if (v != null) setState(() { _categoryFilter = v; }); }),
            ]),
          ),

          const Padding(padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0), child: Text('Daftar Acara', style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold))),

          if (events.isEmpty)
            const Expanded(child: Center(child: Text('Belum ada acara tersimpan.\nGunakan tab Tambah Event untuk menambahkan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey))))
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: displayed.length,
                itemBuilder: (context, index) {
                  final entry = displayed[index];

                  String displayTitle = entry.title;
                  String displayNote = entry.note;

                  if (displayTitle.isEmpty && displayNote.isEmpty) displayTitle = '(Acara Kosong)';
                  else if (displayTitle.isEmpty) { displayTitle = displayNote; displayNote = ''; }

                  return GestureDetector(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailPage(entry: entry, onSave: widget.onEdit, onDelete: widget.onDelete)));
                                  },
                    child: Card(
                      color: Colors.white,
                      elevation: 2.0,
                      margin: const EdgeInsets.only(bottom: 12.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(entry.createdAt).toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'delete') {
                                      final bool? confirm = await _showDeleteConfirmation(context);
                                      if (confirm == true) widget.onDelete(entry.id);
                                    } else if (value == 'edit') {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPage(onSave: widget.onEdit, initialEntry: entry)));
                                    }
                                  },
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(value: 'edit', child: Text('Edit Acara')),
                                    const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Acara')),
                                  ],
                                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(displayTitle, style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                            if (displayNote.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(displayNote, style: const TextStyle(fontSize: 14, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 8),
                            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              if (entry.status != 'completed')
                                TextButton.icon(onPressed: () async {
                                  // Open bottom sheet to allow attaching media or mark complete without media
                                  final choice = await showModalBottomSheet<String?>(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                                    ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Foto - Kamera'), onTap: () => Navigator.of(ctx).pop('photo_cam')),
                                    ListTile(leading: const Icon(Icons.photo), title: const Text('Foto - Galeri'), onTap: () => Navigator.of(ctx).pop('photo_gal')),
                                    ListTile(leading: const Icon(Icons.videocam), title: const Text('Video - Kamera'), onTap: () => Navigator.of(ctx).pop('video_cam')),
                                    ListTile(leading: const Icon(Icons.video_library), title: const Text('Video - Galeri'), onTap: () => Navigator.of(ctx).pop('video_gal')),
                                    ListTile(leading: const Icon(Icons.check), title: const Text('Tandai Selesai tanpa media'), onTap: () => Navigator.of(ctx).pop('none')),
                                  ]));

                                  String? savedPath;
                                  if (choice == 'photo_cam') {
                                    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
                                    if (picked != null) savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                  } else if (choice == 'photo_gal') {
                                    final List<XFile>? pickedList = await ImagePicker().pickMultiImage();
                                    if (pickedList != null && pickedList.isNotEmpty) {
                                      // save first picked image for simplicity
                                      final XFile picked = pickedList.first;
                                      savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                    }
                                  } else if (choice == 'video_cam') {
                                    final XFile? picked = await ImagePicker().pickVideo(source: ImageSource.camera);
                                    if (picked != null) savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                  } else if (choice == 'video_gal') {
                                    final XFile? picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
                                    if (picked != null) savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                  }

                                  // Build updated event
                                  final updated = entry.copyWith(status: 'completed', result: 'Terlaksana', mediaPaths: savedPath != null ? [savedPath] : entry.mediaPaths);
                                  widget.onEdit(updated);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: const Color(0xFF4CAF50), // hijau lembut
                                          behavior: SnackBarBehavior.floating, // melayang sedikit di atas bawah layar
                                          margin: const EdgeInsets.all(12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          content: Row(
                                            children: const [
                                              Icon(Icons.check_circle, color: Colors.white),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Acara Telah Selesai',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );

                                }, icon: const Icon(Icons.check, color: Colors.green), label: const Text('Selesai')),
                              if (entry.status == 'completed')
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(6)), child: const Text('Terlaksana', style: TextStyle(color: Colors.green)) ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}


// ... (Kode RekorCard, ProfilePage, GaleriPage)


class RekorCard extends StatelessWidget {
  final int streak;
  final int wordCount;
  final int dayCount;
  final String nearestDate;

  const RekorCard({super.key, required this.streak, required this.wordCount, required this.dayCount, this.nearestDate = '-'});
  @override
  Widget build(BuildContext context) {
    // Improved visual: card with soft gradient and icons for each stat
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          Expanded(child: _buildStatColumn('Terdekat', nearestDate, '')),
          Expanded(child: _buildStatColumn('Total Event', dayCount.toString(), 'Event')),
        ]),
      ),
    );
  }


  Widget _buildStatColumn(String label, String value, String unit) {
    // pick an icon based on label
    IconData iconData = Icons.info;
    final l = label.toLowerCase();
    if (l.contains('terdekat')) iconData = Icons.calendar_today;
    else if (l.contains('total')) iconData = Icons.event;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(iconData, color: Colors.grey[700], size: 18),
      const SizedBox(height: 6),
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(unit, style: const TextStyle(color: Colors.black54, fontSize: 13)),
      ]),
    ]);
  }
}


class PastEventsPage extends StatelessWidget {
  final List<Event> events;
  final Function(String) onDelete;
  final Function(Event) onEdit;
  PastEventsPage({super.key, required this.events, required this.onDelete, required this.onEdit});

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
  final now = DateTime.now();
  // History includes any event that is completed or missed, or events that are older than now
  final past = events.where((e) => e.status != 'pending' || e.createdAt.isBefore(now)).toList();
    if (past.isEmpty) {
      return const Center(child: Text('Tidak ada acara yang terlewat.', style: TextStyle(fontSize: 18, color: Colors.grey)));
    }

    past.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  // no need to reach into MainScreen; use callbacks provided by parent

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      itemCount: past.length,
      itemBuilder: (context, index) {
        final entry = past[index];

        String displayTitle = entry.title.isEmpty ? (entry.note.isEmpty ? '(Acara Kosong)' : entry.note) : entry.title;
        String displayNote = entry.title.isEmpty ? '' : entry.note;

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailPage(entry: entry, onSave: onEdit, onDelete: onDelete)));
          },
          child: Card(
            color: Colors.white,
            elevation: 2.0,
            margin: const EdgeInsets.only(bottom: 12.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(entry.createdAt).toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                Row(children: [
                                  if (entry.status != 'completed')
                                    TextButton(
                                      onPressed: () async {
                                        // For past events, allow marking completed (optionally with media)
                                        final choice = await showModalBottomSheet<String?>(context: context, builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
                                          ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Foto - Kamera'), onTap: () => Navigator.of(ctx).pop('photo_cam')),
                                          ListTile(leading: const Icon(Icons.photo), title: const Text('Foto - Galeri'), onTap: () => Navigator.of(ctx).pop('photo_gal')),
                                          ListTile(leading: const Icon(Icons.videocam), title: const Text('Video - Kamera'), onTap: () => Navigator.of(ctx).pop('video_cam')),
                                          ListTile(leading: const Icon(Icons.video_library), title: const Text('Video - Galeri'), onTap: () => Navigator.of(ctx).pop('video_gal')),
                                          ListTile(leading: const Icon(Icons.check), title: const Text('Tandai Selesai tanpa media'), onTap: () => Navigator.of(ctx).pop('none')),
                                        ]));

                                        String? savedPath;
                                        if (choice == 'photo') {
                                          final XFile? picked = await ImagePicker().pickImage(source: ImageSource.camera);
                                          if (picked != null) {
                                            savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                          }
                                        } else if (choice == 'video') {
                                          final XFile? picked = await ImagePicker().pickVideo(source: ImageSource.camera);
                                          if (picked != null) {
                                            savedPath = await EventStorage().saveMediaFile(File(picked.path));
                                          }
                                        }

                                        final updated = entry.copyWith(status: 'completed', result: 'Terlaksana', mediaPaths: savedPath != null ? [savedPath] : entry.mediaPaths);
                                        onEdit(updated);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acara ditandai selesai')));
                                      },
                                      child: const Text('Selesai', style: TextStyle(color: Colors.green)),
                                    ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        final bool? confirm = await _showDeleteConfirmation(context);
                                        if (confirm == true) onDelete(entry.id);
                                      } else if (value == 'edit') {
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => CreateEventPage(onSave: onEdit, initialEntry: entry)));
                                      }
                                    },
                                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(value: 'edit', child: Text('Edit Acara')),
                                      const PopupMenuItem<String>(value: 'delete', child: Text('Hapus Acara')),
                                    ],
                                    icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                                  ),
                                ]),
                ]),
                const SizedBox(height: 8),
                Text(displayTitle, style: const TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                if (displayNote.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6.0), child: Text(displayNote, style: const TextStyle(fontSize: 14, color: Colors.black54), maxLines: 3, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ),
        );
      },
    );
  }
}


class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Ini adalah Halaman Profil', style: TextStyle(fontSize: 20)));
  }
}

