DO $$ DECLARE cliente_rodrigo BIGINT; BEGIN
  SELECT id INTO cliente_rodrigo FROM clientes WHERE nome='Aurora' LIMIT 1;
  IF cliente_rodrigo IS NOT NULL THEN
    UPDATE clientes SET nome='Rodrigo' WHERE id=cliente_rodrigo;
    UPDATE piscinas SET nome='Aurora' WHERE cliente_id=cliente_rodrigo AND nome='Piscina Aurora';
  END IF;
END $$;
