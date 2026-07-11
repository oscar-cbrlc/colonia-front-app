import 'package:colonia_front_app/data/repositories/auth_repository.dart';
import 'package:colonia_front_app/ui/auth/view_models/login_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/view_models/create_password_viewmodel.dart';
import 'package:colonia_front_app/ui/auth/widgets/login_password_screen.dart';
import 'package:colonia_front_app/ui/auth/widgets/create_password_screen.dart';
import 'package:colonia_front_app/ui/core/navigation/app_router.dart';
import 'package:colonia_front_app/ui/core/navigation/navigation_callbacks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:colonia_front_app/ui/core/themes/app_theme.dart';
import 'package:colonia_front_app/l10n/app_localizations.dart';
import 'package:colonia_front_app/ui/auth/view_models/email_viewmodel.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key, required this.viewModel});
  final EmailViewModel viewModel;

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  late final TextEditingController _emailController;
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.viewModel.email);

    // auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _emailController.text.isEmpty) {
        _emailFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
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
                    onTap: () {
                      viewModel.resetState();
                      Navigator.of(context).pop();
                    },
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
                              '@',
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

                        Text(
                          locale.continueWithEmail,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),

                        const SizedBox(height: 8.0),

                        Text(
                          locale.enterYourEmail,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        const SizedBox(height: 32.0),

                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          onChanged: (value) => viewModel.setEmail(value),
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\s'))
                          ],
                          decoration: InputDecoration(
                            hintText: locale.emailAddress,
                            errorText: viewModel.error == EmailValidationError.none
                                ? null
                                : locale.notValidInput,
                            labelText: locale.emailAddress,
                          ),
                        ),
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
                      onPressed: viewModel.isLoading || viewModel.error != EmailValidationError.none || viewModel.email.isEmpty
                          ? null
                          : () {
                        _emailFocusNode.unfocus();
                        _findUser(viewModel);
                      },
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

  Future<void> _findUser(EmailViewModel viewModel) async {
    await viewModel.findUser();

    if (!mounted) return;

    if (viewModel.userFoundState == UserFoundState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${viewModel.errorMessage ?? "Unknown error"}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } else {
      handleEmailNavigation(
          context: context,
          email: viewModel.email,
          emailExists: viewModel.userFoundState == UserFoundState.found
      );
    }
  }
}