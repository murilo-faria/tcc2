package br.com.adminpool.service;

import br.com.adminpool.model.*;
import br.com.adminpool.repository.*;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.YearMonth;

@Service
public class LancamentoCobrancaService {
    private final CobrancaRepository cobrancas;
    public LancamentoCobrancaService(CobrancaRepository cobrancas) { this.cobrancas = cobrancas; }
    public void adicionarProduto(Long clienteId, BigDecimal valor) { atualizar(clienteId, valor, true); }
    public void adicionarServico(Long clienteId, BigDecimal valor) { atualizar(clienteId, valor, false); }
    private void atualizar(Long clienteId, BigDecimal valor, boolean produto) {
        CobrancaMensal c = cobrancas.findByClienteIdAndReferencia(clienteId, YearMonth.now().toString()).orElseThrow(() -> new IllegalStateException("Cobrança do mês não encontrada"));
        if (produto) c.setProdutos(c.getProdutos().add(valor)); else c.setServicos(c.getServicos().add(valor));
        c.setTotal(c.getMensalidade().add(c.getProdutos()).add(c.getServicos()));
        cobrancas.save(c);
    }
}
