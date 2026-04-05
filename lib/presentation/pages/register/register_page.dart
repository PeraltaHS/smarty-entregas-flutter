import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PaginaRegistro extends StatefulWidget {
  const PaginaRegistro({super.key});

  @override
  State<PaginaRegistro> createState() => _PaginaRegistroState();
}

class _PaginaRegistroState extends State<PaginaRegistro> {
  final _formKey = GlobalKey<FormState>();

  final _nomeCtrl     = TextEditingController();
  final _cpfCtrl      = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  final _nomeFocus     = FocusNode();
  final _cpfFocus      = FocusNode();
  final _telefoneFocus = FocusNode();
  final _emailFocus    = FocusNode();
  final _senhaFocus    = FocusNode();
  final _confirmFocus  = FocusNode();

  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _obscureSenha   = true;
  bool _obscureConfirm = true;
  bool _aceitouTermos  = false;
  bool _carregando     = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    for (final f in [
      _nomeFocus, _cpfFocus, _telefoneFocus,
      _emailFocus, _senhaFocus, _confirmFocus,
    ]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _cpfCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    _nomeFocus.dispose();
    _cpfFocus.dispose();
    _telefoneFocus.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  InputDecoration _deco({
    required String label,
    required IconData icon,
    required FocusNode focus,
    Widget? suffix,
  }) {
    final active = focus.hasFocus;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: active ? const Color(0xFFF5841F) : const Color(0xFF757575),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: active ? const Color(0xFFF5841F) : const Color(0xFF757575),
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.95),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFF5841F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFFFFCDD2)),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  Widget _fieldShadow({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _registrarCliente() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) {
      setState(() => _erro = 'Aceite os termos para continuar.');
      return;
    }

    setState(() {
      _erro = null;
      _carregando = true;
    });

    try {
      final uri = Uri.parse('http://localhost:8080/auth/register/cliente');
      final body = jsonEncode({
        'nome':     _nomeCtrl.text.trim(),
        'cpf':      _cpfFormatter.getUnmaskedText(),
        'telefone': _telefoneFormatter.getUnmaskedText(),
        'email':    _emailCtrl.text.trim(),
        'senha':    _senhaCtrl.text,
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Navigator.pop(context);
      } else {
        final msg = resp.body.isNotEmpty
            ? (jsonDecode(resp.body)['error'] ?? 'Erro ao registrar').toString()
            : 'Erro ao registrar (${resp.statusCode})';
        setState(() => _erro = msg);
      }
    } catch (e) {
      setState(() =>
          _erro = 'Erro de conexão: verifique se o servidor está rodando.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFFEB3B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 140,
                    errorBuilder: (_, __, ___) => const SizedBox(height: 60),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Registre-se',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _nomeCtrl,
                      focusNode: _nomeFocus,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'Nome completo',
                        icon: Icons.person_outlined,
                        focus: _nomeFocus,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _cpfCtrl,
                      focusNode: _cpfFocus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cpfFormatter],
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'CPF',
                        icon: Icons.badge_outlined,
                        focus: _cpfFocus,
                      ),
                      validator: (_) {
                        final digits = _cpfFormatter.getUnmaskedText();
                        if (digits.length < 11) return 'CPF deve ter 11 dígitos';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _telefoneCtrl,
                      focusNode: _telefoneFocus,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [_telefoneFormatter],
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'Telefone',
                        icon: Icons.phone_outlined,
                        focus: _telefoneFocus,
                      ),
                      validator: (_) {
                        final digits = _telefoneFormatter.getUnmaskedText();
                        if (digits.length < 10) return 'Telefone incompleto';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _emailCtrl,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'E-mail',
                        icon: Icons.email_outlined,
                        focus: _emailFocus,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                        if (!RegExp(r'.+@.+\..+').hasMatch(v.trim())) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _senhaCtrl,
                      focusNode: _senhaFocus,
                      obscureText: _obscureSenha,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'Senha',
                        icon: Icons.lock_outlined,
                        focus: _senhaFocus,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureSenha
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _senhaFocus.hasFocus
                                ? const Color(0xFFF5841F)
                                : const Color(0xFF757575),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureSenha = !_obscureSenha),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a senha';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  _fieldShadow(
                    child: TextFormField(
                      controller: _confirmCtrl,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'Confirmar senha',
                        icon: Icons.lock_outlined,
                        focus: _confirmFocus,
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: _confirmFocus.hasFocus
                                ? const Color(0xFFF5841F)
                                : const Color(0xFF757575),
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v != _senhaCtrl.text) return 'Senhas não coincidem';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Termos
                  Row(
                    children: [
                      Checkbox(
                        value: _aceitouTermos,
                        onChanged: (v) =>
                            setState(() => _aceitouTermos = v ?? false),
                        activeColor: const Color(0xFFF5841F),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                      Expanded(
                        child: Text(
                          'Li e aceito os termos de uso e política de privacidade',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_erro != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _erro!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFFFCDD2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF5841F).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: (_carregando || !_aceitouTermos)
                          ? null
                          : _registrarCliente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5841F),
                        disabledBackgroundColor:
                            const Color(0xFFF5841F).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _carregando
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Registrar',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Voltar para Login',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white70,
                      ),
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
