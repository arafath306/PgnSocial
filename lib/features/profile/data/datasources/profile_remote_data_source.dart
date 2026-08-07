import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../utils/media_compressor.dart';

abstract class ProfileRemoteDataSource {
  Future<bool> submitVerificationRequest(String currentUid, Map<String, dynamic> requestData);
  Future<Map<String, dynamic>?> fetchUserVerificationRequest(String currentUid);
  Future<String?> uploadVerificationImage(String currentUid, Uint8List bytes, String filename);
  Future<List<dynamic>> fetchAdminVerificationRequests();
  Future<bool> updateVerificationRequestStatus(String requestId, String status, {String? reason});
  Future<bool> updateProfile(String currentUid, Map<String, dynamic> profileData);
  Future<bool> updateProfileImage(String currentUid, Uint8List bytes, bool isAvatar);
  Future<List<dynamic>> fetchVerificationPlans();
  Future<bool> updateVerificationPlanPrice(String planId, double price, {double? discountPrice});
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final sb.SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<bool> submitVerificationRequest(String currentUid, Map<String, dynamic> requestData) async {
    final cleanedData = Map<String, dynamic>.from(requestData)..removeWhere((k, v) => v == null);

    final payload = <String, dynamic>{
      'user_id': currentUid,
      ...cleanedData,
      'status': 'pending',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    Map<String, dynamic> activePayload = Map<String, dynamic>.from(payload);

    for (int attempt = 0; attempt < 15; attempt++) {
      try {
        final existing = await supabaseClient
            .from('verification_requests')
            .select('id')
            .eq('user_id', currentUid)
            .maybeSingle();

        if (existing != null) {
          await supabaseClient
              .from('verification_requests')
              .update(activePayload)
              .eq('user_id', currentUid);
        } else {
          await supabaseClient
              .from('verification_requests')
              .insert(activePayload);
        }
        return true;
      } catch (e) {
        final errStr = e.toString();
        final match = RegExp(r"Could not find the '([^']+)' column").firstMatch(errStr);
        if (match != null) {
          final missingCol = match.group(1);
          if (missingCol != null && activePayload.containsKey(missingCol)) {
            activePayload.remove(missingCol);
            continue; // Retry without the missing DB column
          }
        }

        // Try upsert fallback if RLS or other condition occurs
        try {
          await supabaseClient.from('verification_requests').upsert(
            activePayload,
            onConflict: 'user_id',
          );
          return true;
        } catch (upsertErr) {
          final upsertErrStr = upsertErr.toString();
          final upsertMatch = RegExp(r"Could not find the '([^']+)' column").firstMatch(upsertErrStr);
          if (upsertMatch != null) {
            final missingCol = upsertMatch.group(1);
            if (missingCol != null && activePayload.containsKey(missingCol)) {
              activePayload.remove(missingCol);
              continue; // Retry next attempt without missing column
            }
          }
          rethrow;
        }
      }
    }

    return true;
  }

  @override
  Future<Map<String, dynamic>?> fetchUserVerificationRequest(String currentUid) async {
    final response = await supabaseClient
        .from('verification_requests')
        .select('*')
        .eq('user_id', currentUid)
        .maybeSingle();
    return response != null ? Map<String, dynamic>.from(response) : null;
  }

  @override
  Future<String?> uploadVerificationImage(String currentUid, Uint8List bytes, String filename) async {
    final compressedBytes = await MediaCompressor.compressImageBytes(bytes);
    final path = 'verifications/$currentUid/$filename';
    await supabaseClient.storage.from('avatars').uploadBinary(
      path,
      compressedBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    return publicUrl;
  }

  @override
  Future<List<dynamic>> fetchAdminVerificationRequests() async {
    final response = await supabaseClient
        .from('verification_requests')
        .select('*, profiles(id, username, full_name, avatar_url)')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  @override
  Future<bool> updateVerificationRequestStatus(String requestId, String status, {String? reason}) async {
    await supabaseClient.from('verification_requests').update({
      'status': status,
      'rejection_reason': reason,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId);
    return true;
  }

  @override
  Future<bool> updateProfile(String currentUid, Map<String, dynamic> profileData) async {
    await supabaseClient
        .from('profiles')
        .update(profileData)
        .eq('id', currentUid);
    return true;
  }

  @override
  Future<bool> updateProfileImage(String currentUid, Uint8List bytes, bool isAvatar) async {
    final compressedBytes = await MediaCompressor.compressImageBytes(bytes);
    final subFolder = isAvatar ? 'avatars' : 'covers';
    final path = '$subFolder/$currentUid/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    await supabaseClient.storage.from('avatars').uploadBinary(
      path,
      compressedBytes,
      fileOptions: const sb.FileOptions(cacheControl: '3600', upsert: true),
    );
    final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    
    final updateField = isAvatar ? 'avatar_url' : 'cover_url';
    await supabaseClient.from('profiles').update({updateField: publicUrl}).eq('id', currentUid);
    return true;
  }

  @override
  Future<List<dynamic>> fetchVerificationPlans() async {
    final response = await supabaseClient
        .from('verification_plans')
        .select()
        .order('price', ascending: true);
    return response as List<dynamic>;
  }

  @override
  Future<bool> updateVerificationPlanPrice(String planId, double price, {double? discountPrice}) async {
    await supabaseClient.from('verification_plans').update({
      'price': price,
      'discount_price': discountPrice,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', planId);
    return true;
  }
}
