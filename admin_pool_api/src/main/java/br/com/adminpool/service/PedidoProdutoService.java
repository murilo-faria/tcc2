package br.com.adminpool.service;

import br.com.adminpool.dto.ItemPedidoRequest;
import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.ResultadoProdutos;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.PedidoProduto;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.model.Produto;
import br.com.adminpool.model.ResponsavelPagamento;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.ProdutoRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

@Service
public class PedidoProdutoService {

    private static final Set<String> STATUS_OPERACIONAIS =
            Set.of("SOLICITADO", "PEDIDO_REALIZADO", "AGUARDANDO_ENTREGA", "ENTREGUE");

    private final PedidoProdutoRepository pedidos;
    private final ClienteRepository clientes;
    private final ProdutoRepository produtos;
    private final PiscinaRepository piscinas;
    private final ItemCobrancaRepository itensCobranca;
    private final CobrancaService cobrancas;

    public PedidoProdutoService(PedidoProdutoRepository pedidos, ClienteRepository clientes,
                                ProdutoRepository produtos, PiscinaRepository piscinas,
                                ItemCobrancaRepository itensCobranca, CobrancaService cobrancas) {
        this.pedidos = pedidos;
        this.clientes = clientes;
        this.produtos = produtos;
        this.piscinas = piscinas;
        this.itensCobranca = itensCobranca;
        this.cobrancas = cobrancas;
    }

    @Transactional
    public List<PedidoProduto> criar(NovoPedidoLoteRequest requisicao, Authentication auth) {
        if (requisicao.itens() == null || requisicao.itens().isEmpty()) {
            throw new IllegalArgumentException("Inclua pelo menos um produto no pedido.");
        }
        Cliente cliente = clientes.findById(requisicao.clienteId()).orElseThrow();
        Piscina piscina = validarPiscina(requisicao.piscinaId(), cliente, auth);
        Long codigo = pedidos.proximoCodigoPedido();
        List<PedidoProduto> novos = new ArrayList<>();
        for (ItemPedidoRequest item : requisicao.itens()) {
            if (item.quantidade() == null || item.quantidade() <= 0) {
                throw new IllegalArgumentException("A quantidade deve ser maior que zero.");
            }
            Produto produto = produtos.findById(item.produtoId()).orElseThrow();
            PedidoProduto pedido = new PedidoProduto();
            pedido.setCodigoPedido(codigo);
            pedido.setCliente(cliente);
            pedido.setPiscina(piscina);
            pedido.setProduto(produto);
            pedido.setQuantidade(item.quantidade());
            pedido.setPrecoCompraUnitario(produto.getPrecoCompra());
            pedido.setValorUnitario(produto.getPrecoVenda());
            pedido.setDataPedido(LocalDate.now());
            pedido.setStatus("SOLICITADO");
            novos.add(pedido);
        }
        return pedidos.saveAll(novos);
    }

    @Transactional
    public List<PedidoProduto> concluir(Long codigo, ResponsavelPagamento pagoPor) {
        if (pagoPor != ResponsavelPagamento.EMPRESA && pagoPor != ResponsavelPagamento.CLIENTE) {
            throw new IllegalArgumentException("Produto só pode ser pago pela empresa ou pelo cliente.");
        }
        List<PedidoProduto> itens = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (itens.isEmpty()) {
            throw new IllegalArgumentException("Pedido não encontrado.");
        }
        if (itens.stream().anyMatch(PedidoProduto::isFinanceiroLancado)) {
            throw new IllegalStateException("Este pedido já foi concluído.");
        }
        if (pagoPor == ResponsavelPagamento.EMPRESA) {
            BigDecimal totalVenda = itens.stream().map(PedidoProduto::getTotalVenda)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            PedidoProduto primeiro = itens.get(0);
            cobrancas.adicionarLancamento(primeiro.getCliente().getId(), TipoLancamentoCobranca.PEDIDO,
                    codigo, "Pedido #" + codigo, totalVenda);
        }
        for (PedidoProduto item : itens) {
            item.setPagador(pagoPor);
            item.setFinanceiroLancado(true);
            item.setDataConclusao(LocalDate.now());
            item.setStatus("CONCLUIDO");
        }
        return pedidos.saveAll(itens);
    }

    @Transactional
    public void alterarStatus(Long codigo, String status) {
        if (!STATUS_OPERACIONAIS.contains(status)) {
            throw new IllegalArgumentException("Situação do pedido inválida.");
        }
        List<PedidoProduto> itens = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (itens.isEmpty()) {
            throw new IllegalArgumentException("Pedido não encontrado.");
        }
        if (itens.stream().anyMatch(PedidoProduto::isFinanceiroLancado)) {
            throw new IllegalStateException("Pedido concluído não pode ser alterado.");
        }
        itens.forEach(item -> item.setStatus(status));
        pedidos.saveAll(itens);
    }

    public ResultadoProdutos resultado(YearMonth mes) {
        LocalDate inicio = mes.atDay(1);
        LocalDate fim = mes.atEndOfMonth();
        List<PedidoProduto> concluidos = pedidos
                .findByDataConclusaoBetweenAndPagadorOrderByDataConclusaoDesc(inicio, fim, ResponsavelPagamento.EMPRESA);
        BigDecimal compras = concluidos.stream().map(PedidoProduto::getTotalCompra)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal vendas = concluidos.stream().map(PedidoProduto::getTotalVenda)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal lucro = vendas.subtract(compras);
        BigDecimal margem = vendas.compareTo(BigDecimal.ZERO) == 0 ? BigDecimal.ZERO
                : lucro.multiply(BigDecimal.valueOf(100)).divide(vendas, 2, RoundingMode.HALF_UP);
        BigDecimal receber = itensCobranca.findByTipoAndDataLancamentoBetween(
                        TipoLancamentoCobranca.PEDIDO, inicio, fim).stream()
                .map(ItemCobranca::getSaldoPendente).reduce(BigDecimal.ZERO, BigDecimal::add);
        return new ResultadoProdutos(mes.toString(), compras, vendas, lucro, margem, receber);
    }

    private Piscina validarPiscina(Long piscinaId, Cliente cliente, Authentication auth) {
        if (piscinaId == null) {
            throw new IllegalArgumentException("Selecione a piscina do pedido.");
        }
        Piscina piscina = piscinas.findById(piscinaId).orElseThrow();
        if (!piscina.getCliente().getId().equals(cliente.getId())) {
            throw new IllegalArgumentException("A piscina não pertence ao cliente.");
        }
        boolean gestor = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
        if (!gestor && (piscina.getResponsavel() == null
                || !piscina.getResponsavel().getUsuario().getLogin().equalsIgnoreCase(auth.getName()))) {
            throw new org.springframework.security.access.AccessDeniedException("Piscina não vinculada ao funcionário.");
        }
        return piscina;
    }
}
