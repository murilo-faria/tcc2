package br.com.adminpool.repository;
import br.com.adminpool.model.Piscina; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface PiscinaRepository extends JpaRepository<Piscina, Long> { List<Piscina> findByClienteIdOrderByNome(Long clienteId); }
