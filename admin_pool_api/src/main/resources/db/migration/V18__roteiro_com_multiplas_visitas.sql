CREATE TABLE roteiro_atendimentos (
  id BIGSERIAL PRIMARY KEY,
  cliente_id BIGINT NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
  dia_atendimento VARCHAR(20) NOT NULL,
  CONSTRAINT uk_roteiro_cliente_dia UNIQUE (cliente_id, dia_atendimento)
);

INSERT INTO roteiro_atendimentos (cliente_id, dia_atendimento)
SELECT DISTINCT cliente_id, dia_atendimento
FROM piscinas
WHERE dia_atendimento IS NOT NULL AND btrim(dia_atendimento) <> '';
