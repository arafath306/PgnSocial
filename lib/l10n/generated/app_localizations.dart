import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_az.dart';
import 'app_localizations_be.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_bs.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_cy.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_et.dart';
import 'app_localizations_eu.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gl.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_hy.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ig.dart';
import 'app_localizations_is.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_jv.dart';
import 'app_localizations_ka.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_km.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ku.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_lo.dart';
import 'app_localizations_lt.dart';
import 'app_localizations_lv.dart';
import 'app_localizations_mg.dart';
import 'app_localizations_mk.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_my.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_nr.dart';
import 'app_localizations_ny.dart';
import 'app_localizations_om.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_ps.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_sd.dart';
import 'app_localizations_si.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sl.dart';
import 'app_localizations_sn.dart';
import 'app_localizations_so.dart';
import 'app_localizations_sq.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_ss.dart';
import 'app_localizations_st.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tg.dart';
import 'app_localizations_th.dart';
import 'app_localizations_ti.dart';
import 'app_localizations_tk.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_tn.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ts.dart';
import 'app_localizations_ug.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_uz.dart';
import 'app_localizations_ve.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_xh.dart';
import 'app_localizations_yo.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_zu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('am'),
    Locale('ar'),
    Locale('az'),
    Locale('be'),
    Locale('bg'),
    Locale('bn'),
    Locale('bs'),
    Locale('ca'),
    Locale('cs'),
    Locale('cy'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('et'),
    Locale('eu'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('gl'),
    Locale('gu'),
    Locale('ha'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('hy'),
    Locale('id'),
    Locale('ig'),
    Locale('is'),
    Locale('it'),
    Locale('ja'),
    Locale('jv'),
    Locale('ka'),
    Locale('kk'),
    Locale('km'),
    Locale('kn'),
    Locale('ko'),
    Locale('ku'),
    Locale('ky'),
    Locale('lo'),
    Locale('lt'),
    Locale('lv'),
    Locale('mg'),
    Locale('mk'),
    Locale('ml'),
    Locale('mn'),
    Locale('mr'),
    Locale('ms'),
    Locale('my'),
    Locale('ne'),
    Locale('nl'),
    Locale('no'),
    Locale('nr'),
    Locale('ny'),
    Locale('om'),
    Locale('pa'),
    Locale('pl'),
    Locale('ps'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('rw'),
    Locale('sd'),
    Locale('si'),
    Locale('sk'),
    Locale('sl'),
    Locale('sn'),
    Locale('so'),
    Locale('sq'),
    Locale('sr'),
    Locale('ss'),
    Locale('st'),
    Locale('sv'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('tg'),
    Locale('th'),
    Locale('ti'),
    Locale('tk'),
    Locale('tl'),
    Locale('tn'),
    Locale('tr'),
    Locale('ts'),
    Locale('ug'),
    Locale('uk'),
    Locale('ur'),
    Locale('uz'),
    Locale('ve'),
    Locale('vi'),
    Locale('xh'),
    Locale('yo'),
    Locale('zh'),
    Locale('zu'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @communities.
  ///
  /// In en, this message translates to:
  /// **'Communities'**
  String get communities;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali (বাংলা)'**
  String get bengali;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get darkTheme;

  /// No description provided for @lowDataMode.
  ///
  /// In en, this message translates to:
  /// **'Low Data Mode'**
  String get lowDataMode;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @replies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get replies;

  /// No description provided for @reposts.
  ///
  /// In en, this message translates to:
  /// **'Reposts'**
  String get reposts;

  /// No description provided for @media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get media;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @writeAPost.
  ///
  /// In en, this message translates to:
  /// **'Write a post'**
  String get writeAPost;

  /// No description provided for @noRepliesYet.
  ///
  /// In en, this message translates to:
  /// **'No replies yet'**
  String get noRepliesYet;

  /// No description provided for @noRepostsYet.
  ///
  /// In en, this message translates to:
  /// **'No reposts yet'**
  String get noRepostsYet;

  /// No description provided for @noMediaYet.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get noMediaYet;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @accountBlocked.
  ///
  /// In en, this message translates to:
  /// **'Account has been blocked.'**
  String get accountBlocked;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you!'**
  String get reportSubmitted;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profileVerification.
  ///
  /// In en, this message translates to:
  /// **'Profile Verification'**
  String get profileVerification;

  /// No description provided for @creatorMonetization.
  ///
  /// In en, this message translates to:
  /// **'Creator Studio'**
  String get creatorMonetization;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @displayAndTheme.
  ///
  /// In en, this message translates to:
  /// **'Display & Theme'**
  String get displayAndTheme;

  /// No description provided for @lowDataModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Disables autoplay and reduces media quality.'**
  String get lowDataModeSubtitle;

  /// No description provided for @contentAndActivity.
  ///
  /// In en, this message translates to:
  /// **'Content & Activity'**
  String get contentAndActivity;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPosts;

  /// No description provided for @blockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Blocked Accounts'**
  String get blockedAccounts;

  /// No description provided for @mutedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Muted Accounts'**
  String get mutedAccounts;

  /// No description provided for @supportAndInfo.
  ///
  /// In en, this message translates to:
  /// **'Support & Info'**
  String get supportAndInfo;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @yourIdentityIsSecure.
  ///
  /// In en, this message translates to:
  /// **'Your Identity is Secure'**
  String get yourIdentityIsSecure;

  /// No description provided for @reapplyForBlueBadge.
  ///
  /// In en, this message translates to:
  /// **'Re-apply for Blue Badge'**
  String get reapplyForBlueBadge;

  /// No description provided for @enterPaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter Payment Details'**
  String get enterPaymentDetails;

  /// No description provided for @tapToUploadNidFront.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload NID front'**
  String get tapToUploadNidFront;

  /// No description provided for @endtoendEncrypted.
  ///
  /// In en, this message translates to:
  /// **'End-to-End Encrypted'**
  String get endtoendEncrypted;

  /// No description provided for @lookStraight.
  ///
  /// In en, this message translates to:
  /// **'Look Straight'**
  String get lookStraight;

  /// No description provided for @ensureThereAreNoReflectionsOrGlaresOnThe.
  ///
  /// In en, this message translates to:
  /// **'Ensure there are no reflections or glares on the NID photos. All text must be perfectly legible for automatic verification checks to succeed.'**
  String get ensureThereAreNoReflectionsOrGlaresOnThe;

  /// No description provided for @faceVerification.
  ///
  /// In en, this message translates to:
  /// **'Face Verification'**
  String get faceVerification;

  /// No description provided for @verificationPayment.
  ///
  /// In en, this message translates to:
  /// **'Verification Payment'**
  String get verificationPayment;

  /// No description provided for @membershipInvoice.
  ///
  /// In en, this message translates to:
  /// **'MEMBERSHIP INVOICE'**
  String get membershipInvoice;

  /// No description provided for @bkashTransactionIdTrxid.
  ///
  /// In en, this message translates to:
  /// **'bKash Transaction ID (TrxID)'**
  String get bkashTransactionIdTrxid;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @notStoredPublicly.
  ///
  /// In en, this message translates to:
  /// **'Not Stored Publicly'**
  String get notStoredPublicly;

  /// No description provided for @congratulationsYourPigeonBlueBadgeIsNowA.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! Your Pigeon Blue Badge is now active. Your verified checkmark is visible next to your name across the platform.'**
  String get congratulationsYourPigeonBlueBadgeIsNowA;

  /// No description provided for @verificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get verificationStatus;

  /// No description provided for @promoOffer.
  ///
  /// In en, this message translates to:
  /// **'PROMO OFFER'**
  String get promoOffer;

  /// No description provided for @saveContinue.
  ///
  /// In en, this message translates to:
  /// **'Save & Continue'**
  String get saveContinue;

  /// No description provided for @tapToUploadNidBack.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload NID back'**
  String get tapToUploadNidBack;

  /// No description provided for @backToFeedHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Feed Home'**
  String get backToFeedHome;

  /// No description provided for @provideAGovernmentissuedPhotoIdMakeSureT.
  ///
  /// In en, this message translates to:
  /// **'Provide a government-issued photo ID. Make sure the details match your profile and the card is clearly readable.'**
  String get provideAGovernmentissuedPhotoIdMakeSureT;

  /// No description provided for @turnRightSlightly.
  ///
  /// In en, this message translates to:
  /// **'Turn Right Slightly'**
  String get turnRightSlightly;

  /// No description provided for @nationalIdNidNumber.
  ///
  /// In en, this message translates to:
  /// **'National ID (NID) Number'**
  String get nationalIdNidNumber;

  /// No description provided for @takeClearPhotosOfBothTheFrontAndBackOfYo.
  ///
  /// In en, this message translates to:
  /// **'Take clear photos of both the front and back of your NID card.'**
  String get takeClearPhotosOfBothTheFrontAndBackOfYo;

  /// No description provided for @submitVerification.
  ///
  /// In en, this message translates to:
  /// **'Submit Verification'**
  String get submitVerification;

  /// No description provided for @backSide.
  ///
  /// In en, this message translates to:
  /// **'Back Side'**
  String get backSide;

  /// No description provided for @verifyPay.
  ///
  /// In en, this message translates to:
  /// **'Verify & Pay'**
  String get verifyPay;

  /// No description provided for @takeAPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takeAPhoto;

  /// No description provided for @blinkNaturally.
  ///
  /// In en, this message translates to:
  /// **'Blink Naturally'**
  String get blinkNaturally;

  /// No description provided for @frontSide.
  ///
  /// In en, this message translates to:
  /// **'Front Side'**
  String get frontSide;

  /// No description provided for @yourNameProfilePhotoAndDetailsShouldMatc.
  ///
  /// In en, this message translates to:
  /// **'Your name, profile photo, and details should match the government-issued photo ID card you upload in the next step.'**
  String get yourNameProfilePhotoAndDetailsShouldMatc;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @pigeonUsername.
  ///
  /// In en, this message translates to:
  /// **'Pigeon Username'**
  String get pigeonUsername;

  /// No description provided for @pleaseUploadBothSidesOfYourNidCard.
  ///
  /// In en, this message translates to:
  /// **'Please upload both sides of your NID card'**
  String get pleaseUploadBothSidesOfYourNidCard;

  /// No description provided for @applyForBlueBadge.
  ///
  /// In en, this message translates to:
  /// **'Apply for Blue Badge'**
  String get applyForBlueBadge;

  /// No description provided for @sendBkashPayment.
  ///
  /// In en, this message translates to:
  /// **'Send bKash Payment'**
  String get sendBkashPayment;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @pigeonVerified.
  ///
  /// In en, this message translates to:
  /// **'Pigeon Verified'**
  String get pigeonVerified;

  /// No description provided for @turnLeftSlightly.
  ///
  /// In en, this message translates to:
  /// **'Turn Left Slightly'**
  String get turnLeftSlightly;

  /// No description provided for @confirmYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Identity'**
  String get confirmYourIdentity;

  /// No description provided for @goToFeedHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Feed Home'**
  String get goToFeedHome;

  /// No description provided for @livenessChecked.
  ///
  /// In en, this message translates to:
  /// **'Liveness Checked'**
  String get livenessChecked;

  /// No description provided for @verificationActive.
  ///
  /// In en, this message translates to:
  /// **'Verification Active'**
  String get verificationActive;

  /// No description provided for @usernameHandle.
  ///
  /// In en, this message translates to:
  /// **'Username Handle'**
  String get usernameHandle;

  /// No description provided for @verificationTimeline.
  ///
  /// In en, this message translates to:
  /// **'Verification Timeline'**
  String get verificationTimeline;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @subscribeContinue.
  ///
  /// In en, this message translates to:
  /// **'Subscribe & Continue'**
  String get subscribeContinue;

  /// No description provided for @iConfirmAllDocumentsAndCredentialsBelong.
  ///
  /// In en, this message translates to:
  /// **'I confirm all documents and credentials belong to me and represent official, valid, and correct records.'**
  String get iConfirmAllDocumentsAndCredentialsBelong;

  /// No description provided for @uploadIdDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Documents'**
  String get uploadIdDocuments;

  /// No description provided for @statusCode.
  ///
  /// In en, this message translates to:
  /// **'Status Code'**
  String get statusCode;

  /// No description provided for @checkStatusUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check Status Update'**
  String get checkStatusUpdate;

  /// No description provided for @reviewApplication.
  ///
  /// In en, this message translates to:
  /// **'Review Application'**
  String get reviewApplication;

  /// No description provided for @checkCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Current Status'**
  String get checkCurrentStatus;

  /// No description provided for @shortBioOptional.
  ///
  /// In en, this message translates to:
  /// **'Short Bio (Optional)'**
  String get shortBioOptional;

  /// No description provided for @completeYourVerificationBySendingTheBkas.
  ///
  /// In en, this message translates to:
  /// **'Complete your verification by sending the bKash payment to the personal number below.'**
  String get completeYourVerificationBySendingTheBkas;

  /// No description provided for @weDoNotSellOrShareYourIdentityDetailsNid.
  ///
  /// In en, this message translates to:
  /// **'We do not sell or share your identity details. NID images and face selfie records are immediately encrypted and processed for compliance check only.'**
  String get weDoNotSellOrShareYourIdentityDetailsNid;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @identityVerified.
  ///
  /// In en, this message translates to:
  /// **'Identity Verified'**
  String get identityVerified;

  /// No description provided for @faceCaptured.
  ///
  /// In en, this message translates to:
  /// **'Face Captured'**
  String get faceCaptured;

  /// No description provided for @yourSelfieIsReadyForIdentityMatching.
  ///
  /// In en, this message translates to:
  /// **'Your selfie is ready for identity matching.'**
  String get yourSelfieIsReadyForIdentityMatching;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @senderBkashAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Sender bKash Account Number'**
  String get senderBkashAccountNumber;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @confirmPersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Confirm Personal Details'**
  String get confirmPersonalDetails;

  /// No description provided for @pleaseCompleteFaceVerificationToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please complete face verification to continue.'**
  String get pleaseCompleteFaceVerificationToContinue;

  /// No description provided for @pleaseEnterYourNidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your NID number'**
  String get pleaseEnterYourNidNumber;

  /// No description provided for @aSubscriptionBundleToBuildYourPresenceAn.
  ///
  /// In en, this message translates to:
  /// **'A subscription bundle to build your presence and credibility with safety tools and priority support.'**
  String get aSubscriptionBundleToBuildYourPresenceAn;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @verifyThatAllInformationMatchesYourOffic.
  ///
  /// In en, this message translates to:
  /// **'Verify that all information matches your official documents before submitting.'**
  String get verifyThatAllInformationMatchesYourOffic;

  /// No description provided for @bkashTrxid.
  ///
  /// In en, this message translates to:
  /// **'bKash TrxID'**
  String get bkashTrxid;

  /// No description provided for @pleaseSelectYourDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get pleaseSelectYourDateOfBirth;

  /// No description provided for @bkashNumberCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'bKash number copied to clipboard'**
  String get bkashNumberCopiedToClipboard;

  /// No description provided for @privacySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettingsTitle;

  /// No description provided for @accountPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Account Privacy'**
  String get accountPrivacy;

  /// No description provided for @privateAccount.
  ///
  /// In en, this message translates to:
  /// **'Private Account'**
  String get privateAccount;

  /// No description provided for @privateAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only approved followers can see your posts and media.'**
  String get privateAccountSubtitle;

  /// No description provided for @showActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Show Active Status'**
  String get showActiveStatus;

  /// No description provided for @showActiveStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow others to see when you\'re active. If disabled, you won\'t see others\' active status.'**
  String get showActiveStatusSubtitle;

  /// No description provided for @interactions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get interactions;

  /// No description provided for @whoCanMentionYou.
  ///
  /// In en, this message translates to:
  /// **'Who can mention you'**
  String get whoCanMentionYou;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @peopleYouFollow.
  ///
  /// In en, this message translates to:
  /// **'People you follow'**
  String get peopleYouFollow;

  /// No description provided for @noOne.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get noOne;

  /// No description provided for @directMessages.
  ///
  /// In en, this message translates to:
  /// **'Direct Messages'**
  String get directMessages;

  /// No description provided for @directMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control who can send you direct messages'**
  String get directMessagesSubtitle;

  /// No description provided for @contentFilters.
  ///
  /// In en, this message translates to:
  /// **'Content Filters'**
  String get contentFilters;

  /// No description provided for @filterAdultContent.
  ///
  /// In en, this message translates to:
  /// **'Filter Adult Content'**
  String get filterAdultContent;

  /// No description provided for @filterAdultContentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide potentially sensitive content and media from searches and feeds.'**
  String get filterAdultContentSubtitle;

  /// No description provided for @autoplayVideos.
  ///
  /// In en, this message translates to:
  /// **'Autoplay Videos'**
  String get autoplayVideos;

  /// No description provided for @autoplayVideosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically play videos when browsing feeds.'**
  String get autoplayVideosSubtitle;

  /// No description provided for @autoplayMusic.
  ///
  /// In en, this message translates to:
  /// **'Autoplay Music'**
  String get autoplayMusic;

  /// No description provided for @autoplayMusicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically play music tracks on post images.'**
  String get autoplayMusicSubtitle;

  /// No description provided for @safetyLists.
  ///
  /// In en, this message translates to:
  /// **'Safety Lists'**
  String get safetyLists;

  /// No description provided for @blockedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts you have blocked'**
  String get blockedAccountsSubtitle;

  /// No description provided for @mutedAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage accounts you have muted'**
  String get mutedAccountsSubtitle;

  /// No description provided for @accountSetToPrivate.
  ///
  /// In en, this message translates to:
  /// **'Account set to Private'**
  String get accountSetToPrivate;

  /// No description provided for @accountSetToPublic.
  ///
  /// In en, this message translates to:
  /// **'Account set to Public'**
  String get accountSetToPublic;

  /// No description provided for @searchUserToBlock.
  ///
  /// In en, this message translates to:
  /// **'Search user to block...'**
  String get searchUserToBlock;

  /// No description provided for @noUsersFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No users found matching '**
  String get noUsersFoundMatching;

  /// No description provided for @unblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked '**
  String get unblocked;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked '**
  String get blocked;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @noBlockedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No blocked accounts'**
  String get noBlockedAccounts;

  /// No description provided for @mutedAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Muted Accounts'**
  String get mutedAccountsTitle;

  /// No description provided for @searchUserToMute.
  ///
  /// In en, this message translates to:
  /// **'Search user to mute...'**
  String get searchUserToMute;

  /// No description provided for @unmuted.
  ///
  /// In en, this message translates to:
  /// **'Unmuted '**
  String get unmuted;

  /// No description provided for @unmuteUser.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmuteUser;

  /// No description provided for @muted.
  ///
  /// In en, this message translates to:
  /// **'Muted '**
  String get muted;

  /// No description provided for @muteUser.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get muteUser;

  /// No description provided for @noMutedAccounts.
  ///
  /// In en, this message translates to:
  /// **'No muted accounts'**
  String get noMutedAccounts;

  /// No description provided for @chatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettings;

  /// No description provided for @allowDirectMessagesFrom.
  ///
  /// In en, this message translates to:
  /// **'Allow direct messages from'**
  String get allowDirectMessagesFrom;

  /// No description provided for @chatSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can continue ongoing conversations regardless of which setting you choose.'**
  String get chatSettingsSubtitle;

  /// No description provided for @usersIFollow.
  ///
  /// In en, this message translates to:
  /// **'Users I follow'**
  String get usersIFollow;

  /// No description provided for @notificationSounds.
  ///
  /// In en, this message translates to:
  /// **'Notification sounds'**
  String get notificationSounds;

  /// No description provided for @exportMyChatData.
  ///
  /// In en, this message translates to:
  /// **'Export my chat data'**
  String get exportMyChatData;

  /// No description provided for @exportChatDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Chat Data'**
  String get exportChatDataTitle;

  /// No description provided for @exportChatDataMsg.
  ///
  /// In en, this message translates to:
  /// **'Your chat data export has been requested. We will prepare the download and notify you soon.'**
  String get exportChatDataMsg;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @selectLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageTitle;

  /// No description provided for @settingsTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTabTitle;

  /// No description provided for @privacyMenu.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacyMenu;

  /// No description provided for @logOutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutButton;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogout;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'af',
    'am',
    'ar',
    'az',
    'be',
    'bg',
    'bn',
    'bs',
    'ca',
    'cs',
    'cy',
    'da',
    'de',
    'el',
    'en',
    'es',
    'et',
    'eu',
    'fa',
    'fi',
    'fr',
    'gl',
    'gu',
    'ha',
    'he',
    'hi',
    'hr',
    'hu',
    'hy',
    'id',
    'ig',
    'is',
    'it',
    'ja',
    'jv',
    'ka',
    'kk',
    'km',
    'kn',
    'ko',
    'ku',
    'ky',
    'lo',
    'lt',
    'lv',
    'mg',
    'mk',
    'ml',
    'mn',
    'mr',
    'ms',
    'my',
    'ne',
    'nl',
    'no',
    'nr',
    'ny',
    'om',
    'pa',
    'pl',
    'ps',
    'pt',
    'ro',
    'ru',
    'rw',
    'sd',
    'si',
    'sk',
    'sl',
    'sn',
    'so',
    'sq',
    'sr',
    'ss',
    'st',
    'sv',
    'sw',
    'ta',
    'te',
    'tg',
    'th',
    'ti',
    'tk',
    'tl',
    'tn',
    'tr',
    'ts',
    'ug',
    'uk',
    'ur',
    'uz',
    've',
    'vi',
    'xh',
    'yo',
    'zh',
    'zu',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'az':
      return AppLocalizationsAz();
    case 'be':
      return AppLocalizationsBe();
    case 'bg':
      return AppLocalizationsBg();
    case 'bn':
      return AppLocalizationsBn();
    case 'bs':
      return AppLocalizationsBs();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'cy':
      return AppLocalizationsCy();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'et':
      return AppLocalizationsEt();
    case 'eu':
      return AppLocalizationsEu();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'gl':
      return AppLocalizationsGl();
    case 'gu':
      return AppLocalizationsGu();
    case 'ha':
      return AppLocalizationsHa();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'hy':
      return AppLocalizationsHy();
    case 'id':
      return AppLocalizationsId();
    case 'ig':
      return AppLocalizationsIg();
    case 'is':
      return AppLocalizationsIs();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'jv':
      return AppLocalizationsJv();
    case 'ka':
      return AppLocalizationsKa();
    case 'kk':
      return AppLocalizationsKk();
    case 'km':
      return AppLocalizationsKm();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ku':
      return AppLocalizationsKu();
    case 'ky':
      return AppLocalizationsKy();
    case 'lo':
      return AppLocalizationsLo();
    case 'lt':
      return AppLocalizationsLt();
    case 'lv':
      return AppLocalizationsLv();
    case 'mg':
      return AppLocalizationsMg();
    case 'mk':
      return AppLocalizationsMk();
    case 'ml':
      return AppLocalizationsMl();
    case 'mn':
      return AppLocalizationsMn();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'my':
      return AppLocalizationsMy();
    case 'ne':
      return AppLocalizationsNe();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'nr':
      return AppLocalizationsNr();
    case 'ny':
      return AppLocalizationsNy();
    case 'om':
      return AppLocalizationsOm();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'ps':
      return AppLocalizationsPs();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'rw':
      return AppLocalizationsRw();
    case 'sd':
      return AppLocalizationsSd();
    case 'si':
      return AppLocalizationsSi();
    case 'sk':
      return AppLocalizationsSk();
    case 'sl':
      return AppLocalizationsSl();
    case 'sn':
      return AppLocalizationsSn();
    case 'so':
      return AppLocalizationsSo();
    case 'sq':
      return AppLocalizationsSq();
    case 'sr':
      return AppLocalizationsSr();
    case 'ss':
      return AppLocalizationsSs();
    case 'st':
      return AppLocalizationsSt();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tg':
      return AppLocalizationsTg();
    case 'th':
      return AppLocalizationsTh();
    case 'ti':
      return AppLocalizationsTi();
    case 'tk':
      return AppLocalizationsTk();
    case 'tl':
      return AppLocalizationsTl();
    case 'tn':
      return AppLocalizationsTn();
    case 'tr':
      return AppLocalizationsTr();
    case 'ts':
      return AppLocalizationsTs();
    case 'ug':
      return AppLocalizationsUg();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'uz':
      return AppLocalizationsUz();
    case 've':
      return AppLocalizationsVe();
    case 'vi':
      return AppLocalizationsVi();
    case 'xh':
      return AppLocalizationsXh();
    case 'yo':
      return AppLocalizationsYo();
    case 'zh':
      return AppLocalizationsZh();
    case 'zu':
      return AppLocalizationsZu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
