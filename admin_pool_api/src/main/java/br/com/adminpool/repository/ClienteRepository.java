package br.com.adminpool.repository;
import br.com.adminpool.model.Cliente; import java.util.List; import org.springframework.data.jpa.repository.JpaRepository; import org.springframework.data.jpa.repository.Query; import org.springframework.data.repository.query.Param;
public interface ClienteRepository extends JpaRepository<Cliente,Long> { @Query("select distinct p.cliente from Piscina p where lower(p.responsavel.usuario.login) = lower(:login) order by p.cliente.nome") List<Cliente> findResponsaveisPorLogin(@Param("login") String login); }
