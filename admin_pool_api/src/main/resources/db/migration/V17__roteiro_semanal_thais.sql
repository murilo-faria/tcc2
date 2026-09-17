-- O roteiro é registrado nas piscinas; o app exibe apenas um nome por cliente.
DO $$
DECLARE thais BIGINT;
BEGIN
  SELECT f.id INTO thais
  FROM funcionarios f JOIN usuarios u ON u.id = f.usuario_id
  WHERE lower(u.nome) LIKE '%thais%' OR lower(u.nome) LIKE '%thaís%'
  LIMIT 1;

  UPDATE piscinas p SET dia_atendimento = 'Quarta'
  FROM clientes c
  WHERE p.cliente_id = c.id AND c.funcionario_id = thais
    AND c.nome IN ('Planeje', 'Angelica', 'Valtenis', 'Cinquentinha', 'Simone', 'Rafael', 'Milson', 'Sicoob', 'Ronaldo');

  UPDATE piscinas p SET dia_atendimento = 'Quinta'
  FROM clientes c
  WHERE p.cliente_id = c.id AND c.funcionario_id = thais
    AND c.nome IN ('Fernanda', 'Alessandra', 'Lucas Vinil', 'Cristina', 'Stephanie', 'Sirlene', 'Sabrina', 'Elizabete', 'Angela Portal', 'Nilson');

  UPDATE piscinas p SET dia_atendimento = 'Sexta'
  FROM clientes c
  WHERE p.cliente_id = c.id AND c.funcionario_id = thais
    AND c.nome IN ('Tatila', 'Michele', 'Alex', 'Junior', 'Valorka', 'Karina', 'Leticia', 'Paulo', 'Rodrigo', 'Helena');

  UPDATE piscinas p SET dia_atendimento = 'Sábado'
  FROM clientes c
  WHERE p.cliente_id = c.id AND c.funcionario_id = thais
    AND c.nome IN ('Wellington', 'Murilo');
END $$;
