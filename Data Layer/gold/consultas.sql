


------1 - DIAS DA SEMANA COM MAIS SINISTROS
 
 WITH dia AS (
  SELECT
    t.dia_sem,
    COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY t.dia_sem
),
top1 AS (
  SELECT dia_sem, sinistros
  FROM dia
  ORDER BY sinistros DESC
  LIMIT 1
)
SELECT * FROM top1

------2 - ESTADO COM MAIS SINISTROS

WITH uf AS (
  SELECT
    l.uni,
    COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY l.uni
),
top1 AS (
  SELECT uni, sinistros
  FROM uf
  ORDER BY sinistros DESC
  LIMIT 1
)
SELECT * FROM top1


------3 - BR's com a maior taxa de mortalidade (mortos / sinistros)

WITH br AS (
  SELECT
    l.rod AS br,
    COUNT(DISTINCT f.sin_id) AS sinistros,
    SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
    AND l.rod IS NOT NULL AND l.rod <> ''
  GROUP BY l.rod
)
SELECT
  br,
  sinistros,
  mortos,
  ROUND(mortos::numeric / NULLIF(sinistros,0), 4) AS taxa_mortalidade
FROM br
WHERE sinistros >= 1000
ORDER BY taxa_mortalidade DESC
LIMIT 5



------4 - Top causas de acidentes com mortos

WITH causa AS (
  SELECT
    s.cau_aci,
    COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_sin s ON s.srk_sin = f.srk_sin
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY s.cau_aci
),
top1 AS (
  SELECT cau_aci, sinistros
  FROM causa
  ORDER BY sinistros DESC
  LIMIT 1
)
SELECT * FROM top1


-------5 - top tipo de acidentes

WITH tipo AS (
  SELECT
    s.tip_aci,
    COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_sin s ON s.srk_sin = f.srk_sin
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY s.tip_aci
),
top1 AS (
  SELECT tip_aci, sinistros
  FROM tipo
  ORDER BY sinistros DESC
 
)
SELECT * FROM top1


------6 - Top br's com mais sinistros

WITH br AS (
  SELECT
    l.rod AS br,
    COUNT(*) AS sinistros
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
    AND l.rod IS NOT NULL
    AND l.rod <> ''
  GROUP BY l.rod
),
top1 AS (
  SELECT br, sinistros
  FROM br
  ORDER BY sinistros DESC
  LIMIT 1
)
SELECT * FROM top1


7----- Top 2 rodovias com mais sinistros

WITH br_rank AS (
  SELECT
    l.rod AS br,
    COUNT(DISTINCT f.sin_id) AS acidentes
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
    AND l.rod IS NOT NULL
    AND l.rod <> ''
  GROUP BY l.rod
),
top2 AS (
  SELECT br
  FROM br_rank
  ORDER BY acidentes DESC
  LIMIT 2
)
SELECT
  f.sin_id,
  l.rod AS br,
  l.uni,
  l.mun,
  t.dat_aci::date AS data_acidente,
  t.hor_aci,
  l.lat AS latitude,
  l.lon AS longitude,
  f.qtd_mor AS mortos
FROM dw.fat_mor f
JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
JOIN top2 x ON x.br = l.rod
WHERE l.lat IS NOT NULL
  AND l.lon IS NOT NULL
  AND l.lat BETWEEN -90 AND 90
  AND l.lon BETWEEN -180 AND 180
ORDER BY br, data_acidente, f.sin_id


8------ Top dias da semana

WITH dia AS (
  SELECT
    t.dia_sem,
    SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY t.dia_sem
),
top1 AS (
  SELECT dia_sem, mortos
  FROM dia
  ORDER BY mortos DESC
)
SELECT * FROM top1


9------- OUTLIERS
WITH br AS (
  SELECT
    l.rod AS br,
    COUNT(DISTINCT f.sin_id) AS acidentes
  FROM dw.fat_mor f
  JOIN dw.dim_loc l ON l.srk_loc = f.srk_loc
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
    AND l.rod IS NOT NULL
    AND l.rod <> ''
  GROUP BY l.rod
),
quartis AS (
  SELECT
    percentile_cont(0.25) WITHIN GROUP (ORDER BY acidentes) AS q1,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY acidentes) AS q3
  FROM br
),
limites AS (
  SELECT
    q1,
    q3,
    (q3 - q1) AS iqr,
    (q3 + 1.5 * (q3 - q1)) AS lim_superior
  FROM quartis
)
SELECT
  b.br,
  b.acidentes,
  l.lim_superior,
  CASE WHEN b.acidentes > l.lim_superior THEN 'OUTLIER' ELSE 'NORMAL' END AS status
FROM br b
CROSS JOIN limites l
ORDER BY b.acidentes DESC


10 ----- TOP MESES COM MAIS SINISTROS

WITH meses AS (
  SELECT * FROM (VALUES
    (1, 'Janeiro'),
    (2, 'Fevereiro'),
    (3, 'Março'),
    (4, 'Abril'),
    (5, 'Maio'),
    (6, 'Junho'),
    (7, 'Julho'),
    (8, 'Agosto'),
    (9, 'Setembro'),
    (10, 'Outubro'),
    (11, 'Novembro'),
    (12, 'Dezembro')
  ) AS m(mes_num, mes_nome)
),
agg AS (
  SELECT
    EXTRACT(MONTH FROM t.dat_aci)::int AS mes_num,
    SUM(f.qtd_mor) AS mortos
  FROM dw.fat_mor f
  JOIN dw.dim_tmp t ON t.srk_tmp = f.srk_tmp
  WHERE t.dat_aci >= DATE '2025-01-01'
    AND t.dat_aci <  DATE '2026-01-01'
  GROUP BY 1
)
SELECT
  m.mes_nome,
  COALESCE(a.mortos, 0) AS mortos
FROM meses m
LEFT JOIN agg a ON a.mes_num = m.mes_num
ORDER BY m.mes_num
