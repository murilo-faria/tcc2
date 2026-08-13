package br.com.adminpool.controller;

import br.com.adminpool.model.*; import br.com.adminpool.repository.*; import org.springframework.http.*; import org.springframework.web.bind.annotation.*; import java.util.*;
@RestController @RequestMapping("/api/piscinas") @CrossOrigin(originPatterns="http://localhost:*")
public class PiscinaController {
 private final PiscinaRepository piscinas; private final ClienteRepository clientes;
 public PiscinaController(PiscinaRepository piscinas, ClienteRepository clientes){this.piscinas=piscinas;this.clientes=clientes;}
 @GetMapping("/cliente/{clienteId}") public List<Piscina> listar(@PathVariable Long clienteId){return piscinas.findByClienteIdOrderByNome(clienteId);}
 @PostMapping public ResponseEntity<Piscina> criar(@RequestBody NovaPiscina r){Piscina p=new Piscina();p.setCliente(clientes.findById(r.clienteId()).orElseThrow());p.setNome(r.nome());p.setTipo(r.tipo());p.setVolumeLitros(r.volumeLitros());p.setObservacoes(r.observacoes());return ResponseEntity.status(HttpStatus.CREATED).body(piscinas.save(p));}
 public record NovaPiscina(Long clienteId,String nome,String tipo,Integer volumeLitros,String observacoes){}
}
