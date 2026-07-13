import 'package:colonia_front_app/ui/auth/view_models/create_username_viewmodel.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:colonia_front_app/ui/core/ui/validation_row.dart';
import 'package:flutter/material.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';

class CreateUsernameScreen extends StatefulWidget {
  const CreateUsernameScreen({super.key, required this.viewModel});
  final CreateUsernameViewModel viewModel;

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreen();
}

class _CreateUsernameScreen extends State<CreateUsernameScreen> {
  late final TextEditingController _usernameController;
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.viewModel.username);

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _usernameController.text.isEmpty) {
        _usernameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
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

                // main content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16.0),

                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: AppTheme.lightBtBorderColor,
                            border: Border.all(
                              width: 1.9,
                              color: AppTheme.fontPrimaryColor,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '*-*',
                              style: TextStyle(
                                fontSize: 28.0,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.fontPrimaryColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24.0),

                        // 4. TITLE & SUBTITLE
                        Text(
                            locale.createUsername,
                            style: TextTheme.of(context).titleMedium
                        ),

                        const SizedBox(height: 8.0),

                        Text(
                            locale.createANameToIdentifyYou,
                            style: TextTheme.of(context).bodyMedium
                        ),

                        const SizedBox(height: 32.0),

                        TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          onChanged: (value) => viewModel.setUsername(value),
                          decoration: InputDecoration(
                            labelText: locale.usernameLabel,
                            hintText: locale.usernameHint,
                            errorText: viewModel.error == UsernameValidationError.none || viewModel.error == UsernameValidationError.empty
                                ? null
                                : locale.notValidInput,
                          ),
                        ),

                        const SizedBox(height: 24.0),

                        Text(
                          locale.usernameGuide,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.fontPrimaryColor,
                          ),
                        ),

                        const SizedBox(height: 12.0),

                        Column(
                          children: [
                            ValidationRow(text: locale.beBetween4and16Chars, isValid: viewModel.hasLengthCharacters),
                            ValidationRow(text: locale.onlyContainUsernameChars, isValid: viewModel.hasOnlyValidChars)
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
                      onPressed: viewModel.isLoading || viewModel.error != UsernameValidationError.none || viewModel.username.isEmpty
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
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleContinue(CreateUsernameViewModel viewModel) async {
    final success = await viewModel.submitRegistrationAndLogin();
    if (!mounted) return;

    if (success) {
      _usernameFocusNode.unfocus();
      navigateToMapScreen(context);
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage!),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
