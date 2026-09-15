package br.com.adminpool.repository;
import br.com.adminpool.model.ReembolsoColaborador;
import br.com.adminpool.model.StatusReembolso;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
public interface ReembolsoColaboradorRepository extends JpaRepository<ReembolsoColaborador,Long> {
    List<ReembolsoColaborador> findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(Long funcionarioId, LocalDate inicio, LocalDate fim);
    Optional<ReembolsoColaborador> findByOrdemServicoId(Long ordemServicoId);
    List<ReembolsoColaborador> findByFuncionarioIdAndStatusOrderByDataLancamentoAsc(Long funcionarioId, StatusReembolso status);
}
