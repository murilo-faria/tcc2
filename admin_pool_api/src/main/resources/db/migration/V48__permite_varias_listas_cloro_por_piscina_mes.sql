-- Depois que uma lista é finalizada, outra pode ser aberta para a mesma
-- piscina no mesmo mês. Apenas a aplicação mantém uma lista aberta por vez.
DROP INDEX IF EXISTS uq_cloro_emergencial_piscina_mes;
