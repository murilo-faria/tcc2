package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/salarios")
public class SalarioController {
    private final FuncionarioRepository funcionarios;
    private final PiscinaRepository piscinas;

    public SalarioController(FuncionarioRepository funcionarios, PiscinaRepository piscinas) {
        this.funcionarios = funcionarios;
        this.piscinas = piscinas;
    }

    @GetMapping
    public List<Map<String, Object>> listar(Authentication auth) {
        boolean gestor = auth.getAuthorities().stream()
                .anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
        return funcionarios.findAll().stream()
                .filter(f -> gestor || f.getUsuario().getLogin().equalsIgnoreCase(auth.getName()))
                .map(this::resumo)
                .toList();
    }

    private Map<String, Object> resumo(Funcionario funcionario) {
        var piscinasVinculadas = piscinas.findByResponsavelId(funcionario.getId());
        var clientes = piscinasVinculadas.stream()
                .map(p -> p.getCliente())
                .collect(Collectors.toMap(Cliente::getId, cliente -> cliente, (a, b) -> a))
                .values();
        BigDecimal baseMensal = clientes.stream()
                .map(Cliente::getValorMensalidade)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal salario = baseMensal.multiply(funcionario.getPercentualMensalidade())
                .divide(new BigDecimal("100"), 2, RoundingMode.HALF_UP);
        return Map.of("funcionario", funcionario, "piscinas", piscinasVinculadas.size(),
                "clientes", clientes.size(), "baseMensal", baseMensal, "salario", salario);
    }
}
