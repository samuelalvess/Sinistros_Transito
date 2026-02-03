-- ============================================================
-- Consultas SQL ENXUTAS (CTE + JOIN) - DW Sinistros de Trânsito
-- Esquema: dw
-- Fato:    dw.fat_mor
-- Dims:    dw.dim_tmp, dw.dim_loc, dw.dim_sin, dw.dim_via, dw.dim_cli
-- Medida:  qtd_mor
-- Observação: ajuste nomes de colunas se o seu ddl.sql tiver variações.
-- ============================================================

-- 1) Top 10 UFs com mais mortes
WITH uf_mortes AS (
  SELECT l.uni, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  GROUP BY l.uni
)
SELECT *
FROM uf_mortes
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 2) Top 10 municípios com mais mortes (dentro de uma UF)
-- Troque 'RO' pela UF desejada.
WITH mun_mortes AS (
  SELECT l.mun, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  WHERE l.uni = 'RO'
  GROUP BY l.mun
)
SELECT *
FROM mun_mortes
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 3) Mortes por dia da semana
WITH dow_mortes AS (
  SELECT t.dia_sem, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  GROUP BY t.dia_sem
)
SELECT *
FROM dow_mortes
ORDER BY mortos DESC;

-- ------------------------------------------------------------

-- 4) Fim de semana vs dias úteis (mortes e sinistros)
WITH comp AS (
  SELECT t.fim_sem, SUM(f.qtd_mor) AS mortos, COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  GROUP BY t.fim_sem
)
SELECT *
FROM comp
ORDER BY mortos DESC;

-- ------------------------------------------------------------

-- 5) Top 8 horários (hora cheia) com mais mortes
WITH horas AS (
  SELECT
    EXTRACT(HOUR FROM CAST(t.hor_aci AS time))::int AS hora,
    SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  GROUP BY EXTRACT(HOUR FROM CAST(t.hor_aci AS time))::int
)
SELECT *
FROM horas
ORDER BY mortos DESC
LIMIT 8;

-- ------------------------------------------------------------

-- 6) Top 10 condições meteorológicas por mortes
WITH met AS (
  SELECT c.con_met, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_cli c ON c.srk_cli = f.srk_cli
  GROUP BY c.con_met
)
SELECT *
FROM met
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 7) Top 10 tipos de acidente por mortes
WITH tipo AS (
  SELECT s.tip_aci, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_sin s ON s.srk_sin = f.srk_sin
  GROUP BY s.tip_aci
)
SELECT *
FROM tipo
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 8) Top 10 causas de acidente por mortes
WITH causa AS (
  SELECT s.cau_aci, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_sin s ON s.srk_sin = f.srk_sin
  GROUP BY s.cau_aci
)
SELECT *
FROM causa
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 9) Rodovias mais letais (top 10 por mortes)
WITH rod AS (
  SELECT l.rod, SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  WHERE l.rod IS NOT NULL AND l.rod <> ''
  GROUP BY l.rod
)
SELECT *
FROM rod
ORDER BY mortos DESC
LIMIT 10;

-- ------------------------------------------------------------

-- 10) Urbano vs não urbano (mortes + sinistros)
WITH urb AS (
  SELECT l.ara_urb, SUM(f.qtd_mor) AS mortos, COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  GROUP BY l.ara_urb
)
SELECT *
FROM urb
ORDER BY mortos DESC;

-- ============================================================
-- Fim do arquivo
-- ============================================================
