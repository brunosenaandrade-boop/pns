# Auditoria do Painel Admin - Seguro Pneu Pro

**Data:** 21/01/2026
**Projeto:** admin/
**Tipo:** Flutter Web

---

## RESUMO EXECUTIVO

| Severidade | Quantidade |
|------------|------------|
| CRITICO    | 1          |
| ALTO       | 3          |
| MEDIO      | 5          |
| BAIXO      | 4          |

---

## PROBLEMAS CRITICOS

### 1. Service Role Key Exposta no Codigo Web
**Arquivo:** `lib/core/constants.dart:6`
**Severidade:** CRITICO

A chave de servico (service role key) do Supabase esta exposta no codigo:

```dart
static const String supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**Problema:**
- Este e um aplicativo Flutter Web - o codigo JavaScript e visivel no navegador
- A service key permite BYPASSAR todas as politicas RLS
- Qualquer pessoa pode acessar o painel, abrir DevTools e copiar esta chave
- Com esta chave, um atacante pode:
  - Ler/modificar/deletar TODOS os dados do banco
  - Criar usuarios administrativos
  - Acessar dados de todos os clientes (CPF, endereco, etc.)
  - Aprovar pagamentos fraudulentos
  - Deletar prestadores

**Solucao:**
Criar uma API backend (Edge Function ou servidor dedicado) para operacoes administrativas:

```
[Admin Web] --> [Edge Function c/ Auth] --> [Supabase c/ Service Key]
```

A service key NUNCA deve estar no frontend.

---

## PROBLEMAS DE SEVERIDADE ALTA

### 2. Operacoes Administrativas sem Backend Seguro
**Arquivo:** `lib/services/admin_service.dart:156-219`
**Severidade:** ALTA

As operacoes que requerem service key sao feitas diretamente do frontend:

```dart
static Future<void> createPrestadorWithAuth({...}) async {
  final response = await http.post(
    Uri.parse('${AppConstants.supabaseUrl}/auth/v1/admin/users'),
    headers: {
      'apikey': AppConstants.supabaseServiceKey,
      'Authorization': 'Bearer ${AppConstants.supabaseServiceKey}',
    },
    ...
  );
}
```

**Solucao:**
Mover para Edge Functions do Supabase:

```sql
-- Exemplo de Edge Function
create or replace function create_prestador_auth(
  p_email text,
  p_password text,
  p_data jsonb
) returns jsonb as $$
  -- Verificar se usuario e admin
  -- Criar usuario via Admin API (server-side)
  -- Retornar resultado
$$ language plpgsql security definer;
```

### 3. Falta de Logs de Auditoria
**Arquivo:** Todos os servicos
**Severidade:** ALTA

Acoes administrativas criticas nao sao logadas:
- Aprovacao/rejeicao de pagamentos
- Bloqueio de clientes
- Criacao/edicao/exclusao de prestadores
- Alteracao de dados de clientes

**Solucao:**
Criar tabela de audit log:

```sql
CREATE TABLE audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES admins(id),
  acao TEXT NOT NULL,
  tabela TEXT NOT NULL,
  registro_id UUID,
  dados_anteriores JSONB,
  dados_novos JSONB,
  ip_address TEXT,
  user_agent TEXT,
  criado_em TIMESTAMPTZ DEFAULT NOW()
);
```

### 4. Tratamento Silencioso de Erros
**Arquivos:** Todas as telas
**Severidade:** ALTA

Muitos lugares capturam excecoes sem mostrar feedback ao usuario:

```dart
// dashboard_screen.dart:33-47
} catch (e) {
  if (mounted) {
    setState(() {
      _metrics = {...valores padrao...};
      _isLoading = false;
    });
  }
}

// prestadores_screen.dart:32-34
} catch (e) {
  setState(() => _isLoading = false);
  // Nenhuma mensagem de erro!
}
```

**Solucao:**
Sempre mostrar erro ao usuario:

```dart
} catch (e) {
  setState(() => _isLoading = false);
  _showSnackBar('Erro ao carregar dados: $e', isError: true);
}
```

---

## PROBLEMAS DE SEVERIDADE MEDIA

### 5. Acoes Sensiveis sem Confirmacao
**Arquivo:** `lib/screens/prestadores/prestadores_screen.dart:211-214`
**Severidade:** MEDIA

Toggle de ativo/inativo nao pede confirmacao:

```dart
void _toggleAtivo(String id, bool ativo) async {
  await AdminService.togglePrestadorAtivo(id, ativo);  // Executa direto!
  _loadPrestadores();
}
```

**Solucao:**
Adicionar dialog de confirmacao como na exclusao.

### 6. Funcao "Ver Comprovante" nao Implementada
**Arquivo:** `lib/screens/pagamentos/pagamentos_screen.dart:146-152`
**Severidade:** MEDIA

O botao existe mas nao faz nada:

```dart
if (pagamento['comprovante_url'] != null)
  OutlinedButton.icon(
    onPressed: () {
      // Abrir comprovante  <-- VAZIO!
    },
    icon: const Icon(Icons.receipt),
    label: const Text('Ver Comprovante'),
  ),
```

**Solucao:**
Implementar abertura da URL ou modal com imagem.

### 7. Validacao de CPF Inconsistente
**Arquivos:** Multiplos
**Severidade:** MEDIA

A validacao de CPF so existe no formulario de prestador (`prestadores_screen.dart:730-752`), mas nao no formulario de edicao de cliente (`clientes_screen.dart`).

**Solucao:**
Criar classe de validadores compartilhada e usar em todos os formularios.

### 8. Paginacao nao Implementada no Frontend
**Arquivos:** Todas as telas de listagem
**Severidade:** MEDIA

Os servicos suportam paginacao (`page`, `limit`), mas as telas carregam tudo de uma vez:

```dart
final clientes = await AdminService.getClientes(search: search);
// page e limit nao sao usados!
```

Com muitos registros, isso pode causar lentidao.

### 9. Falta de Rate Limiting
**Severidade:** MEDIA

Nao ha protecao contra:
- Tentativas multiplas de login
- Requisicoes em massa
- Ataques de forca bruta

**Solucao:**
Implementar via Supabase Edge Functions ou middleware.

---

## PROBLEMAS DE SEVERIDADE BAIXA

### 10. Strings Hardcoded (i18n)
**Severidade:** BAIXA

Todos os textos estao em portugues hardcoded. Para internacionalizacao futura, considerar usar `flutter_localizations`.

### 11. Cores Hardcoded
**Severidade:** BAIXA

Muitas cores sao definidas inline:

```dart
color: Colors.green  // Deveria usar tema
color: const Color(0xFF25D366)  // Hardcoded
```

### 12. Comentarios Incompletos
**Severidade:** BAIXA

Alguns comentarios indicam funcionalidades pendentes:
- `// Abrir comprovante` (vazio)
- `// pode não existir a tabela` (analytics)

### 13. Imports nao Utilizados
**Arquivo:** `lib/screens/clientes/clientes_screen.dart:4`
**Severidade:** BAIXA

```dart
import '../../services/cep_service.dart';  // Usado apenas no dialog interno
```

---

## RECOMENDACOES DE ARQUITETURA

### Backend para Operacoes Admin

Criar Edge Functions no Supabase para:

1. **Criar Prestador com Auth**
```typescript
// supabase/functions/admin-create-prestador/index.ts
import { createClient } from '@supabase/supabase-js'

export async function handler(req: Request) {
  // Verificar JWT do admin
  // Criar usuario com service key (server-side)
  // Inserir prestador
}
```

2. **Aprovar Pagamento**
```typescript
// Verificar admin
// Atualizar pagamento e assinatura em transacao
// Criar log de auditoria
```

3. **Bloquear Cliente**
```typescript
// Verificar admin
// Cancelar assinatura
// Criar log com motivo
```

### Estrutura de Permissoes

```sql
-- Tabela de permissoes por admin
CREATE TABLE admin_permissoes (
  admin_id UUID REFERENCES admins(id),
  permissao TEXT NOT NULL,
  PRIMARY KEY (admin_id, permissao)
);

-- Permissoes: 'clientes:read', 'clientes:write', 'prestadores:manage', etc.
```

---

## PLANO DE ACAO SUGERIDO

### Fase 1 - Critico (Imediato)
1. [ ] Mover service key para Edge Functions
2. [ ] Remover service key do codigo frontend
3. [ ] Criar Edge Function para criar prestadores

### Fase 2 - Alta Prioridade (1 semana)
4. [ ] Implementar sistema de audit log
5. [ ] Adicionar tratamento de erros em todas as telas
6. [ ] Implementar Edge Functions para aprovar/rejeitar pagamentos

### Fase 3 - Media Prioridade (2 semanas)
7. [ ] Adicionar confirmacao para toggle de status
8. [ ] Implementar visualizacao de comprovante
9. [ ] Unificar validadores
10. [ ] Implementar paginacao no frontend

### Fase 4 - Baixa Prioridade (Backlog)
11. [ ] Configurar internacionalizacao
12. [ ] Refatorar cores para usar tema
13. [ ] Limpar imports nao utilizados

---

## SQL PARA AUDIT LOG

```sql
-- Criar tabela de audit
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  admin_id UUID REFERENCES admins(user_id),
  acao TEXT NOT NULL,
  tabela_afetada TEXT NOT NULL,
  registro_id UUID,
  dados_anteriores JSONB,
  dados_novos JSONB,
  ip_address INET,
  user_agent TEXT,
  criado_em TIMESTAMPTZ DEFAULT NOW()
);

-- Index para buscas
CREATE INDEX idx_audit_logs_admin ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_tabela ON audit_logs(tabela_afetada);
CREATE INDEX idx_audit_logs_data ON audit_logs(criado_em);

-- RLS
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Apenas admins podem ler logs
CREATE POLICY "Admins podem ler audit logs"
ON audit_logs FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM admins WHERE user_id = auth.uid()
  )
);

-- Funcao para inserir log (usar em Edge Functions)
CREATE OR REPLACE FUNCTION insert_audit_log(
  p_admin_id UUID,
  p_acao TEXT,
  p_tabela TEXT,
  p_registro_id UUID DEFAULT NULL,
  p_dados_anteriores JSONB DEFAULT NULL,
  p_dados_novos JSONB DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO audit_logs (admin_id, acao, tabela_afetada, registro_id, dados_anteriores, dados_novos)
  VALUES (p_admin_id, p_acao, p_tabela, p_registro_id, p_dados_anteriores, p_dados_novos)
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

**Fim do Relatorio**
