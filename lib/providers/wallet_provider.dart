import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalletProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];

  double get balance => _balance;
  List<Map<String, dynamic>> get transactions => _transactions;

  WalletProvider() {
    // Call fetches but ensure they are safe
    fetchBalance();
    fetchTransactions();
  }

  Future<void> fetchBalance() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      // use maybeSingle to avoid throwing if no rows are found
      final data = await _supabase.from('profiles').select('balance').maybeSingle();
      if (data != null && data['balance'] != null) {
        final val = data['balance'];
        if (val is num) {
          _balance = val.toDouble();
        } else if (val is String) {
          _balance = double.tryParse(val) ?? 0.0;
        } else {
          _balance = 0.0;
        }
      } else {
        _balance = 0.0;
      }
      notifyListeners();
    } catch (e, st) {
      debugPrint("Error balance: $e\n$st");
      _balance = 0.0;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final data = await _supabase.from('transactions').select().eq('user_id', user.id).order('created_at');
      if (data is List) {
        _transactions = List<Map<String, dynamic>>.from(data);
      } else {
        _transactions = [];
      }
      notifyListeners();
    } catch (e, st) {
      debugPrint("Error transactions: $e\n$st");
      _transactions = [];
      notifyListeners();
    }
  }

  Future<void> addBalance(double amount, String desc) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newBalance = _balance + amount;
    try {
      await _supabase.from('profiles').update({'balance': newBalance}).eq('id', user.id);

      // ثبت تراکنش
      await _supabase.from('transactions').insert({
        'user_id': user.id,
        'amount': amount,
        'description': desc,
        'type': 'credit'
      });

      _balance = newBalance;
      fetchTransactions();
      notifyListeners();
    } catch (e, st) {
      debugPrint("addBalance error: $e\n$st");
    }
  }

  Future<bool> deductBalance(double amount, String desc) async {
    if (_balance < amount) return false;
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final newBalance = _balance - amount;
    try {
      await _supabase.from('profiles').update({'balance': newBalance}).eq('id', user.id);

      // ثبت تراکنش
      await _supabase.from('transactions').insert({
        'user_id': user.id,
        'amount': amount,
        'description': desc,
        'type': 'debit'
      });

      _balance = newBalance;
      fetchTransactions();
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint("deductBalance error: $e\n$st");
      return false;
    }
  }
}
