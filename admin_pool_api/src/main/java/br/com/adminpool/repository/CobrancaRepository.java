package br.com.adminpool.repository;

import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.StatusCobranca;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface CobrancaRepository extends JpaRepository<CobrancaMensal, Long> {
    List<CobrancaMensal> findAllByOrderByVencimentoAsc();

    /** Carrega a lista mensal, cliente e itens em uma única busca, evitando N+1. */
    @EntityGraph(attributePaths = {"cliente", "itens"})
    List<CobrancaMensal> findByReferenciaOrderByVencimentoAsc(String referencia);

    List<CobrancaMensal> findAllByOrderByReferenciaDescVencimentoAsc();
    List<CobrancaMensal> findByClienteIdOrderByReferenciaAsc(Long clienteId);

    @EntityGraph(attributePaths = {"cliente", "itens"})
    @Query("select distinct c from CobrancaMensal c where c.referencia = :referencia order by c.vencimento asc")
    List<CobrancaMensal> findComClienteEItensPorReferencia(@Param("referencia") String referencia);

    @Query("select c from CobrancaMensal c where c.referencia = :referencia or (c.vencimento < :inicioMes and c.status <> br.com.adminpool.model.StatusCobranca.PAGO) order by c.vencimento asc")
    List<CobrancaMensal> findMesAtualComAtrasos(@Param("referencia") String referencia, @Param("inicioMes") LocalDate inicioMes);

    /** Atualiza somente cobranças ainda pendentes, sem recalcular todo o histórico. */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Transactional
    @Query("update CobrancaMensal c set c.status = :vencido, c.dataPagamento = null "
            + "where c.status = :pendente and c.vencimento < :hoje")
    int marcarPendentesComoVencidas(@Param("hoje") LocalDate hoje,
                                    @Param("pendente") StatusCobranca pendente,
                                    @Param("vencido") StatusCobranca vencido);

    boolean existsByClienteIdAndReferencia(Long clienteId, String referencia);
    Optional<CobrancaMensal> findByClienteIdAndReferencia(Long clienteId, String referencia);
}
