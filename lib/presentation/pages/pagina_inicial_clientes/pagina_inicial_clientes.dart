import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/session_store.dart';
import '../../../services/api_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/floating_cart.dart';
import '../../widgets/shimmer_card.dart';

final GlobalKey<ScaffoldMessengerState> contextGlobal =
    GlobalKey<ScaffoldMessengerState>();

class PaginaInicialClientes extends StatefulWidget {
  const PaginaInicialClientes({super.key});

  @override
  State<PaginaInicialClientes> createState() => _PaginaInicialClientesState();
}

class _PaginaInicialClientesState extends State<PaginaInicialClientes> {
  final PageController _bannerController = PageController();
  int _bannerAtual = 0;
  int _tabIndex = 0;
  Timer? _bannerTimer;
  bool _carregando = true;
  bool _erroApi = false;
  List<Map<String, dynamic>> _produtos = [];

  // Abas de filtro por categoria
  static const List<String> _categorias = [
    'Todos', 'Lanches', 'Almoços', 'Sobremesas', 'Pizzas', 'Bebidas',
  ];
  int _categoriaIndex = 0;

  static const int _totalBanners = 3;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
    // Auto-play do banner a cada 5 segundos
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_bannerAtual + 1) % _totalBanners;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _carregarProdutos({String? categoria}) async {
    setState(() { _carregando = true; _erroApi = false; });
    try {
      final lista = await ApiService.getProdutosPublico(
        categoria: (categoria == null || categoria == 'Todos') ? null : categoria,
      );
      if (!mounted) return;
      setState(() { _produtos = lista; _carregando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _erroApi = true; _carregando = false; });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final cat = _categorias[_categoriaIndex];
    await _carregarProdutos(categoria: cat == 'Todos' ? null : cat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Campo de busca ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 4,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  child: TextField(
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar produtos ou lojas...',
                      hintStyle: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Banner rotativo ─────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView(
                        controller: _bannerController,
                        onPageChanged: (i) =>
                            setState(() => _bannerAtual = i),
                        children: const [
                          _BannerItem('assets/banner.png',
                              'Peça Agora no Smarty Entregas'),
                          _BannerItem('assets/banner2.png',
                              'Entrega Rápida em Mallet!'),
                          _BannerItem('assets/banner3.png',
                              'Promoções Imperdíveis!'),
                        ],
                      ),
                      // Dots pill animados
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_totalBanners, (i) {
                            final ativo = _bannerAtual == i;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              width: ativo ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: ativo
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Abas de filtro por categoria ────────────────
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categorias.length,
                  itemBuilder: (_, i) {
                    final selecionado = _categoriaIndex == i;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _categoriaIndex = i);
                        _carregarProdutos(
                          categoria: _categorias[i] == 'Todos'
                              ? null
                              : _categorias[i],
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selecionado
                              ? const Color(0xFF1A1A1A)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: selecionado
                              ? null
                              : Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                        ),
                        child: Text(
                          _categorias[i],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: selecionado
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selecionado
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Produtos filtrados pela aba ──────────────────
              _TituloSecao(titulo: 'Produtos disponíveis'),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: _carregando
                    ? ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        children: const [
                          ShimmerCard(),
                          ShimmerCard(),
                          ShimmerCard(),
                        ],
                      )
                    : _erroApi
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.wifi_off,
                                      color: AppColors.textSecondary, size: 36),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Não foi possível carregar os produtos.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton.icon(
                                    onPressed: () => _carregarProdutos(
                                      categoria:
                                          _categorias[_categoriaIndex] == 'Todos'
                                              ? null
                                              : _categorias[_categoriaIndex],
                                    ),
                                    icon: const Icon(Icons.refresh,
                                        color: AppColors.primary),
                                    label: Text('Tentar novamente',
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _produtos.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.search_off,
                                          color: AppColors.textSecondary,
                                          size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nenhum produto encontrado\nnesta categoria.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                scrollDirection: Axis.horizontal,
                                itemCount: _produtos.length,
                                itemBuilder: (_, i) {
                                  final p = _produtos[i];
                                  final precoRaw = p['preco'];
                                  final precoNum = precoRaw is num
                                      ? precoRaw.toDouble()
                                      : double.tryParse(
                                              precoRaw?.toString() ?? '') ??
                                          0.0;
                                  final precoStr =
                                      'R\$ ${precoNum.toStringAsFixed(2).replaceAll('.', ',')}';
                                  return ProductCard(
                                    nome: p['nome']?.toString() ?? '',
                                    preco: precoStr,
                                    imgPath: '',
                                    restaurante: p['empresa_nome']?.toString(),
                                    nota: 4.5,
                                    tempoEntrega: '25-40 min',
                                    entregaGratis: true,
                                  );
                                },
                              ),
              ),
              const SizedBox(height: 24),

              // ── Cupons e Entregas Grátis ────────────────────
              _TituloSecao(titulo: 'Cupons e Entregas Grátis'),
              const SizedBox(height: 12),
              SizedBox(
                height: 90,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _CupomCard(
                      texto: 'R\$ 10 OFF\nno 1º pedido',
                      icone: Icons.local_offer_outlined,
                      cores: [Color(0xFFF5841F), Color(0xFFFFC107)],
                    ),
                    _CupomCard(
                      texto: 'Entrega\nGrátis',
                      icone: Icons.delivery_dining_outlined,
                      cores: [Color(0xFF4CAF50), Color(0xFF81C784)],
                    ),
                    _CupomCard(
                      texto: '20% OFF\nem pizzas',
                      icone: Icons.local_pizza_outlined,
                      cores: [Color(0xFFE53935), Color(0xFFEF9A9A)],
                    ),
                    _CupomCard(
                      texto: 'Frete\nR\$ 1,99',
                      icone: Icons.two_wheeler_outlined,
                      cores: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Faixa de boas-vindas ────────────────────────
              _BemVindo(),

              const SizedBox(height: 80), // espaço para o FAB
            ],
          ),
        ),
      ),
      floatingActionButton: const FloatingCart(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── APP BAR ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: const Color(0x1A000000),
      backgroundColor: AppColors.surface,
      titleSpacing: 16,
      title: Row(
        children: [
          // Logo circular
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/logo.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delivery_dining,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Localização
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on,
                      color: AppColors.primary, size: 13),
                  SizedBox(width: 2),
                  Text(
                    'Entregar em',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: const [
                  Text(
                    'Mallet - PR',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down,
                      color: AppColors.primary, size: 18),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textPrimary, size: 26),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: AppColors.divider, height: 1),
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const icons = [
      [Icons.home_outlined, Icons.home],
      [Icons.search_outlined, Icons.search],
      [Icons.receipt_long_outlined, Icons.receipt_long],
      [Icons.person_outline, Icons.person],
    ];
    const labels = ['Início', 'Busca', 'Pedidos', 'Perfil'];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        backgroundColor: AppColors.surface,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.disabled,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: List.generate(4, (i) {
          final ativo = _tabIndex == i;
          return BottomNavigationBarItem(
            icon: Icon(ativo ? icons[i][1] : icons[i][0]),
            label: labels[i],
          );
        }),
      ),
    );
  }

}

// ══════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES
// ══════════════════════════════════════════════════════════════════

/// Faixa de boas-vindas com e-mail do usuário logado
class _BemVindo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final email = SessionStore.email;
    if (email == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Bem-vindo, $email!',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Cabeçalho de seção com título e "Ver mais"
class _TituloSecao extends StatelessWidget {
  final String titulo;
  const _TituloSecao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          Text(
            'Ver mais',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Card de cupom com gradiente
class _CupomCard extends StatelessWidget {
  final String texto;
  final IconData icone;
  final List<Color> cores;

  const _CupomCard({
    required this.texto,
    required this.icone,
    required this.cores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cores,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cores.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(icone, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Usar',
                style: GoogleFonts.poppins(
                  color: cores.first,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner do carrossel — mostra imagem ou gradiente como fallback
class _BannerItem extends StatelessWidget {
  final String imgPath;
  final String fallbackText;
  const _BannerItem(this.imgPath, this.fallbackText);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        imgPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Center(
            child: Text(
              fallbackText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
