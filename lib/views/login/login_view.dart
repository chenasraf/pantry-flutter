import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pantry/i18n.dart';
import 'package:provider/provider.dart';

import 'login_controller.dart';

class LoginView extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _urlController = TextEditingController();
  late final _controller = LoginController();

  @override
  void initState() {
    super.initState();
    _controller.setOnLoginSuccess(widget.onLoginSuccess);
    _urlController.addListener(() {
      _controller.setServerUrl(_urlController.text);
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: _LoginViewBody(urlController: _urlController),
    );
  }
}

class _LoginViewBody extends StatelessWidget {
  final TextEditingController urlController;

  const _LoginViewBody({required this.urlController});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SvgPicture.asset(
                    'assets/logo.svg',
                    width: 80,
                    height: 80,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    m.common.appTitle,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    m.login.connectToNextcloud,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextField(
                    controller: urlController,
                    enabled: !controller.isLoading && !controller.isPolling,
                    decoration: InputDecoration(
                      labelText: m.login.serverUrl,
                      hintText: m.login.serverUrlHint,
                      prefixIcon: const Icon(Icons.cloud_outlined),
                      border: const OutlineInputBorder(),
                      errorText: controller.error,
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => controller.startLogin(),
                  ),
                  const SizedBox(height: 24),
                  if (controller.isPolling) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      m.login.waitingForAuth,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: controller.cancelLogin,
                      child: Text(m.common.cancel),
                    ),
                  ] else
                    FilledButton(
                      onPressed: controller.isLoading
                          ? null
                          : controller.startLogin,
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(m.login.connect),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
