import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _serverError = null;
    });

    final auth = context.read<AuthProvider>();
    final isLogin = _tab.index == 0;
    final error = isLogin
        ? await auth.signIn(_emailCtrl.text.trim(), _passwordCtrl.text)
        : await auth.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _serverError = error;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Nexus'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildTabBar(),
              const SizedBox(height: 24),
              _buildForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kNeonOrange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.bolt, color: Colors.black, size: 28),
        ),
        const SizedBox(height: 16),
        Text(
          _tab.index == 0 ? 'Willkommen zurück' : 'Konto erstellen',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Tausche Fähigkeiten mit Menschen in deiner Nähe.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: TabBar(
        controller: _tab,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: kNeonOrange,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.black,
        unselectedLabelColor: kTextSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Anmelden'),
          Tab(text: 'Registrieren'),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
              prefixIcon:
                  Icon(Icons.email_outlined, color: kTextMuted, size: 20),
            ),
            validator: (v) =>
                (v == null || !v.contains('@')) ? 'Gültige E-Mail eingeben' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Passwort',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: kTextMuted, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: kTextMuted,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => (v == null || v.length < 6)
                ? 'Mindestens 6 Zeichen'
                : null,
          ),
          if (_serverError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kError.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kError.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: kError, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_serverError!,
                        style: const TextStyle(color: kError, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(_tab.index == 0 ? 'Anmelden' : 'Konto erstellen'),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _tab.index == 0
                    ? 'Noch kein Konto? '
                    : 'Bereits registriert? ',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              TextButton(
                onPressed: () {
                  _tab.animateTo(_tab.index == 0 ? 1 : 0);
                  setState(() {});
                },
                child: Text(
                  _tab.index == 0 ? 'Registrieren' : 'Anmelden',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
