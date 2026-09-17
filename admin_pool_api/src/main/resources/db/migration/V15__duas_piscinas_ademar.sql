DO $$ DECLARE ademar BIGINT; vitor BIGINT; BEGIN
 SELECT id INTO ademar FROM clientes WHERE lower(nome)='ademar' LIMIT 1;
 SELECT f.id INTO vitor FROM funcionarios f JOIN usuarios u ON u.id=f.usuario_id WHERE lower(u.nome) LIKE '%vitor%' LIMIT 1;
 IF ademar IS NOT NULL THEN
   DELETE FROM piscinas WHERE cliente_id=ademar AND nome='Piscina Ademar';
   INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade) VALUES (ademar,'Piscina Chácara',NULL,vitor,300),(ademar,'Piscina Goiás',NULL,vitor,150);
   UPDATE clientes SET valor_mensalidade=450 WHERE id=ademar;
 END IF;
END $$;
