import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class PersonalNote {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? reminderDate;
  final bool isPinned;

  PersonalNote({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.reminderDate,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'reminderDate': reminderDate?.toIso8601String(),
        'isPinned': isPinned,
      };

  factory PersonalNote.fromJson(Map<String, dynamic> json) => PersonalNote(
        id: json['id'],
        title: json['title'],
        content: json['content'],
        createdAt: DateTime.parse(json['createdAt']),
        reminderDate: json['reminderDate'] != null
            ? DateTime.parse(json['reminderDate'])
            : null,
        isPinned: json['isPinned'] ?? false,
      );

  PersonalNote copyWith({
    String? title,
    String? content,
    DateTime? reminderDate,
    bool? isPinned,
  }) {
    return PersonalNote(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      reminderDate: reminderDate ?? this.reminderDate,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class PersonalNotesNotifier extends StateNotifier<List<PersonalNote>> {
  PersonalNotesNotifier() : super([]) {
    _loadNotes();
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/personal_notes.json');
  }

  Future<void> _loadNotes() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        state = jsonList.map((e) => PersonalNote.fromJson(e)).toList()
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });
      }
    } catch (e) {
      print('Errore caricamento note: $e');
    }
  }

  Future<void> _saveNotes() async {
    try {
      final file = await _getFile();
      final jsonList = state.map((e) => e.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      print('Errore salvataggio note: $e');
    }
  }

  Future<void> addNote(String title, String content, {DateTime? reminderDate}) async {
    final newNote = PersonalNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      reminderDate: reminderDate,
    );
    state = [newNote, ...state];
    await _saveNotes();
  }

  Future<void> updateNote(PersonalNote updatedNote) async {
    state = [
      for (final note in state)
        if (note.id == updatedNote.id) updatedNote else note
    ]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    await _saveNotes();
  }

  Future<void> deleteNote(String id) async {
    state = state.where((note) => note.id != id).toList();
    await _saveNotes();
  }

  Future<void> togglePin(String id) async {
    state = [
      for (final note in state)
        if (note.id == id) note.copyWith(isPinned: !note.isPinned) else note
    ]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
    await _saveNotes();
  }
}

final personalNotesProvider = StateNotifierProvider<PersonalNotesNotifier, List<PersonalNote>>((ref) {
  return PersonalNotesNotifier();
});
