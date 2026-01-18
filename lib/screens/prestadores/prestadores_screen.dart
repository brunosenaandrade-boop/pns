import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class PrestadoresScreen extends StatefulWidget {
  const PrestadoresScreen({super.key});

  @override
  State<PrestadoresScreen> createState() => _PrestadoresScreenState();
}

class _PrestadoresScreenState extends State<PrestadoresScreen> {
  List<Map<String, dynamic>> _prestadores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrestadores();
  }

  Future<void> _loadPrestadores() async {
    setState(() => _isLoading = true);
    try {
      final prestadores = await AdminService.getPrestadores();
      setState(() {
        _prestadores = prestadores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddPrestadorDialog() {
    final nomeController = TextEditingController();
    final telefoneController = TextEditingController();
    final cpfController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Prestador'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone (com DDD)',
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+5511999999999',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cpfController,
                decoration: const InputDecoration(
                  labelText: 'CPF',
                  prefixIcon: Icon(Icons.badge),
                  hintText: '000.000.000-00',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isEmpty || telefoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preencha nome e telefone')),
                );
                return;
              }

              try {
                await AdminService.addPrestador(
                  nome: nomeController.text,
                  telefone: telefoneController.text,
                  cpf: cpfController.text,
                );
                Navigator.pop(context);
                _loadPrestadores();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prestador cadastrado com sucesso!')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('CADASTRAR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestadores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPrestadores,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPrestadorDialog,
        icon: const Icon(Icons.add),
        label: const Text('Novo Prestador'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _prestadores.isEmpty
                  ? const Center(child: Text('Nenhum prestador cadastrado'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Nome')),
                          DataColumn(label: Text('Telefone')),
                          DataColumn(label: Text('CPF')),
                          DataColumn(label: Text('Avaliação')),
                          DataColumn(label: Text('Atendimentos')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Online')),
                          DataColumn(label: Text('Ações')),
                        ],
                        rows: _prestadores.map((prestador) {
                          return DataRow(cells: [
                            DataCell(Text(prestador['nome_completo'] ?? '-')),
                            DataCell(Text(prestador['telefone'] ?? '-')),
                            DataCell(Text(prestador['cpf'] ?? '-')),
                            DataCell(Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text((prestador['avaliacao_media'] ?? 0).toStringAsFixed(1)),
                              ],
                            )),
                            DataCell(Text('${prestador['total_atendimentos'] ?? 0}')),
                            DataCell(_buildStatusChip(prestador['ativo'] == true)),
                            DataCell(_buildOnlineChip(prestador['disponivel'] == true)),
                            DataCell(Row(
                              children: [
                                Switch(
                                  value: prestador['ativo'] == true,
                                  onChanged: (value) => _toggleAtivo(prestador['id'], value),
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool ativo) {
    return Chip(
      label: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: ativo ? Colors.green : Colors.red,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildOnlineChip(bool online) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: online ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(online ? 'Online' : 'Offline'),
      ],
    );
  }

  void _toggleAtivo(String id, bool ativo) async {
    await AdminService.togglePrestadorAtivo(id, ativo);
    _loadPrestadores();
  }
}
