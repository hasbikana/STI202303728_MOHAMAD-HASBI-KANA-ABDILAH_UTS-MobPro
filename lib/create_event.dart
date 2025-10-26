

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_event_planner/event_model.dart';


/// Halaman untuk membuat atau mengedit entri jurnal.
/// Mendukung mode Edit jika [initialEntry] disediakan.
class CreateEventPage extends StatefulWidget {
  final Function(Event) onSave;
  final Event? initialEntry;


  const CreateEventPage({
    super.key,
    required this.onSave,
    this.initialEntry,
  });


  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}


class _CreateEventPageState extends State<CreateEventPage> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedCategory = 'Kategori Acara';
  static const List<String> _allowedCategories = ['Kerja', 'Lembur', 'Kuliah', 'Lainnya'];


  @override
  void initState() {
    super.initState();
    // Memuat data entri lama jika berada dalam mode Edit.
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;

      _titleController.text = entry.title;
      _noteController.text = entry.note;
      // Ensure category exists in allowed list (fallback to 'Lainnya' if not)
      _selectedCategory = _allowedCategories.contains(entry.category) ? entry.category : 'Lainnya';

      _selectedDate = entry.createdAt;
      _selectedTime = TimeOfDay.fromDateTime(entry.createdAt);
    }
  }


  // --- FUNGSI DATE/TIME PICKER ---
 
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2030));
    if (pickedDate != null) {
      setState(() {
        _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, _selectedTime.hour, _selectedTime.minute);
      });
    }
  }


  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: _selectedTime, builder: (context, child) {
        return Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF764BA2), onSurface: Colors.white)), child: child!);
      },
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      });
    }
  }


  // --- FUNGSI SAVE/UPDATE DATA ---


  /// Memproses input, menyalin media, dan memicu fungsi save/update.
  void _saveJournal() async {
    final title = _titleController.text.trim();
    final note = _noteController.text.trim();


    // Validasi dasar
    if (title.isEmpty && note.isEmpty) {
      Navigator.pop(context);
      return;
    }


    // Membuat objek Event BARU atau UPDATE.
    final newEntry = Event(
      id: widget.initialEntry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      note: note,
      createdAt: _selectedDate,
      category: _selectedCategory,
      status: widget.initialEntry?.status ?? 'pending',
      result: widget.initialEntry?.result,
    );


    widget.onSave(newEntry); // Memanggil callback ke MainScreen.


        // Kriteria UTS: SnackBar feedback.
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
                'Acara berhasil disimpan!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

   
    // If this page was pushed (edit flow), pop back. If it's embedded in the TabView (create flow),
    // don't pop the route — instead clear the form so user can add another event.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Clear form for next input
      setState(() {
        _titleController.clear();
        _noteController.clear();
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedCategory = _allowedCategories.contains(_selectedCategory) ? _selectedCategory : 'Kerja';
      });
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }


  // --- WIDGET MEDIA/UI ---


  // Image preview/upload removed per request.


  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1E),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1C1C1E), elevation: 0),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.initialEntry != null ? 'Edit Acara' : DateFormat('EEEE, d MMM', 'id_ID').format(_selectedDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
          centerTitle: true,
          actions: [
            TextButton(onPressed: _saveJournal, child: const Text('Selesai', style: TextStyle(color: Color.fromARGB(255, 255, 247, 0), fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
                // Judul Acara
                TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(hintText: 'Judul Acara', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey, fontSize: 22)),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
             
              // Date/Time Picker Buttons
              Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    TextButton.icon(onPressed: () => _pickDate(context), icon: const Icon(Icons.calendar_today, size: 18), label: Text(DateFormat('EEEE, d MMM yyyy', 'id_ID').format(_selectedDate))),
                    const SizedBox(width: 16),
                    TextButton.icon(onPressed: () => _pickTime(context), icon: const Icon(Icons.access_time, size: 18), label: Text(_selectedTime.format(context))),
                  ],
                ),
              ),
             
              // Category selector
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: _allowedCategories.contains(_selectedCategory) ? _selectedCategory : 'Lainnya',
                      dropdownColor: const Color(0xFF1C1C1E),
                      items: _allowedCategories
                          .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (val) { if (val != null) setState(() { _selectedCategory = val; }); },
                    ),
                  ],
                ),
              ),


              // Deskripsi Acara
              Expanded(
                child: TextField(controller: _noteController, decoration: const InputDecoration(hintText: 'Deskripsi Acara...', border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
                  style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: null, keyboardType: TextInputType.multiline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

