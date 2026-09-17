DO $$ DECLARE vitor BIGINT; rodrigo BIGINT; BEGIN
 SELECT f.id INTO vitor FROM funcionarios f JOIN usuarios u ON u.id=f.usuario_id WHERE lower(u.nome) LIKE '%vitor%' LIMIT 1;
 IF vitor IS NULL THEN RAISE EXCEPTION 'Colaborador Vitor não encontrado'; END IF;
 CREATE TEMP TABLE dados_vitor(nome TEXT, valor NUMERIC, vencimento INT) ON COMMIT DROP;
 INSERT INTO dados_vitor VALUES ('Amanda',210,10),('Sintego',300,10),('Wanessa',300,10),('Tarcisio',230,10),('Arão',250,15),('Semencio',230,10),('Duda',160,25),('Lucas',200,10),('Tacio',140,1),('Murilo',160,15),('Angélica',220,20),('Jeferson',240,20),('Leonardo Leite',170,20),('Luciano',160,15),('Geovana',260,20),('Milta',140,10),('Daniele Fidelis',270,10),('Dimerson',300,10),('Dr Pedro',250,20),('Matheus Lima',325,15),('Dr Bruno',500,10),('Fabim Guincho',250,5),('Henrique',240,20),('Thiago',400,15),('Sebastião',300,15),('Zeila',320,10),('Ademar',450,10),('Edson',280,10),('Maisa',270,10),('Marco',250,10),('Leandro Cordeiro',250,15),('Sandra',250,25),('Danival',160,10);
 INSERT INTO clientes(nome,valor_mensalidade,dia_vencimento,funcionario_id,ativo,primeiro_vencimento)
 SELECT d.nome,d.valor,d.vencimento,vitor,TRUE,CASE WHEN d.nome='Wanessa' THEN (date_trunc('month',CURRENT_DATE)+INTERVAL '1 month')::date ELSE NULL END FROM dados_vitor d WHERE NOT EXISTS(SELECT 1 FROM clientes c WHERE lower(c.nome)=lower(d.nome));
 INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade)
 SELECT c.id,'Piscina '||d.nome,NULL,vitor,d.valor FROM dados_vitor d JOIN clientes c ON lower(c.nome)=lower(d.nome) WHERE NOT EXISTS(SELECT 1 FROM piscinas p WHERE p.cliente_id=c.id AND p.nome='Piscina '||d.nome);
 SELECT id INTO rodrigo FROM clientes WHERE nome='Rodrigo' LIMIT 1;
 IF rodrigo IS NOT NULL THEN INSERT INTO piscinas(cliente_id,nome,endereco,responsavel_id,valor_mensalidade) SELECT rodrigo,'Rodrigo',NULL,vitor,360 WHERE NOT EXISTS(SELECT 1 FROM piscinas WHERE cliente_id=rodrigo AND nome='Rodrigo'); END IF;
END $$;
