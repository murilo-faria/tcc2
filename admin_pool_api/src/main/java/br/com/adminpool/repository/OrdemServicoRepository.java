package br.com.adminpool.repository;
import br.com.adminpool.model.OrdemServico; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> { List<OrdemServico> findAllByOrderByDataServicoDesc(); List<OrdemServico> findByClienteIdOrderByDataServicoDesc(Long clienteId); List<OrdemServico> findByStatusOrderByDataServicoDesc(String status); }
