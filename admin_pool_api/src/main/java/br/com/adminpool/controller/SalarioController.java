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
import br.com.adminpool.model.ItemCobranca;
import br.com.adminpool.model.StatusItemCobranca;
import br.com.adminpool.model.TipoLancamentoCobranca;
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

    public SalarioController(FuncionarioRepository funcionarios, PiscinaRepository piscinas,
                             ReembolsoColaboradorRepository reembolsos, ValeColaboradorRepository vales,
                             CobrancaRepository cobrancas) {
        this.funcionarios = funcionarios;
        this.piscinas = piscinas;
        this.reembolsos = reembolsos;
        this.vales = vales;
        this.cobrancas = cobrancas;
    }

    @GetMapping("/vales") public List<ValeColaborador> listarVales(@RequestParam(required = false) Long funcionarioId, @RequestParam(required = false) String referencia, Authentication auth) { YearMonth mes=referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia); return vales.findAll().stream().filter(v -> !v.getDataLancamento().isBefore(mes.atDay(1)) && !v.getDataLancamento().isAfter(mes.atEndOfMonth())).filter(v -> gestor(auth) ? funcionarioId == null || v.getFuncionario().getId().equals(funcionarioId) : v.getFuncionario().getUsuario().getLogin().equalsIgnoreCase(auth.getName())).toList(); }
    @PostMapping("/vales") public ValeColaborador criarVale(@RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem lançar vales."); ValeColaborador v=new ValeColaborador(); v.setFuncionario(funcionarios.findById(Long.valueOf(dados.get("funcionarioId").toString())).orElseThrow()); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); v.setDataLancamento(mesDoVale(dados)); return vales.save(v); }
    @PutMapping("/vales/{id}") public ValeColaborador editarVale(@PathVariable Long id, @RequestBody Map<String,Object> dados, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem editar vales."); ValeColaborador v=vales.findById(id).orElseThrow(); v.setTipo(dados.get("tipo").toString()); v.setValor(new BigDecimal(dados.get("valor").toString())); v.setObservacao(String.valueOf(dados.getOrDefault("observacao", ""))); v.setDataLancamento(mesDoVale(dados)); return vales.save(v); }
    @DeleteMapping("/vales/{id}") public ResponseEntity<Void> excluirVale(@PathVariable Long id, Authentication auth) { if (!gestor(auth)) throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem excluir vales."); vales.deleteById(id); return ResponseEntity.noContent().build(); }

    @GetMapping
    public List<Map<String, Object>> listar(@RequestParam(required = false) String referencia) {
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        Map<Long, BigDecimal> mensalidadeDoMesPorCliente = mensalidadesPorCliente(mes);
        Map<Long, ItemCobranca> mensalidadesDaReferencia = itensMensalidadePorCliente(mes);
        return funcionarios.findAll().stream()
                .map(f -> resumo(f, mes, mensalidadeDoMesPorCliente, mensalidadesDaReferencia))
                .toList();
    }

    /** Rota exclusiva do colaborador: nunca retorna a folha de outras pessoas. */
    @GetMapping("/meu")
    public List<Map<String, Object>> meuSalario(@RequestParam(required = false) String referencia,
                                                Authentication auth) {
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        Funcionario funcionario = funcionarios.findByUsuarioLoginIgnoreCase(auth.getName())
                .orElseThrow(() -> new org.springframework.security.access.AccessDeniedException(
                        "Colaborador não encontrado."));
        return List.of(resumo(funcionario, mes, mensalidadesPorCliente(mes), itensMensalidadePorCliente(mes)));
    }

    /** Detalhes de reembolso do próprio colaborador, sem aceitar identificador externo. */
    @GetMapping("/meu/reembolsos")
    public List<ReembolsoColaborador> meusReembolsos(@RequestParam(required = false) String referencia,
                                                     Authentication auth) {
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        Funcionario funcionario = funcionarios.findByUsuarioLoginIgnoreCase(auth.getName())
                .orElseThrow(() -> new org.springframework.security.access.AccessDeniedException(
                        "Colaborador não encontrado."));
        return reembolsos.findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(
                funcionario.getId(), mes.atDay(1), mes.atEndOfMonth());
    }

    /** Vales do próprio colaborador, sem filtro que permita consultar outra pessoa. */
    @GetMapping("/meu/vales")
    public List<ValeColaborador> meusVales(@RequestParam(required = false) String referencia,
                                           Authentication auth) {
        YearMonth mes = referencia == null || referencia.isBlank() ? YearMonth.now() : YearMonth.parse(referencia);
        Funcionario funcionario = funcionarios.findByUsuarioLoginIgnoreCase(auth.getName())
                .orElseThrow(() -> new org.springframework.security.access.AccessDeniedException(
                        "Colaborador não encontrado."));
        return vales.findByFuncionarioIdAndDataLancamentoBetweenOrderByDataLancamentoDesc(
                funcionario.getId(), mes.atDay(1), mes.atEndOfMonth());
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
        if (!mes.isAfter(YearMonth.now())) {
            Map<Long, ItemCobranca> mensalidades = itensMensalidadePorCliente(mes);
            List<Map<String, Object>> fotografia = mensalidades.values().stream()
                    .filter(item -> item.getResponsavelReferencia() != null
                            && item.getResponsavelReferencia().getId().equals(funcionarioId)
                            && item.getStatus() != StatusItemCobranca.CANCELADO)
                    .map(item -> linhaDaComissao(item.getCobranca().getCliente(), item.getValorOriginal()))
                    .toList();
            if (!fotografia.isEmpty()) return fotografia;
        }
        return piscinas.findByResponsavelId(funcionarioId).stream()
                .filter(piscina -> {
                    Cliente cliente = piscina.getCliente();
                    if (!cliente.isAtivo()) {
                        return false;
                    }
                    LocalDate primeiroVencimento = cliente.getPrimeiroVencimento();
                    return primeiroVencimento == null || !primeiroVencimento.isAfter(mes.atEndOfMonth());
                })
                .map(piscina -> linhaDaComissao(piscina.getCliente(),
                        piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade()))
                .toList();
    }

    private Map<String, Object> linhaDaComissao(Cliente cliente, BigDecimal valor) {
        Map<String, Object> item = new LinkedHashMap<>();
        item.put("id", cliente.getId());
        item.put("cliente", cliente.getNome());
        item.put("piscina", piscinas.findByClienteIdOrderByNome(cliente.getId()).stream()
                .map(br.com.adminpool.model.Piscina::getNome).collect(Collectors.joining(", ")));
        item.put("valor", valor == null ? BigDecimal.ZERO : valor);
        return item;
    }

    /** Compara a base já lançada de um mês com a projeção do mês seguinte. */
    @GetMapping("/{funcionarioId}/comparativo")
    public List<Map<String, Object>> compararMeses(@PathVariable Long funcionarioId,
                                                    @RequestParam String referencia,
                                                    Authentication auth) {
        if (!gestor(auth)) {
            throw new org.springframework.security.access.AccessDeniedException("Apenas gestores podem comparar comissões.");
        }
        Funcionario funcionario = funcionarios.findById(funcionarioId).orElseThrow();
        YearMonth mesAtual = YearMonth.parse(referencia);
        YearMonth proximoMes = mesAtual.plusMonths(1);
        Map<Long, BigDecimal> valoresAtuais = mensalidadesPorCliente(mesAtual);
        Map<Long, BigDecimal> valoresProximos = mensalidadesPorCliente(proximoMes);
        Map<Long, ItemCobranca> mensalidadesAtuais = itensMensalidadePorCliente(mesAtual);
        List<br.com.adminpool.model.Piscina> piscinasNoProximoMes = piscinas.findByResponsavelId(funcionarioId).stream()
                .filter(piscina -> elegivelNoMes(piscina.getCliente(), proximoMes))
                .toList();
        Map<Long, Cliente> clientesComparados = new LinkedHashMap<>();
        // Outubro usa quem estava registrado na mensalidade; novembro usa o
        // responsável atual da piscina. Assim uma transferência aparece dos dois lados.
        mensalidadesAtuais.values().stream()
                .filter(item -> item.getResponsavelReferencia() != null
                        && item.getResponsavelReferencia().getId().equals(funcionarioId))
                .forEach(item -> clientesComparados.put(item.getCobranca().getCliente().getId(),
                        item.getCobranca().getCliente()));
        piscinasNoProximoMes.forEach(piscina -> clientesComparados.put(piscina.getCliente().getId(), piscina.getCliente()));
        List<br.com.adminpool.model.Piscina> piscinasNoMesAtual = piscinas.findByResponsavelId(funcionarioId).stream()
                .filter(piscina -> elegivelNoMes(piscina.getCliente(), mesAtual))
                .toList();
        return clientesComparados.values().stream()
                .map(cliente -> {
                    ItemCobranca mensalidadeAtual = mensalidadesAtuais.get(cliente.getId());
                    BigDecimal atual;
                    if (mensalidadeAtual != null && mensalidadeAtual.getResponsavelReferencia() != null) {
                        atual = mensalidadeAtual.getResponsavelReferencia().getId().equals(funcionarioId)
                                && mensalidadeAtual.getStatus() != StatusItemCobranca.CANCELADO
                                ? mensalidadeAtual.getValorOriginal() : BigDecimal.ZERO;
                    } else {
                        atual = elegivelNoMes(cliente, mesAtual)
                                ? valorDoClienteNoMes(funcionario, cliente, piscinasNoMesAtual, valoresAtuais)
                                : BigDecimal.ZERO;
                    }
                    BigDecimal proximo = valorDoClienteNoMes(funcionario, cliente, piscinasNoProximoMes, valoresProximos);
                    Map<String, Object> item = new LinkedHashMap<>();
                    item.put("cliente", cliente.getNome());
                    item.put("piscinas", piscinas.findByClienteIdOrderByNome(cliente.getId()).stream()
                            .map(br.com.adminpool.model.Piscina::getNome).collect(Collectors.joining(", ")));
                    item.put("valorAtual", atual);
                    item.put("valorProximo", proximo);
                    item.put("diferenca", proximo.subtract(atual));
                    return item;
                })
                .filter(item -> ((BigDecimal) item.get("diferenca")).compareTo(BigDecimal.ZERO) != 0)
                .sorted((a, b) -> ((BigDecimal) b.get("diferenca")).abs()
                        .compareTo(((BigDecimal) a.get("diferenca")).abs()))
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
                                       Map<Long, BigDecimal> mensalidadeDoMesPorCliente,
                                       Map<Long, ItemCobranca> mensalidadesDaReferencia) {
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
        boolean mesAtualOuPassado = !mes.isAfter(YearMonth.now());
        Map<Long, BigDecimal> valoresFotografados = mensalidadesDaReferencia.values().stream()
                .filter(item -> item.getResponsavelReferencia() != null
                        && item.getResponsavelReferencia().getId().equals(funcionario.getId()))
                .collect(Collectors.toMap(item -> item.getCobranca().getCliente().getId(), item ->
                                item.getStatus() == StatusItemCobranca.CANCELADO
                                        ? BigDecimal.ZERO
                                        : item.getValorOriginal() == null ? BigDecimal.ZERO : item.getValorOriginal(),
                        (primeiro, segundo) -> primeiro));
        BigDecimal baseMensal = valoresFotografados.values().stream().reduce(BigDecimal.ZERO, BigDecimal::add);
        if (!mesAtualOuPassado) {
            baseMensal = clientes.stream()
                    .map(cliente -> valorDoClienteNoMes(funcionario, cliente, piscinasVinculadas,
                            mensalidadeDoMesPorCliente))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
        } else {
            // Mensalidades antigas (sem a nova fotografia) continuam pelo
            // comportamento anterior para não perder registros já existentes.
            BigDecimal legado = clientes.stream()
                    .filter(cliente -> !mensalidadesDaReferencia.containsKey(cliente.getId())
                            || mensalidadesDaReferencia.get(cliente.getId()).getResponsavelReferencia() == null)
                    .map(cliente -> valorDoClienteNoMes(funcionario, cliente, piscinasVinculadas,
                            mensalidadeDoMesPorCliente))
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            baseMensal = baseMensal.add(legado);
        }
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
        // A folha não expõe a entidade JPA diretamente: quando uma
        // mensalidade traz o responsável fotografado, ele pode estar como
        // proxy do Hibernate e quebrar a resposta JSON do mês inteiro.
        resultado.put("funcionario", dadosDoFuncionario(funcionario));
        resultado.put("piscinas", piscinasVinculadas.size());
        resultado.put("clientes", clientes.size());
        resultado.put("baseMensal", baseMensal);
        resultado.put("salario", salario);
        resultado.put("reembolsos", totalReembolsos);
        resultado.put("vales", totalVales);
        BigDecimal saldoDaFolha = salario.add(totalReembolsos).subtract(totalVales);
        resultado.put("totalPagar", saldoDaFolha.max(BigDecimal.ZERO));
        // Não apaga o excedente de vale: ele precisa ficar visível para ser
        // compensado manualmente no pagamento seguinte.
        resultado.put("saldoNegativo", saldoDaFolha.min(BigDecimal.ZERO).abs());
        resultado.put("referencia", mes.toString());
        return resultado;
    }

    private Map<String, Object> dadosDoFuncionario(Funcionario funcionario) {
        Map<String, Object> usuario = new LinkedHashMap<>();
        usuario.put("id", funcionario.getUsuario().getId());
        usuario.put("nome", funcionario.getUsuario().getNome());
        usuario.put("perfil", funcionario.getUsuario().getPerfil().name());
        Map<String, Object> resultado = new LinkedHashMap<>();
        resultado.put("id", funcionario.getId());
        resultado.put("percentualMensalidade", funcionario.getPercentualMensalidade());
        resultado.put("usuario", usuario);
        return resultado;
    }

    private boolean elegivelNoMes(Cliente cliente, YearMonth mes) {
        return cliente.isAtivo() && (cliente.getPrimeiroVencimento() == null
                || !cliente.getPrimeiroVencimento().isAfter(mes.atEndOfMonth()));
    }

    /** A comissão usa o lançamento do mês, e não o preço que foi alterado hoje no cadastro. */
    private Map<Long, BigDecimal> mensalidadesPorCliente(YearMonth mes) {
        boolean mesFuturo = mes.isAfter(YearMonth.now());
        return cobrancas.findComClienteEItensPorReferencia(mes.toString()).stream()
                // Uma cobrança pode existir sem mensalidade (por exemplo, depois de
                // remover uma mensalidade lançada antes da hora). Isso não é valor
                // zero: para a prévia, deve valer o preço cadastrado na piscina.
                .filter(cobranca -> cobranca.getItens().stream().anyMatch(item ->
                        item.getTipo() == TipoLancamentoCobranca.MENSALIDADE
                                && (!mesFuturo || item.getStatus() != StatusItemCobranca.CANCELADO)))
                .collect(Collectors.toMap(c -> c.getCliente().getId(), cobranca -> {
                    var mensalidade = cobranca.getItens().stream()
                            .filter(item -> item.getTipo() == TipoLancamentoCobranca.MENSALIDADE)
                            .findFirst().orElseThrow();
                    return mensalidade.getStatus() == StatusItemCobranca.CANCELADO
                            ? BigDecimal.ZERO
                            : mensalidade.getValorOriginal() == null ? BigDecimal.ZERO : mensalidade.getValorOriginal();
                },
                        (primeiro, segundo) -> primeiro));
    }

    /** Mensalidade com o responsável fotografado na data do lançamento. */
    private Map<Long, ItemCobranca> itensMensalidadePorCliente(YearMonth mes) {
        Map<Long, ItemCobranca> resultado = new LinkedHashMap<>();
        cobrancas.findComClienteEItensPorReferencia(mes.toString()).forEach(cobranca -> cobranca.getItens().stream()
                .filter(item -> item.getTipo() == TipoLancamentoCobranca.MENSALIDADE)
                .findFirst().ifPresent(item -> resultado.put(cobranca.getCliente().getId(), item)));
        return resultado;
    }

    private BigDecimal valorMensalidade(CobrancaMensal cobranca) {
        return cobranca.getItens().stream()
                .filter(item -> item.getTipo() == TipoLancamentoCobranca.MENSALIDADE)
                .map(item -> item.getValorOriginal() == null ? BigDecimal.ZERO : item.getValorOriginal())
                .findFirst().orElse(BigDecimal.ZERO);
    }

    private BigDecimal valorDoClienteNoMes(Funcionario funcionario, Cliente cliente,
                                           List<br.com.adminpool.model.Piscina> piscinasDoFuncionario,
                                           Map<Long, BigDecimal> mensalidadeDoMesPorCliente) {
        List<br.com.adminpool.model.Piscina> todasDoCliente = piscinas.findByClienteIdOrderByNome(cliente.getId());
        boolean clienteTodoDoFuncionario = !todasDoCliente.isEmpty() && todasDoCliente.stream()
                .allMatch(piscina -> piscina.getResponsavel() != null
                        && piscina.getResponsavel().getId().equals(funcionario.getId()));
        if (clienteTodoDoFuncionario) {
            BigDecimal valorLancado = mensalidadeDoMesPorCliente.get(cliente.getId());
            if (valorLancado != null) {
                return valorLancado;
            }
            // Consulta de mês futuro é somente uma prévia: usa o valor cadastrado,
            // sem criar uma cobrança antecipada.
            return todasDoCliente.stream()
                    .map(piscina -> piscina.getValorMensalidade() == null
                            ? BigDecimal.ZERO : piscina.getValorMensalidade())
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
        }
        // Caso raro de piscinas do mesmo cliente divididas entre colaboradores:
        // mantém apenas a parcela das piscinas deste colaborador.
        return piscinasDoFuncionario.stream()
                .filter(piscina -> piscina.getCliente().getId().equals(cliente.getId()))
                .map(piscina -> piscina.getValorMensalidade() == null ? BigDecimal.ZERO : piscina.getValorMensalidade())
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private boolean gestor(Authentication auth) {
        return auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_GESTOR"));
    }

    /** Um vale pertence ao mês escolhido na folha; o dia é apenas técnico. */
    private LocalDate mesDoVale(Map<String, Object> dados) {
        Object referencia = dados.get("referencia");
        if (referencia == null || referencia.toString().isBlank()) return LocalDate.now();
        try {
            return YearMonth.parse(referencia.toString()).atDay(1);
        } catch (java.time.format.DateTimeParseException erro) {
            throw new IllegalArgumentException("Informe um mês válido para o vale.");
        }
    }
}
