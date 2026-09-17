package br.com.adminpool.repository;
import br.com.adminpool.model.BaixaItemCobranca;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;
public interface BaixaItemCobrancaRepository extends JpaRepository<BaixaItemCobranca,Long> { List<BaixaItemCobranca> findByItemIdOrderByDataPagamentoDesc(Long itemId); List<BaixaItemCobranca> findByDataPagamentoBetween(LocalDateTime inicio, LocalDateTime fim); List<BaixaItemCobranca> findAllByOrderByDataPagamentoDesc(); }
