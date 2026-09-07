package br.com.adminpool.repository;
import br.com.adminpool.model.Cliente; import org.springframework.data.jpa.repository.JpaRepository;
public interface ClienteRepository extends JpaRepository<Cliente,Long> { }
