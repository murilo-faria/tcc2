package br.com.adminpool.repository;
import br.com.adminpool.model.Produto; import org.springframework.data.jpa.repository.JpaRepository;
public interface ProdutoRepository extends JpaRepository<Produto,Long> { boolean existsByNomeIgnoreCase(String nome); }
