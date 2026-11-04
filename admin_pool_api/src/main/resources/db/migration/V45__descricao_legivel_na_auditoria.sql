ALTER TABLE registros_auditoria
    ADD COLUMN IF NOT EXISTS descricao VARCHAR(500);
