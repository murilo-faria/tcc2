UPDATE funcionarios f
SET percentual_mensalidade = 74.00
FROM usuarios u
WHERE f.usuario_id = u.id
  AND (LOWER(u.nome) IN ('thaís kaim', 'thais kaim')
       OR LOWER(u.login) IN ('thais', 'thaiskaim'));

ALTER TABLE piscinas ADD COLUMN IF NOT EXISTS dia_atendimento VARCHAR(20);

UPDATE piscinas p
SET responsavel_id = f.id
FROM clientes c
JOIN funcionarios f ON TRUE
JOIN usuarios u ON u.id = f.usuario_id
WHERE p.cliente_id = c.id
  AND (LOWER(u.nome) IN ('thaís kaim', 'thais kaim')
       OR LOWER(u.login) IN ('thais', 'thaiskaim'))
  AND (LOWER(c.nome), c.valor_mensalidade) IN (
    ('planeje', 400.00), ('angelica', 190.00), ('angélica', 190.00),
    ('valtenis', 170.00), ('cinquentinha', 260.00), ('cinquentinha', 140.00),
    ('rafael', 150.00), ('milson', 200.00), ('sicob', 170.00), ('ronaldo', 170.00),
    ('fernanda', 260.00), ('alexandra', 280.00), ('lucas vinici', 300.00),
    ('cristina', 190.00), ('stephanie', 170.00), ('sirene', 190.00),
    ('sabrina', 260.00), ('elizabete', 190.00), ('nilson', 280.00),
    ('tatila', 190.00), ('michele', 260.00), ('alex', 200.00), ('junior', 465.00),
    ('valersca', 380.00), ('valersa', 380.00), ('angela portal', 260.00),
    ('karina', 300.00), ('osmar', 300.00), ('leticia', 240.00), ('paula', 280.00),
    ('aurora', 280.00), ('wellington', 270.00), ('murilo', 300.00), ('helena', 240.00)
  );

UPDATE piscinas p
SET dia_atendimento = CASE
  WHEN (LOWER(c.nome), c.valor_mensalidade) IN (('planeje',400.00),('angelica',190.00),('angélica',190.00),('valtenis',170.00),('cinquentinha',260.00),('cinquentinha',140.00),('rafael',150.00),('milson',200.00),('sicob',170.00),('ronaldo',170.00)) THEN 'Quarta'
  WHEN (LOWER(c.nome), c.valor_mensalidade) IN (('fernanda',260.00),('alexandra',280.00),('lucas vinici',300.00),('cristina',190.00),('stephanie',170.00),('sirene',190.00),('sabrina',260.00),('elizabete',190.00),('nilson',280.00)) THEN 'Quinta'
  WHEN (LOWER(c.nome), c.valor_mensalidade) IN (('tatila',190.00),('michele',260.00),('alex',200.00),('junior',465.00),('valersca',380.00),('valersa',380.00),('angela portal',260.00),('karina',300.00),('osmar',300.00),('leticia',240.00),('paula',280.00),('aurora',280.00)) THEN 'Sexta'
  WHEN (LOWER(c.nome), c.valor_mensalidade) IN (('wellington',270.00),('murilo',300.00),('helena',240.00)) THEN 'Sábado'
END
FROM clientes c
JOIN funcionarios f ON TRUE
JOIN usuarios u ON u.id = f.usuario_id
WHERE p.cliente_id = c.id
  AND (LOWER(u.nome) IN ('thaís kaim', 'thais kaim') OR LOWER(u.login) IN ('thais', 'thaiskaim'));
