import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'models.dart';

/// The object classes the UI knows how to describe. In production these map
/// 1:1 to the label file shipped with the TFLite / ML Kit model.
const List<ObjectClass> kCatalog = [
  ObjectClass(
    id: 'person',
    label: 'Person',
    category: ObjectCategory.people,
    icon: Icons.person_rounded,
    color: AppColors.violet,
    description:
        'A human figure detected from body silhouette, posture and motion cues. '
        'Tracking persists across frames so the same individual keeps a stable ID.',
    facts: {'Avg. height': '1.7 m', 'Class ID': '0', 'Tracking': 'Persistent', 'Privacy': 'No face data'},
    insights: {
      DetectionMode.general: 'One of the most reliably detected classes, even with partial occlusion.',
      DetectionMode.surveillance: 'Entry logged. Dwell time and zone crossings are monitored for this track.',
      DetectionMode.inventory: 'People are excluded from stock counts automatically.',
      DetectionMode.accessibility: 'Someone is nearby. Distance is estimated from body height in frame.',
    },
  ),
  ObjectClass(
    id: 'car',
    label: 'Car',
    category: ObjectCategory.vehicles,
    icon: Icons.directions_car_rounded,
    color: AppColors.cyan,
    description:
        'A passenger vehicle recognised by its body outline, wheels and windows. '
        'Works for parked and moving cars at most viewing angles.',
    facts: {'Avg. length': '4.5 m', 'Class ID': '2', 'Speed est.': 'Supported', 'Plates': 'Not read'},
    insights: {
      DetectionMode.general: 'Detected reliably from front, side and rear views.',
      DetectionMode.surveillance: 'Vehicle presence recorded with timestamp for the activity log.',
      DetectionMode.inventory: 'Useful for parking-lot occupancy counts.',
      DetectionMode.accessibility: 'Vehicle detected. Take care if you are near a road.',
    },
  ),
  ObjectClass(
    id: 'bus',
    label: 'Bus',
    category: ObjectCategory.vehicles,
    icon: Icons.directions_bus_rounded,
    color: Color(0xFF38BDF8),
    description:
        'A large public-transport vehicle identified by its long rectangular body and window rows.',
    facts: {'Avg. length': '12 m', 'Class ID': '5', 'Speed est.': 'Supported', 'Route no.': 'Not read'},
    insights: {
      DetectionMode.general: 'Large footprint makes buses easy to detect at long range.',
      DetectionMode.surveillance: 'Heavy vehicle flagged in the traffic summary.',
      DetectionMode.inventory: 'Fleet counting supported in depot scenarios.',
      DetectionMode.accessibility: 'A bus is nearby — listen for doors and announcements.',
    },
  ),
  ObjectClass(
    id: 'bicycle',
    label: 'Bicycle',
    category: ObjectCategory.vehicles,
    icon: Icons.pedal_bike_rounded,
    color: AppColors.lime,
    description:
        'A two-wheeled bicycle recognised by its frame geometry and pair of wheels, with or without a rider.',
    facts: {'Avg. length': '1.8 m', 'Class ID': '1', 'Rider': 'Tracked separately', 'Speed est.': 'Supported'},
    insights: {
      DetectionMode.general: 'Thin frames can lower confidence at a distance.',
      DetectionMode.surveillance: 'Bike movement logged in the zone timeline.',
      DetectionMode.inventory: 'Great for bike-rack and rental-fleet counts.',
      DetectionMode.accessibility: 'Bicycle nearby — it may be moving quickly and quietly.',
    },
  ),
  ObjectClass(
    id: 'dog',
    label: 'Dog',
    category: ObjectCategory.animals,
    icon: Icons.pets_rounded,
    color: AppColors.amber,
    description:
        'A dog identified from head shape, ears, four-legged stance and fur texture. Covers most breeds and sizes.',
    facts: {'Breeds': '120+ seen', 'Class ID': '16', 'Pose': 'Any', 'Motion': 'Tracked'},
    insights: {
      DetectionMode.general: 'Robust across breeds, coats and poses.',
      DetectionMode.surveillance: 'Animal motion is tagged so it will not raise a person alert.',
      DetectionMode.inventory: 'Animals are excluded from stock counts.',
      DetectionMode.accessibility: 'A dog is close by. It may be a guide or companion animal.',
    },
  ),
  ObjectClass(
    id: 'cat',
    label: 'Cat',
    category: ObjectCategory.animals,
    icon: Icons.pets_outlined,
    color: Color(0xFFFF8A5B),
    description:
        'A cat detected from its compact body, pointed ears and characteristic posture.',
    facts: {'Avg. length': '46 cm', 'Class ID': '15', 'Pose': 'Any', 'Motion': 'Tracked'},
    insights: {
      DetectionMode.general: 'Small size means best results within a few metres.',
      DetectionMode.surveillance: 'Pet activity filtered from intrusion alerts.',
      DetectionMode.inventory: 'Animals are excluded from stock counts.',
      DetectionMode.accessibility: 'A cat is nearby — watch your step.',
    },
  ),
  ObjectClass(
    id: 'laptop',
    label: 'Laptop',
    category: ObjectCategory.everyday,
    icon: Icons.laptop_mac_rounded,
    color: Color(0xFF818CF8),
    description:
        'A portable computer recognised by its screen-and-keyboard clamshell shape, open or closed.',
    facts: {'Avg. width': '33 cm', 'Class ID': '63', 'State': 'Open / closed', 'Screen': 'Not read'},
    insights: {
      DetectionMode.general: 'Detected reliably when open; closed laptops score slightly lower.',
      DetectionMode.surveillance: 'High-value item — unattended device warnings available.',
      DetectionMode.inventory: 'Asset tagged. Add a serial number in the inventory sheet.',
      DetectionMode.accessibility: 'A laptop is in front of you, likely on a desk or table.',
    },
  ),
  ObjectClass(
    id: 'cup',
    label: 'Cup',
    category: ObjectCategory.everyday,
    icon: Icons.coffee_rounded,
    color: Color(0xFFF472B6),
    description:
        'A cup or mug identified by its cylindrical body and handle silhouette.',
    facts: {'Avg. height': '10 cm', 'Class ID': '41', 'Material': 'Any', 'Contents': 'Not inferred'},
    insights: {
      DetectionMode.general: 'Small object — move closer for higher confidence.',
      DetectionMode.surveillance: 'Low-priority object; not included in alerts.',
      DetectionMode.inventory: 'Counted toward kitchenware stock.',
      DetectionMode.accessibility: 'A cup is within reach. Careful — it may contain liquid.',
    },
  ),
  ObjectClass(
    id: 'bottle',
    label: 'Bottle',
    category: ObjectCategory.everyday,
    icon: Icons.local_drink_rounded,
    color: AppColors.mint,
    description:
        'A bottle detected from its tall narrow body and neck. Works for glass, plastic and metal bottles.',
    facts: {'Avg. height': '25 cm', 'Class ID': '39', 'Material': 'Any', 'Label': 'Not read'},
    insights: {
      DetectionMode.general: 'Transparent bottles can be harder to detect in low light.',
      DetectionMode.surveillance: 'Low-priority object; not included in alerts.',
      DetectionMode.inventory: 'Ideal for shelf and fridge stock counts.',
      DetectionMode.accessibility: 'A bottle is in front of you.',
    },
  ),
  ObjectClass(
    id: 'phone',
    label: 'Cell phone',
    category: ObjectCategory.everyday,
    icon: Icons.smartphone_rounded,
    color: Color(0xFF60A5FA),
    description:
        'A smartphone recognised by its flat rectangular slab shape, held in hand or lying on a surface.',
    facts: {'Avg. height': '15 cm', 'Class ID': '67', 'State': 'Any', 'Screen': 'Not read'},
    insights: {
      DetectionMode.general: 'Often detected in hand alongside a person.',
      DetectionMode.surveillance: 'Device usage noted in restricted zones.',
      DetectionMode.inventory: 'Counted as an electronic asset.',
      DetectionMode.accessibility: 'A phone is nearby — possibly the one you are looking for.',
    },
  ),
  ObjectClass(
    id: 'chair',
    label: 'Chair',
    category: ObjectCategory.everyday,
    icon: Icons.chair_rounded,
    color: Color(0xFFA78BFA),
    description:
        'A chair identified by seat, legs and backrest geometry, from office chairs to dining chairs.',
    facts: {'Avg. height': '90 cm', 'Class ID': '56', 'Type': 'Any', 'Occupied': 'Detected'},
    insights: {
      DetectionMode.general: 'Partially hidden chairs under tables are still recognised.',
      DetectionMode.surveillance: 'Furniture is ignored for motion alerts.',
      DetectionMode.inventory: 'Counted toward furniture stock.',
      DetectionMode.accessibility: 'A chair is nearby — a place to sit or an obstacle to avoid.',
    },
  ),
  ObjectClass(
    id: 'backpack',
    label: 'Backpack',
    category: ObjectCategory.everyday,
    icon: Icons.backpack_rounded,
    color: AppColors.pink,
    description:
        'A backpack recognised by its rounded pack shape and shoulder straps, worn or set down.',
    facts: {'Avg. height': '45 cm', 'Class ID': '24', 'Worn': 'Detected', 'Contents': 'Not inferred'},
    insights: {
      DetectionMode.general: 'Detected both on a person and placed on the ground.',
      DetectionMode.surveillance: 'Unattended bag detection available for this class.',
      DetectionMode.inventory: 'Counted as a bag / luggage item.',
      DetectionMode.accessibility: 'A bag is on the floor nearby — mind your step.',
    },
  ),
  ObjectClass(
    id: 'plant',
    label: 'Potted plant',
    category: ObjectCategory.everyday,
    icon: Icons.local_florist_rounded,
    color: Color(0xFF4ADE80),
    description:
        'A potted plant identified from foliage texture and container shape.',
    facts: {'Avg. height': '60 cm', 'Class ID': '58', 'Species': 'Not inferred', 'Pot': 'Detected'},
    insights: {
      DetectionMode.general: 'Leafy textures make plants easy to spot.',
      DetectionMode.surveillance: 'Static décor — ignored for motion alerts.',
      DetectionMode.inventory: 'Counted toward décor stock.',
      DetectionMode.accessibility: 'A plant is nearby, likely on the floor or a shelf.',
    },
  ),
];

ObjectClass catalogById(String id) =>
    kCatalog.firstWhere((c) => c.id == id, orElse: () => kCatalog.first);

// ---------------------------------------------------------------------------
// COCO label mapping for the bundled TensorFlow Lite model.
// ---------------------------------------------------------------------------

const _cocoToCatalog = {
  'person': 'person',
  'car': 'car',
  'bus': 'bus',
  'bicycle': 'bicycle',
  'dog': 'dog',
  'cat': 'cat',
  'laptop': 'laptop',
  'cup': 'cup',
  'bottle': 'bottle',
  'cell phone': 'phone',
  'chair': 'chair',
  'backpack': 'backpack',
  'potted plant': 'plant',
};

const _cocoVehicles = {'motorcycle', 'airplane', 'train', 'truck', 'boat'};
const _cocoAnimals = {
  'bird', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe',
};

const _cocoIcons = <String, IconData>{
  'motorcycle': Icons.two_wheeler_rounded,
  'airplane': Icons.flight_rounded,
  'train': Icons.train_rounded,
  'truck': Icons.local_shipping_rounded,
  'boat': Icons.directions_boat_rounded,
  'bird': Icons.flutter_dash_rounded,
  'tv': Icons.tv_rounded,
  'keyboard': Icons.keyboard_rounded,
  'mouse': Icons.mouse_rounded,
  'book': Icons.menu_book_rounded,
  'clock': Icons.schedule_rounded,
  'couch': Icons.weekend_rounded,
  'bed': Icons.bed_rounded,
  'dining table': Icons.table_restaurant_rounded,
  'umbrella': Icons.umbrella_rounded,
  'handbag': Icons.shopping_bag_rounded,
  'suitcase': Icons.luggage_rounded,
  'sports ball': Icons.sports_soccer_rounded,
  'traffic light': Icons.traffic_rounded,
  'stop sign': Icons.do_not_disturb_on_rounded,
  'scissors': Icons.content_cut_rounded,
  'refrigerator': Icons.kitchen_rounded,
  'microwave': Icons.microwave_rounded,
  'wine glass': Icons.wine_bar_rounded,
  'fork': Icons.restaurant_rounded,
  'knife': Icons.restaurant_rounded,
  'spoon': Icons.restaurant_rounded,
  'bowl': Icons.ramen_dining_rounded,
  'pizza': Icons.local_pizza_rounded,
  'cake': Icons.cake_rounded,
  'remote': Icons.settings_remote_rounded,
  'toilet': Icons.wc_rounded,
  'sink': Icons.water_drop_rounded,
  'vase': Icons.local_florist_rounded,
};

final _generated = <String, ObjectClass>{};

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Resolve a raw model label (e.g. "cell phone") to a UI object class.
/// Labels without a hand-written entry get a generated, still-pretty class.
ObjectClass classForLabel(String label) {
  final known = _cocoToCatalog[label];
  if (known != null) return catalogById(known);
  return _generated.putIfAbsent(label, () {
    final category = _cocoVehicles.contains(label)
        ? ObjectCategory.vehicles
        : _cocoAnimals.contains(label)
            ? ObjectCategory.animals
            : ObjectCategory.everyday;
    final name = _titleCase(label);
    return ObjectClass(
      id: 'coco:$label',
      label: name,
      category: category,
      icon: _cocoIcons[label] ?? category.icon,
      color: category.color,
      description:
          '$name recognised by the on-device COCO model from its shape, '
          'texture and context in the scene.',
      facts: {
        'Dataset': 'COCO',
        'Category': category.label,
        'Runtime': 'TFLite',
        'Tracking': 'IoU-based',
      },
      insights: {
        DetectionMode.general: '$name detected and tracked across frames.',
        DetectionMode.surveillance:
            '$name noted in the activity log for this zone.',
        DetectionMode.inventory: '$name counted toward the current tally.',
        DetectionMode.accessibility: 'There is a ${label.toLowerCase()} nearby.',
      },
    );
  });
}
