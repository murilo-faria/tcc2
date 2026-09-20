ALTER TABLE pedidos_produto ALTER COLUMN cliente_id DROP NOT NULL;
ALTER TABLE pedidos_produto ADD COLUMN IF NOT EXISTS funcionario_id BIGINT;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_pedido_funcionario') THEN
    ALTER TABLE pedidos_produto ADD CONSTRAINT fk_pedido_funcionario
      FOREIGN KEY (funcionario_id) REFERENCES funcionarios(id);
  END IF;
END $$;
