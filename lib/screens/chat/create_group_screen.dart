import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _client = Supabase.instance.client;

  List<Map<String, dynamic>> _searchResults = [];
  final List<Map<String, dynamic>> _selected = [];
  bool _searching = false;
  bool _creating = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final currentUserId =
          context.read<AuthProvider>().currentUser?.id ?? '';
      final data = await _client
          .from('profiles')
          .select('id, user_name, avatar_url')
          .ilike('user_name', '%${query.trim()}%')
          .neq('id', currentUserId)
          .limit(20);

      setState(() {
        _searchResults = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((p) =>
                !_selected.any((s) => s['userId'] == p['id']))
            .toList();
      });
    } catch (_) {
    } finally {
      setState(() => _searching = false);
    }
  }

  void _toggleMember(Map<String, dynamic> profile) {
    setState(() {
      final uid = profile['id'] as String;
      final already = _selected.indexWhere((s) => s['userId'] == uid);
      if (already != -1) {
        _selected.removeAt(already);
      } else {
        _selected.add({
          'userId': uid,
          'userName': profile['user_name'],
          'avatarUrl': profile['avatar_url'],
        });
      }
      _searchResults.removeWhere((r) => r['id'] == uid);
    });
  }

  Future<void> _createGroup() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bitte einen Gruppennamen eingeben');
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = 'Bitte mindestens ein Mitglied hinzufügen');
      return;
    }

    setState(() {
      _creating = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>().profile;

    final (convId, err) = await context.read<ChatProvider>().createGroupChat(
          name: name,
          currentUserId: auth.currentUser!.id,
          currentUserName: profile?.userName ?? 'Anonym',
          currentUserAvatar: profile?.avatarUrl,
          members: _selected,
        );

    if (!mounted) return;
    setState(() => _creating = false);

    if (err != null) {
      setState(() => _error = err);
      return;
    }

    final conversations = context.read<ChatProvider>().conversations;
    final conv = conversations.firstWhere((c) => c.id == convId!);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Gruppe erstellen'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: kNeonOrange, strokeWidth: 2),
                  )
                : const Text('Erstellen',
                    style: TextStyle(
                        color: kNeonOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Gruppenname',
                    prefixIcon:
                        Icon(Icons.group, color: kTextMuted, size: 20),
                  ),
                  style: const TextStyle(color: kTextPrimary),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_error!,
                        style:
                            const TextStyle(color: kError, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                if (_selected.isNotEmpty) ...[
                  const Text('Ausgewählt:',
                      style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selected
                        .map((m) => Chip(
                              label: Text(
                                m['userName'] as String? ?? 'Anonym',
                                style:
                                    const TextStyle(color: kTextPrimary),
                              ),
                              deleteIcon: const Icon(Icons.close,
                                  size: 16, color: kTextMuted),
                              onDeleted: () {
                                setState(() => _selected.remove(m));
                              },
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Mitglieder suchen...',
                    prefixIcon: const Icon(Icons.search,
                        color: kTextMuted, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: kNeonOrange),
                            ),
                          )
                        : null,
                  ),
                  style: const TextStyle(color: kTextPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty && _searchCtrl.text.isNotEmpty
                ? const Center(
                    child: Text('Keine Nutzer gefunden',
                        style: TextStyle(color: kTextSecondary)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final p = _searchResults[i];
                      final avatar = p['avatar_url'] as String?;
                      final name =
                          p['user_name'] as String? ?? 'Anonym';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: kBgCardElevated,
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: kNeonOrange,
                                      fontWeight: FontWeight.w700))
                              : null,
                        ),
                        title: Text(name,
                            style:
                                const TextStyle(color: kTextPrimary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: kNeonOrange),
                          onPressed: () => _toggleMember(p),
                        ),
                        onTap: () => _toggleMember(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
