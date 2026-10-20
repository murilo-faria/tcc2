package br.com.adminpool.service;
import br.com.adminpool.model.*;
import br.com.adminpool.repository.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import java.math.BigDecimal;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

@DataJpaTest(properties={"spring.flyway.enabled=false", "spring.jpa.hibernate.ddl-auto=create-drop"})
class CobrancaExclusaoJpaTest {
 @Autowired TestEntityManager em;
 @Autowired CobrancaRepository cobrancas;
 @Autowired ClienteRepository clientes;
 @Autowired ItemCobrancaRepository itens;
 @Autowired BaixaItemCobrancaRepository baixas;
 @Test void exclusaoFisicaPermaneceDepoisDeRecarregarDoBanco() {
  var cliente = new Cliente(); cliente.setNome("Teste exclusao"); cliente.setValorMensalidade(BigDecimal.ZERO); em.persist(cliente);
  var c = new CobrancaMensal(); c.setCliente(cliente); c.setReferencia("2026-10"); c.setVencimento(LocalDate.now()); c.setMensalidade(BigDecimal.ZERO); c.setTotal(new BigDecimal("175")); em.persist(c);
  var item = new ItemCobranca(); item.setCobranca(c); item.setTipo(TipoLancamentoCobranca.PEDIDO); item.setOrigemId(84L); item.setDescricao("Pedido #84"); item.setValorOriginal(new BigDecimal("175")); em.persistAndFlush(item);
  var outro = new ItemCobranca(); outro.setCobranca(c); outro.setTipo(TipoLancamentoCobranca.PEDIDO); outro.setOrigemId(53L); outro.setDescricao("Pedido #53"); outro.setValorOriginal(new BigDecimal("175")); em.persistAndFlush(outro);
  Long outroId = outro.getId(); Long id = item.getId(); Long cid = c.getId(); em.clear();
  var service = new CobrancaService(cobrancas,clientes,itens,baixas,mock(PiscinaRepository.class),mock(PedidoProdutoRepository.class));
  service.excluirCobrancaDeOrigem(id);
  em.flush(); em.clear();
  assertTrue(itens.findById(id).isEmpty());
  assertTrue(itens.findById(outroId).isPresent());
  assertEquals(0, cobrancas.findById(cid).orElseThrow().getTotal().compareTo(new BigDecimal("175")));
 }
}
