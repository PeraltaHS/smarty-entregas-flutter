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
  // ── PageView ──────────────────────────────────────────────────────────────
  final _pageCtrl = PageController();
  int _step = 0; // 0 = Dados, 1 = Contato, 2 = Senha

  // ── Form keys por etapa ───────────────────────────────────────────────────
  final _form0 = GlobalKey<FormState>();
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  final _nomeCtrl     = TextEditingController();
  final _cpfCtrl      = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  // ── Focus nodes ──────────────────────────────────────────────────────────
  final _nomeFocus     = FocusNode();
  final _cpfFocus      = FocusNode();
  final _telefoneFocus = FocusNode();
  final _emailFocus    = FocusNode();
  final _senhaFocus    = FocusNode();
  final _confirmFocus  = FocusNode();

  // ── Masks ─────────────────────────────────────────────────────────────────
  final _cpfFmt = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telFmt = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  // ── State ─────────────────────────────────────────────────────────────────
  bool    _obscureSenha   = true;
  bool    _obscureConfirm = true;
  bool    _aceitouTermos  = false;
  bool    _carregando     = false;
  String? _erro;

  // ── Colours ───────────────────────────────────────────────────────────────
  static const _orange   = Color(0xFFF5841F);
  static const _orangeDk = Color(0xFFE67316);

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
    _pageCtrl.dispose();
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  InputDecoration _deco({
    required String    label,
    required IconData  icon,
    required FocusNode focus,
    Widget?            suffix,
  }) {
    final active = focus.hasFocus;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color:    active ? _orange : const Color(0xFF757575),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: active ? _orange : const Color(0xFF757575),
        size:  20,
      ),
      suffixIcon: suffix,
      filled:    true,
      fillColor: Colors.white.withValues(alpha: 0.95),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _orange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(
          fontSize: 12, color: const Color(0xFFFFCDD2)),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
    );
  }

  Widget _fieldCard({required Widget child}) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _primaryBtn({
    required String   label,
    required VoidCallback? onPressed,
  }) =>
      Container(
        width:  double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _orange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            disabledBackgroundColor: _orange.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _carregando && label == 'Registrar'
              ? const SizedBox(
                  height: 22,
                  width:  22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:  AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize:   16,
                    fontWeight: FontWeight.bold,
                    color:      Colors.white,
                  ),
                ),
        ),
      );

  Widget _backLink({required VoidCallback onTap}) => TextButton(
        onPressed: onTap,
        child: Text(
          'Voltar',
          style: GoogleFonts.poppins(
            fontSize:            14,
            fontWeight:          FontWeight.w600,
            color:               Colors.white,
            decoration:          TextDecoration.underline,
            decorationColor:     Colors.white,
            decorationThickness: 1.5,
          ),
        ),
      );

  void _goTo(int page) {
    setState(() { _step = page; _erro = null; });
    _pageCtrl.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve:    Curves.easeInOut,
    );
  }

  void _nextStep(GlobalKey<FormState> formKey) {
    if (!formKey.currentState!.validate()) return;
    _goTo(_step + 1);
  }

  Future<void> _registrar() async {
    if (!_form2.currentState!.validate()) return;
    if (!_aceitouTermos) {
      setState(() => _erro = 'Aceite os termos para continuar.');
      return;
    }

    setState(() { _erro = null; _carregando = true; });

    try {
      final uri  = Uri.parse('http://localhost:8080/auth/register/cliente');
      final body = jsonEncode({
        'nome':     _nomeCtrl.text.trim(),
        'cpf':      _cpfFmt.getUnmaskedText(),
        'telefone': _telFmt.getUnmaskedText(),
        'email':    _emailCtrl.text.trim(),
        'senha':    _senhaCtrl.text,
      });

      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body:    body,
      );

      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Navigator.pop(context);
      } else {
        final msg = resp.body.isNotEmpty
            ? (jsonDecode(resp.body)['error'] ?? 'Erro ao registrar')
                .toString()
            : 'Erro ao registrar (${resp.statusCode})';
        setState(() => _erro = msg);
      }
    } catch (_) {
      setState(() =>
          _erro = 'Erro de conexão: verifique se o servidor está rodando.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // ── Step indicator ────────────────────────────────────────────────────────

  Widget _stepIndicator() {
    const labels = ['Dados', 'Contato', 'Senha'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        if (i.isOdd) {
          // linha entre bolinhas
          final lineIdx = i ~/ 2; // 0 ou 1
          final done = _step > lineIdx;
          return Expanded(
            child: Container(
              height: 2,
              color: Colors.white.withValues(alpha: done ? 1.0 : 0.3),
            ),
          );
        }
        // bolinha
        final dotIdx = i ~/ 2;
        final done   = _step >  dotIdx;
        final active = _step == dotIdx;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width:  32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (done || active)
                    ? _orangeDk
                    : Colors.white.withValues(alpha: 0.3),
                border: Border.all(
                  color: (done || active)
                      ? _orangeDk
                      : Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '${dotIdx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize:   13,
                          fontWeight: FontWeight.bold,
                          color:      Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[dotIdx],
              style: GoogleFonts.poppins(
                fontSize:   11,
                color:      Colors.white,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Pages ─────────────────────────────────────────────────────────────────

  Widget _page0() => Form(
        key: _form0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldCard(
              child: TextFormField(
                controller: _nomeCtrl,
                focusNode:  _nomeFocus,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label: 'Nome completo',
                  icon:  Icons.person_outlined,
                  focus: _nomeFocus,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
              ),
            ),
            const SizedBox(height: 16),

            _fieldCard(
              child: TextFormField(
                controller:     _cpfCtrl,
                focusNode:      _cpfFocus,
                keyboardType:   TextInputType.number,
                inputFormatters: [_cpfFmt],
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label: 'CPF',
                  icon:  Icons.badge_outlined,
                  focus: _cpfFocus,
                ),
                validator: (_) {
                  final d = _cpfFmt.getUnmaskedText();
                  return d.length < 11 ? 'CPF deve ter 11 dígitos' : null;
                },
              ),
            ),
            const SizedBox(height: 24),

            _primaryBtn(
              label:     'Continuar',
              onPressed: () => _nextStep(_form0),
            ),
          ],
        ),
      );

  Widget _page1() => Form(
        key: _form1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldCard(
              child: TextFormField(
                controller:     _telefoneCtrl,
                focusNode:      _telefoneFocus,
                keyboardType:   TextInputType.phone,
                inputFormatters: [_telFmt],
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label: 'Telefone',
                  icon:  Icons.phone_outlined,
                  focus: _telefoneFocus,
                ),
                validator: (_) {
                  final d = _telFmt.getUnmaskedText();
                  return d.length < 10 ? 'Telefone incompleto' : null;
                },
              ),
            ),
            const SizedBox(height: 16),

            _fieldCard(
              child: TextFormField(
                controller:   _emailCtrl,
                focusNode:    _emailFocus,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label: 'E-mail',
                  icon:  Icons.email_outlined,
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
            const SizedBox(height: 24),

            _primaryBtn(
              label:     'Continuar',
              onPressed: () => _nextStep(_form1),
            ),
            const SizedBox(height: 8),
            _backLink(onTap: () => _goTo(0)),
          ],
        ),
      );

  Widget _page2() => Form(
        key: _form2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _fieldCard(
              child: TextFormField(
                controller:  _senhaCtrl,
                focusNode:   _senhaFocus,
                obscureText: _obscureSenha,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label:  'Senha',
                  icon:   Icons.lock_outlined,
                  focus:  _senhaFocus,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureSenha
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _senhaFocus.hasFocus
                          ? _orange
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

            _fieldCard(
              child: TextFormField(
                controller:  _confirmCtrl,
                focusNode:   _confirmFocus,
                obscureText: _obscureConfirm,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label:  'Confirmar senha',
                  icon:   Icons.lock_outlined,
                  focus:  _confirmFocus,
                  suffix: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _confirmFocus.hasFocus
                          ? _orange
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
            const SizedBox(height: 12),

            // Checkbox termos
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value:       _aceitouTermos,
                  onChanged:   (v) =>
                      setState(() => _aceitouTermos = v ?? false),
                  activeColor: _orange,
                  checkColor:  Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                ),
                Expanded(
                  child: Text(
                    'Li e aceito os termos de uso e política de privacidade',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),

            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(
                _erro!,
                style: GoogleFonts.poppins(
                  fontSize:   12,
                  color:      const Color(0xFFFFCDD2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),

            _primaryBtn(
              label:     'Registrar',
              onPressed: (_carregando || !_aceitouTermos) ? null : _registrar,
            ),
            const SizedBox(height: 8),
            _backLink(onTap: () => _goTo(1)),
          ],
        ),
      );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _goTo(_step - 1);
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFFEB3B)],
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 120,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(height: 60),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Registre-se',
                    style: GoogleFonts.poppins(
                      fontSize:   28,
                      fontWeight: FontWeight.bold,
                      color:      Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _stepIndicator(),
                  const SizedBox(height: 28),

                  // Conteúdo da etapa atual via PageView
                  SizedBox(
                    height: 420, // altura suficiente para qualquer etapa
                    child: PageView(
                      controller: _pageCtrl,
                      physics:    const NeverScrollableScrollPhysics(),
                      children: [
                        _page0(),
                        _page1(),
                        _page2(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      if (_step == 0) {
                        Navigator.pop(context);
                      } else {
                        _goTo(_step - 1);
                      }
                    },
                    child: Text(
                      'Voltar para Login',
                      style: GoogleFonts.poppins(
                        fontSize:            14,
                        fontWeight:          FontWeight.w600,
                        color:               Colors.white,
                        decoration:          TextDecoration.underline,
                        decorationColor:     Colors.white,
                        decorationThickness: 1.5,
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
