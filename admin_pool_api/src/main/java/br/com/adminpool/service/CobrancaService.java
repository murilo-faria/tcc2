package br.com.adminpool.service;

import br.com.adminpool.dto.ResumoCobrancaCliente;
import br.com.adminpool.dto.FluxoCaixaEntrada;
import br.com.adminpool.model.BaixaItemCobranca;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.StatusCobranca;
import br.com.adminpool.model.StatusItemCobranca;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.repository.BaixaItemCobrancaRepository;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
import br.com.adminpool.repository.PiscinaRepository;
import jakarta.transaction.Transactional;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class CobrancaService {

    private static final List<StatusItemCobranca> STATUS_EM_ABERTO =
            List.of(StatusItemCobranca.PENDENTE, StatusItemCobranca.PARCIAL);

    private final CobrancaRepository cobrancas;
    private final ClienteRepository clientes;
    private final ItemCobrancaRepository itens;
    private final BaixaItemCobrancaRepository baixas;
    private final PiscinaRepository piscinas;

    public CobrancaService(CobrancaRepository cobrancas, ClienteRepository clientes,
                           ItemCobrancaRepository itens, BaixaItemCobrancaRepository baixas,
                           PiscinaRepository piscinas) {
        this.cobrancas = cobrancas;
        this.clientes = clientes;
        this.itens = itens;
        this.baixas = baixas;
        this.piscinas = piscinas;
    }

    public List<CobrancaMensal> listarPorVencimento() {
        atualizarAtrasos();
        return cobrancas.findAllByOrderByVencimentoAsc();
    }

    public List<CobrancaMensal> listarMesAtual() {
        YearMonth mesAtual = YearMonth.now();
        gerarMes(mesAtual);
        atualizarAtrasos();
        return cobrancas.findMesAtualComAtrasos(mesAtual.toString(), mesAtual.atDay(1));
    }

    public List<CobrancaMensal> listarPorReferencia(String referencia) {
        YearMonth mes = YearMonth.parse(referencia);
        if (mes.equals(YearMonth.now())) {
            gerarMes(mes);
        }
        atualizarAtrasos();
        return cobrancas.findByReferenciaOrderByVencimentoAsc(mes.toString());
    }

    public List<String> listarReferencias() {
        return cobrancas.findAllByOrderByReferenciaDescVencimentoAsc().stream()
                .map(CobrancaMensal::getReferencia)
                .distinct()
                .toList();
    }

    public List<ItemCobranca> listarItensCliente(Long clienteId) {
        gerarMes(YearMonth.now());
        atualizarAtrasos();
        return itens.findByCobrancaClienteIdOrderByCobrancaReferenciaAscDataLancamentoAscIdAsc(clienteId);
    }

    public ItemCobranca detalharItem(Long itemId) {
        return itens.findById(itemId).orElseThrow();
    }

    public List<ItemCobranca> listarItensPendentesCliente(Long clienteId) {
        gerarMes(YearMonth.now());
        atualizarAtrasos();
        return itens.findByCobrancaClienteIdAndStatusInOrderByCobrancaReferenciaAscDataLancamentoAscIdAsc(
                clienteId, STATUS_EM_ABERTO);
    }

    public List<ResumoCobrancaCliente> listarResumoClientes() {
        gerarMes(YearMonth.now());
        atualizarAtrasos();
        // Clientes inativos continuam aparecendo caso ainda tenham débitos antigos.
        return clientes.findAll().stream().map(cliente -> {
            List<ItemCobranca> pendentes = itens
                    .findByCobrancaClienteIdAndStatusInOrderByCobrancaReferenciaAscDataLancamentoAscIdAsc(
                            cliente.getId(), STATUS_EM_ABERTO);
            BigDecimal total = pendentes.stream().map(ItemCobranca::getSaldoPendente)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            boolean atrasado = pendentes.stream().anyMatch(item -> item.getVencimento().isBefore(LocalDate.now()));
            return new ResumoCobrancaCliente(cliente.getId(), cliente.getNome(), total, pendentes.size(), atrasado);
        }).sorted(Comparator
                .comparingInt((ResumoCobrancaCliente resumo) -> resumo.possuiAtraso() ? 0
                        : resumo.totalPendente().compareTo(BigDecimal.ZERO) > 0 ? 1 : 2)
                .thenComparing(ResumoCobrancaCliente::clienteNome, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    public BigDecimal fluxoCaixaMesAtual() {
        return listarFluxoCaixa(YearMonth.now()).stream()
                .map(FluxoCaixaEntrada::valor).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    public List<FluxoCaixaEntrada> listarFluxoCaixa(YearMonth mes) {
        return baixas.findByDataPagamentoBetween(mes.atDay(1).atStartOfDay(), mes.atEndOfMonth().atTime(LocalTime.MAX))
                .stream()
                .sorted(Comparator.comparing(BaixaItemCobranca::getDataPagamento).reversed())
                .map(baixa -> new FluxoCaixaEntrada(baixa.getId(), baixa.getItem().getCobranca().getCliente().getNome(),
                        baixa.getItem().getDescricao(), baixa.getValor(), baixa.getFormaPagamento(), baixa.getDataPagamento(),
                        baixa.getItem().getReferencia()))
                .toList();
    }

    public List<String> referenciasFluxoCaixa() {
        return baixas.findAllByOrderByDataPagamentoDesc().stream()
                .map(baixa -> YearMonth.from(baixa.getDataPagamento()).toString())
                .distinct().toList();
    }

    @Scheduled(cron = "0 5 0 1 * *", zone = "America/Sao_Paulo")
    public void gerarCobrancasNaViradaDoMes() {
        gerarMes(YearMonth.now());
    }

    @Transactional
    public CobrancaMensal gerar(Cliente cliente, YearMonth mes) {
        return cobrancas.findByClienteIdAndReferencia(cliente.getId(), mes.toString())
                .orElseGet(() -> criarCobranca(cliente, mes));
    }

    @Transactional
    public List<CobrancaMensal> gerarMesAtual() {
        return gerarMes(YearMonth.now());
    }

    @Transactional
    public List<CobrancaMensal> gerarMes(YearMonth mes) {
        List<CobrancaMensal> resultado = new ArrayList<>();
        for (Cliente cliente : clientes.findAll()) {
            if (!deveGerarMensalidade(cliente, mes)) {
                continue;
            }
            CobrancaMensal cobranca = gerar(cliente, mes);
            garantirMensalidade(cobranca, cliente);
            resultado.add(cobranca);
        }
        return resultado;
    }

    @Transactional
    public ItemCobranca adicionarLancamento(Long clienteId, TipoLancamentoCobranca tipo,
                                             Long origemId, String descricao, BigDecimal valor) {
        if (valor == null || valor.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("O valor do lançamento deve ser maior que zero.");
        }
        if (origemId != null && itens.existsByTipoAndOrigemId(tipo, origemId)) {
            throw new IllegalStateException("Este lançamento já foi incluído na cobrança.");
        }
        Cliente cliente = clientes.findById(clienteId).orElseThrow();
        YearMonth referencia = referenciaParaNovoLancamento(cliente);
        CobrancaMensal cobranca = gerar(cliente, referencia);

        ItemCobranca item = new ItemCobranca();
        item.setCobranca(cobranca);
        item.setTipo(tipo);
        item.setOrigemId(origemId);
        item.setDescricao(descricao);
        item.setDataLancamento(LocalDate.now());
        item.setValorOriginal(valor);
        item.setValorPago(BigDecimal.ZERO);
        item.setStatus(StatusItemCobranca.PENDENTE);
        ItemCobranca salvo = itens.save(item);
        recalcular(cobranca);
        return salvo;
    }

    @Transactional
    public void removerLancamento(TipoLancamentoCobranca tipo, Long origemId) {
        ItemCobranca item = itens.findByTipoAndOrigemId(tipo, origemId)
                .orElseThrow(() -> new IllegalArgumentException("Lançamento de cobrança não encontrado."));
        if (item.getValorPago() != null && item.getValorPago().compareTo(BigDecimal.ZERO) > 0) {
            throw new IllegalStateException("Não é possível desfazer um pedido que já possui pagamento recebido.");
        }
        CobrancaMensal cobranca = item.getCobranca();
        itens.delete(item);
        itens.flush();
        recalcular(cobranca);
    }

    @Transactional
    public ItemCobranca baixarItem(Long itemId, BigDecimal valor, String formaPagamento) {
        ItemCobranca item = itens.findById(itemId).orElseThrow();
        BigDecimal saldo = item.getSaldoPendente();
        BigDecimal valorBaixa = valor == null ? saldo : valor;
        validarValorBaixa(valorBaixa, saldo);
        registrarBaixa(item, valorBaixa, formaPagamento, UUID.randomUUID().toString());
        if (valorBaixa.compareTo(saldo) < 0) {
            transferirSaldo(item);
        }
        return item;
    }

    @Transactional
    public void baixarItens(List<Long> itemIds, String formaPagamento) {
        if (itemIds == null || itemIds.isEmpty()) {
            throw new IllegalArgumentException("Selecione pelo menos um item.");
        }
        String grupo = UUID.randomUUID().toString();
        for (Long itemId : itemIds) {
            ItemCobranca item = itens.findById(itemId).orElseThrow();
            BigDecimal saldo = item.getSaldoPendente();
            if (saldo.compareTo(BigDecimal.ZERO) > 0) {
                registrarBaixa(item, saldo, formaPagamento, grupo);
            }
        }
    }

    @Transactional
    public void baixarTotalCliente(Long clienteId, String formaPagamento) {
        List<Long> ids = listarItensPendentesCliente(clienteId).stream().map(ItemCobranca::getId).toList();
        if (ids.isEmpty()) {
            throw new IllegalStateException("O cliente não possui valores pendentes.");
        }
        baixarItens(ids, formaPagamento);
    }

    @Transactional
    public void baixarParcialCliente(Long clienteId, BigDecimal valor, String formaPagamento) {
        List<ItemCobranca> pendentes = listarItensPendentesCliente(clienteId);
        BigDecimal total = pendentes.stream().map(ItemCobranca::getSaldoPendente)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        validarValorBaixa(valor, total);

        BigDecimal restantePagamento = valor;
        String grupo = UUID.randomUUID().toString();
        for (ItemCobranca item : pendentes) {
            if (restantePagamento.compareTo(BigDecimal.ZERO) <= 0) {
                break;
            }
            BigDecimal aplicado = restantePagamento.min(item.getSaldoPendente());
            registrarBaixa(item, aplicado, formaPagamento, grupo);
            restantePagamento = restantePagamento.subtract(aplicado);
        }
        pendentes.stream()
                .filter(item -> STATUS_EM_ABERTO.contains(item.getStatus()))
                .forEach(this::transferirSaldo);
    }

    private CobrancaMensal criarCobranca(Cliente cliente, YearMonth mes) {
        if (cliente.getDiaVencimento() == null) {
            throw new IllegalArgumentException("Cliente sem dia de vencimento.");
        }
        CobrancaMensal cobranca = new CobrancaMensal();
        cobranca.setCliente(cliente);
        cobranca.setReferencia(mes.toString());
        LocalDate primeiroVencimento = cliente.getPrimeiroVencimento();
        if (primeiroVencimento != null && YearMonth.from(primeiroVencimento).equals(mes)) {
            cobranca.setVencimento(primeiroVencimento);
        } else {
            int diaValido = Math.min(cliente.getDiaVencimento(), mes.lengthOfMonth());
            cobranca.setVencimento(mes.atDay(diaValido));
        }
        cobranca.setMensalidade(BigDecimal.ZERO);
        cobranca.setProdutos(BigDecimal.ZERO);
        cobranca.setServicos(BigDecimal.ZERO);
        cobranca.setTotal(BigDecimal.ZERO);
        cobranca.setValorPago(BigDecimal.ZERO);
        return cobrancas.save(cobranca);
    }

    private boolean deveGerarMensalidade(Cliente cliente, YearMonth mes) {
        if (!cliente.isAtivo() || cliente.getDiaVencimento() == null) {
            return false;
        }
        LocalDate primeiro = cliente.getPrimeiroVencimento();
        return primeiro == null || !mes.isBefore(YearMonth.from(primeiro));
    }

    private void garantirMensalidade(CobrancaMensal cobranca, Cliente cliente) {
        if (itens.existsByCobrancaIdAndTipo(cobranca.getId(), TipoLancamentoCobranca.MENSALIDADE)) {
            return;
        }
        ItemCobranca item = new ItemCobranca();
        item.setCobranca(cobranca);
        item.setTipo(TipoLancamentoCobranca.MENSALIDADE);
        item.setDescricao("Mensalidade " + cobranca.getReferencia());
        item.setDataLancamento(cobranca.getVencimento());
        item.setValorOriginal(valorMensalidadeDasPiscinas(cliente));
        item.setValorPago(BigDecimal.ZERO);
        item.setStatus(StatusItemCobranca.PENDENTE);
        itens.save(item);
        recalcular(cobranca);
    }

    private BigDecimal valorMensalidadeDasPiscinas(Cliente cliente) {
        return piscinas.findByClienteIdOrderByNome(cliente.getId()).stream()
                .map(piscina -> piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade())
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private YearMonth referenciaParaNovoLancamento(Cliente cliente) {
        YearMonth referencia = YearMonth.now();
        if (cliente.getPrimeiroVencimento() != null) {
            YearMonth primeiroMes = YearMonth.from(cliente.getPrimeiroVencimento());
            if (referencia.isBefore(primeiroMes)) {
                referencia = primeiroMes;
            }
        }
        CobrancaMensal atual = cobrancas.findByClienteIdAndReferencia(cliente.getId(), referencia.toString())
                .orElse(null);
        if (atual != null && atual.getStatus() == StatusCobranca.PAGO) {
            referencia = referencia.plusMonths(1);
        }
        return referencia;
    }

    private void registrarBaixa(ItemCobranca item, BigDecimal valor, String formaPagamento, String grupo) {
        BigDecimal novoValorPago = item.getValorPago().add(valor);
        item.setValorPago(novoValorPago);
        item.setDataUltimoPagamento(LocalDate.now());
        item.setStatus(novoValorPago.compareTo(item.getValorOriginal()) >= 0
                ? StatusItemCobranca.PAGO : StatusItemCobranca.PARCIAL);
        itens.save(item);

        BaixaItemCobranca baixa = new BaixaItemCobranca();
        baixa.setItem(item);
        baixa.setValor(valor);
        baixa.setFormaPagamento(formaPagamento);
        baixa.setGrupoPagamento(grupo);
        baixa.setDataPagamento(LocalDateTime.now());
        baixas.save(baixa);
        recalcular(item.getCobranca());
    }

    private void transferirSaldo(ItemCobranca item) {
        BigDecimal saldo = item.getSaldoPendente();
        if (saldo.compareTo(BigDecimal.ZERO) <= 0) {
            return;
        }
        YearMonth proximoMes = YearMonth.now().plusMonths(1);
        YearMonth referenciaItem = YearMonth.parse(item.getCobranca().getReferencia());
        if (referenciaItem.isAfter(proximoMes) || referenciaItem.equals(proximoMes)) {
            return;
        }

        CobrancaMensal destino = gerar(item.getCobranca().getCliente(), proximoMes);
        ItemCobranca saldoAnterior = new ItemCobranca();
        saldoAnterior.setCobranca(destino);
        saldoAnterior.setTipo(TipoLancamentoCobranca.SALDO_ANTERIOR);
        saldoAnterior.setOrigemId(item.getId());
        saldoAnterior.setDescricao("Saldo de " + item.getDescricao());
        saldoAnterior.setDataLancamento(LocalDate.now());
        saldoAnterior.setValorOriginal(saldo);
        saldoAnterior.setValorPago(BigDecimal.ZERO);
        saldoAnterior.setStatus(StatusItemCobranca.PENDENTE);
        itens.save(saldoAnterior);

        item.setStatus(StatusItemCobranca.TRANSFERIDO);
        itens.save(item);
        recalcular(item.getCobranca());
        recalcular(destino);
    }

    private void validarValorBaixa(BigDecimal valor, BigDecimal saldo) {
        if (valor == null || valor.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("O valor do pagamento deve ser maior que zero.");
        }
        if (valor.compareTo(saldo) > 0) {
            throw new IllegalArgumentException("O pagamento não pode ser maior que o saldo pendente.");
        }
    }

    private void atualizarAtrasos() {
        LocalDate hoje = LocalDate.now();
        for (CobrancaMensal cobranca : cobrancas.findAll()) {
            recalcular(cobranca);
            if (cobranca.getStatus() == StatusCobranca.PENDENTE && cobranca.getVencimento().isBefore(hoje)) {
                cobranca.setStatus(StatusCobranca.VENCIDO);
                cobrancas.save(cobranca);
            }
        }
    }

    private void recalcular(CobrancaMensal cobranca) {
        List<ItemCobranca> lista = itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(cobranca.getId());
        BigDecimal mensalidades = somarSaldo(lista, TipoLancamentoCobranca.MENSALIDADE, TipoLancamentoCobranca.SALDO_ANTERIOR);
        BigDecimal produtos = somarSaldo(lista, TipoLancamentoCobranca.PEDIDO);
        BigDecimal servicos = somarSaldo(lista, TipoLancamentoCobranca.ORDEM_SERVICO, TipoLancamentoCobranca.OUTRO);
        BigDecimal total = mensalidades.add(produtos).add(servicos);
        BigDecimal totalPago = lista.stream().map(ItemCobranca::getValorPago).reduce(BigDecimal.ZERO, BigDecimal::add);

        cobranca.setMensalidade(mensalidades);
        cobranca.setProdutos(produtos);
        cobranca.setServicos(servicos);
        cobranca.setTotal(total);
        cobranca.setValorPago(totalPago);
        if (!lista.isEmpty() && total.compareTo(BigDecimal.ZERO) == 0) {
            cobranca.setStatus(StatusCobranca.PAGO);
            cobranca.setDataPagamento(LocalDate.now());
        } else if (totalPago.compareTo(BigDecimal.ZERO) > 0) {
            cobranca.setStatus(StatusCobranca.PARCIAL);
            cobranca.setDataPagamento(null);
        } else {
            cobranca.setStatus(cobranca.getVencimento().isBefore(LocalDate.now())
                    ? StatusCobranca.VENCIDO : StatusCobranca.PENDENTE);
            cobranca.setDataPagamento(null);
        }
        cobrancas.save(cobranca);
    }

    private BigDecimal somarSaldo(List<ItemCobranca> lista, TipoLancamentoCobranca... tipos) {
        List<TipoLancamentoCobranca> tiposAceitos = List.of(tipos);
        return lista.stream().filter(item -> tiposAceitos.contains(item.getTipo()))
                .map(ItemCobranca::getSaldoPendente).reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
