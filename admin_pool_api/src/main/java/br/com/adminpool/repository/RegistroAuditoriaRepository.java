package br.com.adminpool.repository;

import br.com.adminpool.model.RegistroAuditoria;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RegistroAuditoriaRepository extends JpaRepository<RegistroAuditoria, Long> {
    List<RegistroAuditoria> findByDataHoraBetweenOrderByDataHoraDesc(LocalDateTime inicio, LocalDateTime fim);
    List<RegistroAuditoria> findTop200ByOrderByDataHoraDesc();
}
