package br.com.adminpool.controller;

import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.NovoPedidoRequest;
import br.com.adminpool.model.PedidoProduto;
import br.com.adminpool.model.Produto;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.repository.ProdutoRepository;
import br.com.adminpool.service.LancamentoCobrancaService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/pedidos-produto")
@CrossOrigin(originPatterns = "http://localhost:*")
public class PedidoProdutoController {

    private final PedidoProdutoRepository pedidos;
    private final ClienteRepository clientes;
    private final ProdutoRepository produtos;
    private final LancamentoCobrancaService lancamentos;

    public PedidoProdutoController(
            PedidoProdutoRepository pedidos,
            ClienteRepository clientes,
            ProdutoRepository produtos,
            LancamentoCobrancaService lancamentos) {
        this.pedidos = pedidos;
        this.clientes = clientes;
        this.produtos = produtos;
        this.lancamentos = lancamentos;
    }

    @GetMapping
    public List<PedidoProduto> listarTodos() {
        return pedidos.findAllByOrderByDataPedidoDesc();
    }

    @GetMapping("/cliente/{clienteId}")
    public List<PedidoProduto> listarPorCliente(@PathVariable Long clienteId) {
        return pedidos.findByClienteIdOrderByDataPedidoDesc(clienteId);
    }

    @GetMapping("/abertos")
    public List<PedidoProduto> listarAbertos() {
        return pedidos.findByStatusOrderByDataPedidoDesc("SOLICITADO");
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<Void> alterarStatus(@PathVariable Long id, @RequestParam String status) {
        PedidoProduto pedido = pedidos.findById(id).orElseThrow();
        pedido.setStatus(status);
        pedidos.save(pedido);
        return ResponseEntity.noContent().build();
    }

    @PostMapping
    public ResponseEntity<PedidoProduto> criar(@RequestBody NovoPedidoRequest requisicao) {
        Produto produto = produtos.findById(requisicao.produtoId()).orElseThrow();

        PedidoProduto pedido = new PedidoProduto();
        pedido.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        pedido.setProduto(produto);
        pedido.setQuantidade(requisicao.quantidade());
        pedido.setValorUnitario(produto.getPrecoVenda());
        PedidoProduto pedidoSalvo = pedidos.save(pedido);

        BigDecimal total = produto.getPrecoVenda()
                .multiply(BigDecimal.valueOf(requisicao.quantidade()));
        lancamentos.adicionarProduto(requisicao.clienteId(), total);

        return ResponseEntity.status(HttpStatus.CREATED).body(pedidoSalvo);
    }

    @PostMapping("/lote")
    public ResponseEntity<List<PedidoProduto>> criarLote(@RequestBody NovoPedidoLoteRequest requisicao) {
        List<PedidoProduto> pedidosSalvos = requisicao.itens().stream()
                .map(item -> criar(new NovoPedidoRequest(
                        requisicao.clienteId(),
                        item.produtoId(),
                        item.quantidade())).getBody())
                .toList();

        return ResponseEntity.status(HttpStatus.CREATED).body(pedidosSalvos);
    }
}
