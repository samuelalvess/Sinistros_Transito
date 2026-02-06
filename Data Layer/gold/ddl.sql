-- ===========================================================================
-- DDL - DATA WAREHOUSE (Camada Gold) | Projeto: Sinistros_Transito (DATATRAN 2025)
-- ===========================================================================
-- Modelo: Star Schema (Dimensões + Fato)
-- Fato principal: quantidade de mortos (qtd_mortos)
-- Fonte (Silver): silver.silver_sinistros
-- ===========================================================================

CREATE SCHEMA IF NOT EXISTS dw;
COMMENT ON SCHEMA dw IS 'Data Warehouse - Star Schema (Camada Gold) para Sinistros de Trânsito';

-- ===========================================================================
-- LIMPA AS TABELAS (caso já existam)
-- ===========================================================================
DROP TABLE IF EXISTS dw.fat_mor CASCADE;
DROP TABLE IF EXISTS dw.dim_tmp CASCADE;
DROP TABLE IF EXISTS dw.dim_loc CASCADE;
DROP TABLE IF EXISTS dw.dim_sin CASCADE;
DROP TABLE IF EXISTS dw.dim_via CASCADE;
DROP TABLE IF EXISTS dw.dim_cli CASCADE;

-- ============================================================================
-- DIMENSÃO: dim_tmp
-- Descrição: Dimensão temporal (data/hora do sinistro + atributos derivados)
-- ============================================================================
CREATE TABLE dw.dim_tmp (
    srk_tmp SERIAL PRIMARY KEY,
    dat_aci DATE NOT NULL,
    hor_aci TIME NOT NULL,
    dia_sem VARCHAR(30),
    fas_dia VARCHAR(50),
    fim_sem BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (dat_aci, hor_aci, dia_sem, fas_dia)
);

COMMENT ON TABLE dw.dim_tmp IS 'Dimensão temporal do sinistro (data/hora + atributos derivados)';
COMMENT ON COLUMN dw.dim_tmp.srk_tmp IS 'Surrogate Key (PK)';
COMMENT ON COLUMN dw.dim_tmp.dat_aci IS 'Data do sinistro';
COMMENT ON COLUMN dw.dim_tmp.hor_aci IS 'Hora do sinistro';
COMMENT ON COLUMN dw.dim_tmp.dia_sem IS 'Dia da semana (origem Silver / ou derivado)';
COMMENT ON COLUMN dw.dim_tmp.fas_dia IS 'Fase do dia (origem Silver)';
COMMENT ON COLUMN dw.dim_tmp.fim_sem IS 'Indicador de fim de semana (sábado/domingo)';

-- ============================================================================
-- DIMENSÃO: dim_loc
-- Descrição: Dimensão geográfica (UF, município, BR, coordenadas, urbano/rural)
-- ============================================================================
CREATE TABLE dw.dim_loc (
    srk_loc SERIAL PRIMARY KEY,
    uni VARCHAR(2),
    mun TEXT,
    rod VARCHAR(5),
    ara_urb BOOLEAN,
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION,
    UNIQUE (uni, mun, rod, ara_urb, lat, lon)
);

COMMENT ON TABLE dw.dim_loc IS 'Dimensão geográfica do sinistro';
COMMENT ON COLUMN dw.dim_loc.srk_loc IS 'Surrogate Key (PK)';
COMMENT ON COLUMN dw.dim_loc.uni IS 'UF do local do sinistro';
COMMENT ON COLUMN dw.dim_loc.mun IS 'Município do sinistro';
COMMENT ON COLUMN dw.dim_loc.rod IS 'Rodovia/BR (quando aplicável)';
COMMENT ON COLUMN dw.dim_loc.ara_urb IS 'Indicador de área urbana';
COMMENT ON COLUMN dw.dim_loc.lat IS 'Latitude do sinistro (validada/normalizada)';
COMMENT ON COLUMN dw.dim_loc.lon IS 'Longitude do sinistro (validada/normalizada)';

-- ============================================================================
-- DIMENSÃO: dim_sinistro
-- Descrição: Características do sinistro (tipo, causa, classificação)
-- ============================================================================
CREATE TABLE dw.dim_sin (
    srk_sin SERIAL PRIMARY KEY,
    tip_aci TEXT,
    cau_aci TEXT,
    cla_aci VARCHAR(100),
    UNIQUE (tip_aci, cau_aci, cla_aci)
);

COMMENT ON TABLE dw.dim_sin IS 'Dimensão de características do sinistro';
COMMENT ON COLUMN dw.dim_sin.srk_sin IS 'Surrogate Key (PK)';
COMMENT ON COLUMN dw.dim_sin.tip_aci IS 'Tipo de acidente';
COMMENT ON COLUMN dw.dim_sin.cau_aci IS 'Causa presumida';
COMMENT ON COLUMN dw.dim_sin.cla_aci IS 'Classificação do acidente';
-- ============================================================================
-- DIMENSÃO: dim_via
-- Descrição: Condições/atributos da via (sentido, pista, traçado)
-- ============================================================================
CREATE TABLE dw.dim_via (
    srk_via SERIAL PRIMARY KEY,
    sen_via VARCHAR(20),
    tip_pis VARCHAR(30),
    tra_via VARCHAR(100),
    UNIQUE (sen_via, tip_pis, tra_via)
);

COMMENT ON TABLE dw.dim_via IS 'Dimensão de atributos da via';
COMMENT ON COLUMN dw.dim_via.srk_via IS 'Surrogate Key (PK)';
COMMENT ON COLUMN dw.dim_via.sen_via IS 'Sentido da via';
COMMENT ON COLUMN dw.dim_via.tip_pis IS 'Tipo de pista';
COMMENT ON COLUMN dw.dim_via.tra_via IS 'Traçado da via';

-- ============================================================================
-- DIMENSÃO: dim_clima
-- Descrição: Condição meteorológica
-- ============================================================================
CREATE TABLE dw.dim_cli (
    srk_cli SERIAL PRIMARY KEY,
    con_met VARCHAR(100),
    UNIQUE (con_met)
);

COMMENT ON TABLE dw.dim_cli IS 'Dimensão de condição meteorológica';
COMMENT ON COLUMN dw.dim_cli.srk_cli IS 'Surrogate Key (PK)';
COMMENT ON COLUMN dw.dim_cli.con_met IS 'Condição meteorológica no momento do sinistro';

-- ============================================================================
-- TABELA FATO: fat_mor
-- Descrição: Fato de sinistros (medida principal: qtd_mortos)
-- Grão: 1 linha por registro na Silver (id do sinistro)
-- ============================================================================
CREATE TABLE dw.fat_mor (
    srk_fat BIGSERIAL PRIMARY KEY,

    -- Foreign keys (dimensões)
    srk_tmp INTEGER NOT NULL REFERENCES dw.dim_tmp(srk_tmp),
    srk_loc INTEGER REFERENCES dw.dim_loc(srk_loc),
    srk_sin INTEGER REFERENCES dw.dim_sin(srk_sin),
    srk_via INTEGER REFERENCES dw.dim_via(srk_via),
    srk_cli INTEGER REFERENCES dw.dim_cli(srk_cli),

    -- Degenerate dimension (chave natural do sinistro)
    sin_id INTEGER NOT NULL,

    -- Medidas (métricas)
    qtd_mor INTEGER NOT NULL DEFAULT 0,
    qtd_pes INTEGER,
    qtd_fer INTEGER,
    qtd_ile INTEGER,
    qtd_vei INTEGER,

    UNIQUE (sin_id)
);

COMMENT ON TABLE dw.fat_mor IS 'Fato de sinistros - medida principal: quantidade de mortos';
COMMENT ON COLUMN dw.fat_mor.srk_fato IS 'Surrogate Key da tabela fato (PK)';
COMMENT ON COLUMN dw.fat_mor.srk_tmp IS 'FK para dim_tmp';
COMMENT ON COLUMN dw.fat_mor.srk_loc IS 'FK para dim_loc';
COMMENT ON COLUMN dw.fat_mor.srk_sin IS 'FK para dim_sinistro';
COMMENT ON COLUMN dw.fat_mor.srk_via IS 'FK para dim_via';
COMMENT ON COLUMN dw.fat_mor.srk_cli IS 'FK para dim_clima';
COMMENT ON COLUMN dw.fat_mor.sin_id IS 'Identificador original do sinistro (silver.id)';
COMMENT ON COLUMN dw.fat_mor.qtd_mor IS 'Quantidade de mortos no sinistro (medida principal)';
COMMENT ON COLUMN dw.fat_mor.qtd_pes IS 'Total de pessoas envolvidas';
COMMENT ON COLUMN dw.fat_mor.qtd_fer IS 'Total de feridos';
COMMENT ON COLUMN dw.fat_mor.qtd_ile IS 'Total de ilesos';
COMMENT ON COLUMN dw.fat_mor.qtd_vei IS 'Total de veículos';

-- ============================================================================
-- ÍNDICES (para performance analítica)
-- ============================================================================
CREATE INDEX idx_fat_mor_tmp ON dw.fat_mor(srk_tmp);
CREATE INDEX idx_fat_mor_loc ON dw.fat_mor(srk_loc);
CREATE INDEX idx_fat_mor_sin ON dw.fat_mor(srk_sin);
CREATE INDEX idx_fat_mor_via ON dw.fat_mor(srk_via);
CREATE INDEX idx_fat_mor_cli ON dw.fat_mor(srk_cli);

-- Filtro comum: sinistros com mortos
CREATE INDEX idx_fat_mor_fis ON dw.fat_mor(qtd_mor) WHERE qtd_mor > 0;
