import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/tables.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_utils.dart';
import '../../core/utils/text_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/user_avatar.dart';
import 'chat_screen.dart';

class _Person {
  _Person.fromRow(Map<String, dynamic> row)
      : id = row['id'] as String,
        name = row['user_name'] as String? ?? 'Anonym',
        avatarUrl = row['avatar_url'] as String?;

  final String id;
  final String name;
  final String? avatarUrl;
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  static const _maxNameLength = 60;
  static const _maxMembers = 50;

  final _name = TextEditingController();
  final _search = TextEditingController();
  final _client = Supabase.instance.client;

  final List<_Person> _selected = [];
  List<_Person> _results = [];
  bool _searching = false;
  bool _creating = false;
  String? _error;
  Timer? _debounce;
  int _searchId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();
    final me = context.read<AuthProvider>().userId;
    if (q.length < 2 || me == null) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }

    final id = ++_searchId;
    setState(() => _searching = true);
    try {
      final rows = await _client
          .from(Tables.publicProfiles)
          .select('id, user_name, avatar_url')
          .ilike('user_name', '%${escapeLike(q)}%')
          .neq('id', me)
          .limit(20);
      if (!mounted || id != _searchId) return;
      setState(() {
        _results = rows
            .map(_Person.fromRow)
            .where((p) => !_selected.any((s) => s.id == p.id))
            .toList();
      });
    } catch (e) {
      friendlyError(e);
    } finally {
      if (mounted && id == _searchId) setState(() => _searching = false);
    }
  }

  void _add(_Person p) {
    if (_selected.length >= _maxMembers) return;
    setState(() {
      _selected.add(p);
      _results.removeWhere((r) => r.id == p.id);
    });
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final problem = name.isEmpty
        ? 'Bitte gib der Gruppe einen Namen.'
        : _selected.isEmpty
            ? 'Füg mindestens ein Mitglied hinzu.'
            : null;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    final chat = context.read<ChatProvider>();
    final result = await chat.createGroup(name, [for (final p in _selected) p.id]);
    if (!mounted) return;

    final conv = result.conversationId == null ? null : chat.byId(result.conversationId!);
    if (conv == null) {
      setState(() {
        _creating = false;
        _error = result.error ?? 'Gruppe konnte nicht geöffnet werden.';
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Gruppe'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const ButtonSpinner(color: kPrimary)
                : const Text('Erstellen'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  maxLength: _maxNameLength,
                  decoration: const InputDecoration(
                    counterText: '',
                    labelText: 'Gruppenname',
                    prefixIcon: Icon(Icons.group_outlined, color: kTextMuted, size: 20),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  ErrorBanner(_error!),
                ],
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Mitglieder (${_selected.length})',
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final p in _selected)
                        InputChip(
                          avatar: UserAvatar(url: p.avatarUrl, name: p.name, radius: 12),
                          label: Text(p.name),
                          onDeleted: () => setState(() => _selected.remove(p)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: _onSearchChanged,
                  maxLength: 50,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Personen suchen (min. 2 Zeichen)',
                    prefixIcon: const Icon(Icons.search, color: kTextMuted, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: ButtonSpinner(color: kPrimary, size: 16),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _resultList()),
        ],
      ),
    );
  }

  Widget _resultList() {
    if (_results.isEmpty) {
      final searched = _search.text.trim().length >= 2 && !_searching;
      return searched
          ? const Center(
              child: Text(
                'Niemanden gefunden',
                style: TextStyle(color: kTextSecondary),
              ),
            )
          : const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final p = _results[i];
        return ListTile(
          leading: UserAvatar(url: p.avatarUrl, name: p.name),
          title: Text(p.name),
          trailing: const Icon(Icons.add_circle_outline, color: kPrimary),
          onTap: () => _add(p),
        );
      },
    );
  }
}
