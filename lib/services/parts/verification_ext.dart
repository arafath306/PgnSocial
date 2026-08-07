part of '../database_service.dart';

extension VerificationExtension on DatabaseService {
  // --- Profile Verification Operations ---



  Future<void> fetchVerificationPlans() async {
    try {
      final res = await sl<FetchVerificationPlansUseCase>().call();
      _verificationPlans = res.fold((l) => [], (r) => r);
      updateState();
      
      // Start Realtime stream listener so price edits in dak-admin-next update live
      subscribeToVerificationPlansRealtime();
    } catch (e) {
      debugPrint("Fetch verification plans failed: $e. Using fallback values.");
      _verificationPlans = VerificationPlanPricing.allPlans.values.map((p) => {
        'id': p.id,
        'name': p.name,
        'price': p.basePrice,
        'discount_price': p.discountPrice,
        'interval_unit': p.duration,
      }).toList();
      updateState();
    }
  }

  void subscribeToVerificationPlansRealtime() {
    try {
      _supabase
          .from('verification_plans')
          .stream(primaryKey: ['id'])
          .listen((data) {
            if (data.isNotEmpty) {
              _verificationPlans = List<Map<String, dynamic>>.from(data);
              updateState();
            }
          });
    } catch (e) {
      debugPrint("Realtime verification plans stream error: $e");
    }
  }

  Future<bool> updateVerificationPlanPrice(String planId, double price, {double? discountPrice}) async {
    try {
      final res = await sl<UpdateVerificationPlanPriceUseCase>().call(planId, price, discountPrice: discountPrice);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchVerificationPlans();
      }
      return success;
    } catch (e) {
      debugPrint("Update verification plan price failed: $e");
      return false;
    }
  }

  Future<String?> uploadVerificationImage(Uint8List bytes, String filename) async {
    if (_currentUid.isEmpty) return null;
    try {
      final res = await sl<UploadVerificationImageUseCase>().call(bytes, filename);
      return res.fold((l) => null, (r) => r);
    } catch (e) {
      debugPrint("Upload verification image error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchUserVerificationRequest() async {
    if (_currentUid.isEmpty) return null;
    try {
      final res = await sl<GetVerificationStatusUseCase>().call();
      return res.fold((l) => null, (r) => r);
    } catch (e) {
      debugPrint("DB Fetch user verification request failed: $e");
      return null;
    }
  }

  Future<bool> submitVerificationRequest(Map<String, dynamic> requestData) async {
    if (_currentUid.isEmpty) return false;
    try {
      final res = await sl<SubmitVerificationUseCase>().call(requestData);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      return success;
    } catch (e) {
      debugPrint("DB Submit verification request failed: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAdminVerificationRequests() async {
    try {
      final res = await sl<FetchAdminVerificationRequestsUseCase>().call();
      return res.fold((l) => [], (r) => r);
    } catch (e) {
      debugPrint("DB Admin fetch verification requests error: $e");
      return [];
    }
  }

  Future<bool> updateVerificationRequestStatus(String requestId, String status, {String? reason}) async {
    try {
      final res = await sl<UpdateVerificationRequestStatusUseCase>().call(requestId, status, reason: reason);
      final success = res.fold((l) => false, (r) => r);
      if (success) {
        await fetchMyProfile();
      }
      return success;
    } catch (e) {
      debugPrint("DB Update verification status error: $e");
      return false;
    }
  }
}

