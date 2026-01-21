import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class ChamadosScreen extends StatefulWidget {
  const ChamadosScreen({super.key});

  @override
  State<ChamadosScreen> createState() => _ChamadosScreenState();
}

class _ChamadosScreenState extends State<ChamadosScreen> {
  List<Map<String, dynamic>> _chamados = [];
  bool _isLoading = true;
  String? _statusFilter;

  final _statusOptions = [
    {'value': null, 'label': 'Todos'},
    {'value': 'aguardando', 'label': 'Aguardando'},
    {'value': 'aceito', 'label': 'Aceito'},
    {'value': 'em_rota', 'label': 'Em Rota'},
    {'value': 'em_atendimento', 'label': 'Em Atendimento'},
    {'value': 'finalizado', 'label': 'Finalizado'},
    {'value': 'cancelado', 'label': 'Cancelado'},
  ];

  @override
  void initState() {
    super.initState();
    _loadChamados();
  }

  Future<void> _loadChamados() async {
    setState(() => _isLoading = true);
    try {
      final chamados = await AdminService.getChamados(status: _statusFilter);
      setState(() {
        _chamados = chamados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar chamados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChamados,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Filtros
            Row(
              children: [
                const Text('Filtrar por status: '),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  value: _statusFilter,
                  items: _statusOptions
                      .map((s) => DropdownMenuItem(
                            value: s['value'] as String?,
                            child: Text(s['label'] as String),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                    _loadChamados();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tabela
            Expanded(
              child: Card(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _chamados.isEmpty
                        ? const Center(child: Text('Nenhum chamado encontrado'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Data')),
                                  DataColumn(label: Text('Cliente')),
                                  DataColumn(label: Text('Prestador')),
                                  DataColumn(label: Text('Serviço')),
                                  DataColumn(label: Text('Endereço')),
                                  DataColumn(label: Text('Status')),
                                  DataColumn(label: Text('Avaliação')),
                                ],
                                rows: _chamados.map((chamado) {
                                  return DataRow(cells: [
                                    DataCell(Text(chamado['criado_em'] != null
                                        ? dateFormat.format(DateTime.parse(chamado['criado_em']))
                                        : '-')),
                                    DataCell(Text(chamado['usuarios']?['nome_completo'] ?? '-')),
                                    DataCell(Text(chamado['prestadores']?['nome_completo'] ?? 'Aguardando')),
                                    DataCell(Text((chamado['tipo_servico'] ?? '-')
                                        .toString()
                                        .replaceAll('_', ' '))),
                                    DataCell(Container(
                                      constraints: const BoxConstraints(maxWidth: 200),
                                      child: Text(
                                        chamado['endereco_cliente'] ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                                    DataCell(_buildStatusChip(chamado['status'])),
                                    DataCell(chamado['avaliacao_cliente'] != null
                                        ? Row(
                                            children: List.generate(5, (i) {
                                              return Icon(
                                                i < (chamado['avaliacao_cliente'] as int)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              );
                                            }),
                                          )
                                        : const Text('-')),
                                  ]);
                                }).toList(),
                              ),
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
    String text = status ?? '-';

    switch (status) {
      case 'aguardando':
        color = Colors.orange;
        break;
      case 'aceito':
      case 'em_rota':
        color = Colors.blue;
        text = status == 'em_rota' ? 'Em rota' : 'Aceito';
        break;
      case 'chegou':
      case 'em_atendimento':
        color = Colors.purple;
        text = status == 'em_atendimento' ? 'Atendendo' : 'Chegou';
        break;
      case 'finalizado':
        color = Colors.green;
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
}
