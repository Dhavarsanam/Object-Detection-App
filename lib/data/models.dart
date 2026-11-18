import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ObjectCategory {
  people('People', Icons.groups_rounded, AppColors.violet),
  vehicles('Vehicles', Icons.directions_car_filled_rounded, AppColors.cyan),
  animals('Animals', Icons.pets_rounded, AppColors.amber),
  everyday('Everyday', Icons.category_rounded, AppColors.mint);

  const ObjectCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

enum DetectionMode {
  general('General', 'AUTO', Icons.auto_awesome_rounded, AppColors.violet,
      'Detect everything around you'),
  surveillance('Surveillance', 'SECURE', Icons.shield_rounded, AppColors.pink,
      'Monitor people & vehicles'),
  inventory('Inventory', 'STOCK', Icons.inventory_2_rounded, AppColors.mint,
      'Count and track items'),
  accessibility('Accessibility', 'ASSIST', Icons.accessibility_new_rounded,
      AppColors.amber, 'Spoken guidance for low vision');

  const DetectionMode(
      this.label, this.short, this.icon, this.color, this.tagline);
  final String label;
  final String short;
  final IconData icon;
  final Color color;
  final String tagline;
}

enum DetectionModel {
  ssdMobileNet('SSD MobileNet v1 · COCO', 'TensorFlow Lite', '4.0 MB', 22, 0.82, bundled: true),
  efficientDet('EfficientDet-Lite0', 'TensorFlow Lite', '4.4 MB', 30, 0.91),
  mlKit('ML Kit Object Detection', 'Firebase ML Kit', 'Play Services', 15, 0.86);

  const DetectionModel(
      this.title, this.runtime, this.size, this.latencyMs, this.accuracy,
      {this.bundled = false});
  final String title;
  final String runtime;
  final String size;
  final int latencyMs;
  final double accuracy;

  /// Whether this model ships with the app and can be selected.
  final bool bundled;
}

class ObjectClass {
  const ObjectClass({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
    required this.color,
    required this.description,
    required this.facts,
    required this.insights,
  });

  final String id;
  final String label;
  final ObjectCategory category;
  final IconData icon;
  final Color color;
  final String description;
  final Map<String, String> facts;
  final Map<DetectionMode, String> insights;
}

/// A single detection in one frame. [box] is normalised (0..1).
class Detection {
  const Detection({
    required this.trackId,
    required this.cls,
    required this.box,
    required this.confidence,
    required this.visibility,
    required this.age,
  });

  final int trackId;
  final ObjectClass cls;
  final Rect box;
  final double confidence;

  /// 0..1 fade used for appear / disappear animation.
  final double visibility;

  /// Seconds this object has been tracked.
  final double age;

  String get direction {
    final x = box.center.dx;
    if (x < 0.38) return 'to your left';
    if (x > 0.62) return 'to your right';
    return 'ahead';
  }

  double get distanceMeters => (0.9 / box.height).clamp(0.4, 15.0);
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.cls,
    required this.confidence,
    required this.time,
    required this.mode,
  });

  final int id;
  final ObjectClass cls;
  final double confidence;
  final DateTime time;
  final DetectionMode mode;
}
