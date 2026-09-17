ALTER TABLE piscinas ADD COLUMN IF NOT EXISTS valor_mensalidade NUMERIC(12,2) NOT NULL DEFAULT 0;
UPDATE piscinas p SET valor_mensalidade = c.valor_mensalidade FROM clientes c WHERE c.id=p.cliente_id AND p.valor_mensalidade=0 AND c.nome<>'Cinquentinha';
UPDATE piscinas SET valor_mensalidade=260 WHERE nome='Piscina Barcelona';
UPDATE piscinas SET valor_mensalidade=140 WHERE nome='Piscina Flamboyant';
