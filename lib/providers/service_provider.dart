import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';

class ServiceProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<ServiceCategory> _categories = [];
  List<SocialService> _services = [];
  bool _isLoading = false;

  List<ServiceCategory> get categories => _categories;
  List<SocialService> get allServices => _services;
  bool get isLoading => _isLoading;

  ServiceProvider() {
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // دریافت دسته‌بندی‌ها
      final catData = await _supabase.from('categories').select();
      _categories = (catData as List).map((c) => ServiceCategory(
        id: c['id'],
        title: c['title'],
        icon: _getIconData(c['icon_name']),
        color: _getColor(c['color_code']),
      )).toList();

      // دریافت سرویس‌ها
      final serData = await _supabase.from('services').select();
      _services = (serData as List).map((s) => SocialService(
        id: s['id'],
        categoryId: s['category_id'],
        title: s['title'],
        description: s['description'],
        pricePer1000: (s['price_per_1000'] as num).toDouble(),
        minQuantity: s['min_quantity'],
        maxQuantity: s['max_quantity'],
      )).toList();
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  List<SocialService> getServicesByCategory(String categoryId) {
    return _services.where((s) => s.categoryId == categoryId).toList();
  }

  // مدیریت توسط ادمین در دیتابیس
  Future<void> addOrUpdateCategory(String title, String iconName, String colorCode) async {
    await _supabase.from('categories').upsert({
      'title': title,
      'icon_name': iconName,
      'color_code': colorCode,
    });
    fetchData();
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('categories').delete().eq('id', id);
    fetchData();
  }

  Future<void> addOrUpdateService(SocialService service) async {
    await _supabase.from('services').upsert({
      'id': service.id.contains('s') ? null : service.id, // Handle new vs existing
      'category_id': service.categoryId,
      'title': service.title,
      'description': service.description,
      'price_per_1000': service.pricePer1000,
      'min_quantity': service.minQuantity,
      'max_quantity': service.maxQuantity,
    });
    fetchData();
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
    fetchData();
  }

  FaIconData _getIconData(String? name) {
    switch(name) {
      case 'instagram': return FontAwesomeIcons.instagram;
      case 'telegram': return FontAwesomeIcons.telegram;
      case 'code': return FontAwesomeIcons.code;
      default: return FontAwesomeIcons.message;
    }
  }

  Color _getColor(String? hex) {
    if (hex == null) return Colors.blue;
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }
}
