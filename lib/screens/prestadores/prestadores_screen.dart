import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
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

    final telefoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {'#': RegExp(r'[0-9]')},
    );

    final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##',
      filter: {'#': RegExp(r'[0-9]')},
    );

    String? telefoneError;
    String? cpfError;
    String? nomeError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Novo Prestador'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome Completo *',
                    prefixIcon: const Icon(Icons.person),
                    errorText: nomeError,
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setDialogState(() => nomeError = null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: telefoneController,
                  inputFormatters: [telefoneMask],
                  decoration: InputDecoration(
                    labelText: 'Telefone *',
                    prefixIcon: const Icon(Icons.phone),
                    hintText: '(11) 99999-9999',
                    errorText: telefoneError,
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => setDialogState(() => telefoneError = null),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cpfController,
                  inputFormatters: [cpfMask],
                  decoration: InputDecoration(
                    labelText: 'CPF',
                    prefixIcon: const Icon(Icons.badge),
                    hintText: '000.000.000-00',
                    errorText: cpfError,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setDialogState(() => cpfError = null),
                ),
                const SizedBox(height: 8),
                const Text(
                  '* Campos obrigatórios',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
                bool hasError = false;

                // Validar nome
                if (nomeController.text.trim().isEmpty) {
                  setDialogState(() => nomeError = 'Nome é obrigatório');
                  hasError = true;
                } else if (nomeController.text.trim().split(' ').length < 2) {
                  setDialogState(() => nomeError = 'Digite o nome completo');
                  hasError = true;
                }

                // Validar telefone
                final telefoneDigitos = telefoneMask.getUnmaskedText();
                if (telefoneDigitos.isEmpty) {
                  setDialogState(() => telefoneError = 'Telefone é obrigatório');
                  hasError = true;
                } else if (telefoneDigitos.length < 11) {
                  setDialogState(() => telefoneError = 'Telefone incompleto (11 dígitos)');
                  hasError = true;
                }

                // Validar CPF (opcional, mas se preenchido deve ser válido)
                final cpfDigitos = cpfMask.getUnmaskedText();
                if (cpfDigitos.isNotEmpty && cpfDigitos.length < 11) {
                  setDialogState(() => cpfError = 'CPF incompleto (11 dígitos)');
                  hasError = true;
                } else if (cpfDigitos.isNotEmpty && !_validarCPF(cpfDigitos)) {
                  setDialogState(() => cpfError = 'CPF inválido');
                  hasError = true;
                }

                if (hasError) return;

                try {
                  await AdminService.addPrestador(
                    nome: nomeController.text.trim(),
                    telefone: '+55$telefoneDigitos',
                    cpf: cpfDigitos.isNotEmpty ? cpfController.text : null,
                  );
                  Navigator.pop(context);
                  _loadPrestadores();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Prestador cadastrado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao cadastrar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('CADASTRAR'),
            ),
          ],
        ),
      ),
    );
  }

  bool _validarCPF(String cpf) {
    if (cpf.length != 11) return false;

    // Verificar se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Calcular primeiro dígito verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;

    if (int.parse(cpf[9]) != digito1) return false;

    // Calcular segundo dígito verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;

    if (int.parse(cpf[10]) != digito2) return false;

    return true;
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
