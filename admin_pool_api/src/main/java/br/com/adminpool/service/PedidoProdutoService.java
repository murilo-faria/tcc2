package br.com.adminpool.service;

import br.com.adminpool.dto.ItemPedidoRequest;
import br.com.adminpool.dto.EditarPedidoRequest;
import br.com.adminpool.dto.NovoPedidoLoteRequest;
import br.com.adminpool.dto.ResultadoProdutos;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.PedidoProduto;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.model.Produto;
import br.com.adminpool.model.ResponsavelPagamento;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
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
    private final FuncionarioRepository funcionarios;
    private final ProdutoRepository produtos;
    private final PiscinaRepository piscinas;
    private final ItemCobrancaRepository itensCobranca;
    private final CobrancaService cobrancas;

    public PedidoProdutoService(PedidoProdutoRepository pedidos, ClienteRepository clientes, FuncionarioRepository funcionarios,
                                ProdutoRepository produtos, PiscinaRepository piscinas,
                                ItemCobrancaRepository itensCobranca, CobrancaService cobrancas) {
        this.pedidos = pedidos;
        this.clientes = clientes;
        this.funcionarios = funcionarios;
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
        boolean usoInterno = requisicao.funcionarioId() != null;
        if (usoInterno && requisicao.clienteId() != null) {
            throw new IllegalArgumentException("Escolha cliente ou colaborador, não os dois.");
        }
        if (!usoInterno && requisicao.clienteId() == null) {
            throw new IllegalArgumentException("Selecione o cliente do pedido.");
        }
        if (usoInterno && !gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem registrar material para colaboradores.");
        }
        Cliente cliente = usoInterno ? null : clientes.findById(requisicao.clienteId()).orElseThrow();
        Funcionario funcionario = usoInterno ? funcionarios.findById(requisicao.funcionarioId()).orElseThrow() : null;
        Piscina piscina = usoInterno ? null : validarPiscina(requisicao.piscinaId(), cliente, auth);
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
            pedido.setFuncionario(funcionario);
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
    public List<PedidoProduto> concluir(Long codigo, ResponsavelPagamento pagoPor, BigDecimal desconto) {
        List<PedidoProduto> itens = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (itens.isEmpty()) {
            throw new IllegalArgumentException("Pedido não encontrado.");
        }
        if (itens.stream().anyMatch(PedidoProduto::isFinanceiroLancado)) {
            throw new IllegalStateException("Este pedido já foi concluído.");
        }
        boolean usoInterno = itens.stream().allMatch(item -> item.getFuncionario() != null);
        if (usoInterno && pagoPor != ResponsavelPagamento.FUNCIONARIO) {
            throw new IllegalArgumentException("Material de colaborador deve ser concluído como uso interno.");
        }
        if (!usoInterno && pagoPor != ResponsavelPagamento.EMPRESA && pagoPor != ResponsavelPagamento.CLIENTE) {
            throw new IllegalArgumentException("Produto só pode ser pago pela empresa ou pelo cliente.");
        }
        BigDecimal totalVenda = itens.stream().map(PedidoProduto::getTotalVenda)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal descontoAplicado = desconto == null ? BigDecimal.ZERO : desconto;
        if (descontoAplicado.compareTo(BigDecimal.ZERO) < 0 || descontoAplicado.compareTo(totalVenda) > 0) {
            throw new IllegalArgumentException("O desconto deve ficar entre zero e o valor total do pedido.");
        }
        ratearDesconto(itens, totalVenda, descontoAplicado);
        if (pagoPor == ResponsavelPagamento.EMPRESA) {
            BigDecimal totalLiquido = itens.stream().map(PedidoProduto::getTotalLiquido)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            PedidoProduto primeiro = itens.get(0);
            cobrancas.adicionarLancamento(primeiro.getCliente().getId(), TipoLancamentoCobranca.PEDIDO,
                    codigo, "Pedido #" + codigo, totalLiquido);
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
    public void excluir(Long codigo) {
        List<PedidoProduto> itens = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (itens.isEmpty()) {
            throw new IllegalArgumentException("Pedido não encontrado.");
        }
        // Um pedido concluído pode ter gerado uma cobrança. Remova primeiro o
        // lançamento pendente para que ele não continue aparecendo em Cobranças.
        // O serviço preserva qualquer lançamento que já tenha recebido pagamento.
        if (itensCobranca.existsByTipoAndOrigemId(TipoLancamentoCobranca.PEDIDO, codigo)) {
            cobrancas.removerLancamento(TipoLancamentoCobranca.PEDIDO, codigo);
        }
        pedidos.deleteAll(itens);
    }

    /**
     * A edição troca somente os itens de um pedido ainda aberto. Cliente, piscina
     * e colaborador solicitante são preservados, portanto o pedido continua visível
     * para as mesmas pessoas após o gestor salvar.
     */
    @Transactional
    public List<PedidoProduto> editar(Long codigo, EditarPedidoRequest requisicao) {
        List<PedidoProduto> atuais = pedidos.findByCodigoPedidoOrderByIdAsc(codigo);
        if (atuais.isEmpty()) throw new IllegalArgumentException("Pedido não encontrado.");
        if (atuais.stream().anyMatch(PedidoProduto::isFinanceiroLancado)) {
            throw new IllegalStateException("Pedido concluído não pode ser editado.");
        }
        if (requisicao.itens() == null || requisicao.itens().isEmpty()) {
            throw new IllegalArgumentException("Inclua pelo menos um produto no pedido.");
        }
        PedidoProduto modelo = atuais.get(0);
        List<PedidoProduto> atualizados = new ArrayList<>();
        for (ItemPedidoRequest item : requisicao.itens()) {
            if (item.quantidade() == null || item.quantidade() <= 0) {
                throw new IllegalArgumentException("A quantidade deve ser maior que zero.");
            }
            Produto produto = produtos.findById(item.produtoId()).orElseThrow();
            PedidoProduto pedido = new PedidoProduto();
            pedido.setCodigoPedido(codigo);
            pedido.setCliente(modelo.getCliente());
            pedido.setPiscina(modelo.getPiscina());
            pedido.setFuncionario(modelo.getFuncionario());
            pedido.setProduto(produto);
            pedido.setQuantidade(item.quantidade());
            pedido.setPrecoCompraUnitario(produto.getPrecoCompra());
            pedido.setValorUnitario(produto.getPrecoVenda());
            pedido.setDesconto(BigDecimal.ZERO);
            pedido.setDataPedido(modelo.getDataPedido());
            pedido.setStatus(modelo.getStatus());
            atualizados.add(pedido);
        }
        pedidos.deleteAll(atuais);
        return pedidos.saveAll(atualizados);
    }

    /** Confere se o colaborador vinculado ao pedido ainda pode alterá-lo. */
    public void validarEdicaoPorColaborador(Long codigo, String login) {
        PedidoProduto pedido = primeiroPedido(codigo);
        if (pedido.isFinanceiroLancado() || "CONCLUIDO".equals(pedido.getStatus())) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Pedido concluído não pode ser editado pelo colaborador.");
        }
        validarVinculoColaborador(pedido, login);
    }

    /** Permite que o colaborador compartilhe o PDF apenas de um pedido visível para ele. */
    public void validarVisualizacaoPorColaborador(Long codigo, String login) {
        validarVinculoColaborador(primeiroPedido(codigo), login);
    }

    private PedidoProduto primeiroPedido(Long codigo) {
        return pedidos.findByCodigoPedidoOrderByIdAsc(codigo).stream().findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Pedido não encontrado."));
    }

    private void validarVinculoColaborador(PedidoProduto pedido, String login) {
        boolean responsavelDaPiscina = pedido.getPiscina() != null
                && pedido.getPiscina().getResponsavel() != null
                && pedido.getPiscina().getResponsavel().getUsuario() != null
                && login.equalsIgnoreCase(pedido.getPiscina().getResponsavel().getUsuario().getLogin());
        boolean destinatarioInterno = pedido.getFuncionario() != null
                && pedido.getFuncionario().getUsuario() != null
                && login.equalsIgnoreCase(pedido.getFuncionario().getUsuario().getLogin());
        if (!responsavelDaPiscina && !destinatarioInterno) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Pedido não vinculado ao colaborador.");
        }
    }

    private void ratearDesconto(List<PedidoProduto> itens, BigDecimal totalVenda, BigDecimal desconto) {
        if (desconto.compareTo(BigDecimal.ZERO) == 0) {
            itens.forEach(item -> item.setDesconto(BigDecimal.ZERO));
            return;
        }
        BigDecimal restante = desconto;
        for (int indice = 0; indice < itens.size(); indice++) {
            PedidoProduto item = itens.get(indice);
            BigDecimal parcela = indice == itens.size() - 1 ? restante
                    : desconto.multiply(item.getTotalVenda()).divide(totalVenda, 2, RoundingMode.HALF_UP);
            item.setDesconto(parcela);
            restante = restante.subtract(parcela);
        }
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
        List<PedidoProduto> concluidos = pedidos.findByDataConclusaoBetweenOrderByDataConclusaoDesc(inicio, fim);
        BigDecimal compras = concluidos.stream()
                .filter(pedido -> pedido.getPagador() == ResponsavelPagamento.EMPRESA || pedido.getPagador() == ResponsavelPagamento.FUNCIONARIO)
                .map(PedidoProduto::getTotalCompra)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal vendas = concluidos.stream().filter(pedido -> pedido.getPagador() == ResponsavelPagamento.EMPRESA)
                .map(PedidoProduto::getTotalLiquido)
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

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
