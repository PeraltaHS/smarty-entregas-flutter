import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../register/register_page.dart';
import '../trabalhe_conosco/trabalhe_conosco_page.dart';
import '../pagina_esqueci_senha/pagina_esqueci_senha.dart';

import '../../../services/api_service.dart';
import '../../../data/session_store.dart';

class PaginaLogin extends StatefulWidget {
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();

  bool    _loading      = false;
  bool    _obscureSenha = true;
  String? _erro;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _emailFocus.addListener(() => setState(() {}));
    _senhaFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  InputDecoration _deco({
    required String   label,
    required IconData icon,
    required FocusNode focus,
    Widget?            suffix,
  }) {
    final active = focus.hasFocus;
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color:    active ? const Color(0xFFF5841F) : const Color(0xFF757575),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: active ? const Color(0xFFF5841F) : const Color(0xFF757575),
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

  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _erro = null; });

    Map<String, dynamic> resp;
    try {
      resp = await ApiService.login(
        email: _emailCtrl.text.trim(),
        senha: _senhaCtrl.text,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro    = e.toString().replaceFirst('Exception: ', '');
      });
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);

    final user        = resp['user'] as Map<String, dynamic>? ?? {};
    final tipoUsuario = user['tipo_usuario']?.toString() ?? 'cliente';
    final idEmpresa   = user['id_empresa'] is int
        ? user['id_empresa'] as int
        : int.tryParse(user['id_empresa']?.toString() ?? '0') ?? 0;

    SessionStore.set(
      idUsuario: user['id_usuario'] is int
          ? user['id_usuario'] as int
          : int.tryParse(user['id_usuario']?.toString() ?? '0') ?? 0,
      email:       user['email']?.toString()        ?? '',
      nome:        user['nome']?.toString()         ?? '',
      tipoUsuario: tipoUsuario,
      idEmpresa:   idEmpresa > 0 ? idEmpresa : null,
    );

    if (tipoUsuario == 'empresa') {
      Navigator.pushReplacementNamed(context, '/empresa');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient wraps the entire Scaffold so it fills 100% of screen
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Image.asset(
                        'assets/logo.png',
                        height: 260,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(height: 80),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // E-mail
                  _fieldCard(
                    child: TextFormField(
                      controller:  _emailCtrl,
                      focusNode:   _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'E-mail',
                        icon:  Icons.email_outlined,
                        focus: _emailFocus,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o e-mail';
                        }
                        if (!RegExp(r'.+@.+\..+').hasMatch(v.trim())) {
                          return 'E-mail inválido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Senha
                  _fieldCard(
                    child: TextFormField(
                      controller: _senhaCtrl,
                      focusNode:  _senhaFocus,
                      obscureText: _obscureSenha,
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: _deco(
                        label: 'Senha',
                        icon:  Icons.lock_outlined,
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

                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFFFCDD2),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botão Entrar
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF5841F)
                              .withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _fazerLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF5841F),
                        disabledBackgroundColor:
                            const Color(0xFFF5841F).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width:  22,
                              child: CircularProgressIndicator(
                                strokeWidth:  2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Entrar',
                              style: GoogleFonts.poppins(
                                fontSize:   16,
                                fontWeight: FontWeight.bold,
                                color:      Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Botão Registrar-se — contraste melhorado
                  SizedBox(
                    width:  double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PaginaRegistro()),
                              ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.20),
                        side: const BorderSide(
                            color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Registrar-se',
                        style: GoogleFonts.poppins(
                          fontSize:   16,
                          fontWeight: FontWeight.w700,
                          color:      Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Links com contraste melhorado
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrabalheConoscoPage()),
                    ),
                    child: Text(
                      'Trabalhe conosco',
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
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PaginaEsqueciSenha()),
                    ),
                    child: Text(
                      'Esqueci minha senha',
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
