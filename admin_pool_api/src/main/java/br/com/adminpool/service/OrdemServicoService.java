package br.com.adminpool.service;

import br.com.adminpool.dto.ConcluirOrdemServicoRequest;
import br.com.adminpool.dto.NovaOrdemServicoRequest;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.OrdemServico;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.model.ReembolsoColaborador;
import br.com.adminpool.model.ResponsavelPagamento;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.ReembolsoColaboradorRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;

@Service
public class OrdemServicoService {

    private final OrdemServicoRepository ordens;
    private final ClienteRepository clientes;
    private final PiscinaRepository piscinas;
    private final FuncionarioRepository funcionarios;
    private final ReembolsoColaboradorRepository reembolsos;
    private final CobrancaService cobrancas;

    public OrdemServicoService(OrdemServicoRepository ordens, ClienteRepository clientes,
                               PiscinaRepository piscinas, FuncionarioRepository funcionarios,
                               ReembolsoColaboradorRepository reembolsos, CobrancaService cobrancas) {
        this.ordens = ordens;
        this.clientes = clientes;
        this.piscinas = piscinas;
        this.funcionarios = funcionarios;
        this.reembolsos = reembolsos;
        this.cobrancas = cobrancas;
    }

    @Transactional
    public OrdemServico criar(NovaOrdemServicoRequest requisicao, Authentication auth) {
        var cliente = clientes.findById(requisicao.clienteId()).orElseThrow();
        if (requisicao.piscinaId() == null) {
            throw new IllegalArgumentException("Selecione a piscina da ordem.");
        }
        Piscina piscina = piscinas.findById(requisicao.piscinaId()).orElseThrow();
        if (!piscina.getCliente().getId().equals(cliente.getId())) {
            throw new IllegalArgumentException("A piscina não pertence ao cliente.");
        }
        boolean gestor = gestor(auth);
        if (!gestor && (piscina.getResponsavel() == null
                || !piscina.getResponsavel().getUsuario().getLogin().equalsIgnoreCase(auth.getName()))) {
            throw new org.springframework.security.access.AccessDeniedException("Piscina não vinculada ao funcionário.");
        }
        OrdemServico ordem = new OrdemServico();
        ordem.setCliente(cliente);
        ordem.setPiscina(piscina);
        ordem.setDescricao(requisicao.descricao());
        ordem.setDataServico(requisicao.dataServico() == null ? LocalDate.now() : requisicao.dataServico());
        BigDecimal valorSugerido = requisicao.valorAdicional() == null
                ? BigDecimal.ZERO : requisicao.valorAdicional();
        ordem.setValorAdicional(valorSugerido);
        ordem.setValorCobrado(valorSugerido);
        ordem.setCriadoPor(funcionarios.findByUsuarioLoginIgnoreCase(auth.getName()).orElse(null));
        ordem.setStatus("ABERTA");
        return ordens.save(ordem);
    }

    @Transactional
    public OrdemServico concluir(Long id, ConcluirOrdemServicoRequest requisicao) {
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        if (ordem.isFinanceiroLancado() || "CONCLUIDA".equals(ordem.getStatus())) {
            throw new IllegalStateException("Esta ordem de serviço já foi concluída.");
        }
        BigDecimal custo = positivoOuZero(requisicao.valorCusto(), "custo");
        BigDecimal cobrado = positivoOuZero(requisicao.valorCobrado(), "valor cobrado");
        ResponsavelPagamento pagador = requisicao.pagoPor();
        if (pagador == null) {
            throw new IllegalArgumentException("Informe quem pagou a ordem de serviço.");
        }
        if (pagador == ResponsavelPagamento.FUNCIONARIO && ordem.getCriadoPor() == null) {
            throw new IllegalArgumentException("A OS não possui um colaborador criador para receber o reembolso.");
        }
        if (pagador != ResponsavelPagamento.CLIENTE && cobrado.compareTo(BigDecimal.ZERO) > 0) {
            cobrancas.adicionarLancamento(ordem.getCliente().getId(), TipoLancamentoCobranca.ORDEM_SERVICO,
                    ordem.getId(), "OS #" + ordem.getId() + " - " + ordem.getDescricao(), cobrado);
        }
        if (pagador == ResponsavelPagamento.FUNCIONARIO && custo.compareTo(BigDecimal.ZERO) > 0) {
            criarReembolso(ordem, custo);
        }
        ordem.setValorCusto(custo);
        ordem.setValorCobrado(cobrado);
        ordem.setValorAdicional(cobrado);
        ordem.setPagoPor(pagador);
        ordem.setFinanceiroLancado(true);
        ordem.setDataConclusao(LocalDate.now());
        ordem.setStatus("CONCLUIDA");
        return ordens.save(ordem);
    }

    @Transactional
    public OrdemServico editar(Long id, NovaOrdemServicoRequest requisicao) {
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        if (ordem.isFinanceiroLancado()) throw new IllegalStateException("Uma OS concluída não pode ser editada.");
        var cliente = clientes.findById(requisicao.clienteId()).orElseThrow();
        var piscina = piscinas.findById(requisicao.piscinaId()).orElseThrow();
        if (!piscina.getCliente().getId().equals(cliente.getId())) throw new IllegalArgumentException("A piscina não pertence ao cliente.");
        ordem.setCliente(cliente); ordem.setPiscina(piscina); ordem.setDescricao(requisicao.descricao());
        ordem.setDataServico(requisicao.dataServico() == null ? ordem.getDataServico() : requisicao.dataServico());
        BigDecimal valor = requisicao.valorAdicional() == null ? BigDecimal.ZERO : requisicao.valorAdicional();
        ordem.setValorAdicional(valor); ordem.setValorCobrado(valor);
        return ordens.save(ordem);
    }

    @Transactional
    public void cancelar(Long id) {
        OrdemServico ordem = ordens.findById(id).orElseThrow();
        if (ordem.isFinanceiroLancado()) {
            throw new IllegalStateException("Uma OS concluída não pode ser cancelada.");
        }
        ordem.setStatus("CANCELADA");
        ordens.save(ordem);
    }

    private void criarReembolso(OrdemServico ordem, BigDecimal custo) {
        Funcionario funcionario = ordem.getCriadoPor();
        ReembolsoColaborador reembolso = new ReembolsoColaborador();
        reembolso.setFuncionario(funcionario);
        reembolso.setOrdemServico(ordem);
        reembolso.setDescricao("Reembolso - OS #" + ordem.getId() + " - " + ordem.getCliente().getNome());
        reembolso.setValor(custo);
        reembolso.setDataLancamento(LocalDate.now());
        reembolsos.save(reembolso);
    }

    private BigDecimal positivoOuZero(BigDecimal valor, String campo) {
        BigDecimal resultado = valor == null ? BigDecimal.ZERO : valor;
        if (resultado.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("O " + campo + " não pode ser negativo.");
        }
        return resultado;
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
