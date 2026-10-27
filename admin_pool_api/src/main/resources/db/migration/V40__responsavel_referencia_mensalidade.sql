ALTER TABLE itens_cobranca
    ADD COLUMN IF NOT EXISTS responsavel_referencia_id BIGINT;

ALTER TABLE itens_cobranca
    ADD CONSTRAINT fk_item_cobranca_responsavel_referencia
    FOREIGN KEY (responsavel_referencia_id) REFERENCES funcionarios(id);

CREATE INDEX IF NOT EXISTS idx_item_cobranca_responsavel_referencia
    ON itens_cobranca (responsavel_referencia_id);
