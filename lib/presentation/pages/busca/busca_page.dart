import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../cardapio_empresa/cardapio_empresa_page.dart';

const Color _laranja = Color(0xFFF5841F);

class BuscaPage extends StatefulWidget {
  const BuscaPage({super.key});

  @override
  State<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends State<BuscaPage> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _resultados = [];
  bool _loading = false;
  bool _pesquisou = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _buscar(String termo) async {
    if (termo.trim().isEmpty) {
      setState(() {
        _resultados = [];
        _pesquisou = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _pesquisou = true;
    });
    final r = await ApiService.buscarProdutos(termo.trim());
    if (mounted) {
      setState(() {
        _resultados = r;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _laranja,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _ctrl,
            autofocus: false,
            textInputAction: TextInputAction.search,
            onSubmitted: _buscar,
            onChanged: (v) {
              if (v.isEmpty) {
                setState(() {
                  _resultados = [];
                  _pesquisou = false;
                });
              }
            },
            decoration: InputDecoration(
              hintText: 'Buscar produtos ou lojas...',
              hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: _laranja, size: 20),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() {
                          _resultados = [];
                          _pesquisou = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _buscar(_ctrl.text),
            child: const Text(
              'Buscar',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _laranja))
          : !_pesquisou
              ? _TelaInicial()
              : _resultados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              size: 72, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum resultado para "${_ctrl.text}"',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tente outro termo de busca',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _resultados.length,
                      itemBuilder: (_, i) {
                        final empresa = _resultados[i];
                        return _CardEmpresaBusca(
                          empresa: empresa,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CardapioEmpresaPage(empresa: empresa),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _TelaInicial extends StatelessWidget {
  final List<String> _sugestoes = const [
    'Pizza', 'Hamburguer', 'Almoço', 'Bebidas', 'Sobremesa', 'Salgados',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sugestões de busca',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sugestoes.map((s) {
              return ActionChip(
                label: Text(s),
                backgroundColor: _laranja.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: _laranja),
                onPressed: () {
                  final state = context.findAncestorStateOfType<_BuscaPageState>();
                  if (state != null) {
                    state._ctrl.text = s;
                    state._buscar(s);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CardEmpresaBusca extends StatelessWidget {
  final Map<String, dynamic> empresa;
  final VoidCallback onTap;

  const _CardEmpresaBusca({required this.empresa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nome = empresa['nome']?.toString() ?? '';
    final produtos =
        List<Map<String, dynamic>>.from(empresa['produtos'] as List? ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF5841F), Color(0xFFFFC107)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Center(
                child: Text(
                  nome,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            // Produtos encontrados
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${produtos.length} produto(s) encontrado(s)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...produtos.take(3).map((p) {
                    final precoRaw = p['preco'];
                    final preco = precoRaw is num
                        ? precoRaw.toDouble()
                        : double.tryParse(precoRaw?.toString() ?? '') ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.fastfood,
                              size: 16, color: _laranja),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p['nome']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'R\$ ${preco.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (produtos.length > 3)
                    Text(
                      '+${produtos.length - 3} mais...',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Ver cardápio →',
                      style: TextStyle(
                        color: _laranja,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
