-- Correção do vínculo regravado pelo importador automático já desativado.
-- Mantém o responsável histórico das cobranças já existentes; altera somente
-- a responsabilidade operacional da piscina para os próximos ciclos.
UPDATE piscinas
SET responsavel_id = (
    SELECT f.id
    FROM funcionarios f
    JOIN usuarios u ON u.id = f.usuario_id
    WHERE lower(u.nome) LIKE '%victor%'
    LIMIT 1
)
WHERE nome = 'Piscina Eduardo'
  AND cliente_id IN (
      SELECT id FROM clientes WHERE lower(nome) = 'eduardo'
  );
