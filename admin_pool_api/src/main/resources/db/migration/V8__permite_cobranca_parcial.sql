-- A cobrança pode ficar parcialmente paga enquanto ainda houver itens em aberto.
ALTER TABLE cobrancas_mensais
    DROP CONSTRAINT IF EXISTS cobrancas_mensais_status_check;

ALTER TABLE cobrancas_mensais
    ADD CONSTRAINT cobrancas_mensais_status_check
    CHECK (status IN ('PENDENTE', 'PARCIAL', 'PAGO', 'VENCIDO'));
