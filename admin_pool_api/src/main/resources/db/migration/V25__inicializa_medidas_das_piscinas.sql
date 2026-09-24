UPDATE piscinas
SET comprimento = COALESCE(comprimento, 0),
    largura = COALESCE(largura, 0);
