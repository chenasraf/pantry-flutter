import 'package:flutter/material.dart';

const checklistIconMap = <String, IconData>{
  'clipboard-check': Icons.assignment_turned_in,
  'clipboard-list': Icons.assignment,
  'format-list-checks': Icons.checklist,
  'cart': Icons.shopping_cart,
  'basket': Icons.shopping_basket,
  'star': Icons.star,
  'heart': Icons.favorite,
  'home': Icons.home,
  'calendar': Icons.calendar_today,
  'bell': Icons.notifications,
  'flag': Icons.flag,
  'bookmark': Icons.bookmark,
  'pin': Icons.push_pin,
  'map-marker': Icons.place,
  'briefcase': Icons.work,
  'wrench': Icons.build,
  'silverware': Icons.restaurant,
  'coffee': Icons.coffee,
  'gift': Icons.card_giftcard,
  'book': Icons.menu_book,
  'school': Icons.school,
  'palette': Icons.palette,
  'camera': Icons.camera_alt,
  'music': Icons.music_note,
  'gamepad': Icons.sports_esports,
  'run': Icons.directions_run,
  'dumbbell': Icons.fitness_center,
  'pill': Icons.medication,
  'paw': Icons.pets,
  'flower': Icons.local_florist,
  'tree': Icons.park,
  'broom': Icons.cleaning_services,
  'lightbulb': Icons.lightbulb,
  'package': Icons.inventory_2,
  'car': Icons.directions_car,
  'bike': Icons.directions_bike,
  'beach': Icons.beach_access,
  'tag': Icons.label,
};

const defaultChecklistIcon = Icons.assignment_turned_in;

IconData checklistIcon(String? key) {
  return checklistIconMap[key ?? ''] ?? defaultChecklistIcon;
}
