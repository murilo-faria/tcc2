package br.com.adminpool.service;

import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.repository.CobrancaRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.YearMonth;

/** Inclui produtos e serviços adicionais na cobrança do mês atual. */
@Service
public class LancamentoCobrancaService {

    private final CobrancaRepository cobrancas;

    public LancamentoCobrancaService(CobrancaRepository cobrancas) {
        this.cobrancas = cobrancas;
    }

    public void adicionarProduto(Long clienteId, BigDecimal valor) {
        atualizarCobranca(clienteId, valor, true);
    }

    public void adicionarServico(Long clienteId, BigDecimal valor) {
        atualizarCobranca(clienteId, valor, false);
    }

    private void atualizarCobranca(Long clienteId, BigDecimal valor, boolean produto) {
        String referenciaAtual = YearMonth.now().toString();
        CobrancaMensal cobranca = cobrancas
                .findByClienteIdAndReferencia(clienteId, referenciaAtual)
                .orElseThrow(() -> new IllegalStateException(
                        "Cobrança do mês não encontrada para o cliente"));

        if (produto) {
            cobranca.setProdutos(cobranca.getProdutos().add(valor));
        } else {
            cobranca.setServicos(cobranca.getServicos().add(valor));
        }

        BigDecimal total = cobranca.getMensalidade()
                .add(cobranca.getProdutos())
                .add(cobranca.getServicos());
        cobranca.setTotal(total);
        cobrancas.save(cobranca);
    }
}
