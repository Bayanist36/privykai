import 'package:flutter/material.dart';

import 'package:habit_tracker/app/app_info.dart';
import 'package:habit_tracker/app/app_palette.dart';
import 'package:habit_tracker/app/theme/app_spacing.dart';

/// Short offline version of the public privacy policy (edition 1.1).
///
/// The full edition lives on the public page referenced by
/// [AppInfo.privacyPolicyUrl] and linked from the RuStore card. This screen
/// only shows the URL as selectable text: it never opens the network and the
/// app has no `INTERNET` permission.
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: 18, color: palette.green700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Приложение работает офлайн. Данные хранятся на устройстве, '
                    'а копии появляются только по вашей команде — в файле '
                    'экспорта или в системном резервном копировании Android.',
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
                'время напоминания, история выполнения, серии и настройки '
                'приложения. Для виджета сохраняется снимок прогресса и '
                'названий привычек.',
          ),
          _Section(
            title: 'Где хранятся данные',
            body:
                'В локальной базе в приватном хранилище приложения на '
                'телефоне. Нет аккаунта, серверов, облачной синхронизации, '
                'рекламы и аналитики. У приложения нет разрешения INTERNET, '
                'поэтому само оно не может отправлять данные в сеть.',
          ),
          _Section(
            title: 'Экспорт и импорт',
            body:
                'Экспорт запускаете вы в «Настройках»: приложение создаёт '
                'JSON-файл с привычками, историей и настройками и передаёт '
                'его в системный диалог сохранения или отправки. Куда '
                'сохранить файл и какому приложению его передать, выбираете '
                'вы; само приложение файл никуда не отправляет. Файл не '
                'шифруется.\n\n'
                'Импорт читает только выбранный вами файл, проверяет формат '
                'и версию схемы, а после подтверждения заменяет текущие '
                'привычки, историю и настройки. Сам файл приложение не '
                'удаляет.',
          ),
          _Section(
            title: 'Виджет главного экрана',
            body:
                'Виджет необязателен: вы сами добавляете его на главный '
                'экран средствами Android. Он показывает прогресс за сегодня, '
                'серию и названия привычек (до трёх). Содержимое виджета '
                'видно всем, у кого есть доступ к разблокированному телефону. '
                'Если не хотите показывать названия привычек, не добавляйте '
                'виджет или удалите его с главного экрана.',
          ),
          _Section(
            title: 'Уведомления',
            body:
                'Текст напоминания формируется на устройстве и содержит '
                'название привычки. В зависимости от настроек телефона он '
                'может отображаться на экране блокировки. Скрыть содержимое '
                'можно в настройках Android: «Уведомления» → «На экране '
                'блокировки» → «Скрывать содержимое». Названия пунктов '
                'зависят от производителя и версии Android.',
          ),
          _Section(
            title: 'Системное резервное копирование Android',
            body:
                'Если на телефоне включено резервное копирование, '
                'операционная система Android может сохранить копию данных '
                'приложения в ваш аккаунт Google — включая привычки, историю '
                'и настройки. Это делает ОС, а не приложение; такая копия '
                'управляется средствами и правилами Google. Отключить её '
                'можно в настройках резервного копирования телефона.',
          ),
          _Section(
            title: 'Удаление данных',
            body:
                'Сброс в настройках удаляет привычки и историю с устройства '
                'без возможности восстановления. Удаление приложения также '
                'удаляет его локальные данные. Экспортированный файл и '
                'системная резервная копия так не удаляются — их нужно '
                'удалить отдельно.',
          ),
          const SizedBox(height: AppSpacing.sm),
          _FullEditionSection(url: AppInfo.privacyPolicyUrl),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Редакция ${AppInfo.privacyPolicyEdition} · 3 ноября 2026',
            style: textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
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

class _FullEditionSection extends StatelessWidget {
  const _FullEditionSection({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.palette;

    if (url.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Полная редакция', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Это краткая версия для экрана приложения. Полная редакция '
          '${AppInfo.privacyPolicyEdition} опубликована по ссылке из карточки '
          'приложения в RuStore:',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SelectableText(
          url,
          style: textTheme.bodyMedium?.copyWith(
            color: palette.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Приложение не открывает ссылку само и не выполняет сетевых '
          'запросов — адрес можно скопировать и открыть в браузере.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
