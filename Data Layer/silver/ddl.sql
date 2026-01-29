
CREATE SCHEMA IF NOT EXISTS silver;

-- Comentário no schema
COMMENT ON SCHEMA silver IS 'Camada Silver - Sinistros tratados, tipados e validados (sem agregações)';

-- ============================================================================
-- TABELA: SILVER_SINISTROS
-- ============================================================================

DROP TABLE IF EXISTS silver.silver_sinistros CASCADE;

CREATE TABLE silver.silver_sinistros (
   
    id INT PRIMARY KEY,

    -- Temporal
    data_acidente DATE,
    hora_acidente TIME,

    -- Localização
    uf VARCHAR(2),
    municipio TEXT,
    br VARCHAR(10),                 
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    area_urbana BOOLEAN,           

    -- Características do acidente
    dia_semana VARCHAR(30),
    fase_dia VARCHAR(50),
    tipo_acidente TEXT,
    causa_acidente TEXT,
    classificacao_acidente VARCHAR(80),

    -- Via / Condições
    sentido_via VARCHAR(50),
    condicao_metereologica VARCHAR(80),
    tipo_pista VARCHAR(80),
    tracado_via VARCHAR(80),

    -- Métricas (contagens)
    pessoas INTEGER,
    mortos INTEGER,
    feridos INTEGER,
    ilesos INTEGER,
    veiculos INTEGER

);

-- ============================================================================
-- ÍNDICES PARA PERFORMANCE (filtros comuns em análises)
-- ============================================================================

-- Temporais
CREATE INDEX idx_sinistros_data ON silver.silver_sinistros(data_acidente);
CREATE INDEX idx_sinistros_hora ON silver.silver_sinistros(hora_acidente);

-- Localização
CREATE INDEX idx_sinistros_uf ON silver.silver_sinistros(uf);
CREATE INDEX idx_sinistros_municipio ON silver.silver_sinistros(municipio);
CREATE INDEX idx_sinistros_br ON silver.silver_sinistros(br);

-- Categorias
CREATE INDEX idx_sinistros_tipo ON silver.silver_sinistros(tipo_acidente);
CREATE INDEX idx_sinistros_causa ON silver.silver_sinistros(causa_acidente);
CREATE INDEX idx_sinistros_classif ON silver.silver_sinistros(classificacao_acidente);

-- Boolean / segmentação
CREATE INDEX idx_sinistros_area_urbana ON silver.silver_sinistros(area_urbana);

-- Índices parciais úteis (severidade e geo)
CREATE INDEX idx_sinistros_fatais ON silver.silver_sinistros(mortos) WHERE mortos > 0;
CREATE INDEX idx_sinistros_geo ON silver.silver_sinistros(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ============================================================================
-- COMENTÁRIOS (Dicionário de Dados no Banco)
-- ============================================================================

COMMENT ON TABLE silver.silver_sinistros IS 'Sinistros de trânsito (PRF) tratados na camada SILVER: tipagem, normalização e validação, sem regras de negócio agregadas';

COMMENT ON COLUMN silver.silver_sinistros.id IS 'Identificador do registro na base original (CSV/PRF)';
COMMENT ON COLUMN silver.silver_sinistros.data_acidente IS 'Data do sinistro (DATE) - renomeado de data_inversa';
COMMENT ON COLUMN silver.silver_sinistros.hora_acidente IS 'Hora do sinistro (TIME) - renomeado de horario';
COMMENT ON COLUMN silver.silver_sinistros.area_urbana IS 'Indicador booleano de área urbana (normalizado de SIM/NÃO)';

COMMENT ON COLUMN silver.silver_sinistros.uf IS 'UF do local do sinistro';
COMMENT ON COLUMN silver.silver_sinistros.municipio IS 'Município do local do sinistro';
COMMENT ON COLUMN silver.silver_sinistros.br IS 'Rodovia/BR (quando disponível)';
COMMENT ON COLUMN silver.silver_sinistros.latitude IS 'Latitude (validada em [-90,90])';
COMMENT ON COLUMN silver.silver_sinistros.longitude IS 'Longitude (validada em [-180,180])';

COMMENT ON COLUMN silver.silver_sinistros.tipo_acidente IS 'Tipo de acidente';
COMMENT ON COLUMN silver.silver_sinistros.causa_acidente IS 'Causa presumida do acidente';
COMMENT ON COLUMN silver.silver_sinistros.classificacao_acidente IS 'Classificação do acidente (ex.: com vítima, sem vítima, etc.)';

COMMENT ON COLUMN silver.silver_sinistros.pessoas IS 'Total de pessoas envolvidas no sinistro';
COMMENT ON COLUMN silver.silver_sinistros.veiculos IS 'Total de veículos envolvidos no sinistro';
COMMENT ON COLUMN silver.silver_sinistros.mortos IS 'Total de mortos no sinistro';
COMMENT ON COLUMN silver.silver_sinistros.feridos IS 'Total de feridos no sinistro';
COMMENT ON COLUMN silver.silver_sinistros.ilesos IS 'Total de ilesos no sinistro';

-- ============================================================================
-- VIEWS AUXILIARES (Analytics ready)
-- ============================================================================

-- View: Sinistros fatais
CREATE OR REPLACE VIEW silver.vw_sinistros_fatais AS
SELECT
    id,
    data_acidente,
    hora_acidente,
    uf,
    municipio,
    br,
    tipo_acidente,
    causa_acidente,
    classificacao_acidente,
    mortos,
    feridos,
    veiculos,
    pessoas,
    area_urbana,
    latitude,
    longitude
FROM silver.silver_sinistros
WHERE COALESCE(mortos,0) > 0
ORDER BY mortos DESC, data_acidente DESC;

-- View: Resumo por UF
CREATE OR REPLACE VIEW silver.vw_sinistros_uf_stats AS
SELECT
    uf,
    COUNT(*)::bigint AS total_acidentes,
    COALESCE(SUM(mortos),0)::bigint AS total_mortos,
    COALESCE(SUM(feridos),0)::bigint AS total_feridos,
    COALESCE(SUM(veiculos),0)::bigint AS total_veiculos,
    MIN(data_acidente) AS inicio,
    MAX(data_acidente) AS fim
FROM silver.silver_sinistros
GROUP BY uf
ORDER BY total_acidentes DESC;

-- ============================================================================
-- FIM DO DDL
-- ============================================================================
