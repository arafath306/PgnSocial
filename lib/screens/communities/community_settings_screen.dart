import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/community_service.dart';
import '../../utils/app_theme.dart';
import '../../models/community.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommunitySettingsScreen extends StatefulWidget {
  final Community community;
  const CommunitySettingsScreen({super.key, required this.community});

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _privacy;
  
  File? _avatarFile;
  File? _bannerFile;
  bool _isLoading = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.community.name);
    _descController = TextEditingController(text: widget.community.description ?? '');
    _privacy = widget.community.privacy;
  }

  Future<void> _pickImage(bool isAvatar) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isAvatar) {
          _avatarFile = File(picked.path);
        } else {
          _bannerFile = File(picked.path);
        }
      });
    }
  }

  void _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community name is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final service = Provider.of<CommunityService>(context, listen: false);
    final success = await service.updateCommunity(
      id: widget.community.id,
      name: name,
      description: _descController.text.trim(),
      privacy: _privacy,
      avatarFile: _avatarFile,
      bannerFile: _bannerFile,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update community')),
        );
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.scaffoldBg,
        title: Text("Delete Community", style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this community? This action cannot be undone.", style: GoogleFonts.inter(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: GoogleFonts.inter(color: context.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              final service = Provider.of<CommunityService>(context, listen: false);
              final success = await service.deleteCommunity(widget.community.id);
              if (success && mounted) {
                // Pop back twice: once from settings, once from detail screen
                Navigator.of(context).popUntil((route) => route.isFirst);
              } else {
                setState(() => _isLoading = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete community')),
                  );
                }
              }
            },
            child: Text("Delete", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Community Settings",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading 
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E824C)),
                  )
                : Text(
                    "Save",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E824C),
                    ),
                  ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, thickness: 0.5, color: context.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _pickImage(false),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: context.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: _bannerFile != null
                      ? DecorationImage(image: FileImage(_bannerFile!), fit: BoxFit.cover)
                      : (widget.community.bannerUrl != null 
                          ? DecorationImage(image: CachedNetworkImageProvider(widget.community.bannerUrl!), fit: BoxFit.cover) 
                          : null),
                ),
                child: _bannerFile == null && widget.community.bannerUrl == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: context.textSecondary),
                            const SizedBox(height: 4),
                            Text("Add Banner", style: GoogleFonts.inter(color: context.textSecondary)),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(true),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    shape: BoxShape.circle,
                    image: _avatarFile != null
                        ? DecorationImage(image: FileImage(_avatarFile!), fit: BoxFit.cover)
                        : (widget.community.avatarUrl != null 
                            ? DecorationImage(image: CachedNetworkImageProvider(widget.community.avatarUrl!), fit: BoxFit.cover) 
                            : null),
                  ),
                  child: _avatarFile == null && widget.community.avatarUrl == null
                      ? Icon(Icons.add_a_photo, color: context.textSecondary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Community Name",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: GoogleFonts.inter(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: "e.g., Flutter Developers",
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                filled: true,
                fillColor: context.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E824C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Description",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: GoogleFonts.inter(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: "What is this community about?",
                hintStyle: GoogleFonts.inter(color: context.textMuted),
                filled: true,
                fillColor: context.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E824C), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Privacy",
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.border),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text("Public", style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w500)),
                    subtitle: Text("Anyone can view and join", style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
                    value: "public",
                    // ignore: deprecated_member_use
                    groupValue: _privacy,
                    activeColor: const Color(0xFF1E824C),
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _privacy = val!),
                  ),
                  Divider(height: 1, color: context.border),
                  RadioListTile<String>(
                    title: Text("Restricted", style: GoogleFonts.inter(color: context.textPrimary, fontWeight: FontWeight.w500)),
                    subtitle: Text("Only members can view content", style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
                    value: "restricted",
                    // ignore: deprecated_member_use
                    groupValue: _privacy,
                    activeColor: const Color(0xFF1E824C),
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _privacy = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _confirmDelete,
                icon: const Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
                label: Text("Delete Community", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
