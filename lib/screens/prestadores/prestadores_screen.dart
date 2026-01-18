import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PrestadorFormDialog(
        onSaved: () {
          _loadPrestadores();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prestador cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showEditPrestadorDialog(Map<String, dynamic> prestador) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PrestadorFormDialog(
        prestador: prestador,
        onSaved: () {
          _loadPrestadores();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prestador atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Telefone')),
                            DataColumn(label: Text('Cidade')),
                            DataColumn(label: Text('Atende')),
                            DataColumn(label: Text('Avaliacao')),
                            DataColumn(label: Text('Atendimentos')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Online')),
                            DataColumn(label: Text('Acoes')),
                          ],
                          rows: _prestadores.map((prestador) {
                            return DataRow(cells: [
                              DataCell(Text(prestador['nome_completo'] ?? '-')),
                              DataCell(Text(_formatPhone(prestador['telefone']))),
                              DataCell(Text(prestador['cidade'] ?? '-')),
                              DataCell(_buildAtendeChips(prestador)),
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
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    tooltip: 'Editar',
                                    onPressed: () => _showEditPrestadorDialog(prestador),
                                  ),
                                  Switch(
                                    value: prestador['ativo'] == true,
                                    onChanged: (value) => _toggleAtivo(prestador['id'], value),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: 'Excluir',
                                    onPressed: () => _confirmarExclusao(prestador),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  String _formatPhone(String? phone) {
    if (phone == null) return '-';
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 13) {
      return '(${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
    }
    return phone;
  }

  Widget _buildAtendeChips(Map<String, dynamic> prestador) {
    final atendeMoto = prestador['atende_moto'] ?? true;
    final atendeCarro = prestador['atende_carro'] ?? true;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (atendeMoto)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Moto', style: TextStyle(fontSize: 11)),
          ),
        if (atendeCarro)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Carro', style: TextStyle(fontSize: 11)),
          ),
      ],
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

  void _confirmarExclusao(Map<String, dynamic> prestador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tem certeza que deseja excluir este prestador?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prestador['nome_completo'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Tel: ${prestador['telefone'] ?? '-'}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acao nao pode ser desfeita!',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminService.deletePrestador(prestador['id']);
                _loadPrestadores();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prestador excluido com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('EXCLUIR'),
          ),
        ],
      ),
    );
  }
}

// Dialog de formulario do prestador
class _PrestadorFormDialog extends StatefulWidget {
  final Map<String, dynamic>? prestador;
  final VoidCallback onSaved;

  const _PrestadorFormDialog({
    this.prestador,
    required this.onSaved,
  });

  @override
  State<_PrestadorFormDialog> createState() => _PrestadorFormDialogState();
}

class _PrestadorFormDialogState extends State<_PrestadorFormDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers - Dados Pessoais
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _dataNascController = TextEditingController();

  // Controllers - Endereco
  final _cepController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  String _estado = '';

  // Controllers - Trabalho
  bool _atendeMoto = true;
  bool _atendeCarro = true;
  final _raioController = TextEditingController(text: '10');

  // Controllers - Pagamento
  String _pixTipo = '';
  final _pixChaveController = TextEditingController();

  // Controllers - Documentos
  final _cnhNumeroController = TextEditingController();
  final _cnhValidadeController = TextEditingController();

  // Controllers - Observacoes
  final _observacoesController = TextEditingController();

  // Masks
  final _telefoneMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _cepMask = MaskTextInputFormatter(
    mask: '#####-###',
    filter: {'#': RegExp(r'[0-9]')},
  );
  final _dataMask = MaskTextInputFormatter(
    mask: '##/##/####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool get isEditing => widget.prestador != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    if (isEditing) {
      _loadPrestadorData();
    }
  }

  void _loadPrestadorData() {
    final p = widget.prestador!;

    _nomeController.text = p['nome_completo'] ?? '';

    // Formatar telefone
    final tel = (p['telefone'] ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (tel.length >= 11) {
      final digits = tel.length > 11 ? tel.substring(tel.length - 11) : tel;
      _telefoneController.text = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }

    _cpfController.text = p['cpf'] ?? '';
    _emailController.text = p['email'] ?? '';

    if (p['data_nascimento'] != null) {
      final date = DateTime.tryParse(p['data_nascimento']);
      if (date != null) {
        _dataNascController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }

    _cepController.text = p['cep'] ?? '';
    _enderecoController.text = p['endereco'] ?? '';
    _numeroController.text = p['numero'] ?? '';
    _complementoController.text = p['complemento'] ?? '';
    _bairroController.text = p['bairro'] ?? '';
    _cidadeController.text = p['cidade'] ?? '';
    _estado = p['estado'] ?? '';

    _atendeMoto = p['atende_moto'] ?? true;
    _atendeCarro = p['atende_carro'] ?? true;
    _raioController.text = (p['raio_atendimento_km'] ?? 10).toString();

    _pixTipo = p['pix_tipo'] ?? '';
    _pixChaveController.text = p['pix_chave'] ?? '';

    _cnhNumeroController.text = p['cnh_numero'] ?? '';
    if (p['cnh_validade'] != null) {
      final date = DateTime.tryParse(p['cnh_validade']);
      if (date != null) {
        _cnhValidadeController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    }

    _observacoesController.text = p['observacoes'] ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _validarCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^\d]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int resto = soma % 11;
    int digito1 = resto < 2 ? 0 : 11 - resto;
    if (int.parse(cpf[9]) != digito1) return false;

    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    resto = soma % 11;
    int digito2 = resto < 2 ? 0 : 11 - resto;
    if (int.parse(cpf[10]) != digito2) return false;

    return true;
  }

  String? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    final parts = dateStr.split('/');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Future<void> _save() async {
    // Validar campos obrigatorios
    final nome = _nomeController.text.trim();
    final telefoneDigits = _telefoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (nome.isEmpty) {
      _showError('Nome e obrigatorio');
      _tabController.animateTo(0);
      return;
    }

    if (nome.split(' ').length < 2) {
      _showError('Digite o nome completo');
      _tabController.animateTo(0);
      return;
    }

    if (telefoneDigits.length < 11) {
      _showError('Telefone invalido');
      _tabController.animateTo(0);
      return;
    }

    // Email e senha obrigatorios para novo cadastro
    if (!isEditing) {
      if (email.isEmpty || !email.contains('@')) {
        _showError('Email valido e obrigatorio para login');
        _tabController.animateTo(0);
        return;
      }

      if (senha.length < 6) {
        _showError('Senha deve ter no minimo 6 caracteres');
        _tabController.animateTo(0);
        return;
      }
    }

    final cpfDigits = _cpfController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cpfDigits.isNotEmpty && !_validarCPF(cpfDigits)) {
      _showError('CPF invalido');
      _tabController.animateTo(0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'nome_completo': nome,
        'telefone': '+55$telefoneDigits',
        'cpf': cpfDigits.isNotEmpty ? _cpfController.text : null,
        'data_nascimento': _parseDate(_dataNascController.text),
        'cep': _cepController.text.isNotEmpty ? _cepController.text : null,
        'endereco': _enderecoController.text.trim().isNotEmpty ? _enderecoController.text.trim() : null,
        'numero': _numeroController.text.trim().isNotEmpty ? _numeroController.text.trim() : null,
        'complemento': _complementoController.text.trim().isNotEmpty ? _complementoController.text.trim() : null,
        'bairro': _bairroController.text.trim().isNotEmpty ? _bairroController.text.trim() : null,
        'cidade': _cidadeController.text.trim().isNotEmpty ? _cidadeController.text.trim() : null,
        'estado': _estado.isNotEmpty ? _estado : null,
        'atende_moto': _atendeMoto,
        'atende_carro': _atendeCarro,
        'raio_atendimento_km': int.tryParse(_raioController.text) ?? 10,
        'pix_tipo': _pixTipo.isNotEmpty ? _pixTipo : null,
        'pix_chave': _pixChaveController.text.trim().isNotEmpty ? _pixChaveController.text.trim() : null,
        'cnh_numero': _cnhNumeroController.text.trim().isNotEmpty ? _cnhNumeroController.text.trim() : null,
        'cnh_validade': _parseDate(_cnhValidadeController.text),
        'observacoes': _observacoesController.text.trim().isNotEmpty ? _observacoesController.text.trim() : null,
      };

      if (isEditing) {
        data['email'] = email.isNotEmpty ? email : null;
        await AdminService.updatePrestador(widget.prestador!['id'], data);
      } else {
        data['ativo'] = true;
        data['disponivel'] = false;
        data['avaliacao_media'] = 5.0;
        data['total_atendimentos'] = 0;

        // Criar usuario Auth e prestador
        await AdminService.createPrestadorWithAuth(
          email: email,
          password: senha,
          prestadorData: data,
        );
      }

      Navigator.pop(context);
      widget.onSaved();
    } catch (e) {
      _showError('Erro ao salvar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 550,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(isEditing ? Icons.edit : Icons.person_add, size: 28),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Editar Prestador' : 'Novo Prestador',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Pessoal'),
                Tab(text: 'Endereco'),
                Tab(text: 'Trabalho'),
                Tab(text: 'Pagamento'),
                Tab(text: 'Docs'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDadosPessoais(),
                  _buildEndereco(),
                  _buildTrabalho(),
                  _buildPagamento(),
                  _buildDocumentos(),
                ],
              ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCELAR'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'SALVAR' : 'CADASTRAR'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDadosPessoais() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _telefoneController,
                  inputFormatters: [_telefoneMask],
                  decoration: const InputDecoration(
                    labelText: 'Telefone *',
                    prefixIcon: Icon(Icons.phone),
                    hintText: '(11) 99999-9999',
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: isEditing ? 'Email' : 'Email * (login)',
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: isEditing ? 'Nova Senha' : 'Senha * (login)',
                    prefixIcon: const Icon(Icons.lock),
                    hintText: isEditing ? 'Deixe vazio para manter' : 'Min. 6 caracteres',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cpfController,
                  inputFormatters: [_cpfMask],
                  decoration: const InputDecoration(
                    labelText: 'CPF',
                    prefixIcon: Icon(Icons.badge),
                    hintText: '000.000.000-00',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _dataNascController,
                  inputFormatters: [_dataMask],
                  decoration: const InputDecoration(
                    labelText: 'Data de Nascimento',
                    prefixIcon: Icon(Icons.cake),
                    hintText: 'DD/MM/AAAA',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'O prestador faz login no app com email e senha.'
                        : 'O prestador usara email e senha para fazer login no app.',
                    style: TextStyle(fontSize: 13, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndereco() {
    final estados = [
      'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
      'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
      'SP', 'SE', 'TO'
    ];

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cepController,
                  inputFormatters: [_cepMask],
                  decoration: const InputDecoration(
                    labelText: 'CEP',
                    prefixIcon: Icon(Icons.location_on),
                    hintText: '00000-000',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _enderecoController,
                  decoration: const InputDecoration(
                    labelText: 'Endereco',
                    prefixIcon: Icon(Icons.home),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Numero',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _complementoController,
                  decoration: const InputDecoration(
                    labelText: 'Complemento',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _bairroController,
                  decoration: const InputDecoration(
                    labelText: 'Bairro',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _estado.isNotEmpty ? _estado : null,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                  ),
                  items: estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _estado = v ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrabalho() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipos de veiculo que atende:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Row(
                    children: [
                      Icon(Icons.two_wheeler),
                      SizedBox(width: 8),
                      Text('Motos'),
                    ],
                  ),
                  value: _atendeMoto,
                  onChanged: (v) => setState(() => _atendeMoto = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Row(
                    children: [
                      Icon(Icons.directions_car),
                      SizedBox(width: 8),
                      Text('Carros'),
                    ],
                  ),
                  value: _atendeCarro,
                  onChanged: (v) => setState(() => _atendeCarro = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _raioController,
                  decoration: const InputDecoration(
                    labelText: 'Raio de Atendimento (km)',
                    prefixIcon: Icon(Icons.radar),
                    suffixText: 'km',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'O prestador recebera chamados dentro deste raio.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPagamento() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chave PIX para receber pagamentos:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _pixTipo.isNotEmpty ? _pixTipo : null,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Chave',
                    prefixIcon: Icon(Icons.pix),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cpf', child: Text('CPF')),
                    DropdownMenuItem(value: 'telefone', child: Text('Telefone')),
                    DropdownMenuItem(value: 'email', child: Text('Email')),
                    DropdownMenuItem(value: 'aleatoria', child: Text('Chave Aleatoria')),
                  ],
                  onChanged: (v) => setState(() => _pixTipo = v ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _pixChaveController,
                  decoration: const InputDecoration(
                    labelText: 'Chave PIX',
                    prefixIcon: Icon(Icons.key),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Os pagamentos serao enviados automaticamente para esta chave PIX apos a conclusao do atendimento.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentos() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carteira Nacional de Habilitacao (CNH):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cnhNumeroController,
                  decoration: const InputDecoration(
                    labelText: 'Numero da CNH',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _cnhValidadeController,
                  inputFormatters: [_dataMask],
                  decoration: const InputDecoration(
                    labelText: 'Validade',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: 'DD/MM/AAAA',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Observacoes:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _observacoesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Informacoes adicionais sobre o prestador...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
