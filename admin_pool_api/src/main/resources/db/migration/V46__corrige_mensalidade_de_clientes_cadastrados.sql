-- Corrige apenas clientes afetados pelo cadastro que gravava R$ 0,00 no
-- cliente, embora as piscinas vinculadas já tivessem a mensalidade correta.
UPDATE clientes c
SET valor_mensalidade = valores.total
FROM (
    SELECT cliente_id, SUM(valor_mensalidade) AS total
    FROM piscinas
    GROUP BY cliente_id
) valores
WHERE c.id = valores.cliente_id
  AND c.valor_mensalidade = 0
  AND valores.total > 0;
