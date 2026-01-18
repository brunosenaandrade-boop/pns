import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({super.key});

  @override
  State<PagamentosScreen> createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  List<Map<String, dynamic>> _pagamentos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPagamentos();
  }

  Future<void> _loadPagamentos() async {
    setState(() => _isLoading = true);
    try {
      final pagamentos = await AdminService.getPagamentosPendentes();
      setState(() {
        _pagamentos = pagamentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamentos Pendentes (Pix)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPagamentos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _pagamentos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum pagamento pendente!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _pagamentos.length,
                    itemBuilder: (context, index) {
                      final pagamento = _pagamentos[index];
                      final assinatura = pagamento['assinaturas'];
                      final usuario = assinatura?['usuarios'];
                      final plano = assinatura?['planos'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                    child: const Icon(Icons.pix, color: Colors.orange),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          usuario?['nome_completo'] ?? 'Cliente',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          usuario?['telefone'] ?? '',
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        currencyFormat.format(pagamento['valor'] ?? 0),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Text(
                                        'Plano ${plano?['nome']?.toString().toUpperCase() ?? ''}',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Divider(height: 32),

                              // Detalhes
                              Row(
                                children: [
                                  _infoItem('CPF', usuario?['cpf'] ?? '-'),
                                  const SizedBox(width: 32),
                                  _infoItem(
                                    'Data',
                                    pagamento['criado_em'] != null
                                        ? dateFormat.format(DateTime.parse(pagamento['criado_em']))
                                        : '-',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Comprovante
                              if (pagamento['comprovante_url'] != null)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    // Abrir comprovante
                                  },
                                  icon: const Icon(Icons.receipt),
                                  label: const Text('Ver Comprovante'),
                                ),

                              const SizedBox(height: 20),

                              // Ações
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _rejeitarPagamento(pagamento['id']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('REJEITAR'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: () => _aprovarPagamento(
                                      pagamento['id'],
                                      assinatura['id'],
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text('APROVAR'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _aprovarPagamento(String pagamentoId, String assinaturaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprovar Pagamento'),
        content: const Text(
          'Confirma a aprovação deste pagamento? '
          'A assinatura será ativada imediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('APROVAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminService.aprovarPagamento(pagamentoId, assinaturaId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento aprovado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPagamentos();
    }
  }

  void _rejeitarPagamento(String pagamentoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeitar Pagamento'),
        content: const Text('Confirma a rejeição deste pagamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REJEITAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminService.rejeitarPagamento(pagamentoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento rejeitado'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadPagamentos();
    }
  }
}
