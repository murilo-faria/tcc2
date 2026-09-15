-- Registra quem financiou a OS e o reembolso devido ao colaborador.
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS criado_por_id BIGINT REFERENCES funcionarios(id);
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS valor_custo NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS valor_cobrado NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS pago_por VARCHAR(30);
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS financeiro_lancado BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE ordens_servico ADD COLUMN IF NOT EXISTS data_conclusao DATE;
UPDATE ordens_servico SET valor_cobrado=COALESCE(valor_adicional,0),financeiro_lancado=(COALESCE(valor_adicional,0)>0);

CREATE TABLE IF NOT EXISTS reembolsos_colaborador (
    id BIGSERIAL PRIMARY KEY,
    funcionario_id BIGINT NOT NULL REFERENCES funcionarios(id),
    ordem_servico_id BIGINT NOT NULL UNIQUE REFERENCES ordens_servico(id),
    descricao VARCHAR(255) NOT NULL,
    valor NUMERIC(12,2) NOT NULL,
    data_lancamento DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    data_pagamento DATE
);
