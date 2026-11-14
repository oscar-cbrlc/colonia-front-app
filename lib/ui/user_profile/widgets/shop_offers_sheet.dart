import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;

import 'package:colonia_front_app/data/repositories/shop_repository.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/shop_offer.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/loading_widget.dart';
import 'package:colonia_front_app/ui/user_profile/view_models/user_profile_viewmodel.dart';
import 'package:colonia_front_app/ui/user_profile/widgets/item_selection_widget.dart';
import 'package:colonia_front_app/utils/icon_helper.dart';

void showShopOffersSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const ShopOffersSheet(),
  );
}

class ShopOffersSheet extends StatefulWidget {
  const ShopOffersSheet({super.key});

  @override
  State<ShopOffersSheet> createState() => _ShopOffersSheetState();
}

class _ShopOffersSheetState extends State<ShopOffersSheet> {
  String _selectedItemTabId = 'all';

  late PageController _itemPageController;
  late PageController _bundlePageController;

  int _currentItemPage = 0;
  int _currentBundlePage = 0;

  int? _selectedItemOfferId;
  int? _selectedBundleOfferId;

  @override
  void initState() {
    super.initState();
    _itemPageController = PageController();
    _bundlePageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ShopRepository>().fetchOffers();
      }
    });
  }

  @override
  void dispose() {
    _itemPageController.dispose();
    _bundlePageController.dispose();
    super.dispose();
  }

  List<CategoryTabData> _getItemShopTabs(AppLocalizations locale) {
    return [
      CategoryTabData(
        id: 'all',
        label: locale.items.toUpperCase(),
        icon: (Color color, double size) => iconoir.Cell2x2(color: color, width: size, height: size),
      ),
      CategoryTabData(
        id: AvatarItemType.head.name,
        label: locale.avatarItemTypeHead.toUpperCase(),
        icon: avatarItemTypeIcons[AvatarItemType.head]!,
      ),
      CategoryTabData(
        id: AvatarItemType.neck.name,
        label: locale.avatarItemTypeNeck.toUpperCase(),
        icon: avatarItemTypeIcons[AvatarItemType.neck]!,
      ),
      CategoryTabData(
        id: AvatarItemType.body.name,
        label: locale.avatarItemTypeBody.toUpperCase(),
        icon: avatarItemTypeIcons[AvatarItemType.body]!,
      ),
      CategoryTabData(
        id: AvatarItemType.footwear.name,
        label: locale.avatarItemTypeFootwear.toUpperCase(),
        icon: avatarItemTypeIcons[AvatarItemType.footwear]!,
      ),
    ];
  }

  void _onItemTabSelected(String tabId) {
    if (_selectedItemTabId == tabId) return;
    setState(() {
      _selectedItemTabId = tabId;
      _currentItemPage = 0;
      _selectedItemOfferId = null;
    });
    if (_itemPageController.hasClients) {
      _itemPageController.jumpToPage(0);
    }
  }

  List<ShopOffer> _filterItemOffers(List<ShopOffer> offers) {
    final itemOffers = offers.where((o) => o.typeEnum == ShopOfferType.item).toList();
    if (_selectedItemTabId == 'all') {
      return itemOffers;
    }
    return itemOffers.where((o) {
      final item = o.avatarItem;
      if (item == null) return true;
      return item.type.toLowerCase() == _selectedItemTabId.toLowerCase();
    }).toList();
  }

  List<ShopOffer> _getBundleOffers(List<ShopOffer> offers) {
    return offers.where((o) => o.typeEnum == ShopOfferType.bundle).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final shopRepository = context.watch<ShopRepository>();
    final userProfileVM = context.watch<UserProfileViewModel>();

    final offers = shopRepository.offers;
    final filteredItemOffers = _filterItemOffers(offers);
    final bundleOffers = _getBundleOffers(offers);

    final tabs = _getItemShopTabs(locale);
    final coins = userProfileVM.user.coinAmount ?? 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const ShapeDecoration(
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        color: AppTheme.darkBackground,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryColor,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      locale.shop.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                        fontSize: 21,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: ShapeDecoration(
                        color: AppTheme.primaryColor.withAlpha(25),
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppTheme.primaryColor.withAlpha(140),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                           buildIconWidget(iconoir.Coins(color: AppTheme.primaryColor, width: 16, height: 16,), color: AppTheme.primaryColor, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$coins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFamily: 'Oswald',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: shopRepository.isLoading && offers.isEmpty
                  ? const LoadingWidget()
                  : RefreshIndicator(
                      onRefresh: () async {
                        await context.read<ShopRepository>().fetchOffers();
                      },
                      color: AppTheme.primaryColor,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildItemOffersSection(
                              filteredItemOffers,
                              tabs,
                              locale,
                              userProfileVM,
                              coins,
                            ),
                            const SizedBox(height: 20),
                            _buildBundleOffersSection(
                              bundleOffers,
                              locale,
                              userProfileVM,
                              coins,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemOffersSection(
    List<ShopOffer> itemOffers,
    List<CategoryTabData> tabs,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
    int userCoins,
  ) {
    const itemsPerPage = 3;
    final totalPages = itemOffers.isEmpty
        ? 0
        : (itemOffers.length / itemsPerPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.grid_view_sharp,
              color: AppTheme.secondaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              locale.items.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oswald',
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildItemTabNavigation(tabs),
        const SizedBox(height: 14),
        if (totalPages == 0) ...[
          _buildEmptySectionState(locale.noItemOffers),
        ] else ...[
          _buildItemOffersPager(itemOffers, totalPages, itemsPerPage, locale, userProfileVM, userCoins),
        ],
      ],
    );
  }

  Widget _buildItemTabNavigation(List<CategoryTabData> tabs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.id == _selectedItemTabId;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _ExpandableCategoryTabChip(
              icon: tab.icon,
              label: tab.label,
              isSelected: isSelected,
              onSelected: () => _onItemTabSelected(tab.id),
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemOffersPager(
    List<ShopOffer> itemOffers,
    int totalPages,
    int itemsPerPage,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
    int userCoins,
  ) {
    const crossAxisCount = 3;
    const spacing = 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final rowsPerPage = (itemsPerPage / crossAxisCount).ceil();
        final itemWidth = (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

        final cardHeight = itemWidth / 0.65;
        final gridHeight = rowsPerPage * cardHeight + (rowsPerPage - 1) * spacing;

        return Column(
          children: [
            SizedBox(
              height: gridHeight,
              child: PageView.builder(
                controller: _itemPageController,
                itemCount: totalPages,
                onPageChanged: (pageIndex) {
                  setState(() {
                    _currentItemPage = pageIndex;
                  });
                },
                itemBuilder: (context, pageIndex) {
                  final startIndex = pageIndex * itemsPerPage;
                  final endIndex = math.min(
                    (pageIndex + 1) * itemsPerPage,
                    itemOffers.length,
                  );
                  final pageItems = itemOffers.sublist(startIndex, endIndex);

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: pageItems.length,
                    itemBuilder: (context, index) {
                      final offer = pageItems[index];
                      return _buildItemOfferCard(offer, locale, userProfileVM, userCoins);
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
                  final isCurrent = index == _currentItemPage;
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

  Widget _buildItemOfferCard(
    ShopOffer offer,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
    int userCoins,
  ) {
    final avatarItem = offer.avatarItem;
    final itemId = avatarItem?.id;
    final isUnlocked = itemId != null ? userProfileVM.isItemUnlocked(itemId) : false;
    final shopRepo = context.watch<ShopRepository>();
    final isPurchased = shopRepo.isOfferPurchased(offer.id);
    final isOwned = isUnlocked || isPurchased;

    final isSelected = _selectedItemOfferId == offer.id;
    final canAfford = userCoins >= offer.price;

    final itemName = avatarItem != null
        ? avatarItem.getNameLocale(locale)
        : offer.name;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_selectedItemOfferId == offer.id) {
            _selectedItemOfferId = null;
          } else {
            _selectedItemOfferId = offer.id;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: ShapeDecoration(
          color: isOwned
              ? AppTheme.successColor.withAlpha(35)
              : (isSelected
                  ? AppTheme.primaryColor.withAlpha(25)
                  : Colors.black26),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.secondaryColor
                  : (isOwned ? AppTheme.successColor.withAlpha(160) : Colors.white24),
              width: 1.0,
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
                      _buildItemVisual(avatarItem, offer.image),
                      if (isOwned)
                        Container(
                          color: AppTheme.successColor.withAlpha(40),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_outline,
                              color: AppTheme.successColor,
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              decoration: ShapeDecoration(
                color: isOwned
                    ? AppTheme.successColor.withAlpha(50)
                    : Colors.black.withAlpha(140),
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
                    size: 13,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '${offer.price}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Oswald',
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: isSelected
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4, left: 4, right: 4, bottom: 4),
                      child: isOwned
                          ? _buildOwnedContainer(locale)
                          : _buildItemBuyButton(offer, canAfford, locale, userProfileVM),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnedContainer(AppLocalizations locale) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: ShapeDecoration(
        color: AppTheme.successColor.withAlpha(40),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: AppTheme.successColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check, color: AppTheme.successColor, size: 14),
          const SizedBox(width: 4),
          Text(
            locale.owned.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
              fontFamily: 'Oswald',
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemBuyButton(
    ShopOffer offer,
    bool canAfford,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
  ) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey.withAlpha(80),
          foregroundColor: canAfford ? AppTheme.darkBackground : Colors.white38,
          disabledBackgroundColor: Colors.grey.withAlpha(50),
          disabledForegroundColor: Colors.white24,
          padding: EdgeInsets.zero,
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        onPressed: canAfford
            ? () => _showConfirmationDialog(context, offer, locale, userProfileVM)
            : null,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                size: 12,
                color: canAfford ? AppTheme.darkBackground : Colors.white38,
              ),
              const SizedBox(width: 4),
              Text(
                locale.buy.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Oswald',
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: canAfford ? AppTheme.darkBackground : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBundleOffersSection(
    List<ShopOffer> bundleOffers,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
    int userCoins,
  ) {
    final totalPages = bundleOffers.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.card_giftcard_sharp,
              color: AppTheme.tertiaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              locale.bundles.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Oswald',
                fontSize: 16,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (totalPages == 0) ...[
          _buildEmptySectionState(locale.noBundleOffers),
        ] else ...[
          SizedBox(
            height: 260,
            child: PageView.builder(
              controller: _bundlePageController,
              itemCount: totalPages,
              onPageChanged: (pageIndex) {
                setState(() {
                  _currentBundlePage = pageIndex;
                });
              },
              itemBuilder: (context, pageIndex) {
                final offer = bundleOffers[pageIndex];
                return _buildBundleOfferCard(offer, locale, userProfileVM, userCoins);
              },
            ),
          ),
          if (totalPages > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                final isCurrent = index == _currentBundlePage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isCurrent ? 16 : 6,
                  height: 6,
                  decoration: ShapeDecoration(
                    color: isCurrent ? AppTheme.tertiaryColor : Colors.white24,
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildBundleOfferCard(
    ShopOffer offer,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
    int userCoins,
  ) {
    final items = offer.itemsInOffer;
    final shopRepo = context.watch<ShopRepository>();
    final isPurchased = shopRepo.isOfferPurchased(offer.id);

    final isSelected = _selectedBundleOfferId == offer.id;
    final canAfford = userCoins >= offer.price;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (_selectedBundleOfferId == offer.id) {
            _selectedBundleOfferId = null;
          } else {
            _selectedBundleOfferId = offer.id;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: ShapeDecoration(
          color: isPurchased
              ? AppTheme.successColor.withAlpha(20)
              : (isSelected
                  ? AppTheme.tertiaryColor.withAlpha(30)
                  : AppTheme.tertiaryColor.withAlpha(15)),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.secondaryColor
                  : (isPurchased ? AppTheme.successColor : AppTheme.tertiaryColor.withAlpha(140)),
              width: 1.0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: ShapeDecoration(
                          color: AppTheme.tertiaryColor.withAlpha(30),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(
                              color: AppTheme.tertiaryColor.withAlpha(120),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_sharp,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.name.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Oswald',
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money_sharp,
                                  color: AppTheme.primaryColor,
                                  size: 13,
                                ),
                                Text(
                                  '${offer.price}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Oswald',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  offset: isSelected ? const Offset(0.0, 0.0) : const Offset(1.2, 0.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isSelected ? 1.0 : 0.0,
                    child: isPurchased
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: ShapeDecoration(
                              color: AppTheme.successColor.withAlpha(40),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: AppTheme.successColor, width: 1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, color: AppTheme.successColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  locale.owned.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Oswald',
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canAfford ? AppTheme.primaryColor : Colors.grey.withAlpha(80),
                              foregroundColor: canAfford ? AppTheme.darkBackground : Colors.white38,
                              disabledBackgroundColor: Colors.grey.withAlpha(50),
                              disabledForegroundColor: Colors.white24,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: BeveledRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: canAfford
                                ? () => _showConfirmationDialog(context, offer, locale, userProfileVM)
                                : null,
                            icon: Icon(
                              Icons.shopping_cart_outlined,
                              size: 14,
                              color: canAfford ? AppTheme.darkBackground : Colors.white38,
                            ),
                            label: Text(
                              locale.buy.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: canAfford ? AppTheme.darkBackground : Colors.white38,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 10),
              Text(
                locale.items.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oswald',
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items.map((item) {
                      return ShopBundleItemChip(
                        avatarItem: item,
                        locale: locale,
                        mainColor: AppTheme.tertiaryColor,
                        mainTextColor: Colors.white,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemVisual(AvatarItem? item, String fallbackImage) {
    final imagePath = item?.image.isNotEmpty == true ? item!.image : fallbackImage;

    if (imagePath.isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(item),
        );
      } else {
        return Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(item),
        );
      }
    }
    return _buildFallbackIcon(item);
  }

  Widget _buildFallbackIcon(AvatarItem? item) {
    if (item != null) {
      final itemType = AvatarItemType.values.firstWhere(
        (t) => t.name.toLowerCase() == item.type.toLowerCase(),
        orElse: () => AvatarItemType.head,
      );
      final iconBuilder = avatarItemTypeIcons[itemType];
      if (iconBuilder != null) {
        return Center(child: iconBuilder(Colors.white70, 26));
      }
    }
    return const Center(child: Icon(Icons.checkroom, color: Colors.white38, size: 26));
  }

  Widget _buildEmptySectionState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: ShapeDecoration(
        color: Colors.white.withAlpha(8),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.storefront_outlined, size: 36, color: Colors.white.withAlpha(60)),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(120),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    ShopOffer offer,
    AppLocalizations locale,
    UserProfileViewModel userProfileVM,
  ) {
    final offerName = offer.avatarItem != null
        ? offer.avatarItem!.getNameLocale(locale)
        : offer.name;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withAlpha(180),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final heightFactor = Tween<double>(begin: 0.001, end: 1.0).animate(curvedAnimation);

        return AnimatedBuilder(
          animation: curvedAnimation,
          builder: (context, innerChild) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1.0, heightFactor.value, 1.0),
              child: FadeTransition(
                opacity: animation,
                child: innerChild,
              ),
            );
          },
          child: child,
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(18),
            decoration: ShapeDecoration(
              color: AppTheme.darkBackground.withAlpha(245),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locale.confirmPurchase.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 1.0,
                          fontFamily: 'Oswald',
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: ShapeDecoration(
                      color: AppTheme.primaryColor.withAlpha(20),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: AppTheme.primaryColor.withAlpha(100), width: 1),
                      ),
                    ),
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: BeveledRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _buildItemVisual(offer.avatarItem, offer.image),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    locale.confirmPurchaseMessage(offerName, offer.price),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.white38, width: 1),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          locale.cancel.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.darkBackground,
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogContext);
                          final shopRepo = context.read<ShopRepository>();
                          final success = await shopRepo.buyOffer(offer.id);

                          if (mounted) {
                            if (success) {
                              await userProfileVM.loadDownloadedItemModels();
                              userProfileVM.checkAndDownloadAvatarModels();

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(locale.successfullyPurchased(offerName)),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(shopRepo.errorMessage ?? locale.purchaseFailed),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          locale.buy.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.darkBackground,
                            fontFamily: 'Oswald',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ExpandableCategoryTabChip extends StatelessWidget {
  final dynamic icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;
  final BorderRadius borderRadius;

  const _ExpandableCategoryTabChip({
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            buildIconWidget(icon, color: iconColor, size: 16),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: isSelected && label != null && label!.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: Text(
                        label!,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Oswald',
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopBundleItemChip extends StatefulWidget {
  final AvatarItem avatarItem;
  final AppLocalizations locale;
  final Color mainColor;
  final Color mainTextColor;

  const ShopBundleItemChip({
    super.key,
    required this.avatarItem,
    required this.locale,
    required this.mainColor,
    required this.mainTextColor,
  });

  @override
  State<ShopBundleItemChip> createState() => _ShopBundleItemChipState();
}

class _ShopBundleItemChipState extends State<ShopBundleItemChip> {
  bool _isExpanded = false;

  Widget _buildAvatarImageOrIcon(AvatarItem item, Color color, double size) {
    final itemType = AvatarItemType.values.firstWhere(
      (t) => t.name.toLowerCase() == item.type.toLowerCase(),
      orElse: () => AvatarItemType.head,
    );
    final iconBuilder = avatarItemTypeIcons[itemType];
    final defaultIcon = iconBuilder != null
        ? iconBuilder(color, size)
        : Icon(Icons.checkroom, color: color, size: size);

    if (item.image.isNotEmpty) {
      if (item.image.startsWith('http://') || item.image.startsWith('https://')) {
        return Image.network(
          item.image,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => defaultIcon,
        );
      } else {
        return Image.asset(
          item.image,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => defaultIcon,
        );
      }
    }
    return defaultIcon;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.avatarItem;
    final itemType = AvatarItemType.values.firstWhere(
      (t) => t.name.toLowerCase() == item.type.toLowerCase(),
      orElse: () => AvatarItemType.head,
    );
    final iconBuilder = avatarItemTypeIcons[itemType];
    final iconWidget = iconBuilder != null
        ? iconBuilder(widget.mainTextColor, 14)
        : Icon(Icons.checkroom, color: widget.mainTextColor, size: 14);

    final label = item.getNameLocale(widget.locale).toUpperCase();

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubicEmphasized,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: ShapeDecoration(
          color: _isExpanded
              ? widget.mainColor.withAlpha(50)
              : widget.mainColor.withAlpha(25),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _isExpanded
                  ? Colors.white70
                  : widget.mainColor.withAlpha(140),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: widget.mainTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubicEmphasized,
              child: _isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: ShapeDecoration(
                          color: widget.mainColor.withAlpha(30),
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: widget.mainColor.withAlpha(120),
                              width: 1,
                            ),
                          ),
                        ),
                        child: _buildAvatarImageOrIcon(item, widget.mainTextColor, 56),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
