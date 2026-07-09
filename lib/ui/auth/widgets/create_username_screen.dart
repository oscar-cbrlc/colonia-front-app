import 'package:colonia_front_app/ui/auth/view_models/create_username_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';

class CreateUsernameScreen extends StatefulWidget {
  const CreateUsernameScreen({super.key, required this.email, required this.pass});
  final String email;
  final String pass;

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreen();
}

class _CreateUsernameScreen extends State<CreateUsernameScreen> {
  late final TextEditingController _usernameController;
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameFocusNode.requestFocus();
      context.read<CreateUsernameViewModel>().setEmail(widget.email);
      context.read<CreateUsernameViewModel>().setPass(widget.pass);
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

                    Consumer<CreateUsernameViewModel>(
                      builder: (context, viewModel, _) {
                        return TextFormField(
                          controller: _usernameController,
                          focusNode: _usernameFocusNode,
                          onChanged: (value) => viewModel.setUsername(value),
                          decoration: InputDecoration(
                            labelText: locale.usernameLabel,
                            hintText: locale.usernameHint,
                            errorText: viewModel.error == UsernameValidationError.none || viewModel.error == UsernameValidationError.empty ? null : locale.notValidInput,
                          ),
                        );
                      },
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

                    Consumer<CreateUsernameViewModel>(
                      builder: (context, viewModel, _) {
                        return Column(
                          children: [
                            _buildRequirement(locale.beBetween4and16Chars, viewModel.hasLengthCharacters),
                            _buildRequirement(locale.onlyContainUsernameChars, viewModel.hasOnlyValidChars)
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
              child: Consumer<CreateUsernameViewModel>(
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

  Future<void> _handleContinue(CreateUsernameViewModel viewModel) async {
    //final success = await viewModel.registerUser();
    //if (success && mounted) {
    //_usernameFocusNode.unfocus();

    // TODO(auth) register user, home screen
    //}
  }
}
