package br.com.adminpool.controller;

import br.com.adminpool.model.*; import br.com.adminpool.repository.*; import br.com.adminpool.service.LancamentoCobrancaService; import org.springframework.http.*; import org.springframework.web.bind.annotation.*; import java.math.BigDecimal; import java.time.LocalDate; import java.util.*;
@RestController @RequestMapping("/api/ordens-servico") @CrossOrigin(originPatterns="http://localhost:*")
public class OrdemServicoController {
 private final OrdemServicoRepository ordens; private final ClienteRepository clientes; private final PiscinaRepository piscinas; private final LancamentoCobrancaService lancamentos;
 public OrdemServicoController(OrdemServicoRepository o,ClienteRepository c,PiscinaRepository p,LancamentoCobrancaService l){ordens=o;clientes=c;piscinas=p;lancamentos=l;}
 @GetMapping public List<OrdemServico> listarTodas(){return ordens.findAllByOrderByDataServicoDesc();}
 @GetMapping("/cliente/{clienteId}") public List<OrdemServico> listar(@PathVariable Long clienteId){return ordens.findByClienteIdOrderByDataServicoDesc(clienteId);}
 @GetMapping("/abertas") public List<OrdemServico> abertas(){return ordens.findByStatusOrderByDataServicoDesc("ABERTA");}
 @PutMapping("/{id}/status") public ResponseEntity<Void> alterarStatus(@PathVariable Long id,@RequestParam String status){OrdemServico o=ordens.findById(id).orElseThrow();o.setStatus(status);ordens.save(o);return ResponseEntity.noContent().build();}
 @DeleteMapping("/{id}") public ResponseEntity<Void> excluir(@PathVariable Long id){ordens.deleteById(id);return ResponseEntity.noContent().build();}
 @PostMapping public ResponseEntity<OrdemServico> criar(@RequestBody NovaOrdem r){OrdemServico o=new OrdemServico();o.setCliente(clientes.findById(r.clienteId()).orElseThrow());if(r.piscinaId()!=null)o.setPiscina(piscinas.findById(r.piscinaId()).orElseThrow());o.setDescricao(r.descricao());o.setDataServico(r.dataServico()==null?LocalDate.now():r.dataServico());o.setValorAdicional(r.valorAdicional()==null?BigDecimal.ZERO:r.valorAdicional());o=ordens.save(o);if(o.getValorAdicional().signum()>0)lancamentos.adicionarServico(r.clienteId(),o.getValorAdicional());return ResponseEntity.status(HttpStatus.CREATED).body(o);}
 public record NovaOrdem(Long clienteId,Long piscinaId,String descricao,LocalDate dataServico,BigDecimal valorAdicional){}
}
