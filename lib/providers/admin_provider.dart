import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/gateway_model.dart';

class AdminProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<AppOrder> _allOrders = [];
  List<PaymentGateway> _gateways = [];
  List<Map<String, dynamic>> _lotteries = [];
  List<Map<String, dynamic>> _winners = [];

  List<Map<String, dynamic>> _tickets = [];

  List<AppOrder> get allOrders => _allOrders;
  List<PaymentGateway> get allGateways => _gateways;
  List<PaymentGateway> get activeGateways => _gateways.where((g) => g.isActive).toList();
  List<Map<String, dynamic>> get lotteries => _lotteries;
  List<Map<String, dynamic>> get winners => _winners;
  List<Map<String, dynamic>> get tickets => _tickets;

  AdminProvider() {
    // Call startup fetches but ensure they cannot throw uncaught exceptions
    fetchOrders();
    fetchGateways();
    fetchLotteries();
    fetchWinners();
    fetchTickets();
  }

  // --- مدیریت تیکت‌ها ---
  Future<void> fetchTickets() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _tickets = [];
        notifyListeners();
        return;
      }

      var query = _supabase.from('tickets').select();
      // اگر مدیر نیست، فقط تیکت‌های خودش را ببیند
      if (user.phone != '09927891608') {
        query = query.eq('user_id', user.id);
      }

      final data = await query.order('created_at');
      if (data is List) {
        _tickets = List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        _tickets = [Map<String, dynamic>.from(data)];
      } else {
        _tickets = [];
      }
    } catch (e, st) {
      debugPrint('fetchTickets error: $e\n$st');
      _tickets = [];
    }
    notifyListeners();
  }

  Future<void> sendTicket(String subject, String message) async {
    try {
      await _supabase.from('tickets').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'subject': subject,
        'message': message,
      });
    } catch (e, st) {
      debugPrint('sendTicket error: $e\n$st');
    }
    fetchTickets();
  }

  Future<void> replyTicket(String ticketId, String reply) async {
    try {
      await _supabase.from('tickets').update({
        'reply': reply,
        'status': 'closed',
      }).eq('id', ticketId);
    } catch (e, st) {
      debugPrint('replyTicket error: $e\n$st');
    }
    fetchTickets();
  }

  // --- مدیریت قرعه‌کشی ---
  Future<void> fetchLotteries() async {
    try {
      final data = await _supabase.from('lotteries').select().order('created_at');
      if (data is List) {
        _lotteries = List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        _lotteries = [Map<String, dynamic>.from(data)];
      } else {
        _lotteries = [];
      }
    } catch (e, st) {
      debugPrint('fetchLotteries error: $e\n$st');
      _lotteries = [];
    }
    notifyListeners();
  }

  Future<void> fetchWinners() async {
    try {
      final data = await _supabase.from('winners').select().order('winner_date');
      if (data is List) {
        _winners = List<Map<String, dynamic>>.from(data);
      } else if (data is Map) {
        _winners = [Map<String, dynamic>.from(data)];
      } else {
        _winners = [];
      }
    } catch (e, st) {
      debugPrint('fetchWinners error: $e\n$st');
      _winners = [];
    }
    notifyListeners();
  }

  Future<void> addOrUpdateLottery(Map<String, dynamic> lottery) async {
    try {
      await _supabase.from('lotteries').upsert(lottery);
    } catch (e, st) {
      debugPrint('addOrUpdateLottery error: $e\n$st');
    }
    fetchLotteries();
  }

  // --- آپلود تصویر به Supabase Storage ---
  Future<String?> uploadImage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final path = 'uploads/$fileName';
      await _supabase.storage.from('media').upload(path, file);
      return _supabase.storage.from('media').getPublicUrl(path);
    } catch (e, st) {
      debugPrint("Upload error: $e\n$st");
      return null;
    }
  }

  // --- بقیه متدهای قبلی ---
  Future<void> fetchOrders() async {
    try {
      final data = await _supabase.from('orders').select().order('created_at', ascending: false);
      if (data is List) {
        _allOrders = (data).map((o) {
          // safe parsing for created_at
          final createdAtRaw = o['created_at'];
          DateTime date;
          if (createdAtRaw is String) {
            date = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
          } else if (createdAtRaw is DateTime) {
            date = createdAtRaw;
          } else {
            date = DateTime.now();
          }

          final totalPrice = (o['total_price'] is num) ? (o['total_price'] as num).toDouble() : 0.0;
          final quantity = (o['quantity'] is int) ? o['quantity'] as int : (o['quantity'] is num ? (o['quantity'] as num).toInt() : 0);
          final statusName = o['status']?.toString() ?? 'pending';
          final status = OrderStatus.values.firstWhere((e) => e.name == statusName, orElse: () => OrderStatus.pending);

          return AppOrder(
            id: o['id'],
            serviceTitle: o['service_title'] ?? '',
            link: o['link'] ?? '',
            quantity: quantity,
            totalPrice: totalPrice,
            date: date,
            status: status,
          );
        }).toList();
      } else {
        _allOrders = [];
      }
    } catch (e, st) {
      debugPrint('fetchOrders error: $e\n$st');
      _allOrders = [];
    }
    notifyListeners();
  }

  Future<void> fetchGateways() async {
    try {
      final data = await _supabase.from('gateways').select();
      if (data is List) {
        _gateways = (data as List).map((g) {
          return PaymentGateway(
            id: g['id'],
            name: g['name'] ?? '',
            url: g['url'] ?? '',
            isActive: g['is_active'] == true,
          );
        }).toList();
      } else {
        _gateways = [];
      }
    } catch (e, st) {
      debugPrint('fetchGateways error: $e\n$st');
      _gateways = [];
    }
    notifyListeners();
  }

  Future<void> addOrder(AppOrder order) async {
    try {
      await _supabase.from('orders').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'service_title': order.serviceTitle,
        'link': order.link,
        'quantity': order.quantity,
        'total_price': order.totalPrice,
        'status': 'pending',
      });
    } catch (e, st) {
      debugPrint('addOrder error: $e\n$st');
    }
    fetchOrders();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      await _supabase.from('orders').update({'status': newStatus.name}).eq('id', orderId);
    } catch (e, st) {
      debugPrint('updateOrderStatus error: $e\n$st');
    }
    fetchOrders();
  }

  Future<void> addOrUpdateGateway(String id, String name, String url) async {
    final payload = {'name': name, 'url': url};
    try {
      if (id.isEmpty) {
        await _supabase.from('gateways').insert(payload);
      } else {
        await _supabase.from('gateways').update(payload).eq('id', id);
      }
    } catch (e, st) {
      debugPrint('addOrUpdateGateway error: $e\n$st');
    }
    fetchGateways();
  }

  Future<void> toggleGatewayStatus(String id) async {
    try {
      final g = _gateways.firstWhere((element) => element.id == id, orElse: () => PaymentGateway(id: id, name: '', url: '', isActive: false));
      await _supabase.from('gateways').update({'is_active': !g.isActive}).eq('id', id);
    } catch (e, st) {
      debugPrint('toggleGatewayStatus error: $e\n$st');
    }
    fetchGateways();
  }
}
