import 'package:flutter/material.dart';

import 'package:pantry/i18n.dart';
import 'package:pantry/services/prefs_service.dart';
import 'onboarding_pages.dart';
import 'pages/welcome_page.dart';

/// Full-screen onboarding stepper. Reads the user's last-seen onboarding
/// version from [PrefsService], builds the page list, and on Skip/Done writes
/// [appVersion] back as the new last-seen so the same flow won't replay.
class OnboardingView extends StatefulWidget {
  /// Current app version, written back to prefs when the user finishes or
  /// skips the flow.
  final String appVersion;
  final VoidCallback onDone;

  const OnboardingView({
    super.key,
    required this.appVersion,
    required this.onDone,
  });

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _pageCtrl = PageController();
  late final bool _isNewUser;
  late final List<WidgetBuilder> _pages;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    final lastSeen = PrefsService.instance.lastSeenOnboardingVersion;
    _isNewUser = lastSeen == null;
    _pages = [
      (_) => WelcomeOnboardingPage(isNewUser: _isNewUser),
      ...resolveOnboardingPages(lastSeen),
    ];
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _pages.length - 1;

  Future<void> _finish() async {
    await PrefsService.instance.setLastSeenOnboardingVersion(
      onboardingMarkSeenVersion(widget.appVersion),
    );
    if (mounted) widget.onDone();
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _pageCtrl.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ob = m.onboarding;
    final total = _pages.length;

    return PopScope(
      // Intercept back instead of letting it pop the route (which on Android
      // would close the app from the onboarding cold-start). Treat back the
      // same as Skip — save the version, advance to the next screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _finish();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kOnboardingChromeMaxWidth,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ob.stepLabel(_index + 1, total),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(onPressed: _finish, child: Text(ob.skip)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StepProgress(current: _index + 1, total: total),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemCount: _pages.length,
                      itemBuilder: (ctx, i) =>
                          _CenteredPage(child: _pages[i](ctx)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        if (_index > 0)
                          TextButton(
                            onPressed: () => _pageCtrl.previousPage(
                              duration: const Duration(milliseconds: 240),
                              curve: Curves.easeOutCubic,
                            ),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 52),
                            ),
                            child: Text(ob.back),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(140, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(_isLast ? ob.done : ob.next),
                        ),
                      ],
                    ),
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

/// Caps the stepper chrome (header row, progress bar, footer buttons) so it
/// doesn't stretch edge-to-edge on tablet / desktop windows.
const double kOnboardingChromeMaxWidth = 640;

/// Caps a single onboarding page's content narrower than the chrome — keeps
/// body copy at a comfortable reading width on large screens.
const double kOnboardingPageMaxWidth = 460;

/// Vertically-centers a page's content inside the PageView slot, while still
/// allowing it to scroll if the content is taller than the viewport. Pages
/// themselves return their content without an outer scroll view.
class _CenteredPage extends StatelessWidget {
  final Widget child;

  const _CenteredPage({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: kOnboardingPageMaxWidth,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin segmented progress bar — one rounded segment per step, filled left to
/// right as the user advances.
class _StepProgress extends StatelessWidget {
  final int current;
  final int total;

  const _StepProgress({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 4,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                decoration: BoxDecoration(
                  color: i < current ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
