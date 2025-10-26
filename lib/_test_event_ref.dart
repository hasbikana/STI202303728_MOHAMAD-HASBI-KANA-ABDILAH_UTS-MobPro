import 'event_model.dart';

void main() {
  final Event e = Event(id: '1', title: 't', note: 'n', createdAt: DateTime.now(), category: 'c');
  print(e.title);
}
