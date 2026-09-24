package br.com.adminpool.repository;
import br.com.adminpool.model.OrdemServico; import org.springframework.data.jpa.repository.JpaRepository; import org.springframework.data.jpa.repository.Query; import java.util.List;
public interface OrdemServicoRepository extends JpaRepository<OrdemServico, Long> {
 List<OrdemServico> findAllByOrderByDataServicoDesc(); List<OrdemServico> findByClienteIdOrderByDataServicoDesc(Long clienteId); List<OrdemServico> findByStatusOrderByDataServicoDesc(String status);
 @Query("select o from OrdemServico o left join o.piscina p left join p.responsavel responsavel left join responsavel.usuario usuarioResponsavel left join o.criadoPor criador left join criador.usuario usuarioCriador where lower(usuarioResponsavel.login) = lower(:login) or lower(usuarioCriador.login) = lower(:login) order by o.dataServico desc")
 List<OrdemServico> findVisiveisPorColaborador(@org.springframework.data.repository.query.Param("login") String login);
}
