CREATE TABLE DATATRAN2025 (
    id INT PRIMARY KEY,
    data_inversa DATE NOT NULL,
    dia_semana VARCHAR(20),
    horario TIME,
    uf VARCHAR(2) NOT NULL,
    br INT,
    km DECIMAL(10, 2),
    municipio VARCHAR(100),
    causa_acidente VARCHAR(200),
    tipo_acidente VARCHAR(100),
    classificacao_acidente VARCHAR(50),
    fase_dia VARCHAR(30),
    sentido_via VARCHAR(20),
    condicao_metereologica VARCHAR(50),
    tipo_pista VARCHAR(30),
    tracado_via VARCHAR(50),
    uso_solo VARCHAR(20),
    pessoas INT DEFAULT 0,
    mortos INT DEFAULT 0,
    feridos_leves INT DEFAULT 0,
    feridos_graves INT DEFAULT 0,
    ilesos INT DEFAULT 0,
    ignorados INT DEFAULT 0,
    feridos INT DEFAULT 0,
    veiculos INT DEFAULT 0,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    regional VARCHAR(50),
    delegacia VARCHAR(50),
    uop VARCHAR(50)
);

CREATE INDEX idx_uf ON DATATRAN2025(uf);
CREATE INDEX idx_data ON DATATRAN2025(data_inversa);
CREATE INDEX idx_municipio ON DATATRAN2025(municipio);
