CREATE TABLE IF NOT EXISTS itens_cobranca (
    id BIGSERIAL PRIMARY KEY,
    cobranca_id BIGINT NOT NULL REFERENCES cobrancas_mensais(id),
    tipo VARCHAR(40) NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    origem_id BIGINT,
    data_lancamento DATE NOT NULL DEFAULT CURRENT_DATE,
    valor_original NUMERIC(12,2) NOT NULL,
    valor_pago NUMERIC(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDENTE',
    data_ultimo_pagamento DATE
);
CREATE INDEX IF NOT EXISTS ix_itens_cobranca_cliente ON itens_cobranca(cobranca_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS ux_item_origem ON itens_cobranca(tipo, origem_id) WHERE origem_id IS NOT NULL AND tipo IN ('PEDIDO','ORDEM_SERVICO');
CREATE UNIQUE INDEX IF NOT EXISTS ux_mensalidade_cobranca ON itens_cobranca(cobranca_id, tipo) WHERE tipo = 'MENSALIDADE';

INSERT INTO itens_cobranca(cobranca_id,tipo,descricao,data_lancamento,valor_original,valor_pago,status,data_ultimo_pagamento)
SELECT c.id,'MENSALIDADE','Mensalidade ' || c.referencia,c.vencimento,c.mensalidade,
       CASE WHEN c.status='PAGO' THEN c.mensalidade ELSE 0 END,
       CASE WHEN c.status='PAGO' THEN 'PAGO' ELSE 'PENDENTE' END,c.data_pagamento
FROM cobrancas_mensais c
WHERE c.mensalidade > 0 AND NOT EXISTS (SELECT 1 FROM itens_cobranca i WHERE i.cobranca_id=c.id AND i.tipo='MENSALIDADE');

INSERT INTO itens_cobranca(cobranca_id,tipo,descricao,data_lancamento,valor_original,valor_pago,status,data_ultimo_pagamento)
SELECT c.id,'PEDIDO','Produtos (histórico)',c.vencimento,c.produtos,
       CASE WHEN c.status='PAGO' THEN c.produtos ELSE 0 END,
       CASE WHEN c.status='PAGO' THEN 'PAGO' ELSE 'PENDENTE' END,c.data_pagamento
FROM cobrancas_mensais c
WHERE c.produtos > 0 AND NOT EXISTS (SELECT 1 FROM itens_cobranca i WHERE i.cobranca_id=c.id AND i.tipo='PEDIDO');

INSERT INTO itens_cobranca(cobranca_id,tipo,descricao,data_lancamento,valor_original,valor_pago,status,data_ultimo_pagamento)
SELECT c.id,'ORDEM_SERVICO','Serviços (histórico)',c.vencimento,c.servicos,
       CASE WHEN c.status='PAGO' THEN c.servicos ELSE 0 END,
       CASE WHEN c.status='PAGO' THEN 'PAGO' ELSE 'PENDENTE' END,c.data_pagamento
FROM cobrancas_mensais c
WHERE c.servicos > 0 AND NOT EXISTS (SELECT 1 FROM itens_cobranca i WHERE i.cobranca_id=c.id AND i.tipo='ORDEM_SERVICO');

CREATE TABLE IF NOT EXISTS baixas_itens_cobranca (
    id BIGSERIAL PRIMARY KEY,
    item_cobranca_id BIGINT NOT NULL REFERENCES itens_cobranca(id),
    valor NUMERIC(12,2) NOT NULL,
    data_pagamento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    forma_pagamento VARCHAR(80),
    grupo_pagamento VARCHAR(80)
);
