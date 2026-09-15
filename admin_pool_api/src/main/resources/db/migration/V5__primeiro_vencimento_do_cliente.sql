ALTER TABLE clientes ADD COLUMN IF NOT EXISTS primeiro_vencimento DATE;
UPDATE clientes
SET primeiro_vencimento = make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT,EXTRACT(MONTH FROM CURRENT_DATE)::INT,
    LEAST(COALESCE(dia_vencimento,10),EXTRACT(DAY FROM (date_trunc('month',CURRENT_DATE)+interval '1 month - 1 day'))::INT))
WHERE primeiro_vencimento IS NULL;
