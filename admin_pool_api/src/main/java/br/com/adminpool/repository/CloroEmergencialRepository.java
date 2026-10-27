package br.com.adminpool.repository;

import br.com.adminpool.model.CloroEmergencial;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface CloroEmergencialRepository extends JpaRepository<CloroEmergencial, Long> {
    Optional<CloroEmergencial> findByClienteIdAndReferencia(Long clienteId, String referencia);
    List<CloroEmergencial> findByReferenciaOrderByClienteNomeAsc(String referencia);
    List<CloroEmergencial> findByReferenciaAndClienteIdInOrderByClienteNomeAsc(String referencia, List<Long> clienteIds);
}
