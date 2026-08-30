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
      if (catData is List) {
        _categories = (catData).map((c) {
          final id = c['id']?.toString() ?? '';
          final title = c['title']?.toString() ?? '';
          final iconName = c['icon_name']?.toString();
          final colorCode = c['color_code']?.toString();

          return ServiceCategory(
            id: id,
            title: title,
            icon: _getIconData(iconName),
            color: _getColor(colorCode),
          );
        }).toList();
      } else {
        _categories = [];
      }

      // دریافت سرویس‌ها
      final serData = await _supabase.from('services').select();
      if (serData is List) {
        _services = (serData).map((s) {
          final id = s['id']?.toString() ?? '';
          final catId = s['category_id']?.toString() ?? '';
          final title = s['title']?.toString() ?? '';
          final description = s['description']?.toString() ?? '';

          final priceRaw = s['price_per_1000'];
          final double price = (priceRaw is num) ? priceRaw.toDouble() : (double.tryParse(priceRaw?.toString() ?? '') ?? 0.0);

          final minQRaw = s['min_quantity'];
          final int minQ = (minQRaw is int) ? minQRaw : (minQRaw is num ? minQRaw.toInt() : 0);

          final maxQRaw = s['max_quantity'];
          final int maxQ = (maxQRaw is int) ? maxQRaw : (maxQRaw is num ? maxQRaw.toInt() : 0);

          return SocialService(
            id: id,
            categoryId: catId,
            title: title,
            description: description,
            pricePer1000: price,
            minQuantity: minQ,
            maxQuantity: maxQ,
          );
        }).toList();
      } else {
        _services = [];
      }
    } catch (e, st) {
      debugPrint("Error fetching data: $e\n$st");
      _categories = [];
      _services = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<SocialService> getServicesByCategory(String categoryId) {
    return _services.where((s) => s.categoryId == categoryId).toList();
  }

  // مدیریت توسط ادمین در دیتابیس
  Future<void> addOrUpdateCategory(String title, String iconName, String colorCode) async {
    try {
      await _supabase.from('categories').upsert({
        'title': title,
        'icon_name': iconName,
        'color_code': colorCode,
      });
    } catch (e, st) {
      debugPrint('addOrUpdateCategory error: $e\n$st');
    }
    fetchData();
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);
    } catch (e, st) {
      debugPrint('deleteCategory error: $e\n$st');
    }
    fetchData();
  }

  Future<void> addOrUpdateService(SocialService service) async {
    try {
      await _supabase.from('services').upsert({
        'id': service.id.contains('s') ? null : service.id, // Handle new vs existing
        'category_id': service.categoryId,
        'title': service.title,
        'description': service.description,
        'price_per_1000': service.pricePer1000,
        'min_quantity': service.minQuantity,
        'max_quantity': service.maxQuantity,
      });
    } catch (e, st) {
      debugPrint('addOrUpdateService error: $e\n$st');
    }
    fetchData();
  }

  Future<void> deleteService(String id) async {
    try {
      await _supabase.from('services').delete().eq('id', id);
    } catch (e, st) {
      debugPrint('deleteService error: $e\n$st');
    }
    fetchData();
  }

  FaIconData _getIconData(String? name) {
    switch (name) {
      case 'instagram':
        return FontAwesomeIcons.instagram;
      case 'telegram':
        return FontAwesomeIcons.telegram;
      case 'code':
        return FontAwesomeIcons.code;
      default:
        return FontAwesomeIcons.message;
    }
  }

  Color _getColor(String? hex) {
    if (hex == null) return Colors.blue;
    try {
      final cleaned = hex.replaceFirst('#', '').toUpperCase();
      if (cleaned.length == 6) {
        return Color(int.parse('0xFF$cleaned'));
      } else if (cleaned.length == 8) {
        return Color(int.parse('0x$cleaned'));
      }
    } catch (e) {
      debugPrint('Invalid color code: $hex => $e');
    }
    return Colors.blue;
  }
}
