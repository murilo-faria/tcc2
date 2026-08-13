package br.com.adminpool.controller;

import br.com.adminpool.model.*; import br.com.adminpool.repository.*; import br.com.adminpool.service.LancamentoCobrancaService; import org.springframework.http.*; import org.springframework.web.bind.annotation.*; import java.math.BigDecimal; import java.util.*;
@RestController @RequestMapping("/api/pedidos-produto") @CrossOrigin(originPatterns="http://localhost:*")
public class PedidoProdutoController {
 private final PedidoProdutoRepository pedidos; private final ClienteRepository clientes; private final ProdutoRepository produtos; private final LancamentoCobrancaService lancamentos;
 public PedidoProdutoController(PedidoProdutoRepository p,ClienteRepository c,ProdutoRepository pr,LancamentoCobrancaService l){pedidos=p;clientes=c;produtos=pr;lancamentos=l;}
 @GetMapping public List<PedidoProduto> listarTodos(){return pedidos.findAllByOrderByDataPedidoDesc();}
 @GetMapping("/cliente/{clienteId}") public List<PedidoProduto> listar(@PathVariable Long clienteId){return pedidos.findByClienteIdOrderByDataPedidoDesc(clienteId);}
 @GetMapping("/abertos") public List<PedidoProduto> abertos(){return pedidos.findByStatusOrderByDataPedidoDesc("SOLICITADO");}
 @PutMapping("/{id}/status") public ResponseEntity<Void> alterarStatus(@PathVariable Long id,@RequestParam String status){PedidoProduto p=pedidos.findById(id).orElseThrow();p.setStatus(status);pedidos.save(p);return ResponseEntity.noContent().build();}
 @PostMapping public ResponseEntity<PedidoProduto> criar(@RequestBody NovoPedido r){Produto produto=produtos.findById(r.produtoId()).orElseThrow();PedidoProduto p=new PedidoProduto();p.setCliente(clientes.findById(r.clienteId()).orElseThrow());p.setProduto(produto);p.setQuantidade(r.quantidade());p.setValorUnitario(produto.getPrecoVenda());p=pedidos.save(p);lancamentos.adicionarProduto(r.clienteId(),produto.getPrecoVenda().multiply(BigDecimal.valueOf(r.quantidade())));return ResponseEntity.status(HttpStatus.CREATED).body(p);}
 @PostMapping("/lote") public ResponseEntity<List<PedidoProduto>> criarLote(@RequestBody NovoPedidoLote r){List<PedidoProduto> salvos=r.itens().stream().map(item->criar(new NovoPedido(r.clienteId(),item.produtoId(),item.quantidade())).getBody()).toList();return ResponseEntity.status(HttpStatus.CREATED).body(salvos);}
 public record NovoPedido(Long clienteId,Long produtoId,Integer quantidade){}
 public record NovoPedidoLote(Long clienteId,List<ItemPedido> itens){}
 public record ItemPedido(Long produtoId,Integer quantidade){}
}
