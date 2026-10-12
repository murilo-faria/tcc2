package br.com.adminpool.controller;

import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.service.OrdemServicoService;
import br.com.adminpool.service.RelatorioPdfService;
import br.com.adminpool.model.OrdemServico;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.TestingAuthenticationToken;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrdemServicoControllerTest {

    @Test
    void listaDoGestorUsaConsultaQueSeparaAbertasDeConcluidasPorNumero() {
        OrdemServicoRepository repositorio = mock(OrdemServicoRepository.class);
        OrdemServicoController controller = new OrdemServicoController(
                repositorio,
                new OrdemServicoService(repositorio, null, null, null, null, null),
                new RelatorioPdfService());
        List<OrdemServico> esperado = List.of();
        when(repositorio.findTodasOrdenadasParaListagem()).thenReturn(esperado);

        var resultado = controller.listarTodas(
                new TestingAuthenticationToken("gestor", null, "ROLE_GESTOR"));

        assertSame(esperado, resultado);
        verify(repositorio).findTodasOrdenadasParaListagem();
    }
}
