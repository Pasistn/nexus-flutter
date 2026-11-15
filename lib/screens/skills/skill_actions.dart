import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../models/skill.dart';
import '../../providers/chat_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../providers/skills_provider.dart';
import '../../widgets/bottom_sheet.dart';
import '../../widgets/feedback.dart';
import '../../widgets/star_rating.dart';
import '../chat/chat_screen.dart';

const _reportReasons = [
  'Spam oder Werbung',
  'Belästigung oder Hassrede',
  'Falsche oder irreführende Angaben',
  'Unangemessener Inhalt',
  'Sonstiges',
];

Future<void> openChatWith(BuildContext context, Skill skill) async {
  final chat = context.read<ChatProvider>();
  final nav = Navigator.of(context);

  final result = await chat.openDirectChat(skill.userId, skillId: skill.id);
  if (!context.mounted) return;

  final conversation =
      result.conversationId == null ? null : chat.byId(result.conversationId!);
  if (conversation == null) {
    showSnack(
      context,
      result.error ?? 'Chat konnte nicht geöffnet werden.',
      error: true,
    );
    return;
  }
  nav.push(
    MaterialPageRoute(builder: (_) => ChatScreen(conversation: conversation)),
  );
}

Future<void> showRequestSheet(BuildContext context, Skill skill) {
  return showNexusSheet<void>(
    context,
    builder: (_) => _RequestForm(skill: skill, hostContext: context),
  );
}

Future<void> showRatingSheet(BuildContext context, Skill skill) {
  return showNexusSheet<void>(
    context,
    builder: (_) => _RatingForm(skill: skill, hostContext: context),
  );
}

Future<void> showReportDialog(BuildContext context, Skill skill) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
  if (reason == null || !context.mounted) return;

  final err = await context.read<SkillsProvider>().report(skill.id, reason);
  if (!context.mounted) return;
  showSnack(
    context,
    err ?? 'Danke! Wir schauen uns den Eintrag an.',
    error: err != null,
  );
}

class SkillActionBar extends StatelessWidget {
  const SkillActionBar({super.key, required this.skill, this.compact = false});

  final Skill skill;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!skill.hasOwner) {
      return const Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: kTextMuted),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Beispiel-Eintrag – keine Kontaktaufnahme möglich',
              style: TextStyle(fontSize: 12.5, color: kTextMuted),
            ),
          ),
        ],
      );
    }

    final padding = EdgeInsets.symmetric(vertical: compact ? 8 : 10);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => openChatWith(context, skill),
            style: OutlinedButton.styleFrom(padding: padding),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
            label: const Text('Nachricht'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => showRequestSheet(context, skill),
            style: ElevatedButton.styleFrom(padding: padding),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Anfragen'),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mehr',
          icon: const Icon(Icons.more_vert, color: kTextMuted),
          onSelected: (value) => switch (value) {
            'rate' => showRatingSheet(context, skill),
            _ => showReportDialog(context, skill),
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'rate',
              child: ListTile(
                leading: Icon(Icons.star_outline_rounded),
                title: Text('Bewerten'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.flag_outlined),
                title: Text('Melden'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RequestForm extends StatefulWidget {
  const _RequestForm({required this.skill, required this.hostContext});

  final Skill skill;
  final BuildContext hostContext;

  @override
  State<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<_RequestForm> {
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    final err = await context
        .read<SkillRequestProvider>()
        .send(widget.skill.id, message: nullIfBlank(_message.text));
    if (!mounted) return;

    Navigator.of(context).pop();
    final host = widget.hostContext;
    if (host.mounted) {
      showSnack(host, err ?? 'Anfrage gesendet!', error: err != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetTitle(
          'Skill anfragen',
          subtitle: widget.skill.title,
          subtitleColor: kPrimary,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _message,
          maxLines: 3,
          maxLength: SkillRequestProvider.maxMessageLength,
          decoration: const InputDecoration(
            labelText: 'Nachricht (optional)',
            hintText: 'Wann, wo, worum geht es?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _sending ? null : _send,
            child: _sending
                ? const ButtonSpinner()
                : const Text('Anfrage senden'),
          ),
        ),
      ],
    );
  }
}

class _RatingForm extends StatefulWidget {
  const _RatingForm({required this.skill, required this.hostContext});

  final Skill skill;
  final BuildContext hostContext;

  @override
  State<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<_RatingForm> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final err = await context.read<RatingsProvider>().submit(
          ratedUserId: widget.skill.userId,
          stars: _stars,
          comment: nullIfBlank(_comment.text),
          skillId: widget.skill.id,
        );
    if (!mounted) return;

    Navigator.of(context).pop();
    final host = widget.hostContext;
    if (host.mounted) {
      showSnack(host, err ?? 'Danke für deine Bewertung!', error: err != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetTitle(
          '${widget.skill.userName ?? 'Person'} bewerten',
          subtitle: widget.skill.title,
        ),
        const SizedBox(height: 16),
        StarPicker(value: _stars, onChanged: (v) => setState(() => _stars = v)),
        const SizedBox(height: 16),
        TextField(
          controller: _comment,
          maxLines: 3,
          maxLength: RatingsProvider.maxCommentLength,
          decoration: const InputDecoration(
            labelText: 'Kommentar (optional)',
            hintText: 'Wie lief der Austausch?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _stars == 0 || _saving ? null : _submit,
            child: _saving
                ? const ButtonSpinner()
                : const Text('Bewertung abgeben'),
          ),
        ),
      ],
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eintrag melden'),
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in _reportReasons)
            ListTile(
              dense: true,
              onTap: () => setState(() => _reason = r),
              leading: Icon(
                r == _reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: r == _reason ? kPrimary : kTextMuted,
                size: 20,
              ),
              title: Text(r, style: const TextStyle(fontSize: 13.5)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed:
              _reason == null ? null : () => Navigator.of(context).pop(_reason),
          child: const Text('Melden'),
        ),
      ],
    );
  }
}
