DO $$
DECLARE vitor BIGINT; geovana BIGINT;
BEGIN
  SELECT f.id INTO vitor
  FROM funcionarios f JOIN usuarios u ON u.id = f.usuario_id
  WHERE lower(u.nome) LIKE '%vitor%'
  LIMIT 1;

  IF vitor IS NULL THEN RAISE EXCEPTION 'Colaborador Vitor não encontrado'; END IF;

  SELECT id INTO geovana FROM clientes WHERE lower(nome) = 'geovana' LIMIT 1;
  IF geovana IS NULL THEN
    INSERT INTO clientes(nome, valor_mensalidade, dia_vencimento, funcionario_id, ativo)
    VALUES ('Geovana', 260.00, 20, vitor, TRUE)
    RETURNING id INTO geovana;
  ELSE
    UPDATE clientes
    SET valor_mensalidade = 260.00, dia_vencimento = 20, funcionario_id = vitor, ativo = TRUE
    WHERE id = geovana;
  END IF;

  IF EXISTS (SELECT 1 FROM piscinas WHERE cliente_id = geovana AND nome = 'Piscina Geovana') THEN
    UPDATE piscinas
    SET responsavel_id = vitor, valor_mensalidade = 260.00
    WHERE cliente_id = geovana AND nome = 'Piscina Geovana';
  ELSE
    INSERT INTO piscinas(cliente_id, nome, endereco, responsavel_id, valor_mensalidade)
    VALUES (geovana, 'Piscina Geovana', NULL, vitor, 260.00);
  END IF;
END $$;
