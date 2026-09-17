package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.ReembolsoColaborador;
import br.com.adminpool.model.StatusReembolso;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.ReembolsoColaboradorRepository;
import br.com.adminpool.repository.ValeColaboradorRepository;
import br.com.adminpool.model.ValeColaborador;
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

    public SalarioController(FuncionarioRepository funcionarios, PiscinaRepository piscinas,
                             ReembolsoColaboradorRepository reembolsos, ValeColaboradorRepository vales) {
        this.funcionarios = funcionarios;
        this.piscinas = piscinas;
        this.reembolsos = reembolsos;
        this.vales = vales;
    }

    @GetMapping("/vales") public List<ValeColaborador> listarVales(Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem consultar vales."); YearMonth mes=YearMonth.now(); return vales.findAll().stream().filter(v -> !v.getDataLancamento().isBefore(mes.atDay(1)) && !v.getDataLancamento().isAfter(mes.atEndOfMonth())).toList(); }
    @PostMapping("/vales") public ValeColaborador criarVale(@RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem lançar vales."); ValeColaborador v=new ValeColaborador(); v.setFuncionario(funcionarios.findById(Long.valueOf(dados.get("funcionarioId").toString())).orElseThrow()); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); v.setDataLancamento(LocalDate.now()); return vales.save(v); }
    @PutMapping("/vales/{id}") public ValeColaborador editarVale(@PathVariable Long id, @RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar vales."); ValeColaborador v=vales.findById(id).orElseThrow(); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); return vales.save(v); }
    @DeleteMapping("/vales/{id}") public ResponseEntity<Void> excluirVale(@PathVariable Long id, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir vales."); vales.deleteById(id); return ResponseEntity.noContent().build(); }

    @GetMapping
    public List<Map<String, Object>> listar(Authentication auth) {
        boolean gestor = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
        return funcionarios.findAll().stream()
                .filter(f -> gestor || f.getUsuario().getLogin().equalsIgnoreCase(auth.getName()))
                .map(this::resumo)
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

    private Map<String, Object> resumo(Funcionario funcionario) {
        var piscinasVinculadas = piscinas.findByResponsavelId(funcionario.getId());
        var clientes = piscinasVinculadas.stream()
                .map(p -> p.getCliente())
                .collect(Collectors.toMap(Cliente::getId, cliente -> cliente, (a, b) -> a))
                .values();
        BigDecimal baseMensal = piscinasVinculadas.stream()
                .map(br.com.adminpool.model.Piscina::getValorMensalidade)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal salario = baseMensal.multiply(funcionario.getPercentualMensalidade())
                .divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
        BigDecimal totalReembolsos = reembolsos
                .findByFuncionarioIdAndStatusOrderByDataLancamentoAsc(funcionario.getId(), StatusReembolso.PENDENTE)
                .stream().map(ReembolsoColaborador::getValor).reduce(BigDecimal.ZERO, BigDecimal::add);
        YearMonth mesAtual = YearMonth.now();
        BigDecimal totalVales = vales.findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(funcionario.getId(), mesAtual.atDay(1), mesAtual.atEndOfMonth()).stream().map(ValeColaborador::getValor).reduce(BigDecimal.ZERO, BigDecimal::add);
        Map<String, Object> resultado = new LinkedHashMap<>();
        resultado.put("funcionario", funcionario);
        resultado.put("piscinas", piscinasVinculadas.size());
        resultado.put("clientes", clientes.size());
        resultado.put("baseMensal", baseMensal);
        resultado.put("salario", salario);
        resultado.put("reembolsos", totalReembolsos);
        resultado.put("vales", totalVales);
        resultado.put("totalPagar", salario.add(totalReembolsos).subtract(totalVales).max(BigDecimal.ZERO));
        return resultado;
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }
}
