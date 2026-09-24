ALTER TABLE clientes ADD COLUMN data_inativacao DATE;

UPDATE clientes
SET data_inativacao = CURRENT_DATE
WHERE ativo = FALSE AND data_inativacao IS NULL;
