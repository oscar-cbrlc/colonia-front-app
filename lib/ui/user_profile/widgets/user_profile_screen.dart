import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/data/repositories/team_repository.dart';
import 'package:colonia_front_app/data/repositories/territory_repository.dart';
import 'package:colonia_front_app/data/repositories/tracking_repository.dart';
import 'package:colonia_front_app/domain/models/achievement.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/team/widgets/team_shared_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/user_profile/view_models/user_profile_viewmodel.dart';

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
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      StatItem(
                        label: locale!.distance.toUpperCase(),
                        value: vm.formattedDistance,
                        icon: Icons.directions_run,
                      ),
                      StatItem(
                        label: locale.time.toUpperCase(),
                        value: vm.formattedTime,
                        icon: Icons.timer,
                      ),
                    ],
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
    final locale = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  locale!.customizeAvatar.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oswald',
                    fontSize: 20,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Icon(Icons.checkroom, size: 60, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),

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
                onPressed: () {
                  // TODO: Implement avatar customization
                  Navigator.pop(ctx);
                },
                child: Text(locale.saveChanges.toUpperCase(), style: TextStyle(color: AppTheme.fontPrimaryColor, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
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

class _TopHeaderBarOtherUser extends StatelessWidget {
  final UserProfileViewModel viewModel;
  final VoidCallback onBackPressed;

  const _TopHeaderBarOtherUser({
    required this.viewModel,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onBackPressed,
          customBorder: const BeveledRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: ShapeDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: const BeveledRectangleBorder(
                side: BorderSide(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 6),
              ]
            )
          )
        )
      ]
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final UserProfileViewModel viewModel;
  final VoidCallback onEditAccountPressed;
  final VoidCallback onEditAvatarPressed;

  const _AvatarSection({
    required this.viewModel,
    required this.onEditAccountPressed,
    required this.onEditAvatarPressed,
  });

  @override
  Widget build(BuildContext context) {
    final user = viewModel.user;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: ShapeDecoration(
                color: Colors.black26,
                shape: BeveledRectangleBorder(
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  borderRadius: BorderRadius.circular(65),
                ),
              ),
              child: user.avatar?.thumbnailUrl != null
                  ? ClipPath(
                      clipper: _BeveledCircleClipper(),
                      child: Image.network(user.avatar!.thumbnailUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, size: 70, color: Colors.white54),
            ),
            if (viewModel.user == AuthRepository.instance.currentUser)
              GestureDetector(
                onTap: onEditAvatarPressed,
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
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user.username,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            if (viewModel.user == AuthRepository.instance.currentUser)...[
              const SizedBox(width: 6),
              InkWell(
                onTap: onEditAccountPressed,
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

class _BeveledCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final border = BeveledRectangleBorder(borderRadius: BorderRadius.circular(size.width / 2));
    return border.getOuterPath(Offset.zero & size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
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
                    fontWeight: FontWeight.normal,
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
