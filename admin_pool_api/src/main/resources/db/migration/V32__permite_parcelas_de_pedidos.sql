-- Um pedido parcelado possui dois itens de cobrança com a mesma origem.
-- A descrição diferencia as parcelas, enquanto a aplicação continua impedindo
-- que o mesmo pedido seja lançado novamente.
DROP INDEX IF EXISTS ux_item_origem;

CREATE UNIQUE INDEX IF NOT EXISTS ux_item_origem_descricao
    ON itens_cobranca(tipo, origem_id, descricao)
    WHERE origem_id IS NOT NULL AND tipo IN ('PEDIDO', 'ORDEM_SERVICO');
