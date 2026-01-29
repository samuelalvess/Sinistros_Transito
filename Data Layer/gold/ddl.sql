

CREATE SCHEMA IF NOT EXISTS dw;
COMMENT ON SCHEMA dw IS 'Camada dw - Modelo estrela (Fato + Dimensões) para analytics/BI';

-- ============================================================================
-- DIMENSÕES
-- ============================================================================

-- dim_TMP (Dimensão Tempo - por dia)
DROP TABLE IF EXISTS dw.dim_tmp CASCADE;

CREATE TABLE dw.dim_tmp (
  SRK_TMP SERIAL PRIMARY KEY,
  DAT DATE NOT NULL,            
  DIA_SMN VARCHAR(15),              -- nome do dia da semana (ex.: SEGUNDA-FEIRA)                 
);

CREATE UNIQUE INDEX ux_dim_tmp_dat ON dw.dim_tmp(DAT);

COMMENT ON TABLE dw.dim_tmp IS 'Dimensão tempo (1 linha por dia)';

-- dim_HOR (Dimensão Hora)
DROP TABLE IF EXISTS dw.dim_hor CASCADE;

CREATE TABLE dw.dim_hor (
  SRK_HOR SERIAL PRIMARY KEY,
  HOR TIME NOT NULL,            -- hora do acidente
);

CREATE UNIQUE INDEX ux_dim_hor_hor ON dw.dim_hor(HOR);

COMMENT ON TABLE dw.dim_hor IS 'Dimensão hora (TIME) + atributos derivados';

-- dim_LOC (Dimensão Local)
DROP TABLE IF EXISTS dw.dim_loc CASCADE;

CREATE TABLE dw.dim_loc (
  SRK_LOC SERIAL PRIMARY KEY,
  UND_FED VARCHAR(2),               -- UF
  MUN TEXT,                     -- município
  BRR VARCHAR(20),              -- BR / rodovia
  URB BOOLEAN,                  -- área urbana
  LAT DOUBLE PRECISION,
  LNG DOUBLE PRECISION
);

CREATE UNIQUE INDEX ux_dim_loc_key ON dw.dim_loc(UND_FED, MUN, BRR, URB, LAT, LNG);

CREATE INDEX idx_dim_loc_und_fed ON dw.dim_loc(UND_FED);
CREATE INDEX idx_dim_loc_mun ON dw.dim_loc(MUN);
CREATE INDEX idx_dim_loc_brr ON dw.dim_loc(BRR);

COMMENT ON TABLE dw.dim_loc IS 'Dimensão de localização (UF, município, BR, urbano, lat/long)';

-- dim_TIP (Dimensão Tipo de Acidente)
DROP TABLE IF EXISTS dw.dim_tip CASCADE;

CREATE TABLE dw.dim_tip (
  SRK_TIP SERIAL PRIMARY KEY,
  TIP TEXT NOT NULL             -- tipo_acidente
);

CREATE UNIQUE INDEX ux_dim_tip_tip ON dw.dim_tip(TIP);

COMMENT ON TABLE dw.dim_tip IS 'Dimensão do tipo de acidente';

-- dim_CAU (Dimensão Causa)
DROP TABLE IF EXISTS dw.dim_cau CASCADE;

CREATE TABLE dw.dim_cau (
  SRK_CAU SERIAL PRIMARY KEY,
  CAU TEXT NOT NULL             -- causa_acidente
);

CREATE UNIQUE INDEX ux_dim_cau_cau ON dw.dim_cau(CAU);

COMMENT ON TABLE dw.dim_cau IS 'Dimensão da causa do acidente';

-- dim_CLA (Dimensão Classificação)
DROP TABLE IF EXISTS dw.dim_cla CASCADE;

CREATE TABLE dw.dim_cla (
  SRK_CLA SERIAL PRIMARY KEY,
  CLA VARCHAR(120) NOT NULL      -- classificacao_acidente
);

CREATE UNIQUE INDEX ux_dim_cla_cla ON dw.dim_cla(CLA);

COMMENT ON TABLE dw.dim_cla IS 'Dimensão da classificação do acidente';

-- dim_VIA (Dimensão Via / Características da via)
DROP TABLE IF EXISTS dw.dim_via CASCADE;

CREATE TABLE dw.dim_via (
  SRK_VIA SERIAL PRIMARY KEY,
  TPI VARCHAR(120),              -- tipo_pista
  TRC VARCHAR(120),              -- tracado_via
  SNT VARCHAR(120)               -- sentido_via
);

CREATE UNIQUE INDEX ux_dim_via_key ON dw.dim_via(TPI, TRC, SNT);

COMMENT ON TABLE dw.dim_via IS 'Dimensão de características da via';

-- dim_CON (Dimensão Condições / fase do dia / climática)
DROP TABLE IF EXISTS dw.dim_con CASCADE;

CREATE TABLE dw.dim_con (
  SRK_CON SERIAL PRIMARY KEY,
  FAS_DIA VARCHAR(80),               -- fase_dia
  CON_CLI VARCHAR(120)               -- condicao_metereologica (climática)
);

CREATE UNIQUE INDEX ux_dim_con_key ON dw.dim_con(FAS_DIA, CON_CLI);

COMMENT ON TABLE dw.dim_con IS 'Dimensão de condições (fase do dia + condição climática)';

-- ============================================================================
-- FATO
-- ============================================================================

-- FAT_ACI (Fato de Acidentes / Sinistros)
-- Grão: 1 linha = 1 sinistro (registro original)
DROP TABLE IF EXISTS dw.fat_aci CASCADE;

CREATE TABLE dw.fat_aci (
  SRK_ACI SERIAL PRIMARY KEY,  
  IDN BIGINT,    -- SRK da FATO
  SRK_TMP INTEGER NOT NULL,          -- SRK da DIM_TMP
  SRK_HOR INTEGER NOT NULL,          -- SRK da DIM_HOR
  SRK_LOC INTEGER NOT NULL,          -- SRK da DIM_LOC
  SRK_TIP INTEGER NOT NULL,          -- SRK da DIM_TIP      
  SRK_CAU INTEGER NOT NULL,          -- SRK da DIM_CAU
  SRK_CLA INTEGER NOT NULL,          -- SRK da DIM_CLA
  SRK_VIA INTEGER NOT NULL,          -- SRK da DIM_VIA
  SRK_CON INTEGER NOT NULL,          -- SRK da DIM_CON


  -- Chaves estrangeiras (SRKs das dimensões)
  CONSTRAINT FK_FAT_TMP FOREIGN KEY (SRK_TMP)  REFERENCES dw.dim_tmp(SRK_TMP),
  CONSTRAINT FK_FAT_HOR FOREIGN KEY (SRK_HOR) REFERENCES dw.dim_hor(SRK_HOR),
  CONSTRAINT FK_FAT_LOC FOREIGN KEY (SRK_LOC) REFERENCES dw.dim_loc(SRK_LOC),
  CONSTRAINT FK_FAT_TIP FOREIGN KEY (SRK_TIP) REFERENCES dw.dim_tip(SRK_TIP),
  CONSTRAINT FK_FAT_CAU FOREIGN KEY (SRK_CAU) REFERENCES dw.dim_cau(SRK_CAU),
  CONSTRAINT FK_FAT_CLA FOREIGN KEY (SRK_CLA) REFERENCES dw.dim_cla(SRK_CLA),
  CONSTRAINT FK_FAT_VIA FOREIGN KEY (SRK_VIA) REFERENCES dw.dim_via(SRK_VIA),
  CONSTRAINT FK_FAT_CON FOREIGN KEY (SRK_CON) REFERENCES dw.dim_con(SRK_CON),

  -- Chave natural de rastreio (da SILVER/RAW)
  IDN BIGINT,                           -- id original (silver.id)

  -- Medidas (QTD_*)
  QTD_PSA INTEGER,                      -- pessoas
  QTD_MRT INTEGER,                      -- mortos
  QTD_FRD INTEGER,                      -- feridos
  QTD_ILS INTEGER,                      -- ilesos
  QTD_VCL INTEGER,                      -- veículos


);

CREATE INDEX idx_fat_aci_tmp ON dw.fat_aci(SRK_TMP);
CREATE INDEX idx_fat_aci_loc ON dw.fat_aci(SRK_LOC);
CREATE INDEX idx_fat_aci_tip ON dw.fat_aci(SRK_TIP);
CREATE INDEX idx_fat_aci_cau ON dw.fat_aci(SRK_CAU);
CREATE INDEX idx_fat_aci_mrt ON dw.fat_aci(QTD_MRT) WHERE QTD_MRT > 0;

COMMENT ON TABLE dw.fat_aci IS 'Fato de sinistros/acidentes (grão = 1 sinistro), com SRKs e medidas (pessoas, mortos, feridos, etc.)';

-- ============================================================================
-- VIEW (opcional) — Fato enriquecida (join de dimensões)
-- ============================================================================
CREATE OR REPLACE VIEW dw.vw_fat_aci_enriquecida AS
SELECT
  f.SRK_ACI,
  f.IDN,
  t.DAT,
  h.HOR,
  l.UND_FED AS UF,
  l.MUN AS MUNICIPIO,
  l.BRR AS BR,
  l.URB AS AREA_URBANA,
  tip.TIP AS TIPO_ACIDENTE,
  cau.CAU AS CAUSA_ACIDENTE,
  cla.CLA AS CLASSIFICACAO_ACIDENTE,
  via.TPI AS TIPO_PISTA,
  via.TRC AS TRACADO_VIA,
  via.SNT AS SENTIDO_VIA,
  con.FDI AS FASE_DIA,
  con.CLI AS CONDICAO_CLIMATICA,
  f.QTD_ACI,
  f.QTD_PSA,
  f.QTD_MRT,
  f.QTD_FRD,
  f.QTD_ILS,
  f.QTD_VCL
FROM dw.fat_aci f
LEFT JOIN dw.dim_tmp t ON t.SRK_TMP = f.SRK_TMP
LEFT JOIN dw.dim_hor h ON h.SRK_HOR = f.SRK_HOR
LEFT JOIN dw.dim_loc l ON l.SRK_LOC = f.SRK_LOC
LEFT JOIN dw.dim_tip tip ON tip.SRK_TIP = f.SRK_TIP
LEFT JOIN dw.dim_cau cau ON cau.SRK_CAU = f.SRK_CAU
LEFT JOIN dw.dim_cla cla ON cla.SRK_CLA = f.SRK_CLA
LEFT JOIN dw.dim_via via ON via.SRK_VIA = f.SRK_VIA
LEFT JOIN dw.dim_con con ON con.SRK_CON = f.SRK_CON;

-- ============================================================================
-- FIM DO DDL dw
-- ============================================================================
