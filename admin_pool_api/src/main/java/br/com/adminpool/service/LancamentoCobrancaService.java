package br.com.adminpool.service;

import br.com.adminpool.model.TipoLancamentoCobranca;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;

/** Compatibilidade para os lançamentos existentes até a conclusão de pedidos e OS. */
@Service
public class LancamentoCobrancaService {

    private final CobrancaService cobrancas;

    public LancamentoCobrancaService(CobrancaService cobrancas) {
        this.cobrancas = cobrancas;
    }

    public void adicionarProduto(Long clienteId, BigDecimal valor) {
        cobrancas.adicionarLancamento(clienteId, TipoLancamentoCobranca.PEDIDO,
                null, "Pedido de produto", valor);
    }

    public void adicionarServico(Long clienteId, BigDecimal valor) {
        cobrancas.adicionarLancamento(clienteId, TipoLancamentoCobranca.ORDEM_SERVICO,
                null, "Ordem de serviço", valor);
    }
}
