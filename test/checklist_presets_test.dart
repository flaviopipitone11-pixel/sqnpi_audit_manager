import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqnpi_audit_manager/features/audits/application/checklist_note_presets.dart';

void main() {
  group('ChecklistNotePresets', () {
    test('naPresets and ko presets are non-empty', () {
      expect(ChecklistNotePresets.naPresets.isNotEmpty, isTrue);
      expect(ChecklistNotePresets.koRilievoPresets.isNotEmpty, isTrue);
      expect(ChecklistNotePresets.koAzionePresets.isNotEmpty, isTrue);
    });

    test('applyPreset sets text if controller is empty', () {
      final controller = TextEditingController();
      ChecklistNotePresets.applyPreset(controller, 'Specie non soggetta');
      expect(controller.text, 'Specie non soggetta');
      expect(controller.selection.baseOffset, 'Specie non soggetta'.length);
    });

    test('applyPreset appends text with semicolon if controller has text', () {
      final controller = TextEditingController(text: 'Prima nota');
      ChecklistNotePresets.applyPreset(controller, 'Seconda nota');
      expect(controller.text, 'Prima nota; Seconda nota');
    });

    test('applyPreset does not duplicate if preset is already present', () {
      final controller = TextEditingController(
        text: 'Prima nota; Seconda nota',
      );
      ChecklistNotePresets.applyPreset(controller, 'Seconda nota');
      expect(controller.text, 'Prima nota; Seconda nota');
    });
  });
}
