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

class _LoginViewBody extends StatefulWidget {
  final TextEditingController urlController;

  const _LoginViewBody({required this.urlController});

  @override
  State<_LoginViewBody> createState() => _LoginViewBodyState();
}

class _LoginViewBodyState extends State<_LoginViewBody> {
  bool _dialogOpen = false;
  final _usernameController = TextEditingController();
  final _appPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _appPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LoginController>();
    final busy = controller.isLoading || controller.isPolling;

    // Surface a pending cert prompt as a modal dialog — kept inside the
    // build via a post-frame callback so we only push it once per state
    // transition and never during a layout pass.
    final pending = controller.pendingCert;
    if (pending != null && !_dialogOpen) {
      _dialogOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showTrustCertDialog(context, controller);
        if (mounted) _dialogOpen = false;
      });
    }

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
                    controller: widget.urlController,
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
                  if (controller.appPasswordMode && !controller.isPolling) ...[
                    TextField(
                      controller: _usernameController,
                      enabled: !busy,
                      decoration: InputDecoration(
                        labelText: m.login.username,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _appPasswordController,
                      enabled: !busy,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: m.login.appPassword,
                        prefixIcon: const Icon(Icons.key_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.go,
                      onSubmitted: (_) => controller.startAppPasswordLogin(
                        _usernameController.text,
                        _appPasswordController.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.login.appPasswordHelp,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                  ] else if (controller.appPasswordMode)
                    FilledButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => controller.startAppPasswordLogin(
                              _usernameController.text,
                              _appPasswordController.text,
                            ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(m.login.signIn),
                    )
                  else
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
                  if (!controller.isPolling) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: controller.isLoading
                          ? null
                          : controller.toggleAppPasswordMode,
                      child: Text(
                        controller.appPasswordMode
                            ? m.login.useBrowserLogin
                            : m.login.useAppPassword,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showTrustCertDialog(
  BuildContext context,
  LoginController controller,
) async {
  final pending = controller.pendingCert;
  if (pending == null) return;
  final theme = Theme.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        color: theme.colorScheme.tertiary,
        size: 32,
      ),
      title: Text(m.login.untrustedCertTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.login.untrustedCertBody(pending.host)),
              const SizedBox(height: 16),
              _CertField(
                label: m.login.certFingerprint,
                value: pending.fingerprint,
                mono: true,
              ),
              _CertField(label: m.login.certSubject, value: pending.subject),
              _CertField(label: m.login.certIssuer, value: pending.issuer),
              _CertField(
                label: m.login.certValidity,
                value:
                    '${_fmtDate(pending.validFrom)} → ${_fmtDate(pending.validTo)}',
              ),
              const SizedBox(height: 12),
              Text(
                m.login.untrustedCertWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            controller.dismissPendingCert();
          },
          child: Text(m.common.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            controller.acceptPendingCert();
          },
          child: Text(m.login.trustCertificate),
        ),
      ],
    ),
  );
}

String _fmtDate(DateTime d) {
  final local = d.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

class _CertField extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _CertField({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            textDirection: TextDirection.ltr,
            style: mono
                ? const TextStyle(
                    fontFamily: 'monospace',
                    fontFamilyFallback: ['Menlo', 'Courier New', 'monospace'],
                    fontSize: 11,
                    height: 1.4,
                  )
                : theme.textTheme.bodySmall,
          ),
        ],
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
