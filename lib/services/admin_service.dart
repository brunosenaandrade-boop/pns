import 'supabase_service.dart';

class AdminService {
  static final _client = SupabaseService.client;

  // Dashboard metrics
  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      // Total de usuários
      final usuariosResponse = await _client
          .from('usuarios')
          .select('id')
          .count();
      final totalUsuarios = usuariosResponse.count;

      // Assinaturas ativas
      final assinaturasResponse = await _client
          .from('assinaturas')
          .select('id')
          .eq('status', 'ativo')
          .count();
      final totalAssinaturasAtivas = assinaturasResponse.count;

      // Chamados últimos 30 dias
      final data30DiasAtras = DateTime.now().subtract(const Duration(days: 30));
      final chamadosResponse = await _client
          .from('chamados')
          .select('id')
          .gte('criado_em', data30DiasAtras.toIso8601String())
          .count();
      final totalChamados = chamadosResponse.count;

      // Receita dos últimos 30 dias
      final pagamentosData = await _client
          .from('pagamentos')
          .select('valor')
          .eq('status', 'aprovado')
          .gte('criado_em', data30DiasAtras.toIso8601String());

      double receitaTotal = 0;
      for (var p in pagamentosData) {
        receitaTotal += (p['valor'] as num?)?.toDouble() ?? 0;
      }

      // Assinaturas por plano
      final assinaturasPorPlanoData = await _client
          .from('assinaturas')
          .select('planos(nome)')
          .eq('status', 'ativo');

      final assinaturasPorPlano = <String, int>{};
      for (var a in assinaturasPorPlanoData) {
        final planoNome = a['planos']?['nome'] ?? 'Desconhecido';
        assinaturasPorPlano[planoNome] = (assinaturasPorPlano[planoNome] ?? 0) + 1;
      }

      // Chamados por status
      final chamadosPorStatusData = await _client
          .from('chamados')
          .select('status')
          .gte('criado_em', data30DiasAtras.toIso8601String());

      final chamadosPorStatus = <String, int>{};
      for (var c in chamadosPorStatusData) {
        final status = c['status'] ?? 'desconhecido';
        chamadosPorStatus[status] = (chamadosPorStatus[status] ?? 0) + 1;
      }

      // Acessos ao app (analytics)
      final acessosResponse = await _client
          .from('analytics')
          .select('id')
          .eq('evento', 'app_aberto')
          .gte('criado_em', data30DiasAtras.toIso8601String())
          .count();
      final acessosApp = acessosResponse.count;

      return {
        'total_usuarios': totalUsuarios,
        'total_assinaturas_ativas': totalAssinaturasAtivas,
        'total_chamados': totalChamados,
        'receita_total': receitaTotal,
        'assinaturas_por_plano': assinaturasPorPlano,
        'chamados_por_status': chamadosPorStatus,
        'acessos_app': acessosApp,
      };
    } catch (e) {
      // Em caso de erro, retorna valores padrão
      return {
        'total_usuarios': 0,
        'total_assinaturas_ativas': 0,
        'total_chamados': 0,
        'receita_total': 0.0,
        'assinaturas_por_plano': <String, int>{},
        'chamados_por_status': <String, int>{},
        'acessos_app': 0,
      };
    }
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
