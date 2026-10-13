package br.com.adminpool.controller;

import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.CobrancaMensal;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.Perfil;
import br.com.adminpool.model.StatusCobranca;
import br.com.adminpool.model.Usuario;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.BaixaItemCobrancaRepository;
import br.com.adminpool.service.CobrancaService;
import br.com.adminpool.service.RelatorioPdfService;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CobrancaControllerTest {

    @Test
    void mesesAnterioresRetornamRespostaCompleta() throws Exception {
        CobrancaRepository repositorio = mock(CobrancaRepository.class);
        when(repositorio.findComClienteEItensPorReferencia("2026-09"))
                .thenReturn(List.of(cobranca("2026-09", "Setembro")));
        when(repositorio.findComClienteEItensPorReferencia("2026-10"))
                .thenReturn(List.of(cobranca("2026-10", "Outubro")));
        CobrancaService cobrancas = new CobrancaService(repositorio, mock(ClienteRepository.class),
                mock(ItemCobrancaRepository.class), mock(BaixaItemCobrancaRepository.class),
                mock(PiscinaRepository.class), mock(PedidoProdutoRepository.class));
        MockMvc mvc = MockMvcBuilders.standaloneSetup(new CobrancaController(cobrancas,
                new RelatorioPdfService(), mock(ClienteRepository.class),
                mock(PedidoProdutoRepository.class), null, null, null)).build();

        mvc.perform(get("/api/cobrancas").param("referencia", "2026-09"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].referencia").value("2026-09"))
                .andExpect(jsonPath("$[0].cliente.nome").value("Setembro"));
        mvc.perform(get("/api/cobrancas").param("referencia", "2026-10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].referencia").value("2026-10"))
                .andExpect(jsonPath("$[0].cliente.nome").value("Outubro"));
    }

    @Test
    void consultaMensalBuscaRelacionamentosNecessariosParaSerializacao() throws Exception {
        EntityGraph graph = br.com.adminpool.repository.CobrancaRepository.class
                .getMethod("findComClienteEItensPorReferencia", String.class)
                .getAnnotation(EntityGraph.class);

        assertTrue(List.of(graph.attributePaths()).containsAll(
                List.of("cliente", "cliente.funcionario", "cliente.funcionario.usuario", "itens")));
    }

    @Test
    void resumoDaVisaoGeralRetornaSomenteOsIndicadores() throws Exception {
        CobrancaRepository repositorio = mock(CobrancaRepository.class);
        ClienteRepository clientes = mock(ClienteRepository.class);
        String referencia = YearMonth.now().toString();
        when(clientes.findAll()).thenReturn(List.of());
        when(clientes.countByAtivoTrue()).thenReturn(12L);
        when(repositorio.findComClienteEItensPorReferencia(referencia)).thenReturn(List.of());
        when(repositorio.resumirPendenciasDoMes(referencia, StatusCobranca.PAGO))
                .thenReturn(new Object[]{4L, new BigDecimal("870.00")});
        CobrancaService cobrancas = new CobrancaService(repositorio, clientes,
                mock(ItemCobrancaRepository.class), mock(BaixaItemCobrancaRepository.class),
                mock(PiscinaRepository.class), mock(PedidoProdutoRepository.class));
        MockMvc mvc = MockMvcBuilders.standaloneSetup(new CobrancaController(cobrancas,
                new RelatorioPdfService(), clientes, mock(PedidoProdutoRepository.class),
                null, null, null)).build();

        mvc.perform(get("/api/cobrancas/resumo-visao-geral"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.clientesAtivos").value(12))
                .andExpect(jsonPath("$.cobrancasPendentes").value(4))
                .andExpect(jsonPath("$.faturamentoPrevisto").value(870));
    }

    private CobrancaMensal cobranca(String referencia, String nomeCliente) {
        Usuario usuario = new Usuario();
        usuario.setNome("Responsável " + nomeCliente);
        usuario.setPerfil(Perfil.FUNCIONARIO);
        Funcionario funcionario = new Funcionario();
        funcionario.setUsuario(usuario);
        Cliente cliente = new Cliente();
        cliente.setNome(nomeCliente);
        cliente.setFuncionario(funcionario);
        CobrancaMensal cobranca = new CobrancaMensal();
        cobranca.setCliente(cliente);
        cobranca.setReferencia(referencia);
        cobranca.setVencimento(LocalDate.of(2026, Integer.parseInt(referencia.substring(5)), 10));
        cobranca.setTotal(new BigDecimal("200.00"));
        cobranca.setStatus(StatusCobranca.PENDENTE);
        return cobranca;
    }
}
