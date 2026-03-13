import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:path/path.dart' as p;

class SignatureDialog extends StatefulWidget {
  final String title;
  final String? initialSignerName;
  final bool showNameField;

  const SignatureDialog({
    super.key,
    required this.title,
    this.initialSignerName,
    this.showNameField = false,
  });

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  late final SignatureController _controller;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
    _nameController = TextEditingController(text: widget.initialSignerName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Per favore, apponi una firma.')),
      );
      return;
    }

    final Uint8List? signature = await _controller.toPngBytes();
    if (signature != null) {
      final tempDir = await getApplicationDocumentsDirectory();
      final fileName = 'sig_${DateTime.now().microsecondsSinceEpoch}.png';
      final filePath = p.join(tempDir.path, 'signatures', fileName);

      final file = File(filePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(signature);

      if (mounted) {
        Navigator.of(context).pop({
          'filePath': filePath,
          'signerName': _nameController.text.trim(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showNameField) ...[
              TextField(
                controller: _nameController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  labelText: 'Nome del firmatario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Signature(
                  controller: _controller,
                  height: 250,
                  backgroundColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _controller.clear(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Cancella'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Conferma Firma'),
        ),
      ],
    );
  }
}
