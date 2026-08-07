import 'package:dak/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/database_service.dart';
import '../../../state/verification_controller.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/verification/pigeon_primary_button.dart';
import '../../../widgets/verification/pigeon_text_field.dart';
import '../../../widgets/verification/step_progress_bar.dart';
import 'business_identity_upload_screen.dart';
import 'government_identity_upload_screen.dart';
import 'identity_upload_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dob;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<VerificationController>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final myProfile = dbService.myProfile;
    final authUser = Supabase.instance.client.auth.currentUser;

    // Get live logged-in user profile details
    final String liveFullName = (myProfile?.fullName.isNotEmpty == true)
        ? myProfile!.fullName
        : (authUser?.userMetadata?['full_name'] as String? ??
            authUser?.userMetadata?['name'] as String? ??
            '');

    final String liveUsername = (myProfile?.username.isNotEmpty == true)
        ? myProfile!.username
        : (authUser?.userMetadata?['username'] as String? ?? '');

    final String liveEmail = (myProfile?.email?.isNotEmpty == true)
        ? myProfile!.email!
        : (authUser?.email ?? '');

    final String livePhone = (myProfile?.phone?.isNotEmpty == true)
        ? myProfile!.phone!
        : (authUser?.phone ?? '');

    final String liveBio = myProfile?.bio ?? '';

    // Prefer live logged-in user profile details
    _nameController.text = liveFullName.isNotEmpty
        ? liveFullName
        : controller.request.fullName;

    _usernameController.text = liveUsername.isNotEmpty
        ? liveUsername
        : controller.request.username;

    _bioController.text = liveBio.isNotEmpty
        ? liveBio
        : controller.request.bio;

    _emailController.text = liveEmail.isNotEmpty
        ? liveEmail
        : controller.request.email;

    _phoneController.text = livePhone.isNotEmpty
        ? livePhone
        : controller.request.phone;

    if (myProfile?.birthdate?.isNotEmpty == true) {
      _dob = DateTime.tryParse(myProfile!.birthdate!);
    } else if (controller.request.dateOfBirth != null) {
      _dob = controller.request.dateOfBirth;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: context.primaryAccent,
              primary: context.primaryAccent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectYourDateOfBirth)),
      );
      return;
    }

    context.read<VerificationController>().updatePersonalDetails(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          dateOfBirth: _dob!,
          bio: _bioController.text.trim(),
        );

    context.read<VerificationController>().updateContactInfo(
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
        );

    final req = context.read<VerificationController>().request;
    if (req.isBusiness) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BusinessIdentityUploadScreen()),
      );
    } else if (req.isGovernment) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GovernmentIdentityUploadScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const IdentityUploadScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = context.watch<VerificationController>().request;
    final steps = VerificationController.getSteps(req.category);

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          req.isBusiness
              ? "Apply for Gold Badge 👑"
              : (req.isGovernment ? "Apply for Gray Badge 🏛️" : "Apply for Blue Badge 🔵"),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            StepProgressBar(currentStep: 1, labels: steps),
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.confirmPersonalDetails,
                          style: GoogleFonts.inter(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                              letterSpacing: -0.4)),
                      const SizedBox(height: 6),
                      Text(AppLocalizations.of(context)!.yourNameProfilePhotoAndDetailsShouldMatc,
                        style: GoogleFonts.inter(
                          color: context.textSecondary, 
                          fontSize: 13,
                          height: 1.45
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      PigeonTextField(
                        label: AppLocalizations.of(context)!.fullName,
                        hint: 'e.g. Abdullah Al Mamun',
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Full name is required'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      
                      PigeonTextField(
                        label: AppLocalizations.of(context)!.pigeonUsername,
                        hint: 'yourhandle',
                        controller: _usernameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Username is required'
                            : null,
                      ),
                      const SizedBox(height: 6),

                      PigeonTextField(
                        label: AppLocalizations.of(context)!.dateOfBirth,
                        hint: 'Tap to select',
                        controller: TextEditingController(
                          text: _dob == null
                              ? ''
                              : '${_dob!.day.toString().padLeft(2, '0')}/${_dob!.month.toString().padLeft(2, '0')}/${_dob!.year}',
                        ),
                        readOnly: true,
                        onTap: _pickDob,
                        prefixIcon: Icon(Icons.calendar_today_outlined,
                            size: 18, color: context.textMuted),
                      ),
                      const SizedBox(height: 6),

                      PigeonTextField(
                        label: AppLocalizations.of(context)!.emailAddress,
                        hint: 'your.email@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegExp.hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      PigeonTextField(
                        label: AppLocalizations.of(context)!.phoneNumber,
                        hint: '01XXXXXXXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final phoneRegExp = RegExp(r'^(?:\+88|88)?(01[3-9]\d{8})$');
                          if (!phoneRegExp.hasMatch(v.trim())) {
                            return 'Enter a valid Bangladeshi phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6),

                      PigeonTextField(
                        label: AppLocalizations.of(context)!.shortBioOptional,
                        hint: 'Tell us a little about yourself',
                        controller: _bioController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: PigeonPrimaryButton(
                label: AppLocalizations.of(context)!.saveContinue,
                icon: Icons.arrow_forward_rounded,
                onPressed: _onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
