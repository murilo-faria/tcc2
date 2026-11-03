-- Limpeza autorizada do cadastro inativo "Allison" (com i), incluindo os
-- vínculos operacionais e financeiros. Não afeta o cliente "Alisson ADV".

DELETE FROM baixas_itens_cobranca
WHERE item_cobranca_id IN (
    SELECT item.id
    FROM itens_cobranca item
    JOIN cobrancas_mensais cobranca ON cobranca.id = item.cobranca_id
    JOIN clientes cliente ON cliente.id = cobranca.cliente_id
    WHERE lower(trim(cliente.nome)) = 'allison'
);

DELETE FROM itens_cobranca
WHERE cobranca_id IN (
    SELECT cobranca.id
    FROM cobrancas_mensais cobranca
    JOIN clientes cliente ON cliente.id = cobranca.cliente_id
    WHERE lower(trim(cliente.nome)) = 'allison'
);

DELETE FROM cobrancas_mensais
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM reembolsos_colaborador
WHERE ordem_servico_id IN (
    SELECT id FROM ordens_servico
    WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison')
);

DELETE FROM pedidos_produto
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM ordens_servico
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM cloros_emergenciais
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM roteiro_atendimentos
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM piscinas
WHERE cliente_id IN (SELECT id FROM clientes WHERE lower(trim(nome)) = 'allison');

DELETE FROM clientes WHERE lower(trim(nome)) = 'allison';
