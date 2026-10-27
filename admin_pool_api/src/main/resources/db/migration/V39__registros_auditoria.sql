CREATE TABLE IF NOT EXISTS registros_auditoria (
    id BIGSERIAL PRIMARY KEY,
    usuario_login VARCHAR(100) NOT NULL,
    acao VARCHAR(20) NOT NULL,
    modulo VARCHAR(100) NOT NULL,
    recurso VARCHAR(500) NOT NULL,
    data_hora TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dados_informados VARCHAR(4000),
    resultado VARCHAR(1000)
);

CREATE INDEX IF NOT EXISTS idx_registros_auditoria_data_hora
    ON registros_auditoria (data_hora DESC);
