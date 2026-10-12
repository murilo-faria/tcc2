package br.com.adminpool.service;

import br.com.adminpool.dto.ConcluirOrdemServicoRequest;
import br.com.adminpool.model.Cliente;
import br.com.adminpool.model.Funcionario;
import br.com.adminpool.model.OrdemServico;
import br.com.adminpool.model.ReembolsoColaborador;
import br.com.adminpool.model.ResponsavelPagamento;
import br.com.adminpool.repository.BaixaItemCobrancaRepository;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.CobrancaRepository;
import br.com.adminpool.repository.FuncionarioRepository;
import br.com.adminpool.repository.ItemCobrancaRepository;
import br.com.adminpool.repository.OrdemServicoRepository;
import br.com.adminpool.repository.PedidoProdutoRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.ReembolsoColaboradorRepository;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class OrdemServicoServiceTest {

    @Test
    void geraReembolsoParaOFuncionarioEscolhidoPeloGestor() {
        OrdemServicoRepository ordens = mock(OrdemServicoRepository.class);
        FuncionarioRepository funcionarios = mock(FuncionarioRepository.class);
        ReembolsoColaboradorRepository reembolsos = mock(ReembolsoColaboradorRepository.class);
        OrdemServico ordem = new OrdemServico();
        Cliente cliente = new Cliente();
        cliente.setNome("Amanda");
        ordem.setCliente(cliente);
        Funcionario funcionarioEscolhido = new Funcionario();
        funcionarioEscolhido.setId(7L);
        when(ordens.findById(24L)).thenReturn(Optional.of(ordem));
        when(funcionarios.findById(7L)).thenReturn(Optional.of(funcionarioEscolhido));
        when(ordens.save(any(OrdemServico.class))).thenAnswer(invocacao -> invocacao.getArgument(0));

        CobrancaService cobrancas = new CobrancaService(mock(CobrancaRepository.class),
                mock(ClienteRepository.class), mock(ItemCobrancaRepository.class),
                mock(BaixaItemCobrancaRepository.class), mock(PiscinaRepository.class),
                mock(PedidoProdutoRepository.class));
        OrdemServicoService service = new OrdemServicoService(ordens, mock(ClienteRepository.class),
                mock(PiscinaRepository.class), funcionarios, reembolsos, cobrancas);

        service.concluir(24L, new ConcluirOrdemServicoRequest(new BigDecimal("90.00"),
                BigDecimal.ZERO, ResponsavelPagamento.FUNCIONARIO, null, 7L));

        ArgumentCaptor<ReembolsoColaborador> reembolso = ArgumentCaptor.forClass(ReembolsoColaborador.class);
        verify(reembolsos).save(reembolso.capture());
        assertSame(funcionarioEscolhido, reembolso.getValue().getFuncionario());
    }
}
