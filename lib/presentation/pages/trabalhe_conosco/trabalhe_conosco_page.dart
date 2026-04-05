import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../services/api_service.dart';

class TrabalheConoscoPage extends StatefulWidget {
  const TrabalheConoscoPage({super.key});

  @override
  State<TrabalheConoscoPage> createState() => _TrabalheConoscoPageState();
}

class _TrabalheConoscoPageState extends State<TrabalheConoscoPage> {
  String _tipo = 'Empresa';
  bool _carregando = false;
  String? _erro;

  // Controladores compartilhados
  final _nomeCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _docCtrl      = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _senhaCtrl    = TextEditingController();
  // Extra: nome fantasia (Empresa) / CNH (Motoboy)
  final _extraCtrl    = TextEditingController();

  // FocusNodes
  final _nomeFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _docFocus      = FocusNode();
  final _telefoneFocus = FocusNode();
  final _senhaFocus    = FocusNode();
  final _extraFocus    = FocusNode();

  bool _obscureSenha = true;

  final _cnpjFmt = MaskTextInputFormatter(
    mask: '##.###.###/####-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfFmt = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _telFmt = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _empresaFormKey = GlobalKey<FormState>();
  final _motoboyFormKey = GlobalKey<FormState>();

  GlobalKey<FormState> get _formKey =>
      _tipo == 'Empresa' ? _empresaFormKey : _motoboyFormKey;

  @override
  void initState() {
    super.initState();
    for (final f in [
      _nomeFocus, _emailFocus, _docFocus,
      _telefoneFocus, _senhaFocus, _extraFocus,
    ]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _docCtrl.dispose();
    _telefoneCtrl.dispose();
    _senhaCtrl.dispose();
    _extraCtrl.dispose();
    _nomeFocus.dispose();
    _emailFocus.dispose();
    _docFocus.dispose();
    _telefoneFocus.dispose();
    _senhaFocus.dispose();
    _extraFocus.dispose();
    super.dispose();
  }

  void _limparCampos() {
    _nomeCtrl.clear();
    _emailCtrl.clear();
    _docCtrl.clear();
    _telefoneCtrl.clear();
    _senhaCtrl.clear();
    _extraCtrl.clear();
    _cnpjFmt.clear();
    _cpfFmt.clear();
    _telFmt.clear();
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

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _erro = null;
      _carregando = true;
    });

    final nome     = _nomeCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final doc      = _tipo == 'Empresa'
        ? _cnpjFmt.getMaskedText()
        : _cpfFmt.getMaskedText();
    final telefone = _telFmt.getMaskedText();
    final senha    = _senhaCtrl.text;

    String? erroApi;

    if (_tipo == 'Empresa') {
      erroApi = await ApiService.registerEmpresa(
        nome:     nome,
        email:    email,
        senha:    senha,
        cnpj:     doc,
        telefone: telefone,
      );
    } else {
      erroApi = await ApiService.registerCliente(
        nome:     nome,
        email:    email,
        senha:    senha,
        cpf:      doc,
        telefone: telefone,
      );
    }

    if (!mounted) return;

    if (erroApi != null) {
      setState(() {
        _erro = erroApi;
        _carregando = false;
      });
      return;
    }

    setState(() => _carregando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tipo == 'Empresa'
                    ? 'Empresa cadastrada! Faça login para continuar.'
                    : 'Cadastro realizado! Faça login para continuar.',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget _buildForm() {
    final isEmpresa = _tipo == 'Empresa';

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nome
          _fieldShadow(
            child: TextFormField(
              controller: _nomeCtrl,
              focusNode: _nomeFocus,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _deco(
                label: isEmpresa ? 'Nome fantasia' : 'Nome completo',
                icon: isEmpresa ? Icons.store_outlined : Icons.person_outlined,
                focus: _nomeFocus,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
          ),
          const SizedBox(height: 16),

          // Email
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

          // CNPJ ou CPF
          _fieldShadow(
            child: TextFormField(
              controller: _docCtrl,
              focusNode: _docFocus,
              keyboardType: TextInputType.number,
              inputFormatters: [isEmpresa ? _cnpjFmt : _cpfFmt],
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _deco(
                label: isEmpresa ? 'CNPJ' : 'CPF',
                icon: isEmpresa
                    ? Icons.business_outlined
                    : Icons.badge_outlined,
                focus: _docFocus,
              ),
              validator: (_) {
                final digits = isEmpresa
                    ? _cnpjFmt.getUnmaskedText()
                    : _cpfFmt.getUnmaskedText();
                final required = isEmpresa ? 14 : 11;
                if (digits.length < required) {
                  return isEmpresa
                      ? 'CNPJ deve ter 14 dígitos'
                      : 'CPF deve ter 11 dígitos';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Telefone
          _fieldShadow(
            child: TextFormField(
              controller: _telefoneCtrl,
              focusNode: _telefoneFocus,
              keyboardType: TextInputType.phone,
              inputFormatters: [_telFmt],
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: _deco(
                label: 'Telefone',
                icon: Icons.phone_outlined,
                focus: _telefoneFocus,
              ),
              validator: (_) {
                final digits = _telFmt.getUnmaskedText();
                if (digits.length < 10) return 'Telefone incompleto';
                return null;
              },
            ),
          ),
          const SizedBox(height: 16),

          // Senha
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

          if (!isEmpresa) ...[
            const SizedBox(height: 16),
            _fieldShadow(
              child: TextFormField(
                controller: _extraCtrl,
                focusNode: _extraFocus,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: _deco(
                  label: 'Número da CNH',
                  icon: Icons.directions_bike_outlined,
                  focus: _extraFocus,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe a CNH' : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpresa = _tipo == 'Empresa';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFFFEB3B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 120,
                  errorBuilder: (_, __, ___) => const SizedBox(height: 60),
                ),
                const SizedBox(height: 16),

                Text(
                  'Trabalhe Conosco',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Tab toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: ['Empresa', 'Motoboy'].map((t) {
                      final sel = _tipo == t;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_tipo == t) return;
                            _limparCampos();
                            setState(() {
                              _tipo = t;
                              _erro = null;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: sel
                                  ? [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                t,
                                style: GoogleFonts.poppins(
                                  color: sel
                                      ? const Color(0xFFF5841F)
                                      : Colors.white,
                                  fontWeight: sel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isEmpresa ? 'Cadastro de Empresa' : 'Cadastro de Motoboy',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                _buildForm(),

                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFFFFCDD2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

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
                    onPressed: _carregando ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5841F),
                      disabledBackgroundColor:
                          const Color(0xFFF5841F).withValues(alpha: 0.6),
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Cadastrar',
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
                    'Voltar ao login',
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
    );
  }
}
