UPDATE funcionarios f
SET percentual_mensalidade = 74.00
FROM usuarios u
WHERE f.usuario_id = u.id
  AND lower(u.nome) LIKE '%vitor%';
