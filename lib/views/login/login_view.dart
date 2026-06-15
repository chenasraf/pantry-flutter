import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  if (controller.errorDetails != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        icon: const Icon(Icons.bug_report_outlined, size: 18),
                        label: Text(m.login.seeDetails),
                        onPressed: () => _showErrorDetails(
                          context,
                          controller.errorDetails!,
                        ),
                      ),
                    ),
                  ],
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

Future<void> _showErrorDetails(BuildContext context, String details) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(m.login.errorDetailsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              details,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: Text(m.common.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: details));
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(m.common.copied),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(m.common.closeDialog),
        ),
      ],
    ),
  );
}
