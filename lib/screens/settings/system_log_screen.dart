import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/log_service.dart';
import '../../utils/app_theme.dart';

class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = ['ALL', 'INFO', 'DATABASE', 'AUTH', 'ERROR', 'DEBUG'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getLogColor(String type) {
    switch (type.toUpperCase()) {
      case 'ERROR':
        return Colors.redAccent;
      case 'WARNING':
        return Colors.orangeAccent;
      case 'AUTH':
        return Colors.blueAccent;
      case 'DATABASE':
        return Colors.tealAccent;
      case 'DEBUG':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _getLogIcon(String type) {
    switch (type.toUpperCase()) {
      case 'ERROR':
        return Icons.error_outline_rounded;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'AUTH':
        return Icons.vpn_key_outlined;
      case 'DATABASE':
        return Icons.dns_outlined;
      case 'DEBUG':
        return Icons.bug_report_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'System Logs',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy all logs',
            icon: Icon(Icons.copy_all_rounded, color: context.textPrimary, size: 20),
            onPressed: () {
              if (LogService.logs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No logs to copy', style: GoogleFonts.inter()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              final buffer = StringBuffer();
              for (var log in LogService.logs) {
                buffer.writeln('[${log.timestamp.toIso8601String()}][${log.type}][${log.tag}] ${log.message}');
              }
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All logs copied to clipboard', style: GoogleFonts.inter()),
                  backgroundColor: const Color(0xFF1E824C),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Clear logs',
            icon: Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.cardBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Clear System Logs?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  content: Text(
                    'Are you sure you want to delete all in-memory system logs? This action cannot be undone.',
                    style: GoogleFonts.inter(color: context.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: GoogleFonts.inter(color: context.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        LogService.clear();
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Clear', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: context.scaffoldBg,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                  style: GoogleFonts.inter(color: context.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: context.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: context.cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border, width: 0.8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.border, width: 0.8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.primaryAccent, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filters Row
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : context.textPrimary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: context.primaryAccent,
                          backgroundColor: context.cardBg,
                          disabledColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : context.border,
                              width: 0.8,
                            ),
                          ),
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Logs Feed List
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: LogService.logCountNotifier,
              builder: (context, count, _) {
                // Filter and search logs
                final filteredLogs = LogService.logs.where((log) {
                  final matchesFilter = _selectedFilter == 'ALL' ||
                      log.type.toUpperCase() == _selectedFilter.toUpperCase();
                  final matchesSearch = _searchQuery.isEmpty ||
                      log.message.toLowerCase().contains(_searchQuery) ||
                      log.tag.toLowerCase().contains(_searchQuery) ||
                      log.type.toLowerCase().contains(_searchQuery);
                  return matchesFilter && matchesSearch;
                }).toList();

                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 48, color: context.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No logs found',
                          style: GoogleFonts.inter(
                            color: context.textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: filteredLogs.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: context.border),
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    final color = _getLogColor(log.type);
                    final icon = _getLogIcon(log.type);
                    final formattedTime =
                        "${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}";

                    return InkWell(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: log.message));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Log message copied', style: GoogleFonts.inter()),
                            backgroundColor: const Color(0xFF1E824C),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Icon
                                Icon(icon, size: 14, color: color),
                                const SizedBox(width: 6),
                                // Type Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.type.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Tag
                                Text(
                                  log.tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: context.textSecondary,
                                  ),
                                ),
                                const Spacer(),
                                // Time
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: context.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Log Message
                            SelectableText(
                              log.message,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
