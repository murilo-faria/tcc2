package br.com.adminpool.service;
import br.com.adminpool.model.*; import br.com.adminpool.repository.*; import org.springframework.stereotype.Service; import java.math.BigDecimal; import java.time.*; import java.util.*;
@Service public class CobrancaService {
 private final CobrancaRepository cobrancas; private final ClienteRepository clientes;
 public CobrancaService(CobrancaRepository cobrancas,ClienteRepository clientes){this.cobrancas=cobrancas;this.clientes=clientes;}
 public List<CobrancaMensal> listarPorVencimento(){return cobrancas.findAllByOrderByVencimentoAsc();}
 public CobrancaMensal gerar(Cliente cliente, YearMonth mes){ if(cliente.getDiaVencimento()==null) throw new IllegalArgumentException("Cliente sem dia de vencimento"); CobrancaMensal c=new CobrancaMensal(); c.setCliente(cliente); c.setReferencia(mes.toString()); c.setVencimento(mes.atDay(Math.min(cliente.getDiaVencimento(),mes.lengthOfMonth()))); c.setMensalidade(cliente.getValorMensalidade()); c.setProdutos(BigDecimal.ZERO); c.setServicos(BigDecimal.ZERO); c.setTotal(cliente.getValorMensalidade()); return cobrancas.save(c); }
 public List<CobrancaMensal> gerarMesAtual(){YearMonth mes=YearMonth.now(); List<CobrancaMensal> resultado=new ArrayList<>(); for(Cliente c:clientes.findAll()) if(c.isAtivo()&&c.getDiaVencimento()!=null) resultado.add(gerar(c,mes)); return resultado;}
 public CobrancaMensal baixa(Long id,BigDecimal valor){CobrancaMensal c=cobrancas.findById(id).orElseThrow(); c.setStatus(StatusCobranca.PAGO);c.setDataPagamento(LocalDate.now());c.setValorPago(valor);return cobrancas.save(c);}
 public CobrancaMensal reabrir(Long id){CobrancaMensal c=cobrancas.findById(id).orElseThrow(); c.setStatus(c.getVencimento().isBefore(LocalDate.now()) ? StatusCobranca.VENCIDO : StatusCobranca.PENDENTE);c.setDataPagamento(null);c.setValorPago(null);return cobrancas.save(c);}
}
