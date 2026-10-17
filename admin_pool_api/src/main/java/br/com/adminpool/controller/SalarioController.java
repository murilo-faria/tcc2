package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.ReembolsoColaborador;
import br.com.adminpool.model.StatusReembolso;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.ReembolsoColaboradorRepository;
import br.com.adminpool.repository.ValeColaboradorRepository;
import br.com.adminpool.model.ValeColaborador;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.TipoLancamentoCobranca;
import br.com.adminpool.service.CobrancaService;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/salarios")
public class SalarioController {
    private final FuncionarioRepository funcionarios;
    private final PiscinaRepository piscinas;
    private final ReembolsoColaboradorRepository reembolsos;
    private final ValeColaboradorRepository vales;
    private final CobrancaRepository cobrancas;
    private final CobrancaService cobrancaService;

    public SalarioController(FuncionarioRepository funcionarios, PiscinaRepository piscinas,
                             ReembolsoColaboradorRepository reembolsos, ValeColaboradorRepository vales,
                             CobrancaRepository cobrancas, CobrancaService cobrancaService) {
        this.funcionarios = funcionarios;
        this.piscinas = piscinas;
        this.reembolsos = reembolsos;
        this.vales = vales;
        this.cobrancas = cobrancas;
        this.cobrancaService = cobrancaService;
    }

    @GetMapping("/vales") public List<ValeColaborador> listarVales(@RequestParam(required = false) Long funcionarioId, @RequestParam(required = false) String referencia, Authentication auth) { YearMonth mes=referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia); return vales.findAll().stream().filter(v -> !v.getDataLancamento().isBefore(mes.atDay(1)) && !v.getDataLancamento().isAfter(mes.atEndOfMonth())).filter(v -> gestor(auth) ? funcionarioId == null || v.getFuncionario().getId().equals(funcionarioId) : v.getFuncionario().getUsuario().getLogin().equalsIgnoreCase(auth.getName())).toList(); }
    @PostMapping("/vales") public ValeColaborador criarVale(@RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem lançar vales."); ValeColaborador v=new ValeColaborador(); v.setFuncionario(funcionarios.findById(Long.valueOf(dados.get("funcionarioId").toString())).orElseThrow()); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); v.setDataLancamento(LocalDate.now()); return vales.save(v); }
    @PutMapping("/vales/{id}") public ValeColaborador editarVale(@PathVariable Long id, @RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar vales."); ValeColaborador v=vales.findById(id).orElseThrow(); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); return vales.save(v); }
    @DeleteMapping("/vales/{id}") public ResponseEntity<Void> excluirVale(@PathVariable Long id, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir vales."); vales.deleteById(id); return ResponseEntity.noContent().build(); }

    @GetMapping
    public List<Map<String, Object>> listar(@RequestParam(required = false) String referencia, Authentication auth) {
        boolean gestor = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        Map<Long, BigDecimal> mensalidadeDoMesPorCliente = mensalidadesPorCliente(mes);
        return funcionarios.findAll().stream()
                .filter(f -> gestor || f.getUsuario().getLogin().equalsIgnoreCase(auth.getName()))
                .map(f -> resumo(f, mes, mensalidadeDoMesPorCliente))
                .toList();
    }

    @GetMapping("/{funcionarioId}/reembolsos")
    public List<ReembolsoColaborador> listarReembolsos(@PathVariable Long funcionarioId,
                                                       @RequestParam(required = false) String referencia,
                                                       Authentication auth) {
        Funcionario funcionario = funcionarios.findById(funcionarioId).orElseThrow();
        if (!gestor(auth) && !funcionario.getUsuario().getLogin().equalsIgnoreCase(auth.getName())) {
            throw new org.springframework.security.access.AccessDeniedException("Acesso negado aos reembolsos.");
        }
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        return reembolsos.findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(
                funcionarioId, mes.atDay(1), mes.atEndOfMonth());
    }

    @GetMapping("/{funcionarioId}/piscinas")
    public List<Map<String, Object>> listarPiscinasDaComissao(
            @PathVariable Long funcionarioId,
            @RequestParam(required = false) String referencia,
            Authentication auth) {
        Funcionario funcionario = funcionarios.findById(funcionarioId).orElseThrow();
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem ver a composição da comissão.");
        }
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        return piscinas.findByResponsavelId(funcionarioId).stream()
                .filter(piscina -> {
                    Cliente cliente = piscina.getCliente();
                    if (!cliente.isAtivo()) {
                        return false;
                    }
                    LocalDate primeiroVencimento = cliente.getPrimeiroVencimento();
                    return primeiroVencimento == null || !primeiroVencimento.isAfter(mes.atEndOfMonth());
                })
                .map(piscina -> {
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("id", piscina.getId());
                    item.put("cliente", piscina.getCliente().getNome());
                    item.put("piscina", piscina.getNome());
                    item.put("valor", piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade());
                    return item;
                })
                .toList();
    }

    @PutMapping("/reembolsos/{id}/pagar")
    public ResponseEntity<Void> pagarReembolso(@PathVariable Long id, Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem pagar reembolsos.");
        }
        ReembolsoColaborador reembolso = reembolsos.findById(id).orElseThrow();
        reembolso.setStatus(StatusReembolso.PAGO);
        reembolso.setDataPagamento(LocalDate.now());
        reembolsos.save(reembolso);
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> resumo(Funcionario funcionario, YearMonth mes,
                                       Map<Long, BigDecimal> mensalidadeDoMesPorCliente) {
        var piscinasVinculadas = piscinas.findByResponsavelId(funcionario.getId()).stream()
                .filter(piscina -> {
                    Cliente cliente = piscina.getCliente();
                    if (!cliente.isAtivo()) {
                        return false;
                    }
                    LocalDate primeiroVencimento = piscina.getCliente().getPrimeiroVencimento();
                    return primeiroVencimento == null || !primeiroVencimento.isAfter(mes.atEndOfMonth());
                })
                .toList();
        var clientes = piscinasVinculadas.stream()
                .map(p -> p.getCliente())
                .collect(Collectors.toMap(Cliente::getId, cliente -> cliente, (a, b) -> a))
                .values();
        BigDecimal baseMensal = piscinasVinculadas.stream()
                .map(piscina -> valorDaPiscinaNoMes(piscina, mensalidadeDoMesPorCliente))
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal salario = baseMensal.multiply(funcionario.getPercentualMensalidade())
                .divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
        BigDecimal totalReembolsos = reembolsos
                .findByFuncionarioIdAndStatusOrderByDataLancamentoAsc(funcionario.getId(), StatusReembolso.PENDENTE)
                .stream()
                .filter(reembolso -> !reembolso.getDataLancamento().isBefore(mes.atDay(1))
                        && !reembolso.getDataLancamento().isAfter(mes.atEndOfMonth()))
                .map(ReembolsoColaborador::getValor).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalVales = vales.findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(funcionario.getId(), mes.atDay(1), mes.atEndOfMonth()).stream().map(ValeColaborador::getValor).reduce(BigDecimal.ZERO, BigDecimal::add);
        Map<String, Object> resultado = new LinkedHashMap<>();
        resultado.put("funcionario", funcionario);
        resultado.put("piscinas", piscinasVinculadas.size());
        resultado.put("clientes", clientes.size());
        resultado.put("baseMensal", baseMensal);
        resultado.put("salario", salario);
        resultado.put("reembolsos", totalReembolsos);
        resultado.put("vales", totalVales);
        resultado.put("totalPagar", salario.add(totalReembolsos).subtract(totalVales).max(BigDecimal.ZERO));
        resultado.put("referencia", mes.toString());
        return resultado;
    }

    /** A comissão usa o lançamento do mês, e não o preço que foi alterado hoje no cadastro. */
    private Map<Long, BigDecimal> mensalidadesPorCliente(YearMonth mes) {
        cobrancaService.gerarMes(mes);
        return cobrancas.findComClienteEItensPorReferencia(mes.toString()).stream()
                .collect(Collectors.toMap(c -> c.getCliente().getId(), this::valorMensalidade,
                        (primeiro, segundo) -> primeiro));
    }

    private BigDecimal valorMensalidade(CobrancaMensal cobranca) {
        return cobranca.getItens().stream()
                .filter(item -> item.getTipo() == TipoLancamentoCobranca.MENSALIDADE)
                .map(item -> item.getValorOriginal() == null ? BigDecimal.ZERO : item.getValorOriginal())
                .findFirst().orElse(BigDecimal.ZERO);
    }

    private BigDecimal valorDaPiscinaNoMes(br.com.adminpool.model.Piscina piscina,
                                           Map<Long, BigDecimal> mensalidadeDoMesPorCliente) {
        // Em clientes com mais de uma piscina, mantém o valor individual até haver
        // lançamento individual por piscina. No caso normal (uma piscina), usa a
        // fotografia da mensalidade já criada para aquele mês.
        if (piscinas.findByClienteIdOrderByNome(piscina.getCliente().getId()).size() == 1) {
            return mensalidadeDoMesPorCliente.getOrDefault(piscina.getCliente().getId(),
                    piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade());
        }
        return piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade();
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
