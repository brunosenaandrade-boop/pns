import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../core/constants.dart';

class AdminService {
  static final _client = SupabaseService.client;

  // URL base para Edge Functions
  static String get _functionsUrl => '${AppConstants.supabaseUrl}/functions/v1';

  // Obter token do usuario autenticado
  static String? get _authToken => _client.auth.currentSession?.accessToken;

  // Headers para chamar Edge Functions
  static Map<String, String> get _functionHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_authToken ?? ''}',
  };

  // Dashboard metrics
  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    // Retorna valores padrão - queries serão feitas quando houver dados
    int totalUsuarios = 0;
    int totalAssinaturasAtivas = 0;
    int totalChamados = 0;
    double receitaTotal = 0.0;
    Map<String, int> assinaturasPorPlano = {};
    Map<String, int> chamadosPorStatus = {};
    int acessosApp = 0;

    final data30DiasAtras = DateTime.now().subtract(const Duration(days: 30));

    // Total de usuários
    try {
      final usuariosData = await _client.from('usuarios').select('id');
      totalUsuarios = (usuariosData as List).length;
    } catch (_) {}

    // Assinaturas ativas
    try {
      final assinaturasData = await _client
          .from('assinaturas')
          .select('id, planos(nome)')
          .eq('status', 'ativo');
      totalAssinaturasAtivas = (assinaturasData as List).length;

      // Contar por plano
      for (var a in assinaturasData) {
        final planoNome = a['planos']?['nome'] ?? 'Desconhecido';
        assinaturasPorPlano[planoNome] = (assinaturasPorPlano[planoNome] ?? 0) + 1;
      }
    } catch (_) {}

    // Chamados últimos 30 dias
    try {
      final chamadosData = await _client
          .from('chamados')
          .select('id, status')
          .gte('criado_em', data30DiasAtras.toIso8601String());
      totalChamados = (chamadosData as List).length;

      // Contar por status
      for (var c in chamadosData) {
        final status = c['status'] ?? 'desconhecido';
        chamadosPorStatus[status] = (chamadosPorStatus[status] ?? 0) + 1;
      }
    } catch (_) {}

    // Receita dos últimos 30 dias
    try {
      final pagamentosData = await _client
          .from('pagamentos')
          .select('valor')
          .eq('status', 'aprovado')
          .gte('criado_em', data30DiasAtras.toIso8601String());

      for (var p in pagamentosData) {
        receitaTotal += (p['valor'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {}

    // Acessos ao app (analytics) - pode não existir a tabela
    try {
      final acessosData = await _client
          .from('analytics')
          .select('id')
          .eq('evento', 'app_aberto')
          .gte('criado_em', data30DiasAtras.toIso8601String());
      acessosApp = (acessosData as List).length;
    } catch (_) {}

    return {
      'total_usuarios': totalUsuarios,
      'total_assinaturas_ativas': totalAssinaturasAtivas,
      'total_chamados': totalChamados,
      'receita_total': receitaTotal,
      'assinaturas_por_plano': assinaturasPorPlano,
      'chamados_por_status': chamadosPorStatus,
      'acessos_app': acessosApp,
    };
  }

  // Clientes
  static Future<List<Map<String, dynamic>>> getClientes({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    var query = _client.from('usuarios').select('*, veiculos(*), assinaturas(*, planos(*))');

    if (search != null && search.isNotEmpty) {
      query = query.or('nome_completo.ilike.%$search%,telefone.ilike.%$search%,cpf.ilike.%$search%');
    }

    final data = await query
        .order('criado_em', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  // Prestadores
  static Future<List<Map<String, dynamic>>> getPrestadores({
    int page = 0,
    int limit = 20,
  }) async {
    final data = await _client
        .from('prestadores')
        .select()
        .order('criado_em', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> togglePrestadorAtivo(String id, bool ativo) async {
    await _client.from('prestadores').update({'ativo': ativo}).eq('id', id);
  }

  static Future<void> deletePrestador(String id) async {
    await _client.from('prestadores').delete().eq('id', id);
  }

  // Adicionar novo prestador (simples - retrocompatibilidade)
  static Future<void> addPrestador({
    required String nome,
    required String telefone,
    String? cpf,
  }) async {
    await _client.from('prestadores').insert({
      'nome_completo': nome,
      'telefone': telefone.startsWith('+') ? telefone : '+55$telefone',
      'cpf': cpf,
      'ativo': true,
      'disponivel': false,
      'avaliacao_media': 5.0,
      'total_atendimentos': 0,
    });
  }

  // Adicionar novo prestador (completo)
  static Future<void> addPrestadorFull(Map<String, dynamic> data) async {
    await _client.from('prestadores').insert(data);
  }

  // Criar prestador com usuario Auth (email/senha) via Edge Function
  static Future<void> createPrestadorWithAuth({
    required String email,
    required String password,
    required Map<String, dynamic> prestadorData,
  }) async {
    final response = await http.post(
      Uri.parse('$_functionsUrl/admin-create-prestador'),
      headers: _functionHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'prestadorData': prestadorData,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar prestador');
    }

    debugPrint('AdminService: Prestador criado com sucesso');
  }

  // Atualizar prestador
  static Future<void> updatePrestador(String id, Map<String, dynamic> data) async {
    await _client.from('prestadores').update(data).eq('id', id);
  }

  // Atualizar senha do prestador via Edge Function
  static Future<void> updatePrestadorPassword(String userId, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_functionsUrl/admin-update-password'),
      headers: _functionHeaders,
      body: jsonEncode({
        'userId': userId,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar senha');
    }

    debugPrint('AdminService: Senha atualizada com sucesso');
  }

  // Chamados
  static Future<List<Map<String, dynamic>>> getChamados({
    int page = 0,
    int limit = 20,
    String? status,
  }) async {
    var query = _client.from('chamados').select('*, usuarios(*), prestadores(*), assinaturas(*, planos(*))');

    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final data = await query
        .order('criado_em', ascending: false)
        .range(page * limit, (page + 1) * limit - 1);

    return List<Map<String, dynamic>>.from(data);
  }

  // Pagamentos pendentes (Pix)
  static Future<List<Map<String, dynamic>>> getPagamentosPendentes() async {
    final data = await _client
        .from('pagamentos')
        .select('*, assinaturas(*, usuarios(*), planos(*))')
        .eq('status', 'pendente')
        .order('criado_em', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> aprovarPagamento(String pagamentoId, String assinaturaId) async {
    // Atualizar pagamento
    await _client.from('pagamentos').update({
      'status': 'aprovado',
      'data_pagamento': DateTime.now().toIso8601String(),
    }).eq('id', pagamentoId);

    // Ativar assinatura
    await _client.from('assinaturas').update({
      'status': 'ativo',
      'data_inicio': DateTime.now().toIso8601String(),
    }).eq('id', assinaturaId);
  }

  static Future<void> rejeitarPagamento(String pagamentoId) async {
    await _client.from('pagamentos').update({
      'status': 'rejeitado',
    }).eq('id', pagamentoId);
  }

  // Bloquear cliente por fraude
  static Future<void> bloquearCliente(String assinaturaId) async {
    await _client.from('assinaturas').update({
      'status': 'cancelado',
    }).eq('id', assinaturaId);
  }

  // Atualizar cliente
  static Future<void> updateCliente({
    required String id,
    String? nomeCompleto,
    String? telefone,
    String? cpf,
    String? email,
    String? cep,
    String? endereco,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
  }) async {
    final updateData = <String, dynamic>{};

    if (nomeCompleto != null && nomeCompleto.isNotEmpty) {
      updateData['nome_completo'] = nomeCompleto;
    }
    if (telefone != null && telefone.isNotEmpty) {
      updateData['telefone'] = telefone;
    }
    if (cpf != null) updateData['cpf'] = cpf.isEmpty ? null : cpf;
    if (email != null) updateData['email'] = email.isEmpty ? null : email;
    if (cep != null) updateData['cep'] = cep.isEmpty ? null : cep;
    if (endereco != null) updateData['endereco'] = endereco.isEmpty ? null : endereco;
    if (numero != null) updateData['numero'] = numero.isEmpty ? null : numero;
    if (complemento != null) updateData['complemento'] = complemento.isEmpty ? null : complemento;
    if (bairro != null) updateData['bairro'] = bairro.isEmpty ? null : bairro;
    if (cidade != null) updateData['cidade'] = cidade.isEmpty ? null : cidade;
    if (estado != null) updateData['estado'] = estado;

    if (updateData.isEmpty) return;

    await _client.from('usuarios').update(updateData).eq('id', id);
  }

  // Analytics
  static Future<List<Map<String, dynamic>>> getAnalytics({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    final data = await _client
        .from('analytics')
        .select()
        .gte('criado_em', inicio.toIso8601String())
        .lte('criado_em', fim.toIso8601String())
        .order('criado_em', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }
}
