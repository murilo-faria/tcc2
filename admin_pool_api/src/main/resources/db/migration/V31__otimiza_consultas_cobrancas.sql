-- Índices somente de leitura: não modificam dados financeiros existentes.
CREATE INDEX IF NOT EXISTS ix_cobrancas_cliente_referencia
    ON cobrancas_mensais(cliente_id, referencia);

CREATE INDEX IF NOT EXISTS ix_cobrancas_referencia_vencimento
    ON cobrancas_mensais(referencia, vencimento);

CREATE INDEX IF NOT EXISTS ix_cobrancas_status_vencimento
    ON cobrancas_mensais(status, vencimento);

CREATE INDEX IF NOT EXISTS ix_itens_cobranca_cobranca_tipo
    ON itens_cobranca(cobranca_id, tipo);
