package br.com.adminpool.controller;

import br.com.adminpool.dto.ConcluirPedidoRequest;
import br.com.adminpool.dto.ItemPedidoRequest;
import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.NovoPedidoRequest;
import br.com.adminpool.dto.EditarPedidoRequest;
import br.com.adminpool.dto.ResultadoProdutos;
import br.com.adminpool.dto.LinhaRelatorioPdf;
import br.com.adminpool.model.PedidoProduto;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.service.PedidoProdutoService;
import br.com.adminpool.service.RelatorioPdfService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.time.LocalDate;
import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/pedidos-produto")
public class PedidoProdutoController {

    private final PedidoProdutoRepository pedidos;
    private final PedidoProdutoService servico;
    private final RelatorioPdfService relatorios;

    public PedidoProdutoController(PedidoProdutoRepository pedidos, PedidoProdutoService servico, RelatorioPdfService relatorios) {
        this.pedidos = pedidos;
        this.servico = servico;
        this.relatorios = relatorios;
    }

    @GetMapping
    public List<PedidoProduto> listarTodos(Authentication auth) {
        return gestor(auth) ? pedidos.findAllByOrderByDataPedidoDesc()
                : pedidos.findVisiveisPorColaborador(auth.getName());
    }

    @GetMapping("/cliente/{clienteId}")
    public List<PedidoProduto> listarPorCliente(@PathVariable Long clienteId) {
        return pedidos.findByClienteIdOrderByDataPedidoDesc(clienteId);
    }

    @GetMapping("/codigo/{codigo}")
    public List<PedidoProduto> detalhar(@PathVariable Long codigo) {
        return pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
    }

    @GetMapping(value = "/codigo/{codigo}/pdf", produces = "application/pdf")
    public ResponseEntity<byte[]> pedidoPdf(@PathVariable Long codigo, Authentication auth) {
        if (!gestor(auth)) {
            servico.validarVisualizacaoPorColaborador(codigo, auth.getName());
        }
        var itens = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (itens.isEmpty()) throw new IllegalArgumentException("Pedido não encontrado.");
        var primeiro = itens.get(0);
        var linhas = itens.stream().map(p -> new LinhaRelatorioPdf(destinatario(primeiro),
                p.getProduto().getNome() + " • " + p.getQuantidade() + " un.", primeiro.getDataPedido().toString(),
                p.getTotalLiquido() == null ? p.getTotalVenda() : p.getTotalLiquido())).toList();
        String endereco = enderecoEntrega(primeiro);
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=pedido-" + codigo + ".pdf")
                .body(relatorios.gerar("Pedido #" + codigo, endereco, linhas));
    }

    @GetMapping("/abertos")
    public List<PedidoProduto> listarAbertos() {
        return pedidos.findAllByOrderByDataPedidoDesc().stream()
                .filter(pedido -> !"CONCLUIDO".equals(pedido.getStatus()))
                .toList();
    }

    @GetMapping("/resultado")
    public ResultadoProdutos resultado(@RequestParam(required = false) String referencia) {
        return servico.resultado(referencia == null || referencia.isBlank()
                ? YearMonth.now() : YearMonth.parse(referencia));
    }

    @GetMapping("/resultado/itens")
    public List<PedidoProduto> produtosRecebidos(@RequestParam(required = false) String referencia) {
        return servico.produtosRecebidos(referencia == null || referencia.isBlank()
                ? YearMonth.now() : YearMonth.parse(referencia));
    }

    @GetMapping(value = "/relatorio.pdf", produces = "application/pdf")
    public ResponseEntity<byte[]> relatorio(@RequestParam(required = false) Long clienteId,
                                             @RequestParam(required = false) String mes,
                                             @RequestParam(required = false) LocalDate inicio,
                                             @RequestParam(required = false) LocalDate fim) {
        List<PedidoProduto> lista = pedidos.findAllByOrderByDataPedidoDesc().stream()
                .filter(p -> clienteId == null || p.getCliente() != null && p.getCliente().getId().equals(clienteId))
                .filter(p -> mes == null || mes.isBlank() || p.getDataPedido().toString().startsWith(mes))
                .filter(p -> inicio == null || !p.getDataPedido().isBefore(inicio))
                .filter(p -> fim == null || !p.getDataPedido().isAfter(fim)).toList();
        var linhas = lista.stream().map(p -> new LinhaRelatorioPdf(destinatario(p),
                p.getProduto().getNome() + " • " + p.getQuantidade() + " un.", p.getDataPedido().toString(),
                p.getTotalLiquido() == null ? p.getTotalVenda() : p.getTotalLiquido())).toList();
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=relatorio-pedidos.pdf")
                .body(relatorios.gerar("Relatório de pedidos", "Filtros aplicados na tela", linhas));
    }

    @PostMapping
    public ResponseEntity<PedidoProduto> criar(@RequestBody NovoPedidoRequest requisicao, Authentication auth) {
        NovoPedidoLoteRequest lote = new NovoPedidoLoteRequest(requisicao.clienteId(), requisicao.piscinaId(), requisicao.funcionarioId(),
                List.of(new ItemPedidoRequest(requisicao.produtoId(), requisicao.quantidade())));
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(lote, auth).get(0));
    }

    @PostMapping("/lote")
    public ResponseEntity<List<PedidoProduto>> criarLote(@RequestBody NovoPedidoLoteRequest requisicao,
                                                         Authentication auth) {
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criar(requisicao, auth));
    }

    @PutMapping("/codigo/{codigo}")
    public List<PedidoProduto> editar(@PathVariable Long codigo,
                                      @RequestBody EditarPedidoRequest requisicao,
                                      Authentication auth) {
        if (!gestor(auth)) servico.validarEdicaoPorColaborador(codigo, auth.getName());
        return servico.editar(codigo, requisicao);
    }

    @PutMapping("/codigo/{codigo}/status")
    public ResponseEntity<Void> alterarStatus(@PathVariable Long codigo, @RequestParam String status,
                                              Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem alterar o status do pedido.");
        }
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
        return servico.concluir(codigo, requisicao.pagoPor(), requisicao.desconto());
    }

    @DeleteMapping("/codigo/{codigo}")
    public ResponseEntity<Void> excluir(@PathVariable Long codigo, Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir pedidos.");
        }
        servico.excluir(codigo);
        return ResponseEntity.noContent().build();
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }

    private String destinatario(PedidoProduto pedido) {
        if (pedido.getCliente() != null) return pedido.getCliente().getNome();
        if (pedido.getFuncionario() != null) return "Uso interno — " + pedido.getFuncionario().getUsuario().getNome();
        return "Uso interno";
    }

    private String enderecoEntrega(PedidoProduto pedido) {
        if (pedido.getPiscina() != null && possuiTexto(pedido.getPiscina().getEndereco())) {
            return "Endereço: " + pedido.getPiscina().getEndereco().trim();
        }
        if (pedido.getCliente() != null && possuiTexto(pedido.getCliente().getEndereco())) {
            return "Endereço: " + pedido.getCliente().getEndereco().trim();
        }
        return pedido.getCliente() != null ? "Endereço não informado." : "Material de uso interno — " + destinatario(pedido);
    }

    private boolean possuiTexto(String valor) {
        return valor != null && !valor.isBlank();
    }
}
