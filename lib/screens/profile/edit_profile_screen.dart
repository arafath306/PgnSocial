import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';

// ─────────────────────────────────────────────────────────────────
// Full list of world countries + ISO flags
// ─────────────────────────────────────────────────────────────────
const List<Map<String, String>> _kCountries = [
  {'flag': '🇦🇫', 'name': 'Afghanistan'},
  {'flag': '🇦🇱', 'name': 'Albania'},
  {'flag': '🇩🇿', 'name': 'Algeria'},
  {'flag': '🇦🇩', 'name': 'Andorra'},
  {'flag': '🇦🇴', 'name': 'Angola'},
  {'flag': '🇦🇬', 'name': 'Antigua and Barbuda'},
  {'flag': '🇦🇷', 'name': 'Argentina'},
  {'flag': '🇦🇲', 'name': 'Armenia'},
  {'flag': '🇦🇺', 'name': 'Australia'},
  {'flag': '🇦🇹', 'name': 'Austria'},
  {'flag': '🇦🇿', 'name': 'Azerbaijan'},
  {'flag': '🇧🇸', 'name': 'Bahamas'},
  {'flag': '🇧🇭', 'name': 'Bahrain'},
  {'flag': '🇧🇩', 'name': 'Bangladesh'},
  {'flag': '🇧🇧', 'name': 'Barbados'},
  {'flag': '🇧🇾', 'name': 'Belarus'},
  {'flag': '🇧🇪', 'name': 'Belgium'},
  {'flag': '🇧🇿', 'name': 'Belize'},
  {'flag': '🇧🇯', 'name': 'Benin'},
  {'flag': '🇧🇹', 'name': 'Bhutan'},
  {'flag': '🇧🇴', 'name': 'Bolivia'},
  {'flag': '🇧🇦', 'name': 'Bosnia and Herzegovina'},
  {'flag': '🇧🇼', 'name': 'Botswana'},
  {'flag': '🇧🇷', 'name': 'Brazil'},
  {'flag': '🇧🇳', 'name': 'Brunei'},
  {'flag': '🇧🇬', 'name': 'Bulgaria'},
  {'flag': '🇧🇫', 'name': 'Burkina Faso'},
  {'flag': '🇧🇮', 'name': 'Burundi'},
  {'flag': '🇨🇻', 'name': 'Cabo Verde'},
  {'flag': '🇰🇭', 'name': 'Cambodia'},
  {'flag': '🇨🇲', 'name': 'Cameroon'},
  {'flag': '🇨🇦', 'name': 'Canada'},
  {'flag': '🇨🇫', 'name': 'Central African Republic'},
  {'flag': '🇹🇩', 'name': 'Chad'},
  {'flag': '🇨🇱', 'name': 'Chile'},
  {'flag': '🇨🇳', 'name': 'China'},
  {'flag': '🇨🇴', 'name': 'Colombia'},
  {'flag': '🇰🇲', 'name': 'Comoros'},
  {'flag': '🇨🇩', 'name': 'Congo (DRC)'},
  {'flag': '🇨🇬', 'name': 'Congo (Republic)'},
  {'flag': '🇨🇷', 'name': 'Costa Rica'},
  {'flag': '🇨🇮', 'name': "Côte d'Ivoire"},
  {'flag': '🇭🇷', 'name': 'Croatia'},
  {'flag': '🇨🇺', 'name': 'Cuba'},
  {'flag': '🇨🇾', 'name': 'Cyprus'},
  {'flag': '🇨🇿', 'name': 'Czech Republic'},
  {'flag': '🇩🇰', 'name': 'Denmark'},
  {'flag': '🇩🇯', 'name': 'Djibouti'},
  {'flag': '🇩🇲', 'name': 'Dominica'},
  {'flag': '🇩🇴', 'name': 'Dominican Republic'},
  {'flag': '🇪🇨', 'name': 'Ecuador'},
  {'flag': '🇪🇬', 'name': 'Egypt'},
  {'flag': '🇸🇻', 'name': 'El Salvador'},
  {'flag': '🇬🇶', 'name': 'Equatorial Guinea'},
  {'flag': '🇪🇷', 'name': 'Eritrea'},
  {'flag': '🇪🇪', 'name': 'Estonia'},
  {'flag': '🇸🇿', 'name': 'Eswatini'},
  {'flag': '🇪🇹', 'name': 'Ethiopia'},
  {'flag': '🇫🇯', 'name': 'Fiji'},
  {'flag': '🇫🇮', 'name': 'Finland'},
  {'flag': '🇫🇷', 'name': 'France'},
  {'flag': '🇬🇦', 'name': 'Gabon'},
  {'flag': '🇬🇲', 'name': 'Gambia'},
  {'flag': '🇬🇪', 'name': 'Georgia'},
  {'flag': '🇩🇪', 'name': 'Germany'},
  {'flag': '🇬🇭', 'name': 'Ghana'},
  {'flag': '🇬🇷', 'name': 'Greece'},
  {'flag': '🇬🇩', 'name': 'Grenada'},
  {'flag': '🇬🇹', 'name': 'Guatemala'},
  {'flag': '🇬🇳', 'name': 'Guinea'},
  {'flag': '🇬🇼', 'name': 'Guinea-Bissau'},
  {'flag': '🇬🇾', 'name': 'Guyana'},
  {'flag': '🇭🇹', 'name': 'Haiti'},
  {'flag': '🇭🇳', 'name': 'Honduras'},
  {'flag': '🇭🇺', 'name': 'Hungary'},
  {'flag': '🇮🇸', 'name': 'Iceland'},
  {'flag': '🇮🇳', 'name': 'India'},
  {'flag': '🇮🇩', 'name': 'Indonesia'},
  {'flag': '🇮🇷', 'name': 'Iran'},
  {'flag': '🇮🇶', 'name': 'Iraq'},
  {'flag': '🇮🇪', 'name': 'Ireland'},
  {'flag': '🇮🇱', 'name': 'Israel'},
  {'flag': '🇮🇹', 'name': 'Italy'},
  {'flag': '🇯🇲', 'name': 'Jamaica'},
  {'flag': '🇯🇵', 'name': 'Japan'},
  {'flag': '🇯🇴', 'name': 'Jordan'},
  {'flag': '🇰🇿', 'name': 'Kazakhstan'},
  {'flag': '🇰🇪', 'name': 'Kenya'},
  {'flag': '🇰🇮', 'name': 'Kiribati'},
  {'flag': '🇰🇼', 'name': 'Kuwait'},
  {'flag': '🇰🇬', 'name': 'Kyrgyzstan'},
  {'flag': '🇱🇦', 'name': 'Laos'},
  {'flag': '🇱🇻', 'name': 'Latvia'},
  {'flag': '🇱🇧', 'name': 'Lebanon'},
  {'flag': '🇱🇸', 'name': 'Lesotho'},
  {'flag': '🇱🇷', 'name': 'Liberia'},
  {'flag': '🇱🇾', 'name': 'Libya'},
  {'flag': '🇱🇮', 'name': 'Liechtenstein'},
  {'flag': '🇱🇹', 'name': 'Lithuania'},
  {'flag': '🇱🇺', 'name': 'Luxembourg'},
  {'flag': '🇲🇬', 'name': 'Madagascar'},
  {'flag': '🇲🇼', 'name': 'Malawi'},
  {'flag': '🇲🇾', 'name': 'Malaysia'},
  {'flag': '🇲🇻', 'name': 'Maldives'},
  {'flag': '🇲🇱', 'name': 'Mali'},
  {'flag': '🇲🇹', 'name': 'Malta'},
  {'flag': '🇲🇭', 'name': 'Marshall Islands'},
  {'flag': '🇲🇷', 'name': 'Mauritania'},
  {'flag': '🇲🇺', 'name': 'Mauritius'},
  {'flag': '🇲🇽', 'name': 'Mexico'},
  {'flag': '🇫🇲', 'name': 'Micronesia'},
  {'flag': '🇲🇩', 'name': 'Moldova'},
  {'flag': '🇲🇨', 'name': 'Monaco'},
  {'flag': '🇲🇳', 'name': 'Mongolia'},
  {'flag': '🇲🇪', 'name': 'Montenegro'},
  {'flag': '🇲🇦', 'name': 'Morocco'},
  {'flag': '🇲🇿', 'name': 'Mozambique'},
  {'flag': '🇲🇲', 'name': 'Myanmar'},
  {'flag': '🇳🇦', 'name': 'Namibia'},
  {'flag': '🇳🇷', 'name': 'Nauru'},
  {'flag': '🇳🇵', 'name': 'Nepal'},
  {'flag': '🇳🇱', 'name': 'Netherlands'},
  {'flag': '🇳🇿', 'name': 'New Zealand'},
  {'flag': '🇳🇮', 'name': 'Nicaragua'},
  {'flag': '🇳🇪', 'name': 'Niger'},
  {'flag': '🇳🇬', 'name': 'Nigeria'},
  {'flag': '🇲🇰', 'name': 'North Macedonia'},
  {'flag': '🇳🇴', 'name': 'Norway'},
  {'flag': '🇴🇲', 'name': 'Oman'},
  {'flag': '🇵🇰', 'name': 'Pakistan'},
  {'flag': '🇵🇼', 'name': 'Palau'},
  {'flag': '🇵🇦', 'name': 'Panama'},
  {'flag': '🇵🇬', 'name': 'Papua New Guinea'},
  {'flag': '🇵🇾', 'name': 'Paraguay'},
  {'flag': '🇵🇪', 'name': 'Peru'},
  {'flag': '🇵🇭', 'name': 'Philippines'},
  {'flag': '🇵🇱', 'name': 'Poland'},
  {'flag': '🇵🇹', 'name': 'Portugal'},
  {'flag': '🇶🇦', 'name': 'Qatar'},
  {'flag': '🇷🇴', 'name': 'Romania'},
  {'flag': '🇷🇺', 'name': 'Russia'},
  {'flag': '🇷🇼', 'name': 'Rwanda'},
  {'flag': '🇰🇳', 'name': 'Saint Kitts and Nevis'},
  {'flag': '🇱🇨', 'name': 'Saint Lucia'},
  {'flag': '🇻🇨', 'name': 'Saint Vincent and the Grenadines'},
  {'flag': '🇼🇸', 'name': 'Samoa'},
  {'flag': '🇸🇲', 'name': 'San Marino'},
  {'flag': '🇸🇹', 'name': 'São Tomé and Príncipe'},
  {'flag': '🇸🇦', 'name': 'Saudi Arabia'},
  {'flag': '🇸🇳', 'name': 'Senegal'},
  {'flag': '🇷🇸', 'name': 'Serbia'},
  {'flag': '🇸🇨', 'name': 'Seychelles'},
  {'flag': '🇸🇱', 'name': 'Sierra Leone'},
  {'flag': '🇸🇬', 'name': 'Singapore'},
  {'flag': '🇸🇰', 'name': 'Slovakia'},
  {'flag': '🇸🇮', 'name': 'Slovenia'},
  {'flag': '🇸🇧', 'name': 'Solomon Islands'},
  {'flag': '🇸🇴', 'name': 'Somalia'},
  {'flag': '🇿🇦', 'name': 'South Africa'},
  {'flag': '🇸🇸', 'name': 'South Sudan'},
  {'flag': '🇪🇸', 'name': 'Spain'},
  {'flag': '🇱🇰', 'name': 'Sri Lanka'},
  {'flag': '🇸🇩', 'name': 'Sudan'},
  {'flag': '🇸🇷', 'name': 'Suriname'},
  {'flag': '🇸🇪', 'name': 'Sweden'},
  {'flag': '🇨🇭', 'name': 'Switzerland'},
  {'flag': '🇸🇾', 'name': 'Syria'},
  {'flag': '🇹🇼', 'name': 'Taiwan'},
  {'flag': '🇹🇯', 'name': 'Tajikistan'},
  {'flag': '🇹🇿', 'name': 'Tanzania'},
  {'flag': '🇹🇭', 'name': 'Thailand'},
  {'flag': '🇹🇱', 'name': 'Timor-Leste'},
  {'flag': '🇹🇬', 'name': 'Togo'},
  {'flag': '🇹🇴', 'name': 'Tonga'},
  {'flag': '🇹🇹', 'name': 'Trinidad and Tobago'},
  {'flag': '🇹🇳', 'name': 'Tunisia'},
  {'flag': '🇹🇷', 'name': 'Turkey'},
  {'flag': '🇹🇲', 'name': 'Turkmenistan'},
  {'flag': '🇹🇻', 'name': 'Tuvalu'},
  {'flag': '🇺🇬', 'name': 'Uganda'},
  {'flag': '🇺🇦', 'name': 'Ukraine'},
  {'flag': '🇦🇪', 'name': 'United Arab Emirates'},
  {'flag': '🇬🇧', 'name': 'United Kingdom'},
  {'flag': '🇺🇸', 'name': 'United States'},
  {'flag': '🇺🇾', 'name': 'Uruguay'},
  {'flag': '🇺🇿', 'name': 'Uzbekistan'},
  {'flag': '🇻🇺', 'name': 'Vanuatu'},
  {'flag': '🇻🇦', 'name': 'Vatican City'},
  {'flag': '🇻🇪', 'name': 'Venezuela'},
  {'flag': '🇻🇳', 'name': 'Vietnam'},
  {'flag': '🇾🇪', 'name': 'Yemen'},
  {'flag': '🇿🇲', 'name': 'Zambia'},
  {'flag': '🇿🇼', 'name': 'Zimbabwe'},
];

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _villageCtrl;
  late TextEditingController _zipCtrl;

  late final String _initialName;
  late final String _initialUsername;
  late final String _initialBio;
  late final String _initialPhone;
  late final String _initialCity;
  late final String _initialVillage;
  late final String _initialZip;
  late final String? _initialCountry;
  late final String? _initialDivision;
  late final String? _initialGender;
  late final String? _initialBirthdate;

  Timer? _debounceUsernameTimer;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _usernameError;

  String? _selectedCountry;
  String? _selectedDivision;
  String? _selectedGender;
  String? _birthdateString;

  String? _avatarUrl;
  String? _coverUrl;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isPickingImage = false;
  String? _errorMsg;

  Future<void> _pickAndUploadImage(DatabaseService db, bool isAvatar) async {
    if (_isPickingImage || _isUploadingPhoto) return;
    setState(() {
      _isPickingImage = true;
    });
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) {
        setState(() {
          _isPickingImage = false;
        });
        return;
      }

      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: isAvatar ? const CropAspectRatio(ratioX: 1, ratioY: 1) : const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: isAvatar ? 'Crop Profile Photo' : 'Crop Cover Photo',
            toolbarColor: Colors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: isAvatar ? 'Crop Profile Photo' : 'Crop Cover Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) {
        setState(() {
          _isPickingImage = false;
        });
        return;
      }

      setState(() => _isUploadingPhoto = true);
      final bytes = await croppedFile.readAsBytes();
      final success = await db.updateProfileImage(bytes, isAvatar);
      
      if (!mounted) return;
      
      if (success) {
        db.fetchMyProfile();
        if (isAvatar) {
          _avatarUrl = db.myProfile?.avatarUrl;
        } else {
          _coverUrl = db.myProfile?.coverUrl;
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvatar ? 'Profile photo updated successfully.' : 'Cover photo updated successfully.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image. Please try again.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _isPickingImage = false;
        });
      }
    }
  }

  final List<Map<String, String>> _genders = [
    {"label": "Male", "value": "Male"},
    {"label": "Female", "value": "Female"},
    {"label": "Other", "value": "Other"}
  ];

  @override
  void initState() {
    super.initState();
    _initialName = widget.profile['full_name']?.toString() ?? '';
    _initialUsername = widget.profile['username']?.toString() ?? '';
    _initialBio = widget.profile['bio']?.toString() ?? '';
    _initialPhone = widget.profile['phone']?.toString() ?? '';
    _initialCity = widget.profile['city']?.toString() ?? '';
    _initialVillage = widget.profile['village']?.toString() ?? '';
    _initialZip = widget.profile['zip']?.toString() ?? '';

    _nameCtrl = TextEditingController(text: _initialName);
    _usernameCtrl = TextEditingController(text: _initialUsername);
    _bioCtrl = TextEditingController(text: _initialBio);
    _phoneCtrl = TextEditingController(text: _initialPhone);
    _cityCtrl = TextEditingController(text: _initialCity);
    _villageCtrl = TextEditingController(text: _initialVillage);
    _zipCtrl = TextEditingController(text: _initialZip);

    _selectedCountry = widget.profile['country']?.toString();
    if (_selectedCountry != null && _selectedCountry!.isEmpty) _selectedCountry = null;
    _initialCountry = _selectedCountry;

    _selectedDivision = widget.profile['division']?.toString();
    if (_selectedDivision != null && _selectedDivision!.isEmpty) _selectedDivision = null;
    _initialDivision = _selectedDivision;

    _selectedGender = widget.profile['gender']?.toString();
    if (_selectedGender != null) {
      if (_selectedGender == 'Male' || _selectedGender == 'পুরুষ') {
        _selectedGender = 'Male';
      } else if (_selectedGender == 'Female' || _selectedGender == 'নারী') {
        _selectedGender = 'Female';
      } else if (_selectedGender == 'Other' || _selectedGender == 'অন্যান্য') {
        _selectedGender = 'Other';
      } else {
        _selectedGender = null;
      }
    }
    _initialGender = _selectedGender;
    _birthdateString = widget.profile['birthdate']?.toString();
    _initialBirthdate = _birthdateString;
  }

  @override
  void dispose() {
    _debounceUsernameTimer?.cancel();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _villageCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    return _nameCtrl.text.trim() != _initialName.trim() ||
        _usernameCtrl.text.trim().toLowerCase() != _initialUsername.trim().toLowerCase() ||
        _bioCtrl.text.trim() != _initialBio.trim() ||
        _phoneCtrl.text.trim() != _initialPhone.trim() ||
        _cityCtrl.text.trim() != _initialCity.trim() ||
        _villageCtrl.text.trim() != _initialVillage.trim() ||
        _zipCtrl.text.trim() != _initialZip.trim() ||
        _selectedCountry != _initialCountry ||
        _selectedDivision != _initialDivision ||
        _selectedGender != _initialGender ||
        _birthdateString != _initialBirthdate;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Discard changes?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: context.textPrimary),
        ),
        content: Text(
          'You have unsaved changes. If you leave now, your changes will be discarded.',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep Editing',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: context.primaryAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Discard',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  void _onUsernameChanged(String val) {
    _debounceUsernameTimer?.cancel();
    final trimmed = val.trim().toLowerCase();

    if (trimmed == _initialUsername.toLowerCase()) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = null;
        _usernameError = null;
      });
      return;
    }

    if (trimmed.isEmpty) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = "Username cannot be empty";
      });
      return;
    }

    final reg = RegExp(r'^[a-zA-Z0-9_]{3,30}$');
    if (!reg.hasMatch(trimmed)) {
      setState(() {
        _isCheckingUsername = false;
        _isUsernameAvailable = false;
        _usernameError = "3-30 characters (letters, numbers, _ only)";
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    _debounceUsernameTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final taken = await authService.isUsernameTaken(trimmed);
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = !taken;
          _usernameError = taken ? "This username is already taken" : null;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isCheckingUsername = false;
        });
      }
    });
  }

  // ── Country picker ─────────────────────────────────────────
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchablePickerSheet(
        title: 'Select Country',
        hintText: 'Search countries...',
        items: _kCountries.map((c) => '${c['flag']} ${c['name']}').toList(),
        selected: _selectedCountry != null
            ? _kCountries
                .where((c) => c['name'] == _selectedCountry)
                .map((c) => '${c['flag']} ${c['name']}')
                .firstOrNull
            : null,
        onSelected: (val) {
          final name = val.substring(val.indexOf(' ') + 1);
          setState(() => _selectedCountry = name);
        },
      ),
    );
  }

  // ── Division / State / Region picker ───────────────────────
  void _showDivisionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchablePickerSheet(
        title: 'Select State / Division / Region',
        hintText: 'Search or type any region...',
        items: _kWorldDivisions,
        selected: _selectedDivision,
        allowCustom: true,
        onSelected: (val) => setState(() => _selectedDivision = val),
      ),
    );
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    DateTime initialDate = DateTime(2000);
    if (_birthdateString != null && _birthdateString!.isNotEmpty) {
      try {
        final parts = _birthdateString!.split('/');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (e) {
      debugPrint('[EditProfileScreen] Error parsing birthday date: $e');
    }
    }

    final now = DateTime.now();
    final lastAllowedDate = DateTime(now.year - 13, now.month, now.day);
    if (initialDate.isAfter(lastAllowedDate)) {
      initialDate = lastAllowedDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: lastAllowedDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDarkMode
                ? const ColorScheme.dark(
                    primary: Color(0xFF0085FF),
                    onPrimary: Colors.white,
                    surface: Color(0xFF0D0F1A),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF0085FF),
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthdateString = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    final trimmedName = _nameCtrl.text.trim();
    final trimmedUser = _usernameCtrl.text.trim().toLowerCase();

    if (trimmedName.isEmpty || trimmedUser.isEmpty) {
      setState(() => _errorMsg = 'Name and username are required.');
      return;
    }

    if (_isUsernameAvailable == false) {
      setState(() => _errorMsg = _usernameError ?? 'Please choose an available username.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMsg = null;
    });

    final db = Provider.of<DatabaseService>(context, listen: false);
    final success = await db.updateProfile(
      fullName: trimmedName,
      username: trimmedUser,
      bio: _bioCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      country: _selectedCountry ?? '',
      division: _selectedDivision,
      city: _cityCtrl.text.trim(),
      village: _villageCtrl.text.trim(),
      zip: _zipCtrl.text.trim(),
      gender: _selectedGender,
      birthdate: _birthdateString,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _errorMsg = 'Failed to save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fieldBg = context.isDarkMode ? const Color(0xFF0F111E) : Colors.white;

    Widget? usernameSuffix;
    if (_isCheckingUsername) {
      usernameSuffix = const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0085FF)),
        ),
      );
    } else if (_isUsernameAvailable == true) {
      usernameSuffix = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20);
    } else if (_isUsernameAvailable == false) {
      usernameSuffix = const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20);
    }

    String? usernameHelper;
    Color? usernameHelperColor;
    if (_usernameError != null) {
      usernameHelper = _usernameError;
      usernameHelperColor = Colors.redAccent;
    } else if (_isUsernameAvailable == true) {
      usernameHelper = 'Username is available';
      usernameHelperColor = Colors.green;
    }

    final bool isUsernameBlocked = _isUsernameAvailable == false;
    final bool canSave = !_isSaving &&
        !_isCheckingUsername &&
        !isUsernameBlocked &&
        _nameCtrl.text.trim().isNotEmpty &&
        _usernameCtrl.text.trim().isNotEmpty;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final discard = await _confirmDiscard();
          if (discard && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          backgroundColor: context.scaffoldBg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close, color: context.textPrimary),
            onPressed: () async {
              final discard = await _confirmDiscard();
              if (discard && context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 17),
          ),
          actions: [
            TextButton(
              onPressed: canSave ? _saveProfile : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF0085FF)),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: canSave ? const Color(0xFF0085FF) : context.textMuted,
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: context.border, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Consumer<DatabaseService>(
            builder: (context, db, _) {
              final coverUrl = _coverUrl ?? widget.profile['cover_url'];
              final avatarUrl = _avatarUrl ?? widget.profile['avatar_url'];

              return Column(
                children: [
                  SizedBox(
                    height: 175,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: 140,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(db, false),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: coverUrl != null && coverUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: coverUrl,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.blue[50],
                                      child: Center(
                                        child: Icon(Icons.add_a_photo_outlined, color: Colors.blue[300]),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          left: 16,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : () => _pickAndUploadImage(db, true),
                            behavior: HitTestBehavior.translucent,
                            child: Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: context.scaffoldBg, width: 3),
                                  ),
                                  child: ClipOval(
                                    child: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: avatarUrl,
                                            fit: BoxFit.cover,
                                          )
                                        : Icon(Icons.person, size: 40, color: Colors.grey[400]),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0085FF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: context.scaffoldBg, width: 2),
                                    ),
                                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Edit Cover', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_isUploadingPhoto)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                ],
              );
            },
          ),
          
          if (_errorMsg != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFDEDEC),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          _field('Display Name', _nameCtrl, fieldBg, maxLength: 50),
          const SizedBox(height: 14),
          _field(
            'Username',
            _usernameCtrl,
            fieldBg,
            prefix: '@',
            maxLength: 30,
            suffixIcon: usernameSuffix,
            helperText: usernameHelper,
            helperColor: usernameHelperColor,
            onChanged: _onUsernameChanged,
          ),
          const SizedBox(height: 14),
          _field(
            'Bio',
            _bioCtrl,
            fieldBg,
            maxLines: 4,
            maxLength: 160,
            hint: 'Write something about yourself...',
          ),
          const SizedBox(height: 14),
          _field('Phone', _phoneCtrl, fieldBg,
              hint: '+880XXXXXXXXXX', keyboardType: TextInputType.phone),
          const SizedBox(height: 14),

          // ── Country ──────────────────────────────────────────
          _label('Country'),
          const SizedBox(height: 6),
          _pickerTile(
            fieldBg: fieldBg,
            value: _selectedCountry != null
                ? _kCountries
                    .where((c) => c['name'] == _selectedCountry)
                    .map((c) => '${c['flag']}  $_selectedCountry')
                    .firstOrNull
                : null,
            hint: 'Select your country',
            icon: Icons.public_rounded,
            onTap: _showCountryPicker,
            onClear: _selectedCountry != null
                ? () => setState(() => _selectedCountry = null)
                : null,
          ),
          const SizedBox(height: 14),

          // ── Division / State / Region ─────────────────────────
          _label('State / Division / Region'),
          const SizedBox(height: 6),
          _pickerTile(
            fieldBg: fieldBg,
            value: _selectedDivision,
            hint: 'Search or type any region...',
            icon: Icons.location_city_rounded,
            onTap: _showDivisionPicker,
            onClear: _selectedDivision != null
                ? () => setState(() => _selectedDivision = null)
                : null,
          ),
          const SizedBox(height: 14),

          _field('City / Town', _cityCtrl, fieldBg, hint: 'e.g. Mirpur, Dhaka', maxLength: 50),
          const SizedBox(height: 14),
          _field('Village / Street', _villageCtrl, fieldBg, hint: 'e.g. Road 5, Block D', maxLength: 100),
          const SizedBox(height: 14),
          _field('ZIP Code', _zipCtrl, fieldBg, hint: 'e.g. 1216', maxLength: 10),
          const SizedBox(height: 14),

          // ── Gender ───────────────────────────────────────────
          _label('Gender'),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            dropdownColor: context.cardBg,
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: context.isDarkMode ? const Color(0xFF24273F) : const Color(0xFFE5E7EB),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0085FF), width: 1.5),
              ),
            ),
            initialValue: _selectedGender,
            hint: Text('Select Gender',
                style: GoogleFonts.inter(color: context.textMuted)),
            items: _genders
                .map((g) => DropdownMenuItem(
                    value: g['value'],
                    child: Text(g['label']!,
                        style: GoogleFonts.inter(color: context.textPrimary))))
                .toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
          ),
          const SizedBox(height: 14),

          // ── Birthdate ─────────────────────────────────────────
          _label('Birth Date'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _selectBirthdate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: fieldBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: context.isDarkMode ? const Color(0xFF24273F) : const Color(0xFFE5E7EB),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: context.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _birthdateString != null && _birthdateString!.isNotEmpty
                          ? _birthdateString!
                          : 'Select Birth Date',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _birthdateString != null && _birthdateString!.isNotEmpty
                            ? context.textPrimary
                            : context.textMuted,
                      ),
                    ),
                  ),
                  if (_birthdateString != null && _birthdateString!.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _birthdateString = null),
                      child: Icon(Icons.close_rounded, size: 18, color: context.textMuted),
                    )
                  else
                    Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: context.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
  );
}

  Widget _pickerTile({
    required Color fieldBg,
    required String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final borderCol = context.isDarkMode ? const Color(0xFF24273F) : const Color(0xFFE5E7EB);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderCol, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? hint,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: value != null ? context.textPrimary : context.textMuted,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 18, color: context.textMuted),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    Color bg, {
    String? prefix,
    String? hint,
    int maxLines = 1,
    int? maxLength,
    Widget? suffixIcon,
    String? helperText,
    Color? helperColor,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label(label),
            if (maxLength != null)
              Padding(
                padding: const EdgeInsets.only(right: 2, bottom: 4),
                child: Text(
                  '${ctrl.text.length}/$maxLength',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: ctrl.text.length > maxLength ? Colors.redAccent : context.textMuted,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          onChanged: (val) {
            setState(() {});
            onChanged?.call(val);
          },
          decoration: InputDecoration(
            prefixText: prefix,
            prefixStyle: GoogleFonts.inter(color: context.textSecondary, fontWeight: FontWeight.w600),
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 13.5),
            filled: true,
            fillColor: bg,
            suffixIcon: suffixIcon,
            helperText: helperText,
            helperStyle: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: helperColor ?? context.textMuted,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: helperColor != null && helperColor == Colors.redAccent
                    ? Colors.redAccent.withAlpha(150)
                    : (context.isDarkMode ? const Color(0xFF24273F) : const Color(0xFFE5E7EB)),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: helperColor != null && helperColor == Colors.redAccent
                    ? Colors.redAccent
                    : const Color(0xFF0085FF),
                width: 1.5,
              ),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
        ),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 4),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: context.textSecondary.withAlpha(191),
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// Reusable searchable bottom-sheet picker
// ─────────────────────────────────────────────────────────────────
class _SearchablePickerSheet extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> items;
  final String? selected;
  final bool allowCustom;
  final ValueChanged<String> onSelected;

  const _SearchablePickerSheet({
    required this.title,
    required this.hintText,
    required this.items,
    required this.onSelected,
    this.selected,
    this.allowCustom = false,
  });

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  late TextEditingController _searchCtrl;
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((i) => i.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sheetBg = context.isDarkMode ? const Color(0xFF0D0F1A) : Colors.white;
    final inputBg = context.isDarkMode ? const Color(0xFF1A1D2E) : const Color(0xFFF3F5F8);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: GoogleFonts.inter(fontSize: 14, color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.inter(color: context.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.textMuted, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                          },
                          child: Icon(Icons.close_rounded, color: context.textMuted, size: 18),
                        )
                      : null,
                  filled: true,
                  fillColor: inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Custom entry option
            if (widget.allowCustom &&
                _searchCtrl.text.trim().isNotEmpty &&
                !_filtered.any((item) =>
                    item.toLowerCase() == _searchCtrl.text.trim().toLowerCase()))
              ListTile(
                leading: Icon(Icons.add_circle_outline_rounded,
                    color: const Color(0xFF0085FF), size: 22),
                title: Text(
                  'Use "${_searchCtrl.text.trim()}"',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF0085FF),
                      fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  widget.onSelected(_searchCtrl.text.trim());
                  Navigator.pop(context);
                },
              ),

            // Divider
            Divider(height: 1, color: context.border),

            // List
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final item = _filtered[i];
                  final isSelected = item == widget.selected;
                  return ListTile(
                    dense: true,
                    title: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF0085FF)
                            : context.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Color(0xFF0085FF), size: 18)
                        : null,
                    onTap: () {
                      widget.onSelected(item);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Curated list of world divisions/states/regions
// ─────────────────────────────────────────────────────────────────
const List<String> _kWorldDivisions = [
  // Bangladesh
  'Dhaka', 'Chattogram', 'Rajshahi', 'Khulna', 'Barishal', 'Sylhet', 'Rangpur', 'Mymensingh',
  // India
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa',
  'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
  'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland',
  'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi', 'Jammu and Kashmir',
  // United States
  'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado', 'Connecticut',
  'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho', 'Illinois', 'Indiana', 'Iowa',
  'Kansas', 'Kentucky', 'Louisiana', 'Maine', 'Maryland', 'Massachusetts', 'Michigan',
  'Minnesota', 'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
  'New Hampshire', 'New Jersey', 'New Mexico', 'New York', 'North Carolina',
  'North Dakota', 'Ohio', 'Oklahoma', 'Oregon', 'Pennsylvania', 'Rhode Island',
  'South Carolina', 'South Dakota', 'Tennessee', 'Texas', 'Utah', 'Vermont',
  'Virginia', 'Washington', 'West Virginia', 'Wisconsin', 'Wyoming',
  // United Kingdom
  'England', 'Scotland', 'Wales', 'Northern Ireland', 'London', 'Manchester',
  'Birmingham', 'Yorkshire', 'Lancashire', 'Kent',
  // Canada
  'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick', 'Newfoundland and Labrador',
  'Northwest Territories', 'Nova Scotia', 'Nunavut', 'Ontario', 'Prince Edward Island',
  'Quebec', 'Saskatchewan', 'Yukon',
  // Australia
  'New South Wales', 'Queensland', 'South Australia', 'Tasmania', 'Victoria',
  'Western Australia', 'Australian Capital Territory', 'Northern Territory',
  // Germany
  'Bavaria', 'Baden-Württemberg', 'Berlin', 'Brandenburg', 'Bremen', 'Hamburg',
  'Hesse', 'Lower Saxony', 'Mecklenburg-Vorpommern', 'North Rhine-Westphalia',
  'Rhineland-Palatinate', 'Saarland', 'Saxony', 'Saxony-Anhalt',
  'Schleswig-Holstein', 'Thuringia',
  // France
  'Île-de-France', 'Normandy', 'Bretagne', 'Occitanie', 'Nouvelle-Aquitaine',
  'Hauts-de-France', 'Grand Est', 'Pays de la Loire', 'Auvergne-Rhône-Alpes',
  // Pakistan
  'Punjab', 'Sindh', 'Khyber Pakhtunkhwa', 'Balochistan', 'Islamabad Capital Territory',
  'Azad Kashmir', 'Gilgit-Baltistan',
  // China
  'Beijing', 'Shanghai', 'Guangdong', 'Sichuan', 'Zhejiang', 'Jiangsu', 'Shandong',
  'Henan', 'Hunan', 'Hubei', 'Yunnan', 'Xinjiang', 'Tibet', 'Inner Mongolia',
  // Japan
  'Tokyo', 'Osaka', 'Hokkaido', 'Aichi', 'Kanagawa', 'Fukuoka', 'Kyoto',
  'Hyogo', 'Chiba', 'Saitama', 'Hiroshima', 'Okinawa',
  // Brazil
  'São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Bahia', 'Rio Grande do Sul',
  'Paraná', 'Pernambuco', 'Ceará', 'Goiás', 'Maranhão', 'Amazonas', 'Pará',
  // Russia
  'Moscow Oblast', 'Saint Petersburg', 'Krasnodar Krai', 'Sverdlovsk Oblast',
  'Novosibirsk Oblast', 'Tatarstan', 'Bashkortostan', 'Chelyabinsk Oblast',
  // Middle East
  'Riyadh Province', 'Makkah Province', 'Madinah Province', 'Eastern Province',
  'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman',
  'Cairo Governorate', 'Giza Governorate', 'Alexandria Governorate',
  // Turkey
  'Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya', 'Adana',
  // Malaysia
  'Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Sabah', 'Sarawak',
  // Indonesia
  'Jakarta', 'West Java', 'East Java', 'Central Java', 'Bali', 'Sumatra',
  // Nigeria
  'Lagos State', 'Kano State', 'Abuja (FCT)', 'Rivers State', 'Oyo State',
  // South Africa
  'Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape', 'Limpopo',
  // Mexico
  'Mexico City', 'Estado de México', 'Jalisco', 'Nuevo León', 'Veracruz',
  // Argentina
  'Buenos Aires', 'Córdoba', 'Santa Fe', 'Mendoza', 'Tucumán',
  // Spain
  'Madrid', 'Catalonia', 'Andalusia', 'Valencia', 'Galicia', 'Basque Country',
  // Italy
  'Lombardy', 'Lazio', 'Campania', 'Sicily', 'Veneto', 'Tuscany',
];
