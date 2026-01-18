import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  List<Map<String, dynamic>> _clientes = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final clientes = await AdminService.getClientes(search: search);
      setState(() {
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Barra de pesquisa
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome, telefone ou CPF...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onSubmitted: (value) => _loadClientes(search: value),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _loadClientes(search: _searchController.text),
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabela
            Expanded(
              child: Card(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _clientes.isEmpty
                        ? const Center(child: Text('Nenhum cliente encontrado'))
                        : SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Telefone')),
                                DataColumn(label: Text('CPF')),
                                DataColumn(label: Text('Veículo')),
                                DataColumn(label: Text('Plano')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Cadastro')),
                                DataColumn(label: Text('Ações')),
                              ],
                              rows: _clientes.map((cliente) {
                                final veiculo = (cliente['veiculos'] as List?)?.firstOrNull;
                                final assinatura = (cliente['assinaturas'] as List?)?.firstOrNull;
                                final plano = assinatura?['planos'];

                                return DataRow(cells: [
                                  DataCell(Text(cliente['nome_completo'] ?? '-')),
                                  DataCell(Text(cliente['telefone'] ?? '-')),
                                  DataCell(Text(cliente['cpf'] ?? '-')),
                                  DataCell(Text(veiculo != null
                                      ? '${veiculo['modelo']} (${veiculo['placa']})'
                                      : '-')),
                                  DataCell(Text(plano?['nome']?.toString().toUpperCase() ?? '-')),
                                  DataCell(_buildStatusChip(assinatura?['status'])),
                                  DataCell(Text(cliente['criado_em'] != null
                                      ? dateFormat.format(DateTime.parse(cliente['criado_em']))
                                      : '-')),
                                  DataCell(Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility, size: 20),
                                        onPressed: () => _showClienteDetails(cliente),
                                        tooltip: 'Ver detalhes',
                                      ),
                                      if (assinatura?['status'] == 'ativo')
                                        IconButton(
                                          icon: const Icon(Icons.block, size: 20, color: Colors.red),
                                          onPressed: () => _bloquearCliente(assinatura['id']),
                                          tooltip: 'Bloquear por fraude',
                                        ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String text = status ?? 'Sem plano';

    switch (status) {
      case 'ativo':
        color = Colors.green;
        break;
      case 'em_analise':
        color = Colors.blue;
        text = 'Em análise';
        break;
      case 'pendente':
        color = Colors.orange;
        break;
      case 'cancelado':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }

  void _showClienteDetails(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cliente['nome_completo'] ?? 'Cliente'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Telefone', cliente['telefone']),
              _detailRow('CPF', cliente['cpf']),
              const Divider(),
              const Text('Veículos:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...(cliente['veiculos'] as List? ?? []).map((v) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('${v['tipo']} - ${v['modelo']} (${v['placa']})'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FECHAR'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value ?? '-'),
        ],
      ),
    );
  }

  void _bloquearCliente(String assinaturaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bloquear Cliente'),
        content: const Text(
          'Tem certeza que deseja bloquear este cliente por fraude? '
          'A assinatura será cancelada imediatamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('BLOQUEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminService.bloquearCliente(assinaturaId);
      _loadClientes();
    }
  }
}
