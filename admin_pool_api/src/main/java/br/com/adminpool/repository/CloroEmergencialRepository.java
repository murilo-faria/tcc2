package br.com.adminpool.repository;

import br.com.adminpool.model.CloroEmergencial;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CloroEmergencialRepository extends JpaRepository<CloroEmergencial, Long> {
    List<CloroEmergencial> findByPiscinaIdAndReferenciaOrderByIdDesc(Long piscinaId, String referencia);
    List<CloroEmergencial> findByReferenciaOrderByClienteNomeAsc(String referencia);
}
