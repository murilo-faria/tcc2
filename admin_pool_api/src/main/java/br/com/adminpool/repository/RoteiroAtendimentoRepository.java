package br.com.adminpool.repository;

import br.com.adminpool.model.RoteiroAtendimento;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RoteiroAtendimentoRepository extends JpaRepository<RoteiroAtendimento, Long> {
    List<RoteiroAtendimento> findAllByOrderByDiaAtendimentoAscClienteNomeAsc();
    List<RoteiroAtendimento> findByClienteFuncionarioUsuarioLoginIgnoreCaseOrderByDiaAtendimentoAscClienteNomeAsc(String login);
    boolean existsByClienteIdAndDiaAtendimento(Long clienteId, String diaAtendimento);
}
