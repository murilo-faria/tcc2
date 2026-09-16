package br.com.adminpool.repository;
import br.com.adminpool.model.ValeColaborador; import org.springframework.data.jpa.repository.JpaRepository; import java.time.LocalDate; import java.util.List;
public interface ValeColaboradorRepository extends JpaRepository<ValeColaborador,Long>{ List<ValeColaborador> findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(Long id, LocalDate inicio, LocalDate fim); }
