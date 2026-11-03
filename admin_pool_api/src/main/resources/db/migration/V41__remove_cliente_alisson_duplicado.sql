-- Limpeza pontual autorizada: cadastro duplicado sem piscina (cliente 251).
-- Remove primeiro os vínculos financeiros vazios e, por último, o cliente.
DELETE FROM baixas_itens_cobranca
WHERE item_cobranca_id IN (
    SELECT i.id
    FROM itens_cobranca i
    JOIN cobrancas_mensais c ON c.id = i.cobranca_id
    WHERE c.cliente_id = 251
);

DELETE FROM itens_cobranca
WHERE cobranca_id IN (SELECT id FROM cobrancas_mensais WHERE cliente_id = 251);

DELETE FROM cobrancas_mensais WHERE cliente_id = 251;
DELETE FROM roteiro_atendimentos WHERE cliente_id = 251;
DELETE FROM clientes WHERE id = 251 AND nome = 'Alisson duplicado';
