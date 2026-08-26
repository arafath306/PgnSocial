import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MonetizationController extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool isEnabledGlobally = false;
  
  bool isLoadingDashboard = true;
  Map<String, dynamic>? creatorSettings;
  int activeSubscribers = 0;
  
  List<String> mySubscribedCreatorIds = [];

  bool isSubscribedTo(String creatorId) {
    return mySubscribedCreatorIds.contains(creatorId);
  }
  
  Future<void> fetchGlobalStatus({String? uid, String? badgeType}) async {
    try {
      final res = await _supabase.from('system_settings').select('value').eq('key', 'enable_monetization').maybeSingle();
      if (res != null) {
        final val = res['value'] as String?;
        bool isEnabled = false;
        
        if (val != null) {
          try {
            final parsed = jsonDecode(val);
            if (parsed is Map) {
              final access = parsed['access'];
              if (access == 'global') {
                isEnabled = true;
              } else if (access == 'verified' && badgeType != null && badgeType != 'none') {
                isEnabled = true;
              } else if (access == 'specific') {
                final users = parsed['users'];
                if (users is List && uid != null && users.contains(uid)) {
                  isEnabled = true;
                }
              }
            }
          } catch (e) {
            isEnabled = val == 'true'; // Fallback
          }
        }
        
        isEnabledGlobally = isEnabled;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching monetization global status: $e");
    }
  }

  double totalGrossRevenue = 0.0;

  double get monthlyPrice => (creatorSettings?['monthly_price'] as num?)?.toDouble() ?? 0.0;
  double get estimatedMonthlyGross => activeSubscribers * monthlyPrice;
  double get platformFeeRate => 0.10; // 10%
  double get estimatedMonthlyFee => estimatedMonthlyGross * platformFeeRate;
  double get estimatedMonthlyNet => estimatedMonthlyGross * (1 - platformFeeRate);
  double get totalLifetimeNet => totalGrossRevenue * (1 - platformFeeRate);
  double get totalLifetimeFee => totalGrossRevenue * platformFeeRate;

  Future<void> fetchCreatorDashboard(String userId) async {
    isLoadingDashboard = true;
    notifyListeners();
    try {
      // Fetch settings
      final res = await _supabase.from('creator_settings').select().eq('creator_id', userId).maybeSingle();
      creatorSettings = res;
      
      // Fetch subscribers count & total gross revenue
      final subs = await _supabase.from('creator_subscriptions').select('id, plan_price, status').eq('creator_id', userId);
      final list = subs as List;
      activeSubscribers = list.where((e) => e['status'] == 'active').length;

      double gross = 0.0;
      for (var s in list) {
        final st = s['status'] as String?;
        if (st == 'active' || st == 'approved') {
          final price = (s['plan_price'] as num?)?.toDouble() ?? monthlyPrice;
          gross += price;
        }
      }
      totalGrossRevenue = gross;
    } catch (e) {
      debugPrint("Error fetching creator dashboard: $e");
    } finally {
      isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> fetchMySubscriptions(String myUserId) async {
    try {
      final subs = await _supabase
          .from('creator_subscriptions')
          .select('creator_id')
          .eq('subscriber_id', myUserId)
          .eq('status', 'active');
      
      mySubscribedCreatorIds = (subs as List).map((e) => e['creator_id'] as String).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching my subscriptions: $e");
    }
  }

  Future<void> saveCreatorPrice(String userId, double newPrice) async {
    try {
      await _supabase.from('creator_settings').upsert({
        'creator_id': userId,
        'monthly_price': newPrice,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await fetchCreatorDashboard(userId);
    } catch (e) {
      debugPrint("Error saving price: $e");
      rethrow;
    }
  }

  Future<void> submitSubscription(String subscriberId, String creatorId, String bkashSender, String trxId, double planPrice) async {
    try {
      await _supabase.from('creator_subscriptions').insert({
        'subscriber_id': subscriberId,
        'creator_id': creatorId,
        'bkash_sender': bkashSender,
        'bkash_trx_id': trxId,
        'status': 'pending',
        'plan_price': planPrice,
      });
    } catch (e) {
      debugPrint("Error submitting subscription: $e");
      rethrow;
    }
  }

  List<Map<String, dynamic>> payoutRequests = [];
  bool isLoadingPayouts = false;

  Future<void> fetchPayoutRequests(String userId) async {
    isLoadingPayouts = true;
    notifyListeners();
    try {
      final res = await _supabase
          .from('payout_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      payoutRequests = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint("Error fetching payout requests: $e");
    } finally {
      isLoadingPayouts = false;
      notifyListeners();
    }
  }

  Future<void> requestPayout({
    required String userId,
    required double amount,
    required String method,
    required String accountDetails,
  }) async {
    try {
      await _supabase.from('payout_requests').insert({
        'user_id': userId,
        'amount': amount,
        'payout_method': method,
        'account_details': accountDetails,
        'status': 'pending',
      });
      await fetchPayoutRequests(userId);
    } catch (e) {
      debugPrint("Error requesting payout: $e");
      rethrow;
    }
  }

  List<Map<String, dynamic>> subscriberDetailsList = [];
  List<Map<String, dynamic>> lockedPostsIncomeList = [];
  bool isLoadingHistory = false;

  Future<void> fetchSubscriberHistory(String creatorId) async {
    try {
      final res = await _supabase
          .from('creator_subscriptions')
          .select('*, subscriber:profiles!creator_subscriptions_subscriber_id_fkey(username, full_name, avatar_url)')
          .eq('creator_id', creatorId)
          .order('created_at', ascending: false);
      subscriberDetailsList = List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      debugPrint("Error fetching subscriber history: $e");
    }
  }

  Future<void> fetchLockedPostsEarnings(String creatorId) async {
    try {
      // Fetch creator's locked posts
      final postsRes = await _supabase
          .from('threads')
          .select('id, content, created_at, is_subscriber_only')
          .eq('user_id', creatorId)
          .eq('is_subscriber_only', true)
          .order('created_at', ascending: false);
      
      final posts = List<Map<String, dynamic>>.from(postsRes as List);

      // Fetch all active/approved subscriptions for this creator to map post unlocks
      final subsRes = await _supabase
          .from('creator_subscriptions')
          .select('*, subscriber:profiles!creator_subscriptions_subscriber_id_fkey(username, full_name, avatar_url)')
          .eq('creator_id', creatorId);
      final subs = List<Map<String, dynamic>>.from(subsRes as List);

      List<Map<String, dynamic>> list = [];
      for (var post in posts) {
        final postId = post['id'] as String;
        // Find subscriptions linked to this post or overall subscriptions
        final unlocks = subs.where((s) {
          final pid = s['post_id'] as String?;
          return pid == postId || (pid == null && (s['status'] == 'active' || s['status'] == 'approved'));
        }).toList();

        double totalIncome = 0.0;
        for (var u in unlocks) {
          totalIncome += (u['plan_price'] as num?)?.toDouble() ?? monthlyPrice;
        }

        list.add({
          'post_id': postId,
          'content': post['content'] ?? 'Subscriber-Only Post',
          'created_at': post['created_at'],
          'unlock_count': unlocks.length,
          'total_income': totalIncome,
          'unlockers': unlocks,
        });
      }

      lockedPostsIncomeList = list;
    } catch (e) {
      debugPrint("Error fetching locked posts earnings: $e");
    }
  }

  Future<void> fetchFullMonetizationHistory(String creatorId) async {
    isLoadingHistory = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchCreatorDashboard(creatorId),
        fetchPayoutRequests(creatorId),
        fetchSubscriberHistory(creatorId),
        fetchLockedPostsEarnings(creatorId),
      ]);
    } catch (e) {
      debugPrint("Error fetching full monetization history: $e");
    } finally {
      isLoadingHistory = false;
      notifyListeners();
    }
  }
}
