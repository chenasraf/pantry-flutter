import 'package:flutter/material.dart';

const categoryIconMap = <String, IconData>{
  'tag': Icons.label,
  'food': Icons.lunch_dining,
  'fruit': Icons.apple,
  'vegetable': Icons.grass,
  'bakery': Icons.bakery_dining,
  'dairy': Icons.egg_alt,
  'meat': Icons.kebab_dining,
  'fish': Icons.set_meal,
  'snacks': Icons.breakfast_dining,
  'cookie': Icons.cookie,
  'drinks': Icons.wine_bar,
  'coffee': Icons.coffee,
  'frozen': Icons.ac_unit,
  'household': Icons.cleaning_services,
  'pets': Icons.pets,
  'baby': Icons.child_friendly,
  'home': Icons.home,
  'leaf': Icons.eco,
  'pizza': Icons.local_pizza,
};

const defaultCategoryIcon = Icons.label;

IconData categoryIcon(String? key) {
  return categoryIconMap[key ?? ''] ?? defaultCategoryIcon;
}
