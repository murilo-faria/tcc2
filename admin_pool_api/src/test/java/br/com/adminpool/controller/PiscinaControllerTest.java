package br.com.adminpool.controller;

import br.com.adminpool.dto.AtualizarMedidasPiscinaRequest;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.TestingAuthenticationToken;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class PiscinaControllerTest {

    @Test
    void cadastraMedidasAusentesSemAlterarOsOutrosDadosDaPiscina() {
        PiscinaRepository piscinas = mock(PiscinaRepository.class);
        PiscinaController controller = new PiscinaController(piscinas,
                mock(ClienteRepository.class), mock(FuncionarioRepository.class));
        Piscina piscina = new Piscina();
        piscina.setNome("Piscina Goiás");
        piscina.setProfundidade(new BigDecimal("1.40"));
        piscina.setDescontoEscada(new BigDecimal("15"));
        when(piscinas.findById(9L)).thenReturn(Optional.of(piscina));
        when(piscinas.save(piscina)).thenReturn(piscina);

        controller.cadastrarMedidasParaCapa(9L,
                new AtualizarMedidasPiscinaRequest(new BigDecimal("4.5"), new BigDecimal("3")),
                new TestingAuthenticationToken("gestor", null, "ROLE_GESTOR"));

        assertEquals(new BigDecimal("4.5"), piscina.getComprimento());
        assertEquals(new BigDecimal("3"), piscina.getLargura());
        assertEquals(16065, piscina.getVolumeLitros());
        assertEquals("Piscina Goiás", piscina.getNome());
        verify(piscinas).save(piscina);
    }

    @Test
    void naoPermiteSobrescreverMedidasExistentesPeloPedidoDeCapa() {
        PiscinaRepository piscinas = mock(PiscinaRepository.class);
        PiscinaController controller = new PiscinaController(piscinas,
                mock(ClienteRepository.class), mock(FuncionarioRepository.class));
        Piscina piscina = new Piscina();
        piscina.setComprimento(new BigDecimal("4"));
        piscina.setLargura(new BigDecimal("3"));
        when(piscinas.findById(9L)).thenReturn(Optional.of(piscina));

        assertThrows(IllegalStateException.class, () -> controller.cadastrarMedidasParaCapa(9L,
                new AtualizarMedidasPiscinaRequest(new BigDecimal("5"), new BigDecimal("3")),
                new TestingAuthenticationToken("gestor", null, "ROLE_GESTOR")));
    }
}
