import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/auth/view_models/welcome_viewmodel.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:colonia_front_app/ui/auth/widgets/email_screen.dart';
import 'package:colonia_front_app/ui/auth/view_models/email_viewmodel.dart';
import 'package:provider/provider.dart';


class WelcomeScreen extends StatelessWidget {
  final WelcomeViewModel viewModel;

  const WelcomeScreen({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
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
                          Icons.image_outlined, // TODO(Welcome): PUT APP LOGO
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
                  borderRadius: BorderRadius.vertical(
                    //top: Radius.circular(4.0),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                    
                    const SizedBox(height: 8.0),

                    // Title
                    Text(
                      locale.loginOrSignUp,
                      style: TextTheme.of(context).titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),

                    // Subtitle
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        locale.selectYourAuthPref,
                        style: TextTheme.of(context).bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),

                    // Email Button
                    ListenableBuilder(
                      listenable: viewModel,
                      builder: (context, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56.0,
                          child: ElevatedButton(
                            onPressed: () {

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChangeNotifierProvider<EmailViewModel>(
                                    create: (_) => EmailViewModel(),
                                    child: const EmailScreen(),
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              locale.continueWithEmail,
                            ),
                          )
                        );
                      },
                    ),
                    const SizedBox(height: 12.0),

                    // google and apple buttons
                    Row(
                      children: [
                        // Google
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => viewModel.loginWithGoogle(),
                            child: SvgPicture.asset(
                              'assets/icons/google.svg',
                              width: 24,
                              height: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Apple
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => viewModel.loginWithApple(),
                            child: SvgPicture.asset(
                              'assets/icons/apple.svg',
                              width: 24,
                              height: 24,
                            ),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}