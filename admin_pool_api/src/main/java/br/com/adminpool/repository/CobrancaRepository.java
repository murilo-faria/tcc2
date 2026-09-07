package br.com.adminpool.repository;
import br.com.adminpool.model.CobrancaMensal; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List; import java.util.Optional;
public interface CobrancaRepository extends JpaRepository<CobrancaMensal,Long> { List<CobrancaMensal> findAllByOrderByVencimentoAsc(); boolean existsByClienteIdAndReferencia(Long clienteId, String referencia); Optional<CobrancaMensal> findByClienteIdAndReferencia(Long clienteId, String referencia); }
