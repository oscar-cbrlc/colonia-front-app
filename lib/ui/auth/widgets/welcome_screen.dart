import 'package:colonia_front_app/data/models/firebase_auth_result.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/utils/icon_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/ui/core/ui/app_loading_indicator.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;


class WelcomeScreen extends StatefulWidget {
  final WelcomeViewModel viewModel;

  const WelcomeScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isTermsAccepted = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (widget.viewModel.state == WelcomeState.success) {
      final result = widget.viewModel.authResult;
      if (result != null) {
        _handleSocialAuthNavigation(result);
      }
    } else if (widget.viewModel.state == WelcomeState.error) {
      final locale = AppLocalizations.of(context)!;
      final error = widget.viewModel.errorMessage.isEmpty 
          ? locale.errorUnexpected 
          : widget.viewModel.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      widget.viewModel.clearError();
    }
  }

  void _handleSocialAuthNavigation(FirebaseAuthResult result) {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.map);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final viewModel = widget.viewModel;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 240,
                        height: 240,
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/app_icon.svg',
                            width: 320,
                            height: 320,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text(
                        locale.coloniaTitle.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Oswald',
                          letterSpacing: 2.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(
                  color: Colors.white12,
                  height: 1,
                  thickness: 1,
                ),
              ),

              Expanded(
                flex: 5,
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    return Column(
                      children: [
                        const SizedBox(height: 16.0),
                        Text(
                          locale.startYourExcursion.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Oswald',
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32.0),

                        SizedBox(
                          width: double.infinity,
                          height: 54.0,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.darkBackground,
                              disabledBackgroundColor: AppTheme.primaryColor.withAlpha(80),
                              disabledForegroundColor: AppTheme.darkBackground.withAlpha(100),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              shape: const BeveledRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                            onPressed: (viewModel.isLoading || !_isTermsAccepted)
                                ? null
                                : () => viewModel.loginWithGoogle(),
                            child: viewModel.isLoading
                                ? const AppLoadingIndicator(
                                    size: 24.0,
                                    color: AppTheme.darkBackground,
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Opacity(
                                        opacity: _isTermsAccepted ? 1.0 : 0.5,
                                        child: buildIconWidget(iconoir.Google(color: Colors.black87, height: 32, width: 32,), size: 48.0, color: Colors.black87)
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        locale.continueWithGoogle.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                          //fontFamily: 'Oswald',
                                          color: _isTermsAccepted
                                              ? AppTheme.darkBackground
                                              : AppTheme.darkBackground.withAlpha(120),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        Visibility(
                          visible: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 54.0,
                              child: OutlinedButton(
                                onPressed: (viewModel.isLoading || !_isTermsAccepted)
                                    ? null
                                    : () => viewModel.loginWithApple(),
                                child: viewModel.isLoading
                                    ? const AppLoadingIndicator(size: 24.0)
                                    : SvgPicture.asset('assets/icons/apple.svg', width: 24, height: 24),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Theme(
                                data: ThemeData(
                                  unselectedWidgetColor: Colors.white54,
                                ),
                                child: Checkbox(
                                  value: _isTermsAccepted,
                                  activeColor: AppTheme.primaryColor,
                                  checkColor: AppTheme.darkBackground,
                                  side: const BorderSide(color: Colors.white54, width: 1),
                                  shape: const BeveledRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                  ),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isTermsAccepted = value ?? false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              Expanded(
                                child: RichText(
                                  textAlign: TextAlign.left,
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13.0,
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(text: locale.selectingThisBoxConfirms),
                                      TextSpan(
                                        text: locale.privacyNotice,
                                        style: const TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.secondaryColor,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            // TODO: Navigate to Privacy Policy
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
