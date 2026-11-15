import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/segmented_choice.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

enum _Mode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startWithRegister = false});

  final bool startWithRegister;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late _Mode _mode = widget.startWithRegister ? _Mode.register : _Mode.login;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;
  String? _info;

  bool get _isLogin => _mode == _Mode.login;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _switchMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final auth = context.read<AuthProvider>();
    final email = _email.text.trim();

    if (_isLogin) {
      final err = await auth.signIn(email, _password.text);
      if (!mounted) return;
      if (err == null) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _busy = false;
        _error = err;
      });
      return;
    }

    final result = await auth.signUp(email, _password.text);
    if (!mounted) return;

    if (result.error == null && !result.needsConfirmation) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = result.error;
      if (result.needsConfirmation) {
        _info = 'Fast geschafft! Wir haben dir eine E-Mail geschickt – '
            'bestätige deine Adresse und melde dich dann an.';
        _mode = _Mode.login;
        _password.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const NexusLogo(size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Willkommen zurück' : 'Konto erstellen',
                    style: textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tausche Fähigkeiten mit Menschen in deiner Nähe.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  SegmentedChoice<_Mode>(
                    selected: _mode,
                    onChanged: _switchMode,
                    options: const [
                      ChoiceOption(
                        value: _Mode.login,
                        label: 'Anmelden',
                        icon: Icons.login_rounded,
                      ),
                      ChoiceOption(
                        value: _Mode.register,
                        label: 'Registrieren',
                        icon: Icons.person_add_alt_1_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_info != null) ...[
                    _InfoBox(_info!),
                    const SizedBox(height: 16),
                  ],
                  _emailField(),
                  const SizedBox(height: 16),
                  _passwordField(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    ErrorBanner(_error!),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const ButtonSpinner()
                          : Text(_isLogin ? 'Anmelden' : 'Konto erstellen'),
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

  Widget _emailField() {
    return TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      maxLength: 254,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        counterText: '',
        labelText: 'E-Mail',
        prefixIcon: Icon(Icons.email_outlined, color: kTextMuted, size: 20),
      ),
      validator: (v) => _emailPattern.hasMatch(v?.trim() ?? '')
          ? null
          : 'Gültige E-Mail eingeben',
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _password,
      obscureText: _hidePassword,
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 128,
      autofillHints: [
        _isLogin ? AutofillHints.password : AutofillHints.newPassword,
      ],
      onFieldSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        counterText: '',
        labelText: 'Passwort',
        helperText: _isLogin
            ? null
            : 'Mindestens ${AuthProvider.minPasswordLength} Zeichen',
        prefixIcon: const Icon(Icons.lock_outline, color: kTextMuted, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _hidePassword ? Icons.visibility_off : Icons.visibility,
            color: kTextMuted,
            size: 20,
          ),
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Passwort eingeben';
        if (!_isLogin && v.length < AuthProvider.minPasswordLength) {
          return 'Mindestens ${AuthProvider.minPasswordLength} Zeichen';
        }
        return null;
      },
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSuccess.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kSuccess.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mark_email_read_outlined, color: kSuccess, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: kTextPrimary, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
