import 'package:flutter/material.dart';

class ChatTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final List<Color>? gradientColors; // If null, use solid primaryColor
  final bool isDark; // Indicates if text on these colors should be white (true) or black (false)

  const ChatTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    this.gradientColors,
    this.isDark = true,
  });
}

const List<ChatTheme> availableChatThemes = [
  // ── Signature & Corporate Solids ──────────────────────────────────────────
  ChatTheme(
    id: 'default',
    name: 'Dak Emerald',
    primaryColor: Color(0xFF1E824C), // Signature Dak Green
  ),
  ChatTheme(
    id: 'midnight_blue',
    name: 'Sapphire Blue',
    primaryColor: Color(0xFF1D9BF0), // Twitter/X Blue
  ),
  ChatTheme(
    id: 'slate_titanium',
    name: 'Slate Titanium',
    primaryColor: Color(0xFF475569), // Minimal Corporate Slate
  ),
  ChatTheme(
    id: 'royal_purple',
    name: 'Royal Purple',
    primaryColor: Color(0xFF7C3AED),
  ),
  ChatTheme(
    id: 'forest_green',
    name: 'Forest Jade',
    primaryColor: Color(0xFF059669),
  ),
  ChatTheme(
    id: 'dark_mode',
    name: 'Obsidian Black',
    primaryColor: Color(0xFF1E293B),
  ),

  // ── Premium Gradients ─────────────────────────────────────────────────────
  ChatTheme(
    id: 'sapphire_gradient',
    name: 'Twitter Blue',
    primaryColor: Color(0xFF1D9BF0),
    gradientColors: [Color(0xFF1D9BF0), Color(0xFF0A66C2)],
  ),
  ChatTheme(
    id: 'royal_velvet',
    name: 'Neon Velvet',
    primaryColor: Color(0xFF8B5CF6),
    gradientColors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  ),
  ChatTheme(
    id: 'pacific_ocean',
    name: 'Pacific Cyan',
    primaryColor: Color(0xFF06B6D4),
    gradientColors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ),
  ChatTheme(
    id: 'sunset_flare',
    name: 'Sunset Flare',
    primaryColor: Color(0xFFFF5E7E),
    gradientColors: [Color(0xFFFF5E7E), Color(0xFFFFBE76)],
  ),
  ChatTheme(
    id: 'cyberpunk',
    name: 'Cyberpunk',
    primaryColor: Color(0xFFFF007F),
    gradientColors: [Color(0xFFFF007F), Color(0xFF00F0FF)],
  ),
  ChatTheme(
    id: 'mint_aurora',
    name: 'Mint Aurora',
    primaryColor: Color(0xFF10B981),
    gradientColors: [Color(0xFF10B981), Color(0xFF047857)],
  ),
  ChatTheme(
    id: 'solar_mango',
    name: 'Solar Sunrise',
    primaryColor: Color(0xFFF59E0B),
    gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ),
  ChatTheme(
    id: 'rose_sakura',
    name: 'Rose Gold',
    primaryColor: Color(0xFFF43F5E),
    gradientColors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
  ),
  ChatTheme(
    id: 'electric_indigo',
    name: 'Electric Indigo',
    primaryColor: Color(0xFF4F46E5),
    gradientColors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  ),
  ChatTheme(
    id: 'nordic_lights',
    name: 'Nordic Lights',
    primaryColor: Color(0xFF43C6AC),
    gradientColors: [Color(0xFF43C6AC), Color(0xFF191654)],
  ),
];

// Helper to get theme by ID
ChatTheme getChatThemeById(String? id) {
  if (id == null || id.isEmpty) return availableChatThemes.first;
  
  // Check if it's a custom wallpaper URL
  if (id.startsWith('custom:')) return availableChatThemes.first;

  try {
    return availableChatThemes.firstWhere(
      (theme) => theme.id == id,
      orElse: () => availableChatThemes.first,
    );
  } catch (e) {
    return availableChatThemes.first;
  }
}
