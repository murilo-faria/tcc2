package br.com.adminpool.controller;

import br.com.adminpool.dto.ConcluirPedidoRequest;
import br.com.adminpool.dto.ItemPedidoRequest;
import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.NovoPedidoRequest;
import br.com.adminpool.dto.NovoPedidoCapaRequest;
import br.com.adminpool.dto.EditarPedidoCapaRequest;
import br.com.adminpool.dto.EditarPedidoRequest;
import br.com.adminpool.dto.ResultadoProdutos;
import br.com.adminpool.dto.LinhaRelatorioPdf;
import br.com.adminpool.dto.LinhaRelatorioPedidoCompleto;
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
import java.util.Map;
import java.util.LinkedHashMap;

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
        var linhas = "CAPA".equals(primeiro.getTipoPedido())
                ? linhasDaCapa(primeiro)
                : itens.stream().map(p -> new LinhaRelatorioPdf(destinatario(primeiro),
                    descricaoItem(p), primeiro.getDataPedido().toString(),
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
                                             @RequestParam(required = false) LocalDate fim,
                                             @RequestParam(defaultValue = "VENDAS") String tipo) {
        List<PedidoProduto> lista = pedidos.findAllByOrderByDataPedidoDesc().stream()
                .filter(p -> clienteId == null || p.getCliente() != null && p.getCliente().getId().equals(clienteId))
                .filter(p -> mes == null || mes.isBlank() || p.getDataPedido().toString().startsWith(mes))
                .filter(p -> inicio == null || !p.getDataPedido().isBefore(inicio))
                .filter(p -> fim == null || !p.getDataPedido().isAfter(fim)).toList();
        String relatorio = tipo == null ? "VENDAS" : tipo.toUpperCase();
        if ("COMPLETO".equals(relatorio)) {
            return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=relatorio-pedidos-completo.pdf")
                    .body(relatorios.gerarPedidosCompleto("Relatório completo de pedidos", "Filtros aplicados na tela",
                            linhasCompletas(lista)));
        }
        boolean compras = "COMPRAS".equals(relatorio);
        var linhas = lista.stream().map(p -> new LinhaRelatorioPdf(destinatario(p),
                descricaoItem(p), p.getDataPedido().toString(),
                compras ? p.getTotalCompra() : (p.getTotalLiquido() == null ? p.getTotalVenda() : p.getTotalLiquido()))).toList();
        String titulo = compras ? "Relatório de compras dos pedidos" : "Relatório de vendas dos pedidos";
        String arquivo = compras ? "relatorio-compras-pedidos.pdf" : "relatorio-vendas-pedidos.pdf";
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=" + arquivo)
                .body(relatorios.gerar(titulo, "Filtros aplicados na tela", linhas));
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

    @PostMapping("/capa")
    public ResponseEntity<PedidoProduto> criarCapa(@RequestBody NovoPedidoCapaRequest requisicao,
                                                    Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem gerar pedidos de capa.");
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(servico.criarCapa(requisicao, auth));
    }

    @PutMapping("/codigo/{codigo}")
    public List<PedidoProduto> editar(@PathVariable Long codigo,
                                      @RequestBody EditarPedidoRequest requisicao,
                                      Authentication auth) {
        if (!gestor(auth)) servico.validarEdicaoPorColaborador(codigo, auth.getName());
        return servico.editar(codigo, requisicao);
    }

    @PutMapping("/codigo/{codigo}/capa")
    public PedidoProduto editarCapa(@PathVariable Long codigo,
                                    @RequestBody EditarPedidoCapaRequest requisicao,
                                    Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar pedidos de capa.");
        }
        return servico.editarCapa(codigo, requisicao);
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

    private String descricaoItem(PedidoProduto pedido) {
        if ("CAPA".equals(pedido.getTipoPedido())) {
            return pedido.getDescricaoCapa() + " • " + pedido.getAreaCapa() + " m²";
        }
        return pedido.getProduto().getNome() + " • " + pedido.getQuantidade() + " un.";
    }

    private List<LinhaRelatorioPdf> linhasDaCapa(PedidoProduto capa) {
        String medidas = capa.getPiscina().getComprimento().stripTrailingZeros().toPlainString()
                + " m × " + capa.getPiscina().getLargura().stripTrailingZeros().toPlainString()
                + " m = " + capa.getAreaCapa().stripTrailingZeros().toPlainString() + " m²";
        BigDecimal valorCapa = capa.getPrecoCompraUnitario().add(capa.getLucroCapa());
        return List.of(
                new LinhaRelatorioPdf(destinatario(capa), capa.getDescricaoCapa() + " • Metragem: " + medidas,
                        capa.getDataPedido().toString(), valorCapa),
                new LinhaRelatorioPdf(destinatario(capa), "Frete", capa.getDataPedido().toString(), capa.getFreteCapa()));
    }

    private List<LinhaRelatorioPedidoCompleto> linhasCompletas(List<PedidoProduto> lista) {
        Map<Long, List<PedidoProduto>> porPedido = new LinkedHashMap<>();
        for (PedidoProduto item : lista) {
            porPedido.computeIfAbsent(item.getCodigoPedido(), codigo -> new java.util.ArrayList<>()).add(item);
        }
        return porPedido.values().stream().map(itens -> {
            PedidoProduto primeiro = itens.get(0);
            BigDecimal compra = itens.stream().map(PedidoProduto::getTotalCompra)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal venda = itens.stream().map(p -> p.getTotalLiquido() == null ? p.getTotalVenda() : p.getTotalLiquido())
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            String produtos = itens.stream().map(this::descricaoItem).collect(java.util.stream.Collectors.joining("; "));
            return new LinhaRelatorioPedidoCompleto(destinatario(primeiro), produtos, compra, venda,
                    venda.subtract(compra));
        }).toList();
    }

    private boolean possuiTexto(String valor) {
        return valor != null && !valor.isBlank();
    }
}
