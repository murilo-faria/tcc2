package br.com.adminpool.repository;
import br.com.adminpool.model.PedidoProduto; import org.springframework.data.jpa.repository.JpaRepository; import java.util.List;
public interface PedidoProdutoRepository extends JpaRepository<PedidoProduto, Long> { List<PedidoProduto> findAllByOrderByDataPedidoDesc(); List<PedidoProduto> findByClienteIdOrderByDataPedidoDesc(Long clienteId); List<PedidoProduto> findByStatusOrderByDataPedidoDesc(String status); }
