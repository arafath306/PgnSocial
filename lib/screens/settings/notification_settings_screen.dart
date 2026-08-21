import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/notification_settings_provider.dart';
import '../../utils/app_theme.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: GoogleFonts.inter(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: context.border, height: 1.0),
        ),
      ),
      body: Consumer<NotificationSettingsProvider>(
        builder: (context, provider, _) {
          final items = provider.settingsList;
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: context.border, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return _NotifSettingTile(item: item, provider: provider);
            },
          );
        },
      ),
    );
  }
}

class _NotifSettingTile extends StatelessWidget {
  final NotificationSettingItem item;
  final NotificationSettingsProvider provider;

  const _NotifSettingTile({required this.item, required this.provider});

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: context.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // In-app toggle
                      _buildToggleRow(
                        context,
                        label: 'In-app',
                        value: item.inApp,
                        onChanged: (val) {
                          setModalState(() {});
                          provider.updateSetting(id: item.id, inApp: val);
                        },
                      ),
                      // Push toggle
                      _buildToggleRow(
                        context,
                        label: 'Push',
                        value: item.push,
                        onChanged: (val) {
                          setModalState(() {});
                          provider.updateSetting(id: item.id, push: val);
                        },
                      ),
                      if (item.hasFromOption) ...[
                        const SizedBox(height: 12),
                        Text(
                          'From',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildFromOption(context, setModalState, 'everyone', 'Everyone'),
                        _buildFromOption(context, setModalState, 'people_you_follow', 'People you follow'),
                        _buildFromOption(context, setModalState, 'off', 'Off'),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleRow(BuildContext context,
      {required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: context.textPrimary,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: context.primaryAccent,
            inactiveTrackColor: context.isDarkMode ? Colors.grey[800] : Colors.black12,
            inactiveThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFromOption(BuildContext context, StateSetter setModalState, String value, String label) {
    final isSelected = item.from == value;
    return InkWell(
      onTap: () {
        setModalState(() {});
        provider.updateSetting(id: item.id, from: value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.textPrimary,
              ),
            ),
            if (isSelected)
              Icon(Icons.check, color: context.primaryAccent, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: context.textPrimary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtext,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
