
import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/domain/models/achievement.dart';
import 'package:colonia_front_app/domain/models/avatar_item.dart';
import 'package:colonia_front_app/domain/models/user.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/team/widgets/team_shared_widgets.dart';
import 'package:colonia_front_app/ui/user_profile/widgets/three_js_avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/user_profile/view_models/user_profile_viewmodel.dart';
import 'package:colonia_front_app/ui/user_profile/widgets/item_selection_widget.dart';


class UserProfileScreen extends StatelessWidget {
  final UserProfileViewModel viewModel;

  const UserProfileScreen({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: Consumer<UserProfileViewModel>(
        builder: (context, vm, child) {
          final authRepo = Provider.of<AuthRepository>(context);
          final locale = AppLocalizations.of(context);

          return Scaffold(
            backgroundColor: AppTheme.darkBackground,
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0,
              ),
              child: Column(
                children: [
                  if (vm.user == AuthRepository.instance.currentUser)
                    _TopHeaderBarCurrentUser(
                      viewModel: vm,
                      onShopPressed: () {
                        // TODO: Navigate to Item Shop screen
                      },
                      onCoinsPressed: () {
                        // TODO: Navigate to Coin Shop screen / Buy Coins modal
                      },
                    ),
                  if (vm.user != AuthRepository.instance.currentUser)
                    //_TopHeaderBarOtherUser(
                      //viewModel: vm,
                      //onBackPressed: () => Navigator.pop(context)
                    //),

                    Align(
                      alignment: Alignment.topLeft,
                      child: SafeArea(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.primaryColor,
                            size: 32.0,
                          ),
                        ),

                      ),
                    ),

                  const SizedBox(height: 20),

                  _AvatarSection(
                    viewModel: vm,
                    onEditAccountPressed: () => _showEditAccountBottomSheet(context, vm),
                    onEditAvatarPressed: () => _showEditAvatarBottomSheet(context, vm),
                  ),
                  const SizedBox(height: 16),

                  _LevelXpSection(viewModel: vm),


                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: ShapeDecoration(
                      color: Colors.white.withAlpha(8),
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withAlpha(60),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: StatItem(
                                label: locale!.distance.toUpperCase(),
                                value: vm.formattedDistance,
                                icon: Icons.straighten,
                              ),
                            ),
                            Expanded(
                              child: StatItem(
                                label: locale.time.toUpperCase(),
                                value: vm.formattedTime,
                                icon: Icons.timer,
                              ),
                            ),
                            Expanded(
                              child: StatItem(
                                label: locale.captured.toUpperCase(),
                                value: vm.formattedTerritoriesCaptured,
                                icon: Icons.hexagon_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: StatItem(
                                label: locale.attack.toUpperCase(),
                                value: vm.formattedAttack,
                                icon: Icons.flash_on_sharp,
                              ),
                            ),
                            Expanded(
                              child: StatItem(
                                label: locale.defense.toUpperCase(),
                                value: vm.formattedDefense,
                                icon: Icons.shield_sharp,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  _AchievementsSection(viewModel: vm),

                  const SizedBox(height: 32),

                  if (vm.user == AuthRepository.instance.currentUser)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const BeveledRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        icon: const Icon(Icons.logout),
                        label: Text(
                          AppLocalizations.of(context)!.logout,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () async {
                          context.read<TeamRepository>().clear();
                          context.read<TerritoryRepository>().clearCache();
                          context.read<TrackingRepository>().clear();

                          await authRepo.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRouter.welcome,
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditAccountBottomSheet(BuildContext context, UserProfileViewModel vm) {
    final usernameController = TextEditingController(text: vm.user.username);
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final locale = AppLocalizations.of(context);
    String? errorMessage;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale!.editAccountInfo.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                /// TODO: set profile image
                const SizedBox(height: 24),
                _InputField(
                  controller: usernameController,
                  label: locale.usernameLabel.toUpperCase(),
                  hint: locale.usernameHint,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: newPasswordController,
                  label: locale.password.toUpperCase(),
                  hint: locale.passwordHint,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: confirmPasswordController,
                  label: locale.confirmPassword.toUpperCase(),
                  hint: locale.passwordHint,
                  obscureText: true,
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newUsername = usernameController.text.trim();
                            final newPassword = newPasswordController.text;
                            final confirmPassword = confirmPasswordController.text;

                            if (newUsername.isEmpty) {
                              setState(() => errorMessage = locale.usernameCannotBeEmpty);
                              return;
                            }

                            if (newPassword.isNotEmpty && newPassword != confirmPassword) {
                              setState(() => errorMessage = locale.passwordsDoNotMatch);
                              return;
                            }

                            setState(() {
                              isSaving = true;
                              errorMessage = null;
                            });

                            final success = await vm.updateAccountInfo(
                              newUsername: newUsername,
                              newPassword: newPassword.isNotEmpty ? newPassword : null,
                            );

                            if (context.mounted) {
                              final locale = AppLocalizations.of(context)!;
                              Navigator.pop(ctx);

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.profileUpdatedSuccessfully),
                                    backgroundColor: AppTheme.successColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(locale.networkErrorUpdateProfile),
                                    backgroundColor: AppTheme.errorColor,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.fontPrimaryColor,
                            ),
                          )
                        : Text(locale.saveChanges.toUpperCase(), style: TextStyle(color: AppTheme.fontPrimaryColor, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditAvatarBottomSheet(BuildContext context, UserProfileViewModel vm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditAvatarBottomSheet(viewModel: vm),
    );
  }
}

class _EditAvatarBottomSheet extends StatefulWidget {
  final UserProfileViewModel viewModel;
  const _EditAvatarBottomSheet({required this.viewModel});

  @override
  State<_EditAvatarBottomSheet> createState() => _EditAvatarBottomSheetState();
}

class _EditAvatarBottomSheetState extends State<_EditAvatarBottomSheet> {
  AvatarItemType _selectedCategory = AvatarItemType.footwear;

  int? _selectedHead;
  int? _selectedNeck;
  int? _selectedBody;
  int? _selectedFootwear;
  Color? _selectedColor;
  double? _hue;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final avatar = widget.viewModel.user.avatar;
    _selectedHead = avatar?.head;
    _selectedNeck = avatar?.neck;
    _selectedBody = avatar?.body;
    _selectedFootwear = avatar?.footwear;

    if (avatar?.color != null) {
      _selectedColor = Color(avatar!.color!);
      _hue = HSVColor.fromColor(_selectedColor!).hue;
    } else {
      _selectedColor = null;
      _hue = null;
    }

    widget.viewModel.loadDownloadedItemModels();
  }

  List<String> get _equippedGlbPaths {
    final paths = <String>[];
    final selectedIds = [_selectedHead, _selectedNeck, _selectedBody, _selectedFootwear];
    for (final id in selectedIds) {
      if (id != null) {
        final model = widget.viewModel.downloadedItemModels.where((m) => m.id == id).firstOrNull;
        if (model != null && model.filePath.isNotEmpty) {
          paths.add(model.filePath);
        }
      }
    }
    return paths;
  }

  int? get _selectedItemId {
    switch (_selectedCategory) {
      case AvatarItemType.head:
        return _selectedHead;
      case AvatarItemType.neck:
        return _selectedNeck;
      case AvatarItemType.body:
        return _selectedBody;
      case AvatarItemType.footwear:
        return _selectedFootwear;
    }
  }

  void _setItemSelection(int? itemId) {
    switch (_selectedCategory) {
      case AvatarItemType.head:
        _selectedHead = itemId;
        break;
      case AvatarItemType.neck:
        _selectedNeck = itemId;
        break;
      case AvatarItemType.body:
        _selectedBody = itemId;
        break;
      case AvatarItemType.footwear:
        _selectedFootwear = itemId;
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final vm = widget.viewModel;

    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final selectionItems = vm.availableAvatarItems
            .map((item) => ItemSelectionData.fromAvatarItem(
                  item,
                  isUnlocked: vm.isItemUnlocked(item.id),
                ))
            .toList();

        return Container(
          height: MediaQuery.of(context).size.height * 0.95,
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const ShapeDecoration(
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            color: AppTheme.darkBackground,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                      Text(
                        locale.customizeAvatar.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oswald',
                          fontSize: 20,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(40),
                            Colors.white.withAlpha(20),
                            Colors.white.withAlpha(10),
                            Colors.white.withAlpha(10),
                            Colors.white.withAlpha(20),
                            Colors.white.withAlpha(40),
                          ],
                          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                        ),
                        shape: BeveledRectangleBorder(
                          side: const BorderSide(color: AppTheme.tertiaryColor, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        child: ThreeJsAvatarView(
                          baseGlbPath: widget.viewModel.baseModelPath,
                          equippedGlbPaths: _equippedGlbPaths,
                          avatarColor: _selectedColor,
                        ),
                      )
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        locale.color.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFamily: 'Oswald',
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedColor ?? Colors.white24,
                          shape: BoxShape.rectangle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _selectedColor == null
                            ? const Icon(Icons.palette, size: 14, color: Colors.white70)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  HueSlider(
                    hue: _hue ?? 200.0,
                    onChanged: (val) => setState(() {
                      _hue = val;
                      _selectedColor = HSVColor.fromAHSV(1.0, val, 0.8, 0.9).toColor();
                    }),
                  ),

                  const SizedBox(height: 20),

                  ItemSelectionWidget(
                    items: selectionItems,
                    initialCategoryId: _selectedCategory.name,
                    selectedItemId: _selectedItemId,
                    itemsPerPage: 6,
                    onCategoryChanged: (catTab) {
                      final cat = AvatarItemType.values.firstWhere(
                        (t) => t.name == catTab.id,
                        orElse: () => AvatarItemType.head,
                      );
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    onLockedItemTap: (itemData) {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(locale.itemIsLocked),
                          backgroundColor: Colors.orangeAccent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onItemSelected: (itemData) {
                      final itemId = itemData.id as int;
                      final isSelected = _selectedItemId == itemId;
                      HapticFeedback.selectionClick();
                      setState(() {
                        _setItemSelection(isSelected ? null : itemId);
                        debugPrint('Item $itemId selected');
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.fontPrimaryColor,
                        disabledBackgroundColor: AppTheme.primaryColor.withAlpha(80),
                        disabledForegroundColor: Colors.white38,
                        shape: const BeveledRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              HapticFeedback.mediumImpact();

                              final selectedIds = [_selectedHead, _selectedNeck, _selectedBody, _selectedFootwear];
                              for (final id in selectedIds) {
                                if (id != null && !vm.isItemUnlocked(id)) {
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(locale.cannotSaveLockedItems),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                  return;
                                }
                              }

                              setState(() {
                                _isSaving = true;
                              });

                              final currentAvatar = vm.user.avatar ?? const UserAvatar();
                              final updatedAvatar = currentAvatar.copyWith(
                                head: _selectedHead,
                                neck: _selectedNeck,
                                body: _selectedBody,
                                footwear: _selectedFootwear,
                                color: _selectedColor?.toARGB32(),
                              );

                              final success = await vm.updateAvatar(updatedAvatar);

                              if (mounted) {
                                setState(() {
                                  _isSaving = false;
                                });

                                if (success) {
                                  await vm.saveMergedModelLocally(baseColor: _selectedColor);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(locale.avatarUpdatedSuccess),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(locale.avatarUpdateError),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.darkBackground,
                              ),
                            )
                          : Text(
                              locale.saveChanges.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Oswald',
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopHeaderBarCurrentUser extends StatelessWidget {
  final UserProfileViewModel viewModel;
  final VoidCallback onShopPressed;
  final VoidCallback onCoinsPressed;

  const _TopHeaderBarCurrentUser({
    required this.viewModel,
    required this.onShopPressed,
    required this.onCoinsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final coinAmount = viewModel.user.coinAmount ?? 0;
    final locale = AppLocalizations.of(context);

    return
      Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: onShopPressed,
              customBorder: const BeveledRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: ShapeDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: const BeveledRectangleBorder(
                    side: BorderSide(color: Colors.white24, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_bag, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 6),
                    Text(
                      locale!.shop,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              )
          ),
          InkWell(
            onTap: onCoinsPressed,
            customBorder: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: ShapeDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                shape: const BeveledRectangleBorder(
                  side: BorderSide(color: AppTheme.secondaryColor, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_money_sharp, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '$coinAmount',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.add, color: AppTheme.primaryColor, size: 18),
                ],
              ),
            ),
          ),
          ]
      )
    );
  }
}

class _AvatarSection extends StatefulWidget {
  final UserProfileViewModel viewModel;
  final VoidCallback onEditAccountPressed;
  final VoidCallback onEditAvatarPressed;

  const _AvatarSection({
    required this.viewModel,
    required this.onEditAccountPressed,
    required this.onEditAvatarPressed,
  });

  @override
  State<_AvatarSection> createState() => _AvatarSectionState();
}

class _AvatarSectionState extends State<_AvatarSection> {
  Color? get _avatarColor {
    final colorInt = widget.viewModel.user.avatar?.color;
    return colorInt != null ? Color(colorInt) : null;
  }

  List<String> get _equippedGlbPaths {
    final paths = <String>[];
    final avatar = widget.viewModel.user.avatar;
    if (avatar != null) {
      final selectedIds = [avatar.head, avatar.neck, avatar.body, avatar.footwear];
      for (final id in selectedIds) {
        if (id != null) {
          final model = widget.viewModel.downloadedItemModels.where((m) => m.id == id).firstOrNull;
          if (model != null && model.filePath.isNotEmpty) {
            paths.add(model.filePath);
          }
        }
      }
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.viewModel.user;
    final modelPath = widget.viewModel.baseModelPath;
    final baseAvatarContainerColor = Colors.white;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    baseAvatarContainerColor.withAlpha(40),
                    baseAvatarContainerColor.withAlpha(20),
                    baseAvatarContainerColor.withAlpha(10),
                    baseAvatarContainerColor.withAlpha(10),
                    baseAvatarContainerColor.withAlpha(20),
                    baseAvatarContainerColor.withAlpha(40),
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                ),
                shape: BeveledRectangleBorder(
                  side: BorderSide(color: Colors.white.withAlpha(100), width: 1),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ThreeJsAvatarView(
                  baseGlbPath: modelPath,
                  equippedGlbPaths: _equippedGlbPaths,
                  avatarColor: _avatarColor,
                ),
              ),
            ),
            if (widget.viewModel.user == AuthRepository.instance.currentUser)
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.onEditAvatarPressed,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const ShapeDecoration(
                      color: AppTheme.primaryColor,
                      shape: BeveledRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    child: const Icon(Icons.checkroom, size: 18, color: AppTheme.darkBackground),
                  ),
                ),
              ),
          ],
        ),
        if (widget.viewModel.isDownloadingModels) ...[
          const SizedBox(height: 8),
          Container(
            width: 220,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: ShapeDecoration(
              color: AppTheme.darkBackground,
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: AppTheme.primaryColor.withAlpha(150),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ((AppLocalizations.of(context) as dynamic).downloadingModel as String?) ?? 'Descargando modelos 3D...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(widget.viewModel.downloadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.viewModel.downloadProgress,
                    backgroundColor: Colors.white12,
                    color: AppTheme.primaryColor,
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (widget.viewModel.user == AuthRepository.instance.currentUser)...[
              const SizedBox(width: 6),
              InkWell(
                onTap: widget.onEditAccountPressed,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, color: AppTheme.primaryColor.withValues(alpha: 0.9), size: 18),
                ),
              ),
            ]
          ],
        ),

        const SizedBox(height: 12),

        if (user.team != null) ...[
          Text(
            user.team!.role.toUpperCase(),
            style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: ShapeDecoration(
              color: Color(user.team!.color).withValues(alpha: 0.1),
              shape: BeveledRectangleBorder(
                side: BorderSide(color: Color(user.team!.color), width: 1),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
            ),
            child: Text(
              user.team!.name,
              style: TextStyle(color: Colors.white.withAlpha(190), fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }
}

class _LevelXpSection extends StatelessWidget {
  final UserProfileViewModel viewModel;
  const _LevelXpSection({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final isCurrentUser = viewModel.user == AuthRepository.instance.currentUser;
    final level = viewModel.level;
    final xp = viewModel.xp;
    final xpForNextLevel = viewModel.xpForNextLevel;

    final double progressRatio = xpForNextLevel > 0
        ? (xp * 1.0 / (xp + xpForNextLevel))
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: ShapeDecoration(
        color: AppTheme.tertiaryColor.withAlpha(15),
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.tertiaryColor.withAlpha(160),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: AppTheme.tertiaryColor.withAlpha(40),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.tertiaryColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 6),
                    Text(
                      '${locale.levelLabel.toUpperCase()} $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: ShapeDecoration(
                  color: AppTheme.secondaryColor.withAlpha(40),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.secondaryColor, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Oswald',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isCurrentUser) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale.xpForNextLevelLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '$xpForNextLevel XP',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;
  final bool obscureText;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withAlpha(10),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final UserProfileViewModel viewModel;
  const _AchievementsSection({required this.viewModel});

  void _showAchievementDetailBottomSheet(BuildContext context, Achievement achievement) {
    final locale = AppLocalizations.of(context)!;
    final isUnlocked = achievement.acquisitionDate != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: ShapeDecoration(
                      color: isUnlocked
                          ? AppTheme.successColor.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.08),
                      shape: BeveledRectangleBorder(
                        side: BorderSide(
                          color: isUnlocked ? AppTheme.successColor : Colors.white30,
                          width: 1,
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnlocked ? Icons.check_circle : Icons.lock,
                          size: 14,
                          color: isUnlocked ? AppTheme.successColor : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isUnlocked ? locale.unlocked.toUpperCase() : locale.locked.toUpperCase(),
                          style: TextStyle(
                            color: isUnlocked ? AppTheme.successColor : Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: ShapeDecoration(
                  color: isUnlocked
                      ? AppTheme.tertiaryColor.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.03),
                  shape: BeveledRectangleBorder(
                    side: BorderSide(
                      color: isUnlocked ? AppTheme.tertiaryColor : Colors.white12,
                      width: 1.5,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                ),
                child: Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  size: 64,
                  color: isUnlocked ? AppTheme.primaryColor : Colors.white30,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                achievement.getTitle(locale),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                achievement.getDescription(locale),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              if (isUnlocked && achievement.formattedAcquisitionDate != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: ShapeDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: const BeveledRectangleBorder(
                      side: BorderSide(color: Colors.white12, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${locale.unlocked}: ${achievement.formattedAcquisitionDate}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final achievements = viewModel.achievements;
    final unlockedAchievements = viewModel.unlockedAchievements;
    final lockedAchievements = achievements.where((a) => a.acquisitionDate == null).toList();
    final locale = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              locale!.achievements.toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (viewModel.user == AuthRepository.instance.currentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: ShapeDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  shape: const BeveledRectangleBorder(
                    side: BorderSide(color: AppTheme.secondaryColor, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                ),
                child: Text(
                  '${viewModel.unlockedCount}/${viewModel.totalAchievements}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (achievements.isEmpty)
          Text(locale.noAchievementsYet, style: TextStyle(color: Colors.white54))
        else ...[
          Text(
            '${locale.unlocked.toUpperCase()} (${unlockedAchievements.length})',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          if (unlockedAchievements.isEmpty)
            Text(locale.noUnlockedAchievementsYet, style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            _AchievementGrid(
              achievements: unlockedAchievements,
              onTap: (ach) => _showAchievementDetailBottomSheet(context, ach),
            ),


          if (viewModel.user == AuthRepository.instance.currentUser) ... [
            const SizedBox(height: 24),
            Text(
              '${locale.locked.toUpperCase()} (${lockedAchievements.length})',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            if (lockedAchievements.isEmpty)
              Text(locale.allAchievementsCompleted, style: TextStyle(color: Colors.white38, fontSize: 13))
            else
              _AchievementGrid(
                achievements: lockedAchievements,
                onTap: (ach) => _showAchievementDetailBottomSheet(context, ach),
              ),

          ]
        ],
      ],
    );
  }
}



class _AchievementGrid extends StatelessWidget {
  final List<Achievement> achievements;
  final Function(Achievement) onTap;

  const _AchievementGrid({
    required this.achievements,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = achievement.acquisitionDate != null;

        return InkWell(
          onTap: () => onTap(achievement),
          customBorder: const BeveledRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color: isUnlocked
                  ? AppTheme.tertiaryColor.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.03),
              shape: BeveledRectangleBorder(
                side: BorderSide(
                  color: isUnlocked ? AppTheme.tertiaryColor : Colors.white12,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  color: isUnlocked ? AppTheme.primaryColor : Colors.white30,
                  size: 48,
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.getTitle(locale!),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}




class HueSlider extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const HueSlider({super.key, required this.hue, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double thumbRadius = 12.0;
        final double thumbLeft = ((hue / 360.0) * width - thumbRadius).clamp(0.0, width - thumbRadius * 2);

        return GestureDetector(
          onPanUpdate: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          onTapDown: (details) {
            double newHue = (details.localPosition.dx / width) * 360.0;
            onChanged(newHue.clamp(0.0, 360.0));
          },
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 32,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: ShapeDecoration(
                    shape: BeveledRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  child: Container(
                    width: thumbRadius * 2,
                    height: thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black12, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
