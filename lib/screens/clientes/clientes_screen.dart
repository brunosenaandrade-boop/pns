import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/cep_service.dart';
import '../../core/validators.dart';

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
      _showSnackBar('Erro ao carregar clientes: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadClientes(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Barra de pesquisa
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome, telefone, CPF ou email...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onSubmitted: (value) => _loadClientes(search: value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _loadClientes(search: _searchController.text),
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        _loadClientes();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Info
            Row(
              children: [
                Text(
                  '${_clientes.length} cliente(s) encontrado(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tabela
            Expanded(
              child: Card(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _clientes.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Nenhum cliente encontrado'),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                columns: const [
                                  DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Telefone', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('CPF', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Cidade/UF', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Veículo', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Plano', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Cadastro', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _clientes.map((cliente) {
                                  final veiculo = (cliente['veiculos'] as List?)?.firstOrNull;
                                  final assinatura = (cliente['assinaturas'] as List?)?.firstOrNull;
                                  final plano = assinatura?['planos'];
                                  final cidadeUf = cliente['cidade'] != null
                                      ? '${cliente['cidade']}/${cliente['estado'] ?? ''}'
                                      : '-';

                                  return DataRow(
                                    cells: [
                                      DataCell(Text(cliente['nome_completo'] ?? '-')),
                                      DataCell(Text(cliente['telefone'] ?? '-')),
                                      DataCell(Text(cliente['email'] ?? '-')),
                                      DataCell(Text(cliente['cpf'] ?? '-')),
                                      DataCell(Text(cidadeUf)),
                                      DataCell(Text(veiculo != null
                                          ? '${veiculo['modelo']} (${veiculo['placa']})'
                                          : '-')),
                                      DataCell(Text(plano?['nome']?.toString().toUpperCase() ?? '-')),
                                      DataCell(_buildStatusChip(assinatura?['status'])),
                                      DataCell(Text(cliente['criado_em'] != null
                                          ? dateFormat.format(DateTime.parse(cliente['criado_em']))
                                          : '-')),
                                      DataCell(Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.visibility, size: 20, color: Colors.blue),
                                            onPressed: () => _showClienteDetails(cliente),
                                            tooltip: 'Ver detalhes',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 20, color: Colors.orange),
                                            onPressed: () => _editCliente(cliente),
                                            tooltip: 'Editar',
                                          ),
                                          if (assinatura?['status'] == 'ativo')
                                            IconButton(
                                              icon: const Icon(Icons.block, size: 20, color: Colors.red),
                                              onPressed: () => _bloquearCliente(assinatura['id']),
                                              tooltip: 'Bloquear por fraude',
                                            ),
                                        ],
                                      )),
                                    ],
                                  );
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
    String text = status ?? 'Sem plano';

    switch (status) {
      case 'ativo':
        color = Colors.green;
        text = 'Ativo';
        break;
      case 'em_analise':
        color = Colors.blue;
        text = 'Em análise';
        break;
      case 'pendente':
        color = Colors.orange;
        text = 'Pendente';
        break;
      case 'cancelado':
        color = Colors.red;
        text = 'Cancelado';
        break;
      case 'suspenso':
        color = Colors.purple;
        text = 'Suspenso';
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  void _showClienteDetails(Map<String, dynamic> cliente) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final veiculos = cliente['veiculos'] as List? ?? [];
    final assinaturas = cliente['assinaturas'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente['nome_completo'] ?? 'Cliente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            cliente['email'] ?? '',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dados Pessoais
                      _sectionTitle('Dados Pessoais'),
                      _detailCard([
                        _detailRow('Nome Completo', cliente['nome_completo']),
                        _detailRow('CPF', cliente['cpf']),
                        _detailRow('Telefone', cliente['telefone']),
                        _detailRow('Email', cliente['email']),
                        _detailRow('LGPD Aceito', cliente['aceite_lgpd'] == true ? 'Sim' : 'Não'),
                        _detailRow('Cadastrado em', cliente['criado_em'] != null
                            ? dateFormat.format(DateTime.parse(cliente['criado_em']))
                            : null),
                      ]),

                      const SizedBox(height: 16),

                      // Endereço
                      _sectionTitle('Endereço'),
                      _detailCard([
                        _detailRow('CEP', cliente['cep']),
                        _detailRow('Logradouro', cliente['endereco']),
                        _detailRow('Número', cliente['numero']),
                        _detailRow('Complemento', cliente['complemento']),
                        _detailRow('Bairro', cliente['bairro']),
                        _detailRow('Cidade', cliente['cidade']),
                        _detailRow('Estado', cliente['estado']),
                      ]),

                      const SizedBox(height: 16),

                      // Veículos
                      _sectionTitle('Veículos (${veiculos.length})'),
                      if (veiculos.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhum veículo cadastrado'),
                          ),
                        )
                      else
                        ...veiculos.map((v) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              v['tipo'] == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                              color: Colors.blue,
                            ),
                            title: Text('${v['modelo']}'),
                            subtitle: Text('Placa: ${v['placa']} | Estepe: ${v['possui_estepe'] == true ? 'Sim' : 'Não'}'),
                            trailing: v['ativo'] == true
                                ? const Chip(label: Text('Ativo'), backgroundColor: Colors.green)
                                : const Chip(label: Text('Inativo'), backgroundColor: Colors.grey),
                          ),
                        )),

                      const SizedBox(height: 16),

                      // Assinaturas
                      _sectionTitle('Assinaturas (${assinaturas.length})'),
                      if (assinaturas.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma assinatura'),
                          ),
                        )
                      else
                        ...assinaturas.map((a) {
                          final plano = a['planos'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Plano ${plano?['nome']?.toString().toUpperCase() ?? 'N/A'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      _buildStatusChip(a['status']),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Preço: R\$ ${plano?['preco']?.toStringAsFixed(2) ?? '0.00'}/mês'),
                                  Text('Acionamentos: ${a['acionamentos_usados'] ?? 0}/${plano?['acionamentos_mes'] ?? 0}'),
                                  Text('Câmaras: ${a['camaras_usadas'] ?? 0}/${plano?['camaras_mes'] ?? 0}'),
                                  if (a['data_inicio'] != null)
                                    Text('Início: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(a['data_inicio']))}'),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editCliente(cliente);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('FECHAR'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _detailCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _editCliente(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (context) => _EditClienteDialog(
        cliente: cliente,
        onSaved: () {
          _loadClientes();
          _showSnackBar('Cliente atualizado com sucesso!');
        },
      ),
    );
  }

  void _bloquearCliente(String assinaturaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Bloquear Cliente'),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja bloquear este cliente por fraude?\n\n'
          'A assinatura será cancelada imediatamente e o cliente não poderá mais usar o serviço.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('BLOQUEAR'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AdminService.bloquearCliente(assinaturaId);
        _loadClientes();
        _showSnackBar('Cliente bloqueado com sucesso');
      } catch (e) {
        _showSnackBar('Erro ao bloquear cliente: $e', isError: true);
      }
    }
  }
}

// Dialog de Edição de Cliente
class _EditClienteDialog extends StatefulWidget {
  final Map<String, dynamic> cliente;
  final VoidCallback onSaved;

  const _EditClienteDialog({
    required this.cliente,
    required this.onSaved,
  });

  @override
  State<_EditClienteDialog> createState() => _EditClienteDialogState();
}

class _EditClienteDialogState extends State<_EditClienteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _cepController;
  late final TextEditingController _enderecoController;
  late final TextEditingController _numeroController;
  late final TextEditingController _complementoController;
  late final TextEditingController _bairroController;
  late final TextEditingController _cidadeController;
  String? _estado;
  bool _isLoading = false;
  bool _isBuscandoCep = false;

  final List<String> _estados = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
    'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
    'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.cliente['nome_completo']);
    _telefoneController = TextEditingController(text: widget.cliente['telefone']);
    _cpfController = TextEditingController(text: widget.cliente['cpf']);
    _emailController = TextEditingController(text: widget.cliente['email']);
    _cepController = TextEditingController(text: widget.cliente['cep']);
    _enderecoController = TextEditingController(text: widget.cliente['endereco']);
    _numeroController = TextEditingController(text: widget.cliente['numero']);
    _complementoController = TextEditingController(text: widget.cliente['complemento']);
    _bairroController = TextEditingController(text: widget.cliente['bairro']);
    _cidadeController = TextEditingController(text: widget.cliente['cidade']);
    _estado = widget.cliente['estado'];
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _enderecoController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    super.dispose();
  }

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CEP deve ter 8 dígitos'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isBuscandoCep = true);

    try {
      final resultado = await CepService.buscarCep(cep);
      if (resultado != null) {
        setState(() {
          _enderecoController.text = resultado['logradouro'] ?? '';
          _bairroController.text = resultado['bairro'] ?? '';
          _cidadeController.text = resultado['localidade'] ?? '';
          _estado = resultado['uf'];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CEP não encontrado'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar CEP: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isBuscandoCep = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AdminService.updateCliente(
        id: widget.cliente['id'],
        nomeCompleto: _nomeController.text,
        telefone: _telefoneController.text,
        cpf: _cpfController.text,
        email: _emailController.text,
        cep: _cepController.text,
        endereco: _enderecoController.text,
        numero: _numeroController.text,
        complemento: _complementoController.text,
        bairro: _bairroController.text,
        cidade: _cidadeController.text,
        estado: _estado,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Editar Cliente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dados Pessoais
                      const Text(
                        'Dados Pessoais',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo *',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validateFullName,
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cpfController,
                              decoration: const InputDecoration(
                                labelText: 'CPF',
                                prefixIcon: Icon(Icons.badge),
                                border: OutlineInputBorder(),
                              ),
                              validator: Validators.validateCPF,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _telefoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone *',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: Validators.validatePhone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: Validators.validateEmail,
                      ),

                      const SizedBox(height: 24),

                      // Endereço
                      const Text(
                        'Endereço',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextFormField(
                              controller: _cepController,
                              decoration: const InputDecoration(
                                labelText: 'CEP',
                                prefixIcon: Icon(Icons.location_on),
                                border: OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) => _buscarCep(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isBuscandoCep ? null : _buscarCep,
                            icon: _isBuscandoCep
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: const Text('Buscar CEP'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _enderecoController,
                              decoration: const InputDecoration(
                                labelText: 'Logradouro',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _numeroController,
                              decoration: const InputDecoration(
                                labelText: 'Número',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _complementoController,
                        decoration: const InputDecoration(
                          labelText: 'Complemento',
                          border: OutlineInputBorder(),
                          hintText: 'Apto, Bloco, etc.',
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bairroController,
                              decoration: const InputDecoration(
                                labelText: 'Bairro',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cidadeController,
                              decoration: const InputDecoration(
                                labelText: 'Cidade',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: DropdownButtonFormField<String>(
                              value: _estado,
                              decoration: const InputDecoration(
                                labelText: 'UF',
                                border: OutlineInputBorder(),
                              ),
                              items: _estados.map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              )).toList(),
                              onChanged: (v) => setState(() => _estado = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _salvar,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: const Text('SALVAR'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
