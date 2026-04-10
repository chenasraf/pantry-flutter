import 'package:flutter/material.dart';
import 'package:pantry/i18n.dart';
import 'package:pantry/models/category.dart';
import 'package:pantry/services/category_service.dart';
import 'package:pantry/utils/category_icons.dart';
import 'package:pantry/widgets/create_category_dialog.dart';

class CategoriesView extends StatefulWidget {
  final int houseId;

  const CategoriesView({super.key, required this.houseId});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await CategoryService.instance.getCategories(widget.houseId);
      if (!mounted) return;
      setState(() {
        _categories = list..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _create() async {
    final created = await showDialog<Category>(
      context: context,
      builder: (_) => CreateCategoryDialog(houseId: widget.houseId),
    );
    if (created != null) {
      setState(() => _categories = [..._categories, created]);
    }
  }

  Future<void> _edit(Category category) async {
    final updated = await showDialog<Category>(
      context: context,
      builder: (_) =>
          CreateCategoryDialog(houseId: widget.houseId, existing: category),
    );
    if (updated != null) {
      setState(() {
        final index = _categories.indexWhere((c) => c.id == updated.id);
        if (index != -1) {
          _categories[index] = updated;
          _categories = [..._categories];
        }
      });
    }
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.categories.deleteConfirm),
        content: Text(m.categories.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(m.common.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(m.common.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await CategoryService.instance.deleteCategory(
        widget.houseId,
        category.id,
      );
      setState(() {
        _categories = _categories.where((c) => c.id != category.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(m.categories.deleteFailed)));
    }
  }

  Color? _parseColor(String hex) {
    if (hex.isEmpty) return null;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(m.categories.manageTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: Text(m.common.retry)),
                  ],
                ),
              ),
            )
          : _categories.isEmpty
          ? Center(child: Text(m.categories.noCategories))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final color =
                      _parseColor(cat.color) ?? theme.colorScheme.primary;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withAlpha(40),
                      child: Icon(categoryIcon(cat.icon), color: color),
                    ),
                    title: Text(cat.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _edit(cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          onPressed: () => _delete(cat),
                        ),
                      ],
                    ),
                    onTap: () => _edit(cat),
                  );
                },
              ),
            ),
    );
  }
}
