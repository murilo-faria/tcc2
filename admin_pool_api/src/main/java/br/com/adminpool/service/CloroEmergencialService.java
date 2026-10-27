package br.com.adminpool.service;

import br.com.adminpool.dto.FinalizarCloroEmergencialRequest;
import br.com.adminpool.dto.NovoCloroEmergencialRequest;
import br.com.adminpool.dto.NovoUsoCloroEmergencialRequest;
import br.com.adminpool.model.*;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CloroEmergencialRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@Service
public class CloroEmergencialService {
    private final CloroEmergencialRepository listas;
    private final ClienteRepository clientes;
    private final FuncionarioRepository funcionarios;
    private final CobrancaService cobrancas;

    public CloroEmergencialService(CloroEmergencialRepository listas, ClienteRepository clientes,
                                   FuncionarioRepository funcionarios, CobrancaService cobrancas) {
        this.listas = listas; this.clientes = clientes; this.funcionarios = funcionarios; this.cobrancas = cobrancas;
    }

    public List<CloroEmergencial> listar(String referencia, Authentication auth) {
        String mes = referencia == null || referencia.isBlank() ? YearMonth.now().toString() : referencia;
        if (gestor(auth)) return listas.findByReferenciaOrderByClienteNomeAsc(mes);
        List<Long> clientesDoColaborador = clientes.findResponsaveisPorLogin(auth.getName()).stream()
                .map(Cliente::getId).toList();
        return clientesDoColaborador.isEmpty() ? List.of()
                : listas.findByReferenciaAndClienteIdInOrderByClienteNomeAsc(mes, clientesDoColaborador);
    }

    @Transactional
    public CloroEmergencial criarOuAbrir(NovoCloroEmergencialRequest requisicao, Authentication auth) {
        if (requisicao.clienteId() == null) throw new IllegalArgumentException("Selecione o cliente.");
        validarClienteDoColaborador(requisicao.clienteId(), auth);
        String referencia = YearMonth.now().toString();
        CloroEmergencial existente = listas.findByClienteIdAndReferencia(requisicao.clienteId(), referencia).orElse(null);
        if (existente != null) {
            if (existente.getStatus() != StatusCloroEmergencial.ABERTA) {
                throw new IllegalStateException("A lista de cloro deste cliente já foi finalizada neste mês.");
            }
            return existente;
        }
        CloroEmergencial lista = new CloroEmergencial();
        lista.setCliente(clientes.findById(requisicao.clienteId()).orElseThrow());
        lista.setReferencia(referencia);
        lista.setCriadoPor(funcionarios.findByUsuarioLoginIgnoreCase(auth.getName()).orElse(null));
        return listas.save(lista);
    }

    @Transactional
    public CloroEmergencial adicionarUso(Long id, NovoUsoCloroEmergencialRequest requisicao, Authentication auth) {
        CloroEmergencial lista = aberta(id);
        validarClienteDoColaborador(lista.getCliente().getId(), auth);
        if (requisicao.quantidadeKg() == null || requisicao.quantidadeKg().compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Informe uma quantidade de cloro maior que zero.");
        }
        UsoCloroEmergencial uso = new UsoCloroEmergencial();
        uso.setLista(lista);
        uso.setQuantidadeKg(requisicao.quantidadeKg());
        uso.setDescricao(requisicao.descricao() == null ? null : requisicao.descricao().trim());
        uso.setDataUso(LocalDate.now());
        lista.getUsos().add(uso);
        return listas.save(lista);
    }

    @Transactional
    public CloroEmergencial finalizar(Long id, FinalizarCloroEmergencialRequest requisicao) {
        CloroEmergencial lista = aberta(id);
        if (lista.getUsos().isEmpty()) throw new IllegalArgumentException("Adicione ao menos um uso de cloro.");
        String destino = requisicao.destino() == null ? "" : requisicao.destino().trim().toUpperCase();
        if ("COBRANCA".equals(destino)) {
            BigDecimal valor = requisicao.valorCobrado();
            if (valor == null || valor.compareTo(BigDecimal.ZERO) <= 0) {
                throw new IllegalArgumentException("Informe o valor a cobrar do cliente.");
            }
            cobrancas.adicionarLancamento(lista.getCliente().getId(), TipoLancamentoCobranca.CLORO_EMERGENCIAL,
                    lista.getId(), descricaoDaCobranca(lista), valor);
            lista.setValorCobrado(valor);
            lista.setStatus(StatusCloroEmergencial.COBRADA);
        } else if ("REPOSICAO".equals(destino)) {
            lista.setStatus(StatusCloroEmergencial.AGUARDANDO_REPOSICAO);
        } else {
            throw new IllegalArgumentException("Escolha gerar cobrança ou reposição.");
        }
        lista.setDataConclusao(LocalDate.now());
        return listas.save(lista);
    }

    @Transactional
    public CloroEmergencial confirmarReposicao(Long id) {
        CloroEmergencial lista = listas.findById(id).orElseThrow();
        if (lista.getStatus() != StatusCloroEmergencial.AGUARDANDO_REPOSICAO) {
            throw new IllegalStateException("Esta lista não está aguardando reposição.");
        }
        lista.setStatus(StatusCloroEmergencial.REPOSTA);
        return listas.save(lista);
    }

    /** Exclui a lista e qualquer cobrança que ela tenha gerado. Uso exclusivo do gestor. */
    @Transactional
    public void excluir(Long id) {
        CloroEmergencial lista = listas.findById(id).orElseThrow();
        cobrancas.removerLancamentoSeExistir(TipoLancamentoCobranca.CLORO_EMERGENCIAL, lista.getId());
        listas.delete(lista);
    }

    private void validarClienteDoColaborador(Long clienteId, Authentication auth) {
        if (gestor(auth)) return;
        boolean permitido = clientes.findResponsaveisPorLogin(auth.getName()).stream()
                .anyMatch(cliente -> cliente.getId().equals(clienteId));
        if (!permitido) {
            throw new org.springframework.security.access.AccessDeniedException(
                    "Cliente não vinculado ao colaborador.");
        }
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }

    private CloroEmergencial aberta(Long id) {
        CloroEmergencial lista = listas.findById(id).orElseThrow();
        if (lista.getStatus() != StatusCloroEmergencial.ABERTA) {
            throw new IllegalStateException("Esta lista de cloro já foi finalizada.");
        }
        return lista;
    }

    private String descricaoDaCobranca(CloroEmergencial lista) {
        BigDecimal total = lista.getUsos().stream().map(UsoCloroEmergencial::getQuantidadeKg)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return "Cloro emergencial — " + total.stripTrailingZeros().toPlainString() + " kg — " + lista.getReferencia();
    }
}
