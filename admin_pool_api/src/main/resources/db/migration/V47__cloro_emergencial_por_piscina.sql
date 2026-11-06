-- Novas listas de cloro pertencem à piscina atendida. Os registros antigos
-- são preservados sem adivinhar a qual piscina eles pertenciam.
ALTER TABLE cloros_emergenciais ADD COLUMN IF NOT EXISTS piscina_id BIGINT;

-- Em registros antigos, vincula somente quando o colaborador que abriu a
-- lista é responsável por exatamente uma das piscinas do cliente. Casos
-- ambíguos permanecem sem vínculo para não atribuir cloro à piscina errada.
UPDATE cloros_emergenciais ce
SET piscina_id = correspondencia.piscina_id
FROM (
    SELECT ce2.id, MIN(p.id) AS piscina_id
    FROM cloros_emergenciais ce2
    JOIN piscinas p ON p.cliente_id = ce2.cliente_id
        AND p.responsavel_id = ce2.criado_por_id
    WHERE ce2.piscina_id IS NULL
    GROUP BY ce2.id
    HAVING COUNT(*) = 1
) correspondencia
WHERE ce.id = correspondencia.id;

ALTER TABLE cloros_emergenciais
    ADD CONSTRAINT fk_cloro_emergencial_piscina
    FOREIGN KEY (piscina_id) REFERENCES piscinas(id);

ALTER TABLE cloros_emergenciais
    DROP CONSTRAINT IF EXISTS uq_cloro_emergencial_cliente_mes;

CREATE UNIQUE INDEX IF NOT EXISTS uq_cloro_emergencial_piscina_mes
    ON cloros_emergenciais(piscina_id, referencia);
