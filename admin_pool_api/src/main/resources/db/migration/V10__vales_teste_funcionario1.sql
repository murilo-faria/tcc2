INSERT INTO vales_colaborador (funcionario_id, tipo, valor, data_lancamento, observacao)
SELECT f.id, 'ADIANTAMENTO', 50.00, CURRENT_DATE, 'Vale teste 1'
FROM funcionarios f JOIN usuarios u ON u.id = f.usuario_id WHERE u.login = 'funcionario1'
AND NOT EXISTS (SELECT 1 FROM vales_colaborador v WHERE v.observacao = 'Vale teste 1');
INSERT INTO vales_colaborador (funcionario_id, tipo, valor, data_lancamento, observacao)
SELECT f.id, 'DINHEIRO_CLIENTE', 50.00, CURRENT_DATE, 'Vale teste 2'
FROM funcionarios f JOIN usuarios u ON u.id = f.usuario_id WHERE u.login = 'funcionario1'
AND NOT EXISTS (SELECT 1 FROM vales_colaborador v WHERE v.observacao = 'Vale teste 2');
