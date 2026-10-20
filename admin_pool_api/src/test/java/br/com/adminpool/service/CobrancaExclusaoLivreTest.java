package br.com.adminpool.service;
import br.com.adminpool.model.*;
import br.com.adminpool.repository.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
class CobrancaExclusaoLivreTest {
    @Test void permiteExcluirMensalidadePagaESaldosDerivados() {
        var cobrancas = mock(CobrancaRepository.class);
        var itens = mock(ItemCobrancaRepository.class);
        var baixas = mock(BaixaItemCobrancaRepository.class);
        var service = new CobrancaService(cobrancas, mock(ClienteRepository.class), itens,
                baixas, mock(PiscinaRepository.class), mock(PedidoProdutoRepository.class));
        var c = new CobrancaMensal(); c.setId(1L); c.setVencimento(LocalDate.now());
        var item = new ItemCobranca(); item.setId(2L); item.setCobranca(c);
        item.setTipo(TipoLancamentoCobranca.MENSALIDADE);
        item.setValorOriginal(new BigDecimal("700")); item.setValorPago(new BigDecimal("700"));
        item.setStatus(StatusItemCobranca.PAGO);
        var saldo = new ItemCobranca(); saldo.setId(3L); saldo.setCobranca(c);
        saldo.setTipo(TipoLancamentoCobranca.SALDO_ANTERIOR);
        when(itens.findById(2L)).thenReturn(Optional.of(item));
        when(itens.findAllByTipoAndOrigemId(TipoLancamentoCobranca.SALDO_ANTERIOR, 2L)).thenReturn(List.of(saldo));
        when(itens.findByCobrancaIdOrderByDataLancamentoAscIdAsc(1L)).thenReturn(List.of(item));
        service.excluirItem(2L);
        verify(baixas).deleteByItemId(2L); verify(baixas).deleteByItemId(3L);
        verify(itens).delete(saldo); verify(itens).saveAndFlush(item);
        assertEquals(StatusItemCobranca.CANCELADO, item.getStatus());
        assertEquals(BigDecimal.ZERO, c.getTotal()); assertEquals(BigDecimal.ZERO, c.getValorPago());
        verify(itens, never()).delete(item);
    }
}
