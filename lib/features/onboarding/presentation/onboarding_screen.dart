import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';
import 'package:habit_tracker/features/settings/presentation/controllers/settings_controller.dart';

/// Three first-run slides from the SUK-4 mockups (01, 01b, 01c).
///
/// The flag is persisted in settings. Existing installations are migrated with
/// the flag already set, so only genuinely new users see this flow.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;
  bool _isFinishing = false;

  static const List<_SlideData> _slides = <_SlideData>[
    _SlideData(
      title: 'Маленькие шаги.\nБольшие перемены.',
      body:
          'Отмечайте привычки в один тап, следите за серией и возвращайтесь, '
          'когда собьётесь.',
      hint: 'Настройка займёт меньше минуты',
      action: 'Далее',
    ),
    _SlideData(
      title: 'Работает\nбез интернета',
      body:
          'Привычки хранятся только на вашем телефоне. Без аккаунта, рекламы '
          'и подписок.',
      hint: 'Ничего не нужно настраивать',
      action: 'Далее',
    ),
    _SlideData(
      title: 'Напоминания вовремя',
      body:
          'Одно мягкое уведомление в выбранное время — без давления и лишних '
          'сообщений.',
      hint: 'Первую привычку добавим вместе',
      action: 'Начать',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_isFinishing) {
      return;
    }
    setState(() => _isFinishing = true);
    final controller = context.read<SettingsController>();
    final messenger = ScaffoldMessenger.of(context);
    await controller.completeOnboarding();
    if (!mounted) {
      return;
    }
    if (controller.settings.onboardingCompleted) {
      return;
    }
    setState(() => _isFinishing = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ?? 'Не удалось сохранить настройку.',
        ),
      ),
    );
    controller.clearError();
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final slide = _slides[_index];
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            0,
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: _isFinishing ? null : _finish,
                    child: const Text('Пропустить'),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) => Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 320,
                              height: 340,
                              child: _OnboardingArt(index: index),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xs,
                          0,
                          AppSpacing.xs,
                          AppSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Dots(count: _slides.length, active: index),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              _slides[index].title,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _slides[index].body,
                              style: TextStyle(
                                fontSize: 15,
                                height: 22 / 15,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xxl,
                ),
                child: Column(
                  children: [
                    FilledButton(
                      onPressed: _isFinishing ? null : _next,
                      child: _isFinishing && isLast
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: palette.onAccent,
                              ),
                            )
                          : Text(slide.action),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.hint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.body,
    required this.hint,
    required this.action,
  });

  final String title;
  final String body;
  final String hint;
  final String action;
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 6),
            width: index == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == active ? palette.accent : palette.borderStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => const _TodayArt(),
      1 => const _OfflineArt(),
      _ => const _ReminderArt(),
    };
  }
}

class _TodayArt extends StatelessWidget {
  const _TodayArt();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Positioned(
          left: 30,
          top: 32,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          right: 6,
          bottom: 40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: palette.accentSoft,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 184,
            height: 184,
            child: CustomPaint(
              painter: _RingPainter(
                track: palette.borderSubtle,
                progress: palette.accent,
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.check_rounded, size: 54, color: palette.accent),
          ),
        ),
        Positioned(
          top: 6,
          right: 0,
          child: _FloatCard(
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.amber100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 17,
                    color: palette.amber600,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '12 дней',
                      style: TextStyle(
                        fontSize: 15,
                        height: 18 / 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      'подряд',
                      style: TextStyle(
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          bottom: 44,
          child: _FloatCard(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: palette.accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: palette.onAccent,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Чтение',
                      style: TextStyle(
                        fontSize: 13,
                        height: 17 / 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      'выполнено сегодня',
                      style: TextStyle(
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OfflineArt extends StatelessWidget {
  const _OfflineArt();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Positioned(
          left: 30,
          top: 32,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(60),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.verified_user_outlined,
              size: 74,
              color: palette.accent,
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 0,
          child: _FloatCard(
            child: Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: palette.accent,
                ),
                const SizedBox(width: 7),
                Text(
                  'Данные на устройстве',
                  style: TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 44,
          child: Center(
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 15,
                    color: palette.onAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Работает офлайн',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w600,
                      color: palette.onAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReminderArt extends StatelessWidget {
  const _ReminderArt();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Stack(
      children: [
        Positioned(
          left: 30,
          top: 32,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: palette.surfaceSubtle,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          left: 26,
          top: 34,
          right: 26,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.borderSubtle),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: palette.onAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Привычки · сейчас',
                      style: TextStyle(
                        fontSize: 11,
                        height: 14 / 11,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Пить воду',
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Отметьте привычку, когда будет удобно.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 26,
          bottom: 64,
          child: Transform.rotate(
            angle: -8 * math.pi / 180,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: palette.amber100,
                borderRadius: BorderRadius.circular(24),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: palette.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: palette.amber600,
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 48,
          child: _FloatCard(
            child: SizedBox(
              width: 86,
              child: Column(
                children: [
                  Text(
                    '08:00',
                    style: TextStyle(
                      fontSize: 16,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    'каждый день',
                    style: TextStyle(
                      fontSize: 10,
                      height: 13 / 10,
                      fontWeight: FontWeight.w500,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatCard extends StatelessWidget {
  const _FloatCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderSubtle),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.track, required this.progress});

  final Color track;
  final Color progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final progressPaint = Paint()
      ..color = progress
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * 0.68,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.track != track || oldDelegate.progress != progress;
  }
}
