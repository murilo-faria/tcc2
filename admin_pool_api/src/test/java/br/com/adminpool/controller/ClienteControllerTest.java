package br.com.adminpool.controller;

import br.com.adminpool.dto.NovoClienteRequest;
import br.com.adminpool.dto.PiscinaCadastroRequest;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Piscina;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.RoteiroAtendimentoRepository;
import br.com.adminpool.service.RelatorioPdfService;
import br.com.adminpool.service.CobrancaService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.authentication.TestingAuthenticationToken;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ClienteControllerTest {

    @Test
    void cadastraTodasAsPiscinasAdicionaisJuntoComOCliente() {
        ClienteRepository clientes = mock(ClienteRepository.class);
        PiscinaRepository piscinas = mock(PiscinaRepository.class);
        RoteiroAtendimentoRepository roteiro = mock(RoteiroAtendimentoRepository.class);
        ClienteController controller = new ClienteController(clientes, piscinas,
                mock(FuncionarioRepository.class), roteiro, new RelatorioPdfService(),
                mock(CobrancaService.class));
        when(clientes.save(any(Cliente.class))).thenAnswer(invocacao -> {
            Cliente cliente = invocacao.getArgument(0);
            cliente.setId(25L);
            return cliente;
        });

        NovoClienteRequest requisicao = new NovoClienteRequest(
                "Amanda", null, "", "Rua das Flores", new BigDecimal("250.00"), 10,
                LocalDate.now(), "Piscina principal", "Fibra", new BigDecimal("4"),
                new BigDecimal("3"), new BigDecimal("1.4"), new BigDecimal("15"), null,
                "Rua das Flores", null, null, "Segunda",
                List.of(new PiscinaCadastroRequest("Piscina dos fundos", "Alvenaria",
                        new BigDecimal("5"), new BigDecimal("2"), new BigDecimal("1.5"),
                        new BigDecimal("10"), "Rua das Flores", new BigDecimal("180.00"),
                        null, "Quinta")));

        controller.criar(requisicao, new TestingAuthenticationToken("gestor", null, "ROLE_GESTOR"));

        ArgumentCaptor<Piscina> piscinasSalvas = ArgumentCaptor.forClass(Piscina.class);
        verify(piscinas, org.mockito.Mockito.times(2)).save(piscinasSalvas.capture());
        assertEquals(List.of("Piscina principal", "Piscina dos fundos"),
                piscinasSalvas.getAllValues().stream().map(Piscina::getNome).toList());
        assertEquals(new BigDecimal("250.00"), piscinasSalvas.getAllValues().get(0).getValorMensalidade());
        assertEquals(new BigDecimal("180.00"), piscinasSalvas.getAllValues().get(1).getValorMensalidade());
        verify(roteiro, org.mockito.Mockito.times(2)).save(any());
    }
}
