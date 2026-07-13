import 'package:colonia_front_app/data/models/firebase_auth_result.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';


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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.errorMessage),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      widget.viewModel.clearError();
    }
  }

  void _handleSocialAuthNavigation(FirebaseAuthResult result) {
    if (result.isNewUser) {
      Navigator.of(context).pushNamed(
        AppRouter.createUsername,
        arguments: {
          'email': result.email,
          'password': '',
          'isSocialAuth': true,
        },
      );
    } else {

      // TODO: LOGIN
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final viewModel = widget.viewModel;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // top: logo
            Expanded(
              flex: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2523),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(
                          color: const Color(0xFF3B3331),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Color(0xFF8B807D),
                          size: 72.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // bottom section
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.lightBackground,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ListenableBuilder(
                  listenable: viewModel,
                  builder: (context, _) {
                    return Column(
                      children: [
                        const SizedBox(height: 8.0),
                        Text(
                          locale.loginOrSignUp,
                          style: TextTheme.of(context).titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            locale.selectYourAuthPref,
                            style: TextTheme.of(context).bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Spacer(),

                        // Email Button
                        SizedBox(
                          width: double.infinity,
                          height: 56.0,
                          child: ElevatedButton(
                            onPressed: viewModel.isLoading 
                              ? null 
                              : () => navigateToEmailScreen(context),
                            child: Text(locale.continueWithEmail),
                          )
                        ),
                        const SizedBox(height: 12.0),

                        // google and apple buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: viewModel.isLoading 
                                  ? null 
                                  : () => viewModel.loginWithGoogle(),
                                child: viewModel.isLoading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : SvgPicture.asset('assets/icons/google.svg', width: 24, height: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: viewModel.isLoading 
                                  ? null 
                                  : () => viewModel.loginWithApple(),
                                child: viewModel.isLoading 
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                  : SvgPicture.asset('assets/icons/apple.svg', width: 24, height: 24),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // bottom bottom
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextTheme.of(context).bodySmall,
                              children: [
                                TextSpan(text: locale.ifCreatingNewAccount),
                                TextSpan(
                                  text: locale.termsAndConditions,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.fontUnderlineColor
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // TODO: Navigate to Terms
                                    },
                                ),
                                TextSpan(text: ' ${locale.and} '),
                                TextSpan(
                                  text: locale.privacyPolicy,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.fontUnderlineColor
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      // TODO: Navigate to Privacy Policy
                                    },
                                ),
                                TextSpan(text: ' ${locale.willApply}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    );
                  }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
