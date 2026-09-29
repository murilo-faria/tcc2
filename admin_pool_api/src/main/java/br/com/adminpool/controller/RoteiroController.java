package br.com.adminpool.controller;

import br.com.adminpool.dto.RoteiroRequest;
import br.com.adminpool.dto.RoteiroResponse;
import br.com.adminpool.model.RoteiroAtendimento;
import br.com.adminpool.repository.ClienteRepository;
import br.com.adminpool.repository.PiscinaRepository;
import br.com.adminpool.repository.RoteiroAtendimentoRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/roteiro")
public class RoteiroController {
    private final RoteiroAtendimentoRepository atendimentos;
    private final ClienteRepository clientes;
    private final PiscinaRepository piscinas;
    private static final List<String> DIAS = List.of("Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado");
    public RoteiroController(RoteiroAtendimentoRepository atendimentos, ClienteRepository clientes, PiscinaRepository piscinas) { this.atendimentos=atendimentos; this.clientes=clientes; this.piscinas=piscinas; }
    @GetMapping public List<RoteiroResponse> listar(Authentication auth) {
        return atendimentos.findAllByOrderByIdAsc().stream()
                .filter(atendimento -> gestor(auth) || responsavelPorAlgumaPiscina(atendimento.getCliente().getId(), auth))
                .map(this::resposta).toList();
    }
    @PostMapping public ResponseEntity<RoteiroResponse> adicionar(@RequestBody RoteiroRequest r, Authentication auth) {
        validarDia(r.diaAtendimento()); var cliente=clientes.findById(r.clienteId()).orElseThrow(); autorizar(cliente.getId(), auth);
        if(atendimentos.existsByClienteIdAndDiaAtendimento(cliente.getId(),r.diaAtendimento())) throw new IllegalArgumentException("Esse cliente já está neste dia.");
        RoteiroAtendimento a=new RoteiroAtendimento(); a.setCliente(cliente); a.setDiaAtendimento(r.diaAtendimento()); return ResponseEntity.status(HttpStatus.CREATED).body(resposta(atendimentos.save(a)));
    }
    @PutMapping("/{id}") public RoteiroResponse atualizar(@PathVariable Long id,@RequestBody RoteiroRequest r,Authentication auth) { validarDia(r.diaAtendimento()); RoteiroAtendimento a=atendimentos.findById(id).orElseThrow(); autorizar(a.getCliente().getId(),auth); if(atendimentos.existsByClienteIdAndDiaAtendimento(a.getCliente().getId(),r.diaAtendimento())&&!a.getDiaAtendimento().equals(r.diaAtendimento())) throw new IllegalArgumentException("Esse cliente já está neste dia."); a.setDiaAtendimento(r.diaAtendimento()); return resposta(atendimentos.save(a)); }
    @DeleteMapping("/{id}") public ResponseEntity<Void> excluir(@PathVariable Long id,Authentication auth) { RoteiroAtendimento a=atendimentos.findById(id).orElseThrow(); autorizar(a.getCliente().getId(),auth); atendimentos.delete(a); return ResponseEntity.noContent().build(); }
    private RoteiroResponse resposta(RoteiroAtendimento a){return new RoteiroResponse(a.getId(),a.getCliente().getId(),a.getCliente().getNome(),a.getDiaAtendimento());}
    private void validarDia(String dia){if(!DIAS.contains(dia))throw new IllegalArgumentException("Escolha um dia de segunda a sábado.");}
    private void autorizar(Long clienteId,Authentication a){if(!gestor(a)&&!responsavelPorAlgumaPiscina(clienteId,a))throw new org.springframework.security.access.AccessDeniedException("Você só pode ajustar sua própria rota.");}
    private boolean responsavelPorAlgumaPiscina(Long clienteId, Authentication auth) {
        return piscinas.findByClienteIdOrderByNome(clienteId).stream()
                .anyMatch(piscina -> piscina.getResponsavel() != null
                        && piscina.getResponsavel().getUsuario() != null
                        && piscina.getResponsavel().getUsuario().getLogin().equalsIgnoreCase(auth.getName()));
    }
    private boolean gestor(Authentication a){return a.getAuthorities().stream().anyMatch(x->x.getAuthority().equals("ROLE_GESTOR"));}
}
