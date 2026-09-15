package br.com.adminpool.controller;

import br.com.adminpool.dto.ConcluirPedidoRequest;
import br.com.adminpool.dto.ItemPedidoRequest;
import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.NovoPedidoRequest;
import br.com.adminpool.dto.ResultadoProdutos;
import br.com.adminpool.model.PedidoProduto;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.service.PedidoProdutoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/pedidos-produto")
public class PedidoProdutoController {

    private final PedidoProdutoRepository pedidos;
    private final PedidoProdutoService servico;

    public PedidoProdutoController(PedidoProdutoRepository pedidos, PedidoProdutoService servico) {
        this.pedidos = pedidos;
        this.servico = servico;
    }

    @GetMapping
    public List<PedidoProduto> listarTodos(Authentication auth) {
        return gestor(auth) ? pedidos.findAllByOrderByDataPedidoDesc()
                : pedidos.findByPiscinaResponsavelUsuarioLoginIgnoreCaseOrderByDataPedidoDesc(auth.getName());
    }

    @GetMapping("/cliente/{clienteId}")
    public List<PedidoProduto> listarPorCliente(@PathVariable Long clienteId) {
        return pedidos.findByClienteIdOrderByDataPedidoDesc(clienteId);
    }

    @GetMapping("/codigo/{codigo}")
    public List<PedidoProduto> detalhar(@PathVariable Long codigo) {
        return pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
    }

    @GetMapping("/abertos")
    public List<PedidoProduto> listarAbertos() {
        return pedidos.findByStatusOrderByDataPedidoDesc("SOLICITADO");
    }

    @GetMapping("/resultado")
    public ResultadoProdutos resultado(@RequestParam(required = false) String referencia) {
        return servico.resultado(referencia == null || referencia.isBlank()
                ? YearMonth.now() : YearMonth.parse(referencia));
    }

    @PostMapping
    public ResponseEntity<PedidoProduto> criar(@RequestBody NovoPedidoRequest requisicao, Authentication auth) {
        NovoPedidoLoteRequest lote = new NovoPedidoLoteRequest(requisicao.clienteId(), requisicao.piscinaId(),
                List.of(new ItemPedidoRequest(requisicao.produtoId(), requisicao.quantidade())));
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(lote, auth).get(0));
    }

    @PostMapping("/lote")
    public ResponseEntity<List<PedidoProduto>> criarLote(@RequestBody NovoPedidoLoteRequest requisicao,
                                                         Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(requisicao, auth));
    }

    @PutMapping("/codigo/{codigo}/status")
    public ResponseEntity<Void> alterarStatus(@PathVariable Long codigo, @RequestParam String status) {
        servico.alterarStatus(codigo, status);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/codigo/{codigo}/concluir")
    public List<PedidoProduto> concluir(@PathVariable Long codigo,
                                        @RequestBody ConcluirPedidoRequest requisicao,
                                        Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem concluir pedidos.");
        }
        return servico.concluir(codigo, requisicao.pagoPor());
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
