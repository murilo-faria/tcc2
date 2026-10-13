package br.com.adminpool.service;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.BaixaItemCobranca;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.model.StatusCobranca;
import br.com.adminpool.model.StatusItemCobranca;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.repository.BaixaItemCobrancaRepository;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.mockito.ArgumentCaptor;

class CobrancaServicePerformanceTest {

    @Test
    void consultaDeMesEncerradoNaoRecalculaTodoHistorico() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        CobrancaService service = service(cobrancas, clientes, itens, mock(PiscinaRepository.class));
        String referenciaAntiga = YearMonth.now().minusMonths(1).toString();

        when(cobrancas.findComClienteEItensPorReferencia(referenciaAntiga)).thenReturn(List.of());

        assertEquals(List.of(), service.listarPorReferencia(referenciaAntiga));

        verify(cobrancas).marcarPendentesComoVencidas(
                eq(LocalDate.now()), eq(StatusCobranca.PENDENTE), eq(StatusCobranca.VENCIDO));
        verify(cobrancas).findComClienteEItensPorReferencia(referenciaAntiga);
        verify(cobrancas, never()).findAll();
        verify(clientes, never()).findAll();
        verify(itens, never()).findByCobrancaIdOrderByDataLancamentoAscIdAsc(any());
    }

    @Test
    void mensalidadePagaNaoEAlteradaNemDuplicadaNaGeracaoDoMes() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        PiscinaRepository piscinas = mock(PiscinaRepository.class);
        CobrancaService service = service(cobrancas, clientes, itens, piscinas);

        YearMonth mes = YearMonth.now();
        Cliente cliente = cliente(1L, mes);
        CobrancaMensal cobranca = cobranca(10L, cliente, mes);
        ItemCobranca mensalidadePaga = mensalidade(cobranca, "100.00", "100.00", StatusItemCobranca.PAGO);
        Piscina piscina = new Piscina();
        piscina.setCliente(cliente);
        piscina.setValorMensalidade(new BigDecimal("200.00"));

        when(clientes.findAll()).thenReturn(List.of(cliente));
        when(cobrancas.findComClienteEItensPorReferencia(mes.toString())).thenReturn(List.of(cobranca));
        when(itens.findByCobrancaIdInAndTipo(List.of(10L), TipoLancamentoCobranca.MENSALIDADE))
                .thenReturn(List.of(mensalidadePaga));
        when(piscinas.findByClienteIdIn(List.of(1L))).thenReturn(List.of(piscina));

        List<CobrancaMensal> resultado = service.gerarMes(mes);

        assertEquals(List.of(cobranca), resultado);
        assertEquals(new BigDecimal("100.00"), mensalidadePaga.getValorOriginal());
        verify(itens, never()).saveAll(any());
        verify(cobrancas, never()).save(any(CobrancaMensal.class));
        verify(itens, never()).findByCobrancaIdOrderByDataLancamentoAscIdAsc(any());
    }

    @Test
    void baixaParcialContinuaCriandoRegistroEManterSaldoPendente() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        BaixaItemCobrancaRepository baixas = mock(BaixaItemCobrancaRepository.class);
        CobrancaService service = service(cobrancas, mock(ClienteRepository.class), itens,
                mock(PiscinaRepository.class), baixas);
        YearMonth mesOriginal = YearMonth.now().minusMonths(1);
        Cliente cliente = cliente(1L, mesOriginal);
        CobrancaMensal cobranca = cobranca(10L, cliente, mesOriginal);
        ItemCobranca item = mensalidade(cobranca, "100.00", "0.00", StatusItemCobranca.PENDENTE);
        item.setId(50L);

        when(itens.findById(50L)).thenReturn(Optional.of(item));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(10L)).thenReturn(List.of(item));

        service.baixarItem(50L, new BigDecimal("40.00"), "PIX");

        assertEquals(new BigDecimal("40.00"), item.getValorPago());
        assertEquals(StatusItemCobranca.PARCIAL, item.getStatus());
        assertEquals(mesOriginal.atDay(10), cobranca.getVencimento());
        ArgumentCaptor<BaixaItemCobranca> baixa = ArgumentCaptor.forClass(BaixaItemCobranca.class);
        verify(baixas).save(baixa.capture());
        assertEquals(new BigDecimal("40.00"), baixa.getValue().getValor());
        assertEquals("PIX", baixa.getValue().getFormaPagamento());
    }

    @Test
    void baixaTotalContinuaMarcandoItemComoPagoERegistrandoValorIntegral() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        BaixaItemCobrancaRepository baixas = mock(BaixaItemCobrancaRepository.class);
        CobrancaService service = service(cobrancas, mock(ClienteRepository.class), itens,
                mock(PiscinaRepository.class), baixas);
        Cliente cliente = cliente(1L, YearMonth.now());
        CobrancaMensal cobranca = cobranca(10L, cliente, YearMonth.now());
        ItemCobranca item = mensalidade(cobranca, "100.00", "0.00", StatusItemCobranca.PENDENTE);
        item.setId(51L);

        when(itens.findById(51L)).thenReturn(Optional.of(item));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(10L)).thenReturn(List.of(item));

        service.baixarItem(51L, null, "PIX");

        assertEquals(new BigDecimal("100.00"), item.getValorPago());
        assertEquals(StatusItemCobranca.PAGO, item.getStatus());
        ArgumentCaptor<BaixaItemCobranca> baixa = ArgumentCaptor.forClass(BaixaItemCobranca.class);
        verify(baixas).save(baixa.capture());
        assertEquals(new BigDecimal("100.00"), baixa.getValue().getValor());
    }

    @Test
    void lancamentoParceladoGeraDuasCobrancasComValoresQueSomamOTotal() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        CobrancaService service = service(cobrancas, clientes, itens, mock(PiscinaRepository.class));
        YearMonth primeiroMes = YearMonth.now();
        Cliente cliente = cliente(1L, primeiroMes);
        CobrancaMensal primeiraCobranca = cobranca(10L, cliente, primeiroMes);
        primeiraCobranca.setStatus(StatusCobranca.PENDENTE);
        CobrancaMensal segundaCobranca = cobranca(11L, cliente, primeiroMes.plusMonths(1));
        when(clientes.findById(1L)).thenReturn(Optional.of(cliente));
        when(cobrancas.findByClienteIdAndReferencia(1L, primeiroMes.toString()))
                .thenReturn(Optional.of(primeiraCobranca));
        when(cobrancas.findByClienteIdAndReferencia(1L, primeiroMes.plusMonths(1).toString()))
                .thenReturn(Optional.of(segundaCobranca));
        when(itens.save(any(ItemCobranca.class))).thenAnswer(invocacao -> invocacao.getArgument(0));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(any())).thenReturn(List.of());

        List<ItemCobranca> parcelas = service.adicionarLancamentosParcelados(1L,
                TipoLancamentoCobranca.PEDIDO, 76L, "Pedido #76", new BigDecimal("401.01"), 2);

        assertEquals(2, parcelas.size());
        assertEquals(new BigDecimal("200.51"), parcelas.get(0).getValorOriginal());
        assertEquals(new BigDecimal("200.50"), parcelas.get(1).getValorOriginal());
        assertEquals(primeiroMes.atDay(10), parcelas.get(0).getVencimento());
        assertEquals(primeiroMes.plusMonths(1).atDay(10), parcelas.get(1).getVencimento());
    }

    @Test
    void excluirPedidoAntigoRemoveLancamentoIdentificadoPeloNumeroDaDescricao() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        Cliente cliente = cliente(1L, YearMonth.now());
        CobrancaMensal cobranca = cobranca(10L, cliente, YearMonth.now());
        ItemCobranca pedidoAntigo = mensalidade(cobranca, "420.00", "0.00", StatusItemCobranca.PENDENTE);
        pedidoAntigo.setTipo(TipoLancamentoCobranca.PEDIDO);
        pedidoAntigo.setDescricao("Pedido #65");
        pedidoAntigo.setOrigemId(999L);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        when(itens.findByTipo(TipoLancamentoCobranca.PEDIDO)).thenReturn(List.of(pedidoAntigo));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(10L)).thenReturn(List.of());
        CobrancaService service = service(cobrancas, mock(ClienteRepository.class), itens,
                mock(PiscinaRepository.class));

        service.removerLancamentosDePedidoSeExistirem(65L);

        verify(itens).delete(pedidoAntigo);
    }

    @Test
    void gestorPodeExcluirCobrancaPendenteDePedidoMesmoQueEleEstejaConcluido() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        Cliente cliente = cliente(1L, YearMonth.now());
        CobrancaMensal cobranca = cobranca(10L, cliente, YearMonth.now());
        ItemCobranca pedido = mensalidade(cobranca, "290.00", "0.00", StatusItemCobranca.PENDENTE);
        pedido.setId(65L);
        pedido.setTipo(TipoLancamentoCobranca.PEDIDO);
        pedido.setDescricao("Pedido #65");
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        when(itens.findById(65L)).thenReturn(Optional.of(pedido));
        when(itens.findByTipo(TipoLancamentoCobranca.PEDIDO)).thenReturn(List.of(pedido));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(10L)).thenReturn(List.of());
        CobrancaService service = service(cobrancas, mock(ClienteRepository.class), itens,
                mock(PiscinaRepository.class));

        service.excluirCobrancaDePedidoExcluido(65L);

        verify(itens).delete(pedido);
    }

    @Test
    void consultaDeCobrancaAtrasadaNaoAlteraCobrancaParcialJaPaga() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        CobrancaService service = service(cobrancas, mock(ClienteRepository.class),
                mock(ItemCobrancaRepository.class), mock(PiscinaRepository.class));
        YearMonth mesAnterior = YearMonth.now().minusMonths(1);
        CobrancaMensal cobrancaParcial = cobranca(10L, cliente(1L, mesAnterior), mesAnterior);
        cobrancaParcial.setStatus(StatusCobranca.PARCIAL);
        cobrancaParcial.setValorPago(new BigDecimal("40.00"));
        cobrancaParcial.setTotal(new BigDecimal("100.00"));
        cobrancaParcial.setVencimento(LocalDate.now().minusDays(1));

        when(cobrancas.findComClienteEItensPorReferencia(mesAnterior.toString()))
                .thenReturn(List.of(cobrancaParcial));

        List<CobrancaMensal> resultado = service.listarPorReferencia(mesAnterior.toString());

        assertEquals(List.of(cobrancaParcial), resultado);
        assertEquals(StatusCobranca.PARCIAL, cobrancaParcial.getStatus());
        assertEquals(new BigDecimal("40.00"), cobrancaParcial.getValorPago());
        verify(cobrancas).marcarPendentesComoVencidas(
                eq(LocalDate.now()), eq(StatusCobranca.PENDENTE), eq(StatusCobranca.VENCIDO));
    }

    @Test
    void alternarEntreMesesNaoDuplicaMensalidadeExistenteDoMesAtual() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        ItemCobrancaRepository itens = mock(ItemCobrancaRepository.class);
        PiscinaRepository piscinas = mock(PiscinaRepository.class);
        CobrancaService service = service(cobrancas, clientes, itens, piscinas);
        YearMonth setembro = YearMonth.now().minusMonths(1);
        YearMonth outubro = YearMonth.now();
        YearMonth novembro = YearMonth.now().plusMonths(1);
        Cliente cliente = cliente(1L, setembro);
        CobrancaMensal cobrancaOutubro = cobranca(10L, cliente, outubro);
        ItemCobranca mensalidadePaga = mensalidade(cobrancaOutubro, "100.00", "100.00", StatusItemCobranca.PAGO);

        when(clientes.findAll()).thenReturn(List.of(cliente));
        when(cobrancas.findComClienteEItensPorReferencia(setembro.toString())).thenReturn(List.of());
        when(cobrancas.findComClienteEItensPorReferencia(outubro.toString())).thenReturn(List.of(cobrancaOutubro));
        when(cobrancas.findComClienteEItensPorReferencia(novembro.toString())).thenReturn(List.of());
        when(itens.findByCobrancaIdInAndTipo(List.of(10L), TipoLancamentoCobranca.MENSALIDADE))
                .thenReturn(List.of(mensalidadePaga));
        when(piscinas.findByClienteIdIn(List.of(1L))).thenReturn(List.of());

        assertEquals(List.of(), service.listarPorReferencia(setembro.toString()));
        assertEquals(List.of(cobrancaOutubro), service.listarPorReferencia(outubro.toString()));
        assertEquals(List.of(), service.listarPorReferencia(novembro.toString()));

        verify(cobrancas, never()).save(any(CobrancaMensal.class));
        verify(itens, never()).saveAll(any());
    }

    @Test
    void resumoDaVisaoGeralNaoCarregaListaCompletaDeCobrancas() {
        CobrancaRepository cobrancas = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        CobrancaService service = service(cobrancas, clientes, mock(ItemCobrancaRepository.class),
                mock(PiscinaRepository.class));
        String referencia = YearMonth.now().toString();

        when(clientes.findAll()).thenReturn(List.of());
        when(clientes.countByAtivoTrue()).thenReturn(18L);
        when(cobrancas.findComClienteEItensPorReferencia(referencia)).thenReturn(List.of());
        when(cobrancas.resumirPendenciasDoMes(referencia, StatusCobranca.PAGO))
                .thenReturn(new Object[]{7L, new BigDecimal("1250.50")});

        var resumo = service.resumirVisaoGeral();

        assertEquals(18L, resumo.clientesAtivos());
        assertEquals(7L, resumo.cobrancasPendentes());
        assertEquals(new BigDecimal("1250.50"), resumo.faturamentoPrevisto());
        verify(cobrancas, never()).findMesAtualComAtrasos(any(), any());
    }

    private CobrancaService service(CobrancaRepository cobrancas, ClienteRepository clientes,
                                    ItemCobrancaRepository itens, PiscinaRepository piscinas) {
        return service(cobrancas, clientes, itens, piscinas, mock(BaixaItemCobrancaRepository.class));
    }

    private CobrancaService service(CobrancaRepository cobrancas, ClienteRepository clientes,
                                    ItemCobrancaRepository itens, PiscinaRepository piscinas,
                                    BaixaItemCobrancaRepository baixas) {
        return service(cobrancas, clientes, itens, piscinas, baixas, mock(PedidoProdutoRepository.class));
    }

    private CobrancaService service(CobrancaRepository cobrancas, ClienteRepository clientes,
                                    ItemCobrancaRepository itens, PiscinaRepository piscinas,
                                    BaixaItemCobrancaRepository baixas, PedidoProdutoRepository pedidos) {
        return new CobrancaService(cobrancas, clientes, itens, baixas, piscinas,
                pedidos);
    }

    private Cliente cliente(Long id, YearMonth mes) {
        Cliente cliente = new Cliente();
        cliente.setId(id);
        cliente.setAtivo(true);
        cliente.setDiaVencimento(10);
        cliente.setPrimeiroVencimento(mes.atDay(10));
        return cliente;
    }

    private CobrancaMensal cobranca(Long id, Cliente cliente, YearMonth mes) {
        CobrancaMensal cobranca = new CobrancaMensal();
        cobranca.setId(id);
        cobranca.setCliente(cliente);
        cobranca.setReferencia(mes.toString());
        cobranca.setVencimento(mes.atDay(10));
        cobranca.setStatus(StatusCobranca.PAGO);
        return cobranca;
    }

    private ItemCobranca mensalidade(CobrancaMensal cobranca, String original, String pago,
                                     StatusItemCobranca status) {
        ItemCobranca item = new ItemCobranca();
        item.setCobranca(cobranca);
        item.setTipo(TipoLancamentoCobranca.MENSALIDADE);
        item.setValorOriginal(new BigDecimal(original));
        item.setValorPago(new BigDecimal(pago));
        item.setStatus(status);
        return item;
    }
}
