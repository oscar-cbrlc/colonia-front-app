import 'package:colonia_front_app/ui/auth/view_models/create_password_viewmodel.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:colonia_front_app/ui/core/ui/validation_row.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, required this.viewModel});
  final CreatePasswordViewModel viewModel;

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreen();
}

class _CreatePasswordScreen extends State<CreatePasswordScreen> {
  late final TextEditingController _passController;
  final FocusNode _passFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _passController = TextEditingController();

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passFocusNode.requestFocus();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8B807D)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: AppTheme.lightBackground,
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                        // TITLE & SUBTITLE
                        Text(
                          locale.createPass,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 16.0),

                        TextFormField(
                          controller: _passController,
                          focusNode: _passFocusNode,
                          onChanged: (value) => widget.viewModel.setPass(value),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: locale.passwordLabel,
                            hintText: locale.password,
                            errorText: widget.viewModel.error == PassValidationError.none ||
                                widget.viewModel.error == PassValidationError.empty
                                ? null
                                : locale.notValidInput,
                          ),
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

                        Column(
                          children: [
                            ValidationRow(
                                text: locale.atLeast8Characters,
                                isValid: widget.viewModel.has8Characters
                            ),
                            ValidationRow(
                                text: locale.oneUppercaseLetter,
                                isValid: widget.viewModel.hasUppercase
                            ),
                            ValidationRow(
                                text: locale.oneLowercaseLetter,
                                isValid: widget.viewModel.hasLowercase
                            ),
                            ValidationRow(
                                text: locale.oneNumber,
                                isValid: widget.viewModel.hasDigit
                            ),
                            ValidationRow(
                                text: locale.oneSpecialCharacter,
                                isValid: widget.viewModel.hasSpecial
                            ),
                          ],
                        ),

                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                ),

                // continue button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: ElevatedButton(
                      onPressed: widget.viewModel.isLoading
                          ? null
                          : () => navigateToCreateUsernameScreen(
                            context: context,
                            email: widget.viewModel.email,
                            password: widget.viewModel.pass
                          ),
                      child: widget.viewModel.isLoading
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
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
