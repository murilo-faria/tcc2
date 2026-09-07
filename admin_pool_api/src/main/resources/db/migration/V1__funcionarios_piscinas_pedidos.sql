ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS login VARCHAR(80);
CREATE UNIQUE INDEX IF NOT EXISTS ux_usuarios_login ON usuarios(login);
ALTER TABLE piscinas ADD COLUMN IF NOT EXISTS endereco VARCHAR(500);
ALTER TABLE piscinas ADD COLUMN IF NOT EXISTS responsavel_id BIGINT;
ALTER TABLE pedidos_produto ADD COLUMN IF NOT EXISTS piscina_id BIGINT;
DO $$ BEGIN
  ALTER TABLE piscinas ADD CONSTRAINT fk_piscina_responsavel FOREIGN KEY (responsavel_id) REFERENCES funcionarios(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
  ALTER TABLE pedidos_produto ADD CONSTRAINT fk_pedido_piscina FOREIGN KEY (piscina_id) REFERENCES piscinas(id);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
