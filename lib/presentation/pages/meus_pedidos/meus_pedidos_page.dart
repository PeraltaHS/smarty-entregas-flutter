import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../data/session_store.dart';

const Color _laranja = Color(0xFFF5841F);

class MeusPedidosPage extends StatefulWidget {
  const MeusPedidosPage({super.key});

  @override
  State<MeusPedidosPage> createState() => _MeusPedidosPageState();
}

class _MeusPedidosPageState extends State<MeusPedidosPage> {
  List<Map<String, dynamic>> _pedidos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final idUsuario = SessionStore.idUsuario;
    if (idUsuario == null) {
      setState(() {
        _loading = false;
        _erro = 'Usuário não autenticado.';
      });
      return;
    }
    final lista = await ApiService.getPedidosByCliente(idUsuario);
    if (mounted) {
      setState(() {
        _pedidos = lista;
        _loading = false;
      });
    }
  }

  Color _corStatus(int idStatus) {
    switch (idStatus) {
      case 1: return Colors.grey;
      case 2: return Colors.orange;
      case 3: return Colors.blue;
      case 4: return const Color(0xFF4CAF50);
      case 5: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _iconeStatus(int idStatus) {
    switch (idStatus) {
      case 1: return Icons.access_time;
      case 2: return Icons.local_fire_department;
      case 3: return Icons.delivery_dining;
      case 4: return Icons.check_circle;
      case 5: return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: _laranja,
        elevation: 0,
        title: const Text(
          'Meus Pedidos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _laranja))
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _carregar,
                        style: ElevatedButton.styleFrom(backgroundColor: _laranja),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _pedidos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum pedido ainda',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Faça seu primeiro pedido!',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      color: _laranja,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pedidos.length,
                        itemBuilder: (_, i) => _CardPedido(
                          pedido: _pedidos[i],
                          corStatus: _corStatus,
                          iconeStatus: _iconeStatus,
                        ),
                      ),
                    ),
    );
  }
}

class _CardPedido extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final Color Function(int) corStatus;
  final IconData Function(int) iconeStatus;

  const _CardPedido({
    required this.pedido,
    required this.corStatus,
    required this.iconeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final idStatus = pedido['id_status'] is int
        ? pedido['id_status'] as int
        : int.tryParse(pedido['id_status']?.toString() ?? '') ?? 1;
    final status     = pedido['status']?.toString() ?? '';
    final empresa    = pedido['empresa']?.toString() ?? '';
    final totalRaw   = pedido['valor_total'];
    final total      = totalRaw is num
        ? totalRaw.toDouble()
        : double.tryParse(totalRaw?.toString() ?? '') ?? 0.0;
    final criadoEm   = pedido['criado_em']?.toString() ?? '';
    final idPedido   = pedido['id_pedido'];

    // Formata data
    String dataFormatada = '';
    try {
      final dt = DateTime.parse(criadoEm);
      dataFormatada =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      dataFormatada = criadoEm;
    }

    // Itens
    final itensRaw = pedido['itens'];
    List<Map<String, dynamic>> itens = [];
    if (itensRaw is List) {
      itens = itensRaw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final cor = corStatus(idStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(iconeStatus(idStatus), color: cor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    status,
                    style: TextStyle(
                      color: cor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$idPedido',
                    style: TextStyle(
                      color: cor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      empresa,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Itens
                if (itens.isNotEmpty) ...[
                  ...itens.take(3).map((item) {
                    final nomeItem = item['nome']?.toString() ?? '';
                    final qtd      = item['quantidade'] is int
                        ? item['quantidade'] as int
                        : int.tryParse(item['quantidade']?.toString() ?? '') ?? 1;
                    final precoUnit = item['preco_unit'] is num
                        ? (item['preco_unit'] as num).toDouble()
                        : double.tryParse(item['preco_unit']?.toString() ?? '') ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: _laranja.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '$qtd',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _laranja,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nomeItem,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            'R\$ ${(precoUnit * qtd).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (itens.length > 3)
                    Text(
                      '+${itens.length - 3} item(s)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                ],
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dataFormatada,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      'R\$ ${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
