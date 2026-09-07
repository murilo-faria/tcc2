package br.com.adminpool.service;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.StatusCobranca;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

/** Regras de negócio relacionadas ao fechamento mensal dos clientes. */
@Service
public class CobrancaService {

    private final CobrancaRepository cobrancas;
    private final ClienteRepository clientes;

    public CobrancaService(CobrancaRepository cobrancas, ClienteRepository clientes) {
        this.cobrancas = cobrancas;
        this.clientes = clientes;
    }

    public List<CobrancaMensal> listarPorVencimento() {
        return cobrancas.findAllByOrderByVencimentoAsc();
    }

    public List<CobrancaMensal> listarMesAtual() {
        YearMonth mesAtual = YearMonth.now();
        gerarMes(mesAtual);
        // Mantém apenas uma previsão: o mês seguinte. Não antecipa o ano inteiro.
        gerarMes(mesAtual.plusMonths(1));
        atualizarAtrasos();
        return cobrancas.findMesAtualComAtrasos(mesAtual.toString(), mesAtual.atDay(1));
    }

    /** Consulta um mês já gerado. Somente o mês vigente é criado automaticamente. */
    public List<CobrancaMensal> listarPorReferencia(String referencia) {
        YearMonth mes = YearMonth.parse(referencia);
        if (mes.equals(YearMonth.now())) {
            return listarMesAtual();
        }
        return cobrancas.findByReferenciaOrderByVencimentoAsc(mes.toString());
    }

    public List<String> listarReferencias() {
        return cobrancas.findAllByOrderByReferenciaDescVencimentoAsc().stream()
                .map(CobrancaMensal::getReferencia)
                .distinct()
                .toList();
    }

    private void atualizarAtrasos() {
        LocalDate hoje = LocalDate.now();
        List<CobrancaMensal> atrasadas = cobrancas.findAll().stream()
                .filter(c -> c.getStatus() == StatusCobranca.PENDENTE && c.getVencimento().isBefore(hoje))
                .toList();
        atrasadas.forEach(c -> c.setStatus(StatusCobranca.VENCIDO));
        cobrancas.saveAll(atrasadas);
    }

    public CobrancaMensal gerar(Cliente cliente, YearMonth mes) {
        if (cliente.getDiaVencimento() == null) {
            throw new IllegalArgumentException("Cliente sem dia de vencimento");
        }

        CobrancaMensal cobranca = new CobrancaMensal();
        cobranca.setCliente(cliente);
        cobranca.setReferencia(mes.toString());

        int diaValido = Math.min(cliente.getDiaVencimento(), mes.lengthOfMonth());
        cobranca.setVencimento(mes.atDay(diaValido));
        cobranca.setMensalidade(cliente.getValorMensalidade());
        cobranca.setProdutos(BigDecimal.ZERO);
        cobranca.setServicos(BigDecimal.ZERO);
        cobranca.setTotal(cliente.getValorMensalidade());

        return cobrancas.save(cobranca);
    }

    public List<CobrancaMensal> gerarMesAtual() {
        return gerarMes(YearMonth.now());
    }

    public List<CobrancaMensal> gerarMes(YearMonth mesAtual) {
        List<CobrancaMensal> resultado = new ArrayList<>();

        for (Cliente cliente : clientes.findAll()) {
            if (cliente.isAtivo() && cliente.getDiaVencimento() != null && !cobrancas.existsByClienteIdAndReferencia(cliente.getId(), mesAtual.toString())) {
                resultado.add(gerar(cliente, mesAtual));
            }
        }
        return resultado;
    }

    public CobrancaMensal darBaixa(Long id, BigDecimal valorPago) {
        CobrancaMensal cobranca = cobrancas.findById(id).orElseThrow();
        cobranca.setStatus(StatusCobranca.PAGO);
        cobranca.setDataPagamento(LocalDate.now());
        cobranca.setValorPago(valorPago);
        return cobrancas.save(cobranca);
    }

    public CobrancaMensal reabrir(Long id) {
        CobrancaMensal cobranca = cobrancas.findById(id).orElseThrow();
        StatusCobranca novoStatus = cobranca.getVencimento().isBefore(LocalDate.now())
                ? StatusCobranca.VENCIDO
                : StatusCobranca.PENDENTE;

        cobranca.setStatus(novoStatus);
        cobranca.setDataPagamento(null);
        cobranca.setValorPago(null);
        return cobrancas.save(cobranca);
    }
}
