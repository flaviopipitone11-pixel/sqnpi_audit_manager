import 'package:flutter/material.dart';

class SyncLogDialog extends StatelessWidget {
  final List<String> logs;

  const SyncLogDialog({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      elevation: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(context),

            // Content
            Flexible(
              child: logs.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      shrinkWrap: true,
                      itemCount: logs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _LogItem(log: logs[index]),
                    ),
            ),

            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync_alt_rounded,
              color: Color(0xFF0F172A),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Log Sincronizzazione',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Dettaglio operazioni cloud',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 48, color: Color(0xFF94A3B8)),
          SizedBox(height: 16),
          Text(
            'Nessun log disponibile',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            'CHIUDI REPORT',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String log;

  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess =
        log.contains('✅') || log.contains('Sincronizzazione completata');
    final bool isError = log.contains('❌') || log.contains('Errore');
    final bool isWarning = log.contains('⚠️');
    final bool isInfo =
        log.contains('🚀') ||
        log.contains('📥') ||
        log.contains('📤') ||
        log.contains('☁️');

    Color bgColor = const Color(0xFFF1F5F9);
    Color iconColor = const Color(0xFF64748B);
    IconData iconData = Icons.chevron_right_rounded;

    if (isSuccess) {
      bgColor = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF16A34A);
      iconData = Icons.check_circle_rounded;
    } else if (isError) {
      bgColor = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
      iconData = Icons.error_rounded;
    } else if (isWarning) {
      bgColor = const Color(0xFFFFFBEB);
      iconColor = const Color(0xFFD97706);
      iconData = Icons.warning_rounded;
    } else if (isInfo) {
      bgColor = const Color(0xFFF0F9FF);
      iconColor = const Color(0xFF0284C7);
      iconData = Icons.info_rounded;
    }

    // Pulisci il testo dagli emoji se necessario, o mantienili
    String cleanText = log
        .replaceAll('✅', '')
        .replaceAll('❌', '')
        .replaceAll('⚠️', '')
        .replaceAll('🚀', '')
        .replaceAll('📥', '')
        .replaceAll('📤', '')
        .replaceAll('☁️', '')
        .trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isSuccess || isError)
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: (isSuccess || isError)
                    ? iconColor
                    : const Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
