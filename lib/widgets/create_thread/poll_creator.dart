import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class PollCreator extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<Uint8List?>? optionImageBytesList;
  final VoidCallback onClose;
  final Function(int index) onRemoveOption;
  final VoidCallback onAddOption;
  final Function(int index)? onPickOptionImage;
  final Function(int index)? onRemoveOptionImage;
  final Duration selectedDuration;
  final List<Map<String, dynamic>> durations;
  final Function(Duration) onDurationChanged;

  const PollCreator({
    super.key,
    required this.controllers,
    this.optionImageBytesList,
    required this.onClose,
    required this.onRemoveOption,
    required this.onAddOption,
    this.onPickOptionImage,
    this.onRemoveOptionImage,
    required this.selectedDuration,
    required this.durations,
    required this.onDurationChanged,
  });

  String _getDurationLabel() {
    final days = selectedDuration.inDays;
    final hours = selectedDuration.inHours % 24;
    final mins = selectedDuration.inMinutes % 60;

    if (days > 0 && hours == 0 && mins == 0) {
      return "$days day${days > 1 ? 's' : ''}";
    }
    if (days == 0 && hours > 0 && mins == 0) {
      return "$hours hour${hours > 1 ? 's' : ''}";
    }
    if (days == 0 && hours == 0 && mins > 0) {
      return "$mins minute${mins > 1 ? 's' : ''}";
    }
    final List<String> parts = [];
    if (days > 0) parts.add("$days d");
    if (hours > 0) parts.add("$hours h");
    if (mins > 0) parts.add("$mins m");
    return parts.isEmpty ? "1 day" : parts.join(" ");
  }

  void _showSetLengthDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SetLengthDialog(
        initialDuration: selectedDuration,
        onSet: (newDuration) {
          onDurationChanged(newDuration);
        },
      ),
    );
  }

  void _showImageOptionsSheet(BuildContext context, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF1D9BF0)),
                title: Text("Change image", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  onPickOptionImage?.call(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: Text("Remove image", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  onRemoveOptionImage?.call(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.isDarkMode
        ? const Color(0xFF2F3336)
        : const Color(0xFFCFD9DE);
    final cardBgColor = context.isDarkMode
        ? const Color(0xFF16181C)
        : const Color(0xFFF7F9F9);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poll Choices List
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Column(
              children: List.generate(controllers.length, (index) {
                final isFirst = index == 0;
                final isLast = index == controllers.length - 1;
                final canAddMore = isLast && controllers.length < 4;

                final Uint8List? imageBytes = (optionImageBytesList != null && optionImageBytesList!.length > index)
                    ? optionImageBytesList![index]
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      // Square Image Attachment Box
                      GestureDetector(
                        onTap: () {
                          if (imageBytes != null) {
                            _showImageOptionsSheet(context, index);
                          } else {
                            onPickOptionImage?.call(index);
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: imageBytes != null ? const Color(0xFF1D9BF0) : borderColor,
                              width: imageBytes != null ? 1.5 : 1.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.image_outlined,
                                    color: context.textMuted,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Choice TextField Input
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 1.0),
                          ),
                          alignment: Alignment.center,
                          child: TextField(
                            controller: controllers[index],
                            maxLength: 25,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              color: context.textPrimary,
                              fontWeight: FontWeight.w400,
                            ),
                            decoration: InputDecoration(
                              hintText: "Choice ${index + 1}",
                              hintStyle: GoogleFonts.inter(
                                fontSize: 14.5,
                                color: context.textMuted,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),
                      ),

                      // Action Icon Button (Close 'X' or Plus '+')
                      if (isFirst) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.isDarkMode
                                  ? const Color(0xFF2C2F33)
                                  : const Color(0xFFE2E8F0),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ] else if (canAddMore) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: onAddOption,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: const Icon(
                              Icons.add_rounded,
                              color: Color(0xFF1D9BF0),
                              size: 26,
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => onRemoveOption(index),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.isDarkMode
                                  ? const Color(0xFF2C2F33)
                                  : const Color(0xFFE2E8F0),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.textPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),

          // Divider Line
          Divider(height: 1, thickness: 1, color: borderColor),

          // Poll Length Section
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Poll length",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                GestureDetector(
                  onTap: () => _showSetLengthDialog(context),
                  child: Text(
                    _getDurationLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1D9BF0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetLengthDialog extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onSet;

  const _SetLengthDialog({
    required this.initialDuration,
    required this.onSet,
  });

  @override
  State<_SetLengthDialog> createState() => _SetLengthDialogState();
}

class _SetLengthDialogState extends State<_SetLengthDialog> {
  late int _selectedDays;
  late int _selectedHours;
  late int _selectedMins;

  late FixedExtentScrollController _daysController;
  late FixedExtentScrollController _hoursController;
  late FixedExtentScrollController _minsController;

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDuration.inDays.clamp(0, 7);
    _selectedHours = (widget.initialDuration.inHours % 24).clamp(0, 23);
    _selectedMins = (widget.initialDuration.inMinutes % 60).clamp(0, 59);

    _daysController = FixedExtentScrollController(initialItem: _selectedDays);
    _hoursController = FixedExtentScrollController(initialItem: _selectedHours);
    _minsController = FixedExtentScrollController(initialItem: _selectedMins);
  }

  @override
  void dispose() {
    _daysController.dispose();
    _hoursController.dispose();
    _minsController.dispose();
    super.dispose();
  }

  void _handleSet() {
    Duration newDuration = Duration(
      days: _selectedDays,
      hours: _selectedHours,
      minutes: _selectedMins,
    );

    // If all 0, default to 1 day
    if (newDuration.inMinutes == 0) {
      newDuration = const Duration(days: 1);
    }

    widget.onSet(newDuration);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final dialogBgColor = isDark ? const Color(0xFF16181C) : const Color(0xFFFFFFFF);
    final textPrimaryColor = isDark ? Colors.white : Colors.black;
    final textSecondaryColor = isDark ? const Color(0xFF8B98A5) : const Color(0xFF536471);
    final dividerColor = isDark ? const Color(0xFF2F3336) : const Color(0xFFCFD9DE);

    return Dialog(
      backgroundColor: dialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        decoration: BoxDecoration(
          color: dialogBgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Set length",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),

            // Headers: Days, Hours, Min
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      "Days",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Hours",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Min",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textSecondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3 Scroll Wheels Container
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // Days Wheel (0 - 7)
                  Expanded(
                    child: _buildPickerWheel(
                      controller: _daysController,
                      itemCount: 8,
                      selectedIndex: _selectedDays,
                      onChanged: (idx) {
                        setState(() {
                          _selectedDays = idx;
                        });
                      },
                      textColor: textPrimaryColor,
                      dividerColor: dividerColor,
                    ),
                  ),

                  // Hours Wheel (0 - 23)
                  Expanded(
                    child: _buildPickerWheel(
                      controller: _hoursController,
                      itemCount: 24,
                      selectedIndex: _selectedHours,
                      onChanged: (idx) {
                        setState(() {
                          _selectedHours = idx;
                        });
                      },
                      textColor: textPrimaryColor,
                      dividerColor: dividerColor,
                    ),
                  ),

                  // Min Wheel (0 - 59)
                  Expanded(
                    child: _buildPickerWheel(
                      controller: _minsController,
                      itemCount: 60,
                      selectedIndex: _selectedMins,
                      onChanged: (idx) {
                        setState(() {
                          _selectedMins = idx;
                        });
                      },
                      textColor: textPrimaryColor,
                      dividerColor: dividerColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Set Button
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleSet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    "Set",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required Color textColor,
    required Color dividerColor,
  }) {
    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 38,
      onSelectedItemChanged: onChanged,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: dividerColor,
              width: 1.0,
            ),
          ),
        ),
      ),
      children: List.generate(itemCount, (index) {
        final isSelected = index == selectedIndex;
        return Center(
          child: Text(
            "$index",
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? textColor : textColor.withValues(alpha: 0.35),
            ),
          ),
        );
      }),
    );
  }
}
