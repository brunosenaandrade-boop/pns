-- =====================================================
-- SETUP DE AUTENTICACAO ADMIN - Seguro Pneu Pro
-- Execute este SQL no Supabase SQL Editor
-- =====================================================

-- 1. Criar tabela de admins
CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    criado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    atualizado_em TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id),
    UNIQUE(email)
);

-- 2. Habilitar RLS na tabela admins
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

-- 3. Politica para admins verem a propria entrada
CREATE POLICY "Admins podem ver propria entrada" ON admins
    FOR SELECT USING (auth.uid() = user_id);

-- =====================================================
-- FUNCAO HELPER: Verificar se usuario e admin
-- =====================================================
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins
        WHERE user_id = auth.uid()
        AND ativo = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- POLITICAS RLS PARA PRESTADORES
-- =====================================================
-- Remover politicas antigas se existirem
DROP POLICY IF EXISTS "Admins podem ver prestadores" ON prestadores;
DROP POLICY IF EXISTS "Admins podem inserir prestadores" ON prestadores;
DROP POLICY IF EXISTS "Admins podem atualizar prestadores" ON prestadores;
DROP POLICY IF EXISTS "Admins podem deletar prestadores" ON prestadores;

-- Criar novas politicas
CREATE POLICY "Admins podem ver prestadores" ON prestadores
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem inserir prestadores" ON prestadores
    FOR INSERT WITH CHECK (is_admin());

CREATE POLICY "Admins podem atualizar prestadores" ON prestadores
    FOR UPDATE USING (is_admin());

CREATE POLICY "Admins podem deletar prestadores" ON prestadores
    FOR DELETE USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA USUARIOS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver usuarios" ON usuarios;
DROP POLICY IF EXISTS "Admins podem atualizar usuarios" ON usuarios;

CREATE POLICY "Admins podem ver usuarios" ON usuarios
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem atualizar usuarios" ON usuarios
    FOR UPDATE USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA CHAMADOS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver chamados" ON chamados;
DROP POLICY IF EXISTS "Admins podem atualizar chamados" ON chamados;

CREATE POLICY "Admins podem ver chamados" ON chamados
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem atualizar chamados" ON chamados
    FOR UPDATE USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA ASSINATURAS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver assinaturas" ON assinaturas;
DROP POLICY IF EXISTS "Admins podem atualizar assinaturas" ON assinaturas;

CREATE POLICY "Admins podem ver assinaturas" ON assinaturas
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem atualizar assinaturas" ON assinaturas
    FOR UPDATE USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA PAGAMENTOS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver pagamentos" ON pagamentos;
DROP POLICY IF EXISTS "Admins podem atualizar pagamentos" ON pagamentos;

CREATE POLICY "Admins podem ver pagamentos" ON pagamentos
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem atualizar pagamentos" ON pagamentos
    FOR UPDATE USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA PLANOS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver planos" ON planos;
DROP POLICY IF EXISTS "Admins podem gerenciar planos" ON planos;

CREATE POLICY "Admins podem ver planos" ON planos
    FOR SELECT USING (is_admin());

CREATE POLICY "Admins podem gerenciar planos" ON planos
    FOR ALL USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA VEICULOS
-- =====================================================
DROP POLICY IF EXISTS "Admins podem ver veiculos" ON veiculos;

CREATE POLICY "Admins podem ver veiculos" ON veiculos
    FOR SELECT USING (is_admin());

-- =====================================================
-- POLITICAS RLS PARA ANALYTICS (se existir)
-- =====================================================
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'analytics') THEN
        EXECUTE 'DROP POLICY IF EXISTS "Admins podem ver analytics" ON analytics';
        EXECUTE 'CREATE POLICY "Admins podem ver analytics" ON analytics FOR SELECT USING (is_admin())';
    END IF;
END $$;

-- =====================================================
-- CRIAR PRIMEIRO USUARIO ADMIN
-- Substitua os valores abaixo pelos seus dados
-- =====================================================

-- PASSO 1: Criar usuario no Supabase Auth
-- Va em Authentication > Users > Add User
-- Email: seu-email@exemplo.com
-- Senha: sua-senha-segura

-- PASSO 2: Depois de criar o usuario, pegue o UUID dele
-- e execute o comando abaixo substituindo os valores:

-- INSERT INTO admins (user_id, nome, email)
-- VALUES (
--     'UUID-DO-USUARIO-AQUI',
--     'Nome do Admin',
--     'seu-email@exemplo.com'
-- );

-- =====================================================
-- EXEMPLO: Se o UUID do usuario for
-- '12345678-1234-1234-1234-123456789012'
-- =====================================================
-- INSERT INTO admins (user_id, nome, email)
-- VALUES (
--     '12345678-1234-1234-1234-123456789012',
--     'Bruno Admin',
--     'bruno@seguropneupro.com'
-- );
