import 'package:colonia_front_app/ui/auth/view_models/newpassword_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.email});
  final String email;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreen();
}

class _NewPasswordScreen extends State<NewPasswordScreen> {
  late final TextEditingController _passController;
  final FocusNode _passFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passController = TextEditingController();

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passFocusNode.requestFocus();
      context.read<NewPasswordViewModel>().setEmail(widget.email);
    });
  }

  @override
  void dispose() {
    _passController.dispose();
    _passFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back,
                      color: AppTheme.primaryColor,
                      size: 32.0,
                    ),
                  ],
                ),
              ),
            ),

            // main content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),


                    const SizedBox(height: 24.0),

                    // 4. TITLE & SUBTITLE
                    Text(
                        locale.createPass,
                        style: Theme.of(context).textTheme.titleMedium
                    ),

                    const SizedBox(height: 16.0),


                    Consumer<NewPasswordViewModel>(
                      builder: (context, viewModel, _) {
                        return TextFormField(
                          controller: _passController,
                          focusNode: _passFocusNode,
                          onChanged: (value) => viewModel.validatePass(value),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: locale.passwordLabel,
                            hintText: locale.password,
                            errorText: viewModel.error == PassValidationError.none || viewModel.error == PassValidationError.empty ? null : locale.notValidInput,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24.0),

                    Text(
                      locale.yourPasswordMustInclude,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.fontPrimaryColor,
                      ),
                    ),

                    const SizedBox(height: 12.0),

                    Consumer<NewPasswordViewModel>(
                      builder: (context, viewModel, _) {
                        return Column(
                          children: [
                            _buildRequirement(locale.atLeast8Characters, viewModel.has8Characters),
                            _buildRequirement(locale.oneUppercaseLetter, viewModel.hasUppercase),
                            _buildRequirement(locale.oneLowercaseLetter, viewModel.hasLowercase),
                            _buildRequirement(locale.oneNumber, viewModel.hasDigit),
                            _buildRequirement(locale.oneSpecialCharacter, viewModel.hasSpecial),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 8.0),


                  ],
                ),
              ),
            ),

            // continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<NewPasswordViewModel>(
                builder: (context, viewModel, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () => _handleContinue(viewModel),
                      child: viewModel.isLoading
                          ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        locale.continueM,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.arrow_forward,
            size: 16.0,
            color: isSatisfied ? AppTheme.secondaryColor : AppTheme.fontVeryLightColor,
          ),
          const SizedBox(width: 12.0),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.0,
              color: isSatisfied ? AppTheme.secondaryColor : AppTheme.fontVeryLightColor,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue(NewPasswordViewModel viewModel) async {
    //final success = await viewModel.registerUser();
    //if (success && mounted) {
      //_passFocusNode.unfocus();

      // TODO(auth) register user, home screen
    //}
  }
}
