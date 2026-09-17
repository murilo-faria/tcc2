DO $$ DECLARE orlando BIGINT; samuel BIGINT; BEGIN
 SELECT f.id INTO orlando FROM funcionarios f JOIN usuarios u ON u.id=f.usuario_id WHERE lower(u.nome) LIKE '%orlando%' LIMIT 1;
 CREATE TEMP TABLE dados_orlando(nome TEXT, valor NUMERIC, vencimento INT) ON COMMIT DROP;
 INSERT INTO dados_orlando VALUES ('Cláudio',190,10),('Bruno',170,10),('Rafael',160,10),('Maycon',250,10),('Elaine Susy',150,10),('Jessica',250,10),('Natação',700,25),('Edna',200,20),('Camila',400,20),('Ipanema',500,10),('Anna',250,10),('Felipe',250,15),('Adylla',170,10),('Anderson',210,10),('Matheus',300,25),('Lucas',450,25),('Fernanda',250,10),('Divino',280,10),('Vinicius',250,10),('Melissa',300,10),('Casinha',270,10),('Juliana',360,10),('Walessa',250,10),('Gessilene',250,25),('Fausto',270,10);
 INSERT INTO clientes(nome,valor_mensalidade,dia_vencimento,funcionario_id,ativo) SELECT nome,valor,vencimento,orlando,TRUE FROM dados_orlando d WHERE NOT EXISTS(SELECT 1 FROM clientes c WHERE lower(c.nome)=lower(d.nome) AND c.funcionario_id=orlando);
 INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade) SELECT c.id,'Piscina '||d.nome,NULL,orlando,d.valor FROM dados_orlando d JOIN clientes c ON lower(c.nome)=lower(d.nome) AND c.funcionario_id=orlando WHERE NOT EXISTS(SELECT 1 FROM piscinas p WHERE p.cliente_id=c.id AND p.nome='Piscina '||d.nome);
 INSERT INTO clientes(nome,valor_mensalidade,dia_vencimento,funcionario_id,ativo) SELECT 'Samuel',280,10,orlando,TRUE WHERE NOT EXISTS(SELECT 1 FROM clientes WHERE nome='Samuel' AND funcionario_id=orlando);
 SELECT id INTO samuel FROM clientes WHERE nome='Samuel' AND funcionario_id=orlando LIMIT 1;
 INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade) SELECT samuel,'Piscina Venda',NULL,orlando,140 WHERE NOT EXISTS(SELECT 1 FROM piscinas WHERE cliente_id=samuel AND nome='Piscina Venda');
 INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade) SELECT samuel,'Piscina Samuel',NULL,orlando,140 WHERE NOT EXISTS(SELECT 1 FROM piscinas WHERE cliente_id=samuel AND nome='Piscina Samuel');
END $$;
