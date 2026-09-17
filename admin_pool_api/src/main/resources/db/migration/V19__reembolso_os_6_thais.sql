-- Correção da OS #6: paga pela colaboradora, com R$ 40,00 cobrados do cliente.
INSERT INTO reembolsos_colaborador (funcionario_id, ordem_servico_id, descricao, valor, data_lancamento, status)
SELECT p.responsavel_id, os.id, 'Reembolso - OS #' || os.id || ' - ' || c.nome,
       os.valor_cobrado, CURRENT_DATE, 'PENDENTE'
FROM ordens_servico os
JOIN clientes c ON c.id = os.cliente_id
JOIN piscinas p ON p.id = os.piscina_id
WHERE os.id = 6
  AND os.pago_por = 'FUNCIONARIO'
  AND os.valor_cobrado = 40.00
  AND p.responsavel_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM reembolsos_colaborador r WHERE r.ordem_servico_id = os.id);
