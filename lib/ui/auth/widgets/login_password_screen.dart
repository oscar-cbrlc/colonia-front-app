import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/auth/view_models/login_password_viewmodel.dart';

class LoginPasswordScreen extends StatefulWidget {
  const LoginPasswordScreen({super.key, required this.viewModel});
  final LoginPasswordViewModel viewModel;

  @override
  State<LoginPasswordScreen> createState() => _LoginPasswordScreen();
}

class _LoginPasswordScreen extends State<LoginPasswordScreen> {
  late final TextEditingController _passController;
  final FocusNode _passFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passController = TextEditingController(text: widget.viewModel.password);

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _passController.text.isEmpty) {
        _passFocusNode.requestFocus();
      }
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
    final viewModel = widget.viewModel;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
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

                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          locale.loginTitle,
                          style: AppTheme.theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                            viewModel.email,
                            style: TextTheme.of(context).bodyLarge
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passController,
                          focusNode: _passFocusNode,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: locale.passwordLabel,
                            hintText: locale.passwordHint,
                            errorText: _getValidationErrorText(viewModel.error, locale),
                          ),
                          onChanged: (value) {
                            viewModel.setPass(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading || viewModel.error != LoginValidationError.none || viewModel.password.isEmpty
                          ? null
                          : () => _handleLogin(viewModel),
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
                        locale.loginTitle,
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Future<void> _handleLogin(LoginPasswordViewModel model) async {
    final success = await model.login();
    if (!mounted) return;

    if (success) {
      _passFocusNode.unfocus();
      navigateToMapScreen(context);
    } else if (model.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(model.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  String? _getValidationErrorText(LoginValidationError error, AppLocalizations locale) {
    switch (error) {
      case LoginValidationError.empty:
        return locale.errorEmptyPassword;
      case LoginValidationError.none:
        return null;
    }
  }
}
