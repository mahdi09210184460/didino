import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServiceCategory {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  ServiceCategory({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}
