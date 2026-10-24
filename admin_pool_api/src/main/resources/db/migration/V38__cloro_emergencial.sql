CREATE TABLE IF NOT EXISTS cloros_emergenciais (
    id BIGSERIAL PRIMARY KEY,
    cliente_id BIGINT NOT NULL REFERENCES clientes(id),
    criado_por_id BIGINT REFERENCES funcionarios(id),
    referencia VARCHAR(7) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'ABERTA',
    valor_cobrado NUMERIC(12,2) NOT NULL DEFAULT 0,
    data_conclusao DATE,
    CONSTRAINT uq_cloro_emergencial_cliente_mes UNIQUE (cliente_id, referencia)
);

CREATE TABLE IF NOT EXISTS usos_cloro_emergencial (
    id BIGSERIAL PRIMARY KEY,
    cloro_emergencial_id BIGINT NOT NULL REFERENCES cloros_emergenciais(id) ON DELETE CASCADE,
    quantidade_kg NUMERIC(10,2) NOT NULL,
    descricao VARCHAR(1000),
    data_uso DATE NOT NULL DEFAULT CURRENT_DATE
);
