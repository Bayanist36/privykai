import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_info.dart';
import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';

/// Local privacy text. The public URL for the store card lives in
/// [AppInfo.privacyPolicyUrl] and is supplied by marketing in SUK-15; this
/// screen stays offline and makes no network promises.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: palette.green700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Все данные хранятся только на этом устройстве.',
                    style: textTheme.labelSmall?.copyWith(
                      color: palette.green700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _Section(
            title: 'Какие данные хранятся',
            body:
                'Названия привычек, выбранные иконки и цвета, дни недели, '
                'время напоминания, история выполнения и настройки приложения.',
          ),
          _Section(
            title: 'Где хранятся данные',
            body:
                'В локальной базе на телефоне. Приложение не отправляет данные '
                'на серверы, не требует аккаунта и не содержит рекламы или '
                'аналитики.',
          ),
          _Section(
            title: 'Сеть и разрешения',
            body:
                'Приложение работает офлайн и не запрашивает доступ в интернет. '
                'Разрешение на уведомления используется только для локальных '
                'напоминаний о привычках: уведомления создаются на устройстве '
                'и никуда не отправляются.',
          ),
          _Section(
            title: 'Удаление данных',
            body:
                'Сброс в настройках удаляет привычки и историю с устройства '
                'без возможности восстановления. Удаление приложения также '
                'удаляет локальные данные.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(AppInfo.copyright, style: textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
