package br.com.adminpool.repository;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.StatusItemCobranca;
import br.com.adminpool.model.TipoLancamentoCobranca;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.time.LocalDate;

public interface ItemCobrancaRepository extends JpaRepository<ItemCobranca,Long> {
    List<ItemCobranca> findByCobrancaIdOrderByDataLancamentoAscIdAsc(Long cobrancaId);
    List<ItemCobranca> findByCobrancaClienteIdOrderByCobrancaReferenciaAscDataLancamentoAscIdAsc(Long clienteId);
    List<ItemCobranca> findByCobrancaClienteIdAndStatusInOrderByCobrancaReferenciaAscDataLancamentoAscIdAsc(Long clienteId, List<StatusItemCobranca> status);
    boolean existsByCobrancaIdAndTipo(Long cobrancaId, TipoLancamentoCobranca tipo);
    boolean existsByTipoAndOrigemId(TipoLancamentoCobranca tipo, Long origemId);
    Optional<ItemCobranca> findByTipoAndOrigemId(TipoLancamentoCobranca tipo, Long origemId);
    List<ItemCobranca> findByTipoAndDataLancamentoBetween(TipoLancamentoCobranca tipo, LocalDate inicio, LocalDate fim);
}
