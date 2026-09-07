package br.com.adminpool.repository;

import br.com.adminpool.model.Funcionario;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FuncionarioRepository extends JpaRepository<Funcionario, Long> {
    Optional<Funcionario> findByUsuarioLoginIgnoreCase(String login);
}
