import 'dart:math' as math;
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;
import 'package:colonia_front_app/utils/icon_helper.dart';

class CategoryTabData {
  final String id;
  final String? label;
  final dynamic icon;

  const CategoryTabData({
    required this.id,
    this.label,
    required this.icon,
  });

  static List<CategoryTabData> get defaultAvatarCategories => [
        CategoryTabData(
          id: AvatarItemType.head.name,
          icon: avatarItemTypeIcons[AvatarItemType.head]!,
        ),
        CategoryTabData(
          id: AvatarItemType.neck.name,
          icon: avatarItemTypeIcons[AvatarItemType.neck]!,
        ),
        CategoryTabData(
          id: AvatarItemType.body.name,
          icon: avatarItemTypeIcons[AvatarItemType.body]!,
        ),
        CategoryTabData(
          id: AvatarItemType.footwear.name,
          icon: avatarItemTypeIcons[AvatarItemType.footwear]!,
        ),
      ];
}

class ItemSelectionData {
  final dynamic id;
  final String? name;
  final String? type;
  final String? image;
  final dynamic icon;
  final int? cost;
  final bool isUnlocked;
  final bool isEquipped;
  final dynamic originalItem;

  const ItemSelectionData({
    required this.id,
    this.name,
    this.type,
    this.image,
    this.icon,
    this.cost,
    this.isUnlocked = true,
    this.isEquipped = false,
    this.originalItem,
  });

  factory ItemSelectionData.fromAvatarItem(
    AvatarItem avatarItem, {
    bool isUnlocked = true,
    bool isEquipped = false,
    int? cost,
    dynamic icon,
  }) {
    return ItemSelectionData(
      id: avatarItem.id,
      name: avatarItem.name,
      type: avatarItem.type,
      image: avatarItem.image,
      icon: icon,
      cost: cost,
      isUnlocked: isUnlocked,
      isEquipped: isEquipped,
      originalItem: avatarItem,
    );
  }
}

class ItemSelectionWidget extends StatefulWidget {
  final List<ItemSelectionData> items;
  final List<CategoryTabData>? categories;
  final String? initialCategoryId;
  final dynamic selectedItemId;
  final Set<dynamic>? selectedItemIds;
  final Set<dynamic>? equippedItemIds;
  final ValueChanged<ItemSelectionData>? onItemSelected;
  final ValueChanged<ItemSelectionData>? onLockedItemTap;
  final ValueChanged<CategoryTabData>? onCategoryChanged;
  final int itemsPerPage;
  final int crossAxisCount;
  final double? childAspectRatio;
  final bool showTabs;
  final String? emptyMessage;

  const ItemSelectionWidget({
    super.key,
    required this.items,
    this.categories,
    this.initialCategoryId,
    this.selectedItemId,
    this.selectedItemIds,
    this.equippedItemIds,
    this.onItemSelected,
    this.onLockedItemTap,
    this.onCategoryChanged,
    this.itemsPerPage = 3,
    this.crossAxisCount = 3,
    this.childAspectRatio,
    this.showTabs = true,
    this.emptyMessage,
  });

  @override
  State<ItemSelectionWidget> createState() => _ItemSelectionWidgetState();
}

class _ItemSelectionWidgetState extends State<ItemSelectionWidget> {
  late String _currentCategoryId;
  late PageController _pageController;
  int _currentPage = 0;

  List<CategoryTabData> get _activeCategories {
    if (widget.categories != null && widget.categories!.isNotEmpty) {
      return widget.categories!;
    }
    final itemTypes = widget.items.map((e) => e.type).whereType<String>().toSet();
    if (itemTypes.isEmpty) {
      return CategoryTabData.defaultAvatarCategories;
    }
    final defaults = CategoryTabData.defaultAvatarCategories;
    final categoryList = <CategoryTabData>[];
    for (final defaultCat in defaults) {
      if (itemTypes.contains(defaultCat.id)) {
        categoryList.add(defaultCat);
      }
    }
    for (final type in itemTypes) {
      if (!categoryList.any((c) => c.id == type)) {
        categoryList.add(CategoryTabData(
          id: type,
          icon: (Color color, double size) => iconoir.Cell2x2(color: color, width: size, height: size),
          label: type.toUpperCase(),
        ));
      }
    }
    return categoryList.isEmpty ? CategoryTabData.defaultAvatarCategories : categoryList;
  }

  @override
  void initState() {
    super.initState();
    final categories = _activeCategories;
    if (widget.initialCategoryId != null &&
        categories.any((c) => c.id == widget.initialCategoryId)) {
      _currentCategoryId = widget.initialCategoryId!;
    } else {
      _currentCategoryId = categories.isNotEmpty ? categories.first.id : '';
    }
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant ItemSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategoryId != null &&
        widget.initialCategoryId != oldWidget.initialCategoryId &&
        widget.initialCategoryId != _currentCategoryId) {
      _selectCategory(widget.initialCategoryId!);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectCategory(String categoryId) {
    if (_currentCategoryId == categoryId) return;
    final cat = _activeCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => CategoryTabData(
        id: categoryId,
        icon: (Color color, double size) => iconoir.Cell2x2(color: color, width: size, height: size),
      ),
    );
    setState(() {
      _currentCategoryId = categoryId;
      _currentPage = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    widget.onCategoryChanged?.call(cat);
  }

  bool _isItemSelected(dynamic itemId) {
    if (widget.selectedItemId != null && widget.selectedItemId == itemId) {
      return true;
    }
    if (widget.selectedItemIds != null && widget.selectedItemIds!.contains(itemId)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final categories = _activeCategories;
    final categoryItems = widget.items
        .where((item) => item.type == _currentCategoryId || _currentCategoryId.isEmpty)
        .toList();

    final totalPages = categoryItems.isEmpty
        ? 0
        : (categoryItems.length / widget.itemsPerPage).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTabs && categories.isNotEmpty) ...[
          _buildCategoryTabs(categories),
          const SizedBox(height: 12),
        ],
        if (totalPages == 0) ...[
          _buildEmptyState(locale),
        ] else ...[
          _buildPaginatedGrid(categoryItems, totalPages),
        ],
      ],
    );
  }

  Widget _buildCategoryTabs(List<CategoryTabData> categories) {
    if (categories.length <= 4) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final isFirst = index == 0;
          final isLast = index == categories.length - 1;
          final isSelected = cat.id == _currentCategoryId;

          BorderRadius borderRadius;
          if (isFirst) {
            borderRadius = const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            );
          } else if (isLast) {
            borderRadius = const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            );
          } else {
            borderRadius = BorderRadius.zero;
          }

          return Expanded(
            child: _ItemCategoryTabChip(
              icon: cat.icon,
              label: cat.label,
              isSelected: isSelected,
              onSelected: () => _selectCategory(cat.id),
              borderRadius: borderRadius,
              color: AppTheme.tertiaryColor,
            ),
          );
        }).toList(),
      );
    } else {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.asMap().entries.map((entry) {
            final cat = entry.value;
            final isSelected = cat.id == _currentCategoryId;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _ItemCategoryTabChip(
                icon: cat.icon,
                label: cat.label,
                isSelected: isSelected,
                onSelected: () => _selectCategory(cat.id),
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.tertiaryColor,
              ),
            );
          }).toList(),
        ),
      );
    }
  }

  Widget _buildPaginatedGrid(List<ItemSelectionData> categoryItems, int totalPages) {
    final hasPrice = categoryItems.any((item) => item.cost != null);
    final defaultAspectRatio = hasPrice ? 0.72 : 0.85;
    final aspectRatio = widget.childAspectRatio ?? defaultAspectRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 10.0;
        final rowsPerPage = (widget.itemsPerPage / widget.crossAxisCount).ceil();
        final itemWidth = (availableWidth - (widget.crossAxisCount - 1) * spacing) / widget.crossAxisCount;
        final itemHeight = itemWidth / aspectRatio;
        final gridHeight = rowsPerPage * itemHeight + (rowsPerPage - 1) * spacing;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages,
                onPageChanged: (pageIndex) {
                  setState(() {
                    _currentPage = pageIndex;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * widget.itemsPerPage;
                  final endIndex = math.min(
                    (pageIndex + 1) * widget.itemsPerPage,
                    categoryItems.length,
                  );
                  final pageItems = categoryItems.sublist(startIndex, endIndex);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) {
                      final item = pageItems[index];
                      return _buildItemCard(context, item);
                    },
                  );
                },
              ),
            ),
            if (totalPages > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  final isCurrent = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 16 : 6,
                    height: 6,
                    decoration: ShapeDecoration(
                      color: isCurrent ? AppTheme.primaryColor : Colors.white24,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isItemEquipped(ItemSelectionData item) {
    if (item.isEquipped) return true;
    if (widget.equippedItemIds != null && widget.equippedItemIds!.contains(item.id)) {
      return true;
    }
    return false;
  }

  Widget _buildItemCard(BuildContext context, ItemSelectionData item) {
    final isSelected = _isItemSelected(item.id);
    final isUnlocked = item.isUnlocked;
    final isEquipped = _isItemEquipped(item);

    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          widget.onLockedItemTap?.call(item);
        }
        widget.onItemSelected?.call(item);
      },
      child: Stack(
        children: [
          Container(
            decoration: ShapeDecoration(
              color: isSelected
                  ? AppTheme.tertiaryColor.withAlpha(25)
                  : (isEquipped
                      ? AppTheme.primaryColor.withAlpha(25)
                      : (isUnlocked ? Colors.black26 : Colors.white.withAlpha(5))),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.secondaryColor
                      : (isEquipped
                          ? AppTheme.primaryColor.withAlpha(160)
                          : (isUnlocked ? Colors.white24 : Colors.white12)),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4.0),
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: isUnlocked ? 1.0 : 0.4,
                            child: _buildItemVisual(item),
                          ),
                          if (isEquipped)
                            Container(
                              color: AppTheme.primaryColor.withAlpha(45),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (item.cost != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: ShapeDecoration(
                      color: Colors.black.withAlpha(120),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_money_sharp,
                          color: AppTheme.primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${item.cost}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            fontFamily: 'Oswald',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isUnlocked)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: ShapeDecoration(
                  color: Colors.black54,
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: isUnlocked ? AppTheme.successColor : Colors.orangeAccent,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.lock,
                  size: 11,
                  color: isUnlocked ? AppTheme.successColor : Colors.orangeAccent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItemVisual(ItemSelectionData item) {
    if (item.image != null && item.image!.isNotEmpty) {
      if (item.image!.startsWith('http://') || item.image!.startsWith('https://')) {
        return Image.network(
          item.image!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: buildIconWidget(
                item.icon,
                color: Colors.white38,
                size: 32,
              ),
            );
          },
        );
      } else {
        return Image.asset(
          item.image!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: buildIconWidget(
                item.icon,
                color: Colors.white38,
                size: 32,
              ),
            );
          },
        );
      }
    } else {
      return Center(
        child: buildIconWidget(
          item.icon,
          color: Colors.white70,
          size: 32,
        ),
      );
    }
  }

  Widget _buildEmptyState(AppLocalizations? locale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(10),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white24, width: 1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.checkroom_outlined, size: 40, color: Colors.white.withAlpha(80)),
          const SizedBox(height: 8),
          Text(
            widget.emptyMessage ?? locale?.noItemsForCategory ?? 'No items available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCategoryTabChip extends StatelessWidget {
  final dynamic icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;
  final BorderRadius borderRadius;

  const _ItemCategoryTabChip({
    required this.icon,
    this.label,
    required this.isSelected,
    required this.onSelected,
    required this.color,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? AppTheme.darkBackground : Colors.white;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: isSelected ? color : color.withAlpha(20),
          shape: BeveledRectangleBorder(
            borderRadius: borderRadius,
            side: BorderSide(
              color: isSelected ? Colors.white : color.withAlpha(100),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildIconWidget(icon, color: iconColor, size: 18),
            if (label != null && label!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  fontFamily: 'Oswald',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
