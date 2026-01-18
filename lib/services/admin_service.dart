import 'supabase_service.dart';

class AdminService {
  static final _client = SupabaseService.client;

  // Dashboard metrics
  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    final response = await _client.rpc('get_dashboard_metricas');
    return response ?? {};
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
