// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2026, Alessandro Cipriani and SnapPress contributors.

import 'package:flutter/material.dart';

import '../../core/auth/app_lock_service.dart';
import '../../l10n/app_localizations.dart';

/// Shows the right screen for the current lock state.
class LockScreen extends StatelessWidget {
  const LockScreen({super.key, required this.lock});

  final AppLockService lock;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: lock,
      builder: (context, _) {
        switch (lock.state) {
          case AppLockState.loading:
          case AppLockState.unlocked:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AppLockState.needsSetup:
            return SetupPasswordScreen(lock: lock);
          case AppLockState.locked:
            return UnlockScreen(lock: lock);
        }
      },
    );
  }
}

/// First launch: choose the app password and, if available, biometrics.
class SetupPasswordScreen extends StatefulWidget {
  const SetupPasswordScreen({super.key, required this.lock});

  final AppLockService lock;

  @override
  State<SetupPasswordScreen> createState() => _SetupPasswordScreenState();
}

class _SetupPasswordScreenState extends State<SetupPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _useBiometrics = true;
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final lock = widget.lock;
    if (lock.biometricsAvailable) {
      await lock.setBiometricsEnabled(_useBiometrics);
    }
    await lock.setPassword(_password.text);
    // The widget is removed once unlocked: no setState afterwards.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lockSetupTitle)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(l10n.lockSetupDescription, style: textTheme.bodyLarge),
              const SizedBox(height: 24),
              _PasswordField(
                controller: _password,
                label: l10n.lockPasswordLabel,
                helper: l10n.lockPasswordHelper(
                  AppLockService.minPasswordLength,
                ),
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    (value ?? '').length < AppLockService.minPasswordLength
                        ? l10n.lockPasswordTooShort(
                            AppLockService.minPasswordLength,
                          )
                        : null,
              ),
              const SizedBox(height: 16),
              _PasswordField(
                controller: _confirm,
                label: l10n.lockPasswordConfirmLabel,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) => value != _password.text
                    ? l10n.lockPasswordMismatch
                    : null,
              ),
              if (widget.lock.biometricsAvailable) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.lockUseBiometrics),
                  subtitle: Text(l10n.lockUseBiometricsDescription),
                  value: _useBiometrics,
                  onChanged: (value) => setState(() => _useBiometrics = value),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: l10n.pleaseWait,
                        ),
                      )
                    : Text(l10n.lockSetupButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unlock with password or biometrics.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key, required this.lock});

  final AppLockService lock;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _password = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (widget.lock.canUseBiometrics) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometrics());
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _biometrics() async {
    if (!mounted) return;
    final reason = AppLocalizations.of(context).lockBiometricReason;
    await widget.lock.unlockWithBiometrics(reason);
  }

  Future<void> _unlock() async {
    final l10n = AppLocalizations.of(context);
    if (_password.text.isEmpty) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final result = await widget.lock.unlockWithPassword(_password.text);
    if (!mounted || result == UnlockResult.success) return;
    setState(() {
      _checking = false;
      _password.clear();
      _error = switch (result) {
        UnlockResult.lockedOut => l10n.lockLockedOut(
            widget.lock.lockoutRemaining?.inSeconds ??
                widget.lock.lockoutDuration.inSeconds,
          ),
        _ => l10n.lockWrongPassword,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 64),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.lockUnlockTitle,
                      style: textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _PasswordField(
                    controller: _password,
                    label: l10n.lockPasswordLabel,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _unlock(),
                    errorText: _error,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _checking ? null : _unlock,
                    child: Text(l10n.lockUnlockButton),
                  ),
                  if (widget.lock.canUseBiometrics) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _checking ? null : _biometrics,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(l10n.lockUseBiometricsButton),
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

/// Password field with a show/hide toggle.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    this.helper,
    this.errorText,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscure ? l10n.showPassword : l10n.hidePassword,
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
